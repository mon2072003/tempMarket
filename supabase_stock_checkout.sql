-- Atomic checkout: decrement stock and save the order in one transaction.
-- Run this once in the Supabase SQL Editor for an existing project.
CREATE OR REPLACE FUNCTION public.place_order_with_stock(
    p_order JSONB,
    p_items JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    item_row JSONB;
    item_product_id TEXT;
    item_quantity INTEGER;
    new_order_id TEXT;
BEGIN
    IF jsonb_typeof(p_items) IS DISTINCT FROM 'array' THEN
        RAISE EXCEPTION 'Order items must be an array';
    END IF;

    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'An order must contain at least one item';
    END IF;

    new_order_id := p_order->>'id';
    IF new_order_id IS NULL OR new_order_id = '' THEN
        RAISE EXCEPTION 'Order ID is required';
    END IF;

    IF auth.uid() IS NOT NULL
       AND (p_order->>'user_id')::UUID IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'Cannot place an order for another user';
    END IF;

    -- Conditional UPDATE acquires row locks and prevents overselling when two
    -- customers try to buy the remaining stock at the same time.
    FOR item_row IN SELECT value FROM jsonb_array_elements(p_items)
    LOOP
        item_product_id := item_row->>'product_id';
        item_quantity := (item_row->>'quantity')::INTEGER;

        IF item_product_id IS NULL OR item_quantity IS NULL OR item_quantity <= 0 THEN
            RAISE EXCEPTION 'Invalid product or quantity in order';
        END IF;

        UPDATE public.products
        SET stock_count = stock_count - item_quantity,
            in_stock = (stock_count - item_quantity) > 0
        WHERE id = item_product_id
          AND in_stock = TRUE
          AND stock_count >= item_quantity;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Insufficient stock for product %', item_product_id;
        END IF;
    END LOOP;

    INSERT INTO public.orders (
        id, user_id, subtotal, tax, delivery_fee, discount, total, status,
        delivery_address, dest_lat, dest_lng, driver_progress, courier_name,
        courier_phone, courier_vehicle, courier_avatar, payment_method,
        estimated_arrival_minutes
    ) VALUES (
        new_order_id,
        (p_order->>'user_id')::UUID,
        (p_order->>'subtotal')::NUMERIC,
        (p_order->>'tax')::NUMERIC,
        COALESCE((p_order->>'delivery_fee')::NUMERIC, 0),
        COALESCE((p_order->>'discount')::NUMERIC, 0),
        (p_order->>'total')::NUMERIC,
        COALESCE(p_order->>'status', 'placed'),
        p_order->>'delivery_address',
        COALESCE((p_order->>'dest_lat')::NUMERIC, 24.7136),
        COALESCE((p_order->>'dest_lng')::NUMERIC, 46.6753),
        COALESCE((p_order->>'driver_progress')::NUMERIC, 0.1),
        p_order->>'courier_name',
        p_order->>'courier_phone',
        p_order->>'courier_vehicle',
        p_order->>'courier_avatar',
        p_order->>'payment_method',
        COALESCE((p_order->>'estimated_arrival_minutes')::INTEGER, 30)
    );

    FOR item_row IN SELECT value FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.order_items (
            order_id, product_id, quantity, unit_price, total_price
        ) VALUES (
            new_order_id,
            item_row->>'product_id',
            (item_row->>'quantity')::INTEGER,
            (item_row->>'unit_price')::NUMERIC,
            (item_row->>'total_price')::NUMERIC
        );
    END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.place_order_with_stock(JSONB, JSONB) TO authenticated;

-- Make the new RPC visible to the REST API immediately.
NOTIFY pgrst, 'reload schema';
