-- Courier order claiming, ownership, customer notifications, and cancellation.
-- Run this migration once in the Supabase SQL editor for an existing project.

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS courier_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.orders
  ALTER COLUMN courier_name DROP DEFAULT,
  ALTER COLUMN courier_phone DROP DEFAULT,
  ALTER COLUMN courier_vehicle DROP DEFAULT,
  ALTER COLUMN courier_avatar DROP DEFAULT,
  ALTER COLUMN driver_progress SET DEFAULT 0,
  ALTER COLUMN estimated_arrival_minutes DROP DEFAULT;

-- Remove placeholder courier data from orders that have not been claimed.
UPDATE public.orders
SET courier_name = NULL,
    courier_phone = NULL,
    courier_vehicle = NULL,
    courier_avatar = NULL,
    driver_progress = 0,
    estimated_arrival_minutes = NULL
WHERE courier_id IS NULL;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS related_order_id TEXT REFERENCES public.orders(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS orders_courier_id_idx ON public.orders(courier_id);
CREATE INDEX IF NOT EXISTS notifications_user_created_idx
  ON public.notifications(user_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  );
$$;
REVOKE ALL ON FUNCTION public.is_current_user_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO authenticated;

DROP POLICY IF EXISTS "Orders can be updated" ON public.orders;
DROP POLICY IF EXISTS "Admins can update orders" ON public.orders;
CREATE POLICY "Admins can update orders" ON public.orders
  FOR UPDATE TO authenticated
  USING (
    public.is_current_user_admin()
  )
  WITH CHECK (
    public.is_current_user_admin()
  );

DROP POLICY IF EXISTS "Notifications are viewable by everyone" ON public.notifications;
DROP POLICY IF EXISTS "Users can view own and broadcast notifications" ON public.notifications;
CREATE POLICY "Users can view own and broadcast notifications" ON public.notifications
  FOR SELECT
  USING (user_id IS NULL OR user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.claim_courier_order(p_order_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_courier_name TEXT;
  v_courier_phone TEXT;
  v_customer_id UUID;
  v_rows INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Sign in to accept an order.';
  END IF;

  SELECT da.full_name, da.phone
    INTO v_courier_name, v_courier_phone
  FROM public.driver_applications da
  WHERE da.user_id = auth.uid() AND da.status = 'approved'
  ORDER BY da.created_at DESC
  LIMIT 1;

  IF v_courier_name IS NULL OR v_courier_phone IS NULL THEN
    RAISE EXCEPTION 'An approved courier application is required.';
  END IF;

  -- The courier_id IS NULL condition makes competing claims atomic: only one update wins.
  UPDATE public.orders
  SET courier_id = auth.uid(),
      courier_name = v_courier_name,
      courier_phone = v_courier_phone,
      status = 'processing',
      driver_progress = 0.1
  WHERE id = p_order_id
    AND courier_id IS NULL
    AND lower(status) IN ('placed', 'processing');

  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows = 0 THEN
    RETURN FALSE;
  END IF;

  SELECT o.user_id INTO v_customer_id
  FROM public.orders o
  WHERE o.id = p_order_id;

  IF v_customer_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      id, user_id, title_ar, title_en, body_ar, body_en,
      type, is_read, related_order_id
    ) VALUES (
      'courier_assigned_' || gen_random_uuid()::TEXT,
      v_customer_id,
      'Courier accepted your order',
      'Courier assigned to your order',
      format('المندوب %s استلم طلبك. رقم الهاتف: %s', v_courier_name, v_courier_phone),
      format('Courier %s accepted your order. Phone: %s', v_courier_name, v_courier_phone),
      'order', FALSE, p_order_id
    );
  END IF;

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_courier_order_status(
  p_order_id TEXT,
  p_status TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_courier_name TEXT;
  v_courier_phone TEXT;
  v_customer_id UUID;
  v_rows INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Sign in to update this order.';
  END IF;

  IF p_status NOT IN ('onTheWay', 'delivered', 'cancelled') THEN
    RAISE EXCEPTION 'Unsupported courier order status.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.driver_applications da
    WHERE da.user_id = auth.uid() AND da.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'An approved courier application is required.';
  END IF;

  UPDATE public.orders
  SET status = p_status,
      driver_progress = CASE WHEN p_status = 'delivered' THEN 1 ELSE driver_progress END
  WHERE id = p_order_id
    AND courier_id = auth.uid()
    AND (
      (p_status = 'onTheWay' AND lower(status) = 'processing')
      OR (p_status = 'delivered' AND lower(status) IN ('ontheway', 'on_the_way'))
      OR (p_status = 'cancelled' AND lower(status) IN ('processing', 'ontheway', 'on_the_way'))
    );

  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows = 0 THEN
    RETURN FALSE;
  END IF;

  IF p_status = 'cancelled' THEN
    UPDATE public.products AS p
    SET stock_count = COALESCE(p.stock_count, 0) + item_totals.quantity,
        in_stock = COALESCE(p.stock_count, 0) + item_totals.quantity > 0
    FROM (
      SELECT oi.product_id, SUM(oi.quantity)::INTEGER AS quantity
      FROM public.order_items oi
      WHERE oi.order_id = p_order_id AND oi.product_id IS NOT NULL
      GROUP BY oi.product_id
    ) AS item_totals
    WHERE p.id = item_totals.product_id;
    SELECT o.user_id, o.courier_name, o.courier_phone
      INTO v_customer_id, v_courier_name, v_courier_phone
    FROM public.orders o
    WHERE o.id = p_order_id;

    IF v_customer_id IS NOT NULL THEN
      INSERT INTO public.notifications (
        id, user_id, title_ar, title_en, body_ar, body_en,
        type, is_read, related_order_id
      ) VALUES (
        'courier_cancelled_' || gen_random_uuid()::TEXT,
        v_customer_id,
        'Order cancelled by courier',
        'Your order was cancelled by the courier',
        format('ألغى المندوب %s طلبك. يمكنك التواصل معه على %s.', v_courier_name, v_courier_phone),
        format('Courier %s cancelled your order. Contact: %s.', v_courier_name, v_courier_phone),
        'order', FALSE, p_order_id
      );
    END IF;
  END IF;

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_courier_order(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_courier_order(TEXT) TO authenticated;
REVOKE ALL ON FUNCTION public.update_courier_order_status(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_courier_order_status(TEXT, TEXT) TO authenticated;
-- Only administrators can approve couriers or change account roles.
DROP POLICY IF EXISTS "Profiles updatable by user" ON public.profiles;
DROP POLICY IF EXISTS "Users update own profile or admins" ON public.profiles;
CREATE POLICY "Users update own profile or admins" ON public.profiles
  FOR UPDATE TO authenticated
  USING (
    id = auth.uid() OR public.is_current_user_admin()
  )
  WITH CHECK (
    id = auth.uid() OR public.is_current_user_admin()
  );

CREATE OR REPLACE FUNCTION public.prevent_profile_role_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF auth.uid() IS NOT NULL
     AND NEW.role IS DISTINCT FROM OLD.role
     AND NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Only administrators can change profile roles.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_profile_role_escalation ON public.profiles;
CREATE TRIGGER prevent_profile_role_escalation
  BEFORE UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_profile_role_escalation();

DROP POLICY IF EXISTS "Driver applications can be inserted" ON public.driver_applications;
DROP POLICY IF EXISTS "Users submit pending courier applications" ON public.driver_applications;
CREATE POLICY "Users submit pending courier applications" ON public.driver_applications
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND status = 'pending');

DROP POLICY IF EXISTS "Driver applications can be updated" ON public.driver_applications;
DROP POLICY IF EXISTS "Admins can review courier applications" ON public.driver_applications;
CREATE POLICY "Admins can review courier applications" ON public.driver_applications
  FOR UPDATE TO authenticated
  USING (
    public.is_current_user_admin()
  )
  WITH CHECK (
    public.is_current_user_admin()
  );

NOTIFY pgrst, 'reload schema';
