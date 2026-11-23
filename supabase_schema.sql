-- =====================================================================
-- SUPABASE POSTGRESQL DATABASE SCHEMA & STORAGE SETUP
-- White-Label Multi-Store Commerce Platform
-- =====================================================================

-- 1. Create Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    business_type TEXT NOT NULL, -- factory, mall, pharmacy, restaurant, all
    product_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Global service type, brand, theme colors, and contact settings.
CREATE TABLE IF NOT EXISTS public.app_settings (
    id TEXT PRIMARY KEY CHECK (id = 'brand'),
    settings JSONB NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id TEXT PRIMARY KEY,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    description_ar TEXT NOT NULL,
    description_en TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    old_price NUMERIC(12, 2),
    category_id TEXT REFERENCES public.categories(id) ON DELETE SET NULL,
    business_type TEXT NOT NULL,
    images TEXT[] DEFAULT '{}',
    rating NUMERIC(3, 2) DEFAULT 5.0,
    review_count INT DEFAULT 0,
    in_stock BOOLEAN DEFAULT true,
    stock_count INT DEFAULT 100,
    unit_ar TEXT NOT NULL,
    unit_en TEXT NOT NULL,
    specifications_ar JSONB DEFAULT '{}'::jsonb,
    specifications_en JSONB DEFAULT '{}'::jsonb,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create Orders Table
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    subtotal NUMERIC(12, 2) NOT NULL,
    tax NUMERIC(12, 2) NOT NULL,
    delivery_fee NUMERIC(12, 2) DEFAULT 0.0,
    discount NUMERIC(12, 2) DEFAULT 0.0,
    total NUMERIC(12, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'placed', -- placed, processing, onTheWay, delivered, cancelled
    delivery_address TEXT NOT NULL,
    dest_lat NUMERIC(10, 6) DEFAULT 24.7136,
    dest_lng NUMERIC(10, 6) DEFAULT 46.6753,
    driver_progress NUMERIC(4, 2) DEFAULT 0.1,
    courier_name TEXT DEFAULT 'طارق الزهراني',
    courier_phone TEXT DEFAULT '+966559876543',
    courier_vehicle TEXT DEFAULT 'تويوتا يارس أبيض',
    courier_avatar TEXT DEFAULT 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
    payment_method TEXT NOT NULL,
    estimated_arrival_minutes INT DEFAULT 30,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS courier_avatar TEXT;

-- 4. Create Order Items Table
CREATE TABLE IF NOT EXISTS public.order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id TEXT REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id TEXT REFERENCES public.products(id) ON DELETE SET NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(12, 2) NOT NULL,
    total_price NUMERIC(12, 2) NOT NULL
);

-- Persistent shopping carts
CREATE TABLE IF NOT EXISTS public.cart_items (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    selected_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE (user_id, product_id)
);

-- 5. Create Reviews Table
CREATE TABLE IF NOT EXISTS public.reviews (
    id TEXT PRIMARY KEY,
    product_id TEXT REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_name TEXT NOT NULL,
    user_avatar TEXT,
    rating NUMERIC(2, 1) NOT NULL,
    comment TEXT NOT NULL,
    is_verified_purchase BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Create User Profiles Table (Linked with Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'customer', -- admin, vendor, customer
    address TEXT,
    avatar_url TEXT,
    total_spent NUMERIC(12, 2) DEFAULT 0.0,
    orders_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. Create Notifications Table
CREATE TABLE IF NOT EXISTS public.promo_codes (
    code TEXT PRIMARY KEY,
    discount_percent NUMERIC(5, 2) NOT NULL CHECK (discount_percent > 0 AND discount_percent <= 100),
    is_active BOOLEAN NOT NULL DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 8. Create Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title_ar TEXT NOT NULL,
    title_en TEXT NOT NULL,
    body_ar TEXT NOT NULL,
    body_en TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'system', -- order, promo, delivery, system
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 8. Create Support Tickets Table
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_name TEXT NOT NULL,
    user_email TEXT,
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. Create Driver Applications Table (سائقي ومندوبي التوصيل)
CREATE TABLE IF NOT EXISTS public.driver_applications (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    national_id TEXT NOT NULL,
    vehicle_type TEXT NOT NULL, -- motorcycle, car, van, truck
    city TEXT NOT NULL,
    experience_years INT DEFAULT 1,
    license_image_url TEXT,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================================

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_applications ENABLE ROW LEVEL SECURITY;

-- Categories & Products are viewable by everyone
CREATE POLICY "Categories are viewable by everyone" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Categories can be inserted" ON public.categories FOR INSERT WITH CHECK (true);
CREATE POLICY "Categories can be updated" ON public.categories FOR UPDATE USING (true);
CREATE POLICY "Categories can be deleted" ON public.categories FOR DELETE USING (true);

CREATE POLICY "Promo codes are readable by everyone" ON public.promo_codes FOR SELECT USING (true);
CREATE POLICY "Admins can create promo codes" ON public.promo_codes FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));
CREATE POLICY "Admins can update promo codes" ON public.promo_codes FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));
CREATE POLICY "Admins can delete promo codes" ON public.promo_codes FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));
GRANT SELECT ON public.promo_codes TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.promo_codes TO authenticated;

CREATE POLICY "App settings are publicly readable" ON public.app_settings FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert app settings" ON public.app_settings FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can update app settings" ON public.app_settings FOR UPDATE USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

GRANT SELECT ON public.app_settings TO anon, authenticated;
GRANT INSERT, UPDATE ON public.app_settings TO authenticated;

INSERT INTO public.app_settings (id, settings)
VALUES ('brand', '{"brand_id":"temp_market","brand_name_ar":"tempMarket","brand_name_en":"tempMarket","slogan_ar":"","slogan_en":"","primary_color":4280640491,"secondary_color":4279548070,"accent_color":4294286859,"business_type":"general","hotline":"","whatsapp_number":"","email":"","address_ar":"","address_en":""}'::jsonb)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Products are viewable by everyone" ON public.products FOR SELECT USING (true);
CREATE POLICY "Products can be inserted" ON public.products FOR INSERT WITH CHECK (true);
CREATE POLICY "Products can be updated" ON public.products FOR UPDATE USING (true);
CREATE POLICY "Products can be deleted" ON public.products FOR DELETE USING (true);

-- Reviews are viewable by everyone, insertable by anyone
CREATE POLICY "Reviews are viewable by everyone" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Anyone can post reviews" ON public.reviews FOR INSERT WITH CHECK (true);

-- Orders viewable and insertable and updatable (for live tracking & admin status updates)
CREATE POLICY "Users can view their own orders" ON public.orders FOR SELECT USING (true);
CREATE POLICY "Users can insert their own orders" ON public.orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Orders can be updated" ON public.orders FOR UPDATE USING (true);

CREATE POLICY "Users can view their order items" ON public.order_items FOR SELECT USING (true);
CREATE POLICY "Users can insert their order items" ON public.order_items FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view their cart" ON public.cart_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their cart items" ON public.cart_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their cart items" ON public.cart_items FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their cart items" ON public.cart_items FOR DELETE USING (auth.uid() = user_id);

-- Profiles
CREATE POLICY "Profiles viewable by user" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Profiles updatable by user" ON public.profiles FOR UPDATE USING (true);
CREATE POLICY "Profiles insertable" ON public.profiles FOR INSERT WITH CHECK (true);

-- Notifications
CREATE POLICY "Notifications are viewable by everyone" ON public.notifications FOR SELECT USING (true);
CREATE POLICY "Notifications can be inserted" ON public.notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Notifications can be updated" ON public.notifications FOR UPDATE USING (true);

-- Support Tickets
CREATE POLICY "Support tickets are viewable" ON public.support_tickets FOR SELECT USING (true);
CREATE POLICY "Support tickets can be inserted" ON public.support_tickets FOR INSERT WITH CHECK (true);

-- Driver Applications (توظيف السائقين)
CREATE POLICY "Driver applications are viewable" ON public.driver_applications FOR SELECT USING (true);
CREATE POLICY "Driver applications can be inserted" ON public.driver_applications FOR INSERT WITH CHECK (true);
CREATE POLICY "Driver applications can be updated" ON public.driver_applications FOR UPDATE USING (true);

-- =====================================================================
-- SEED DEFAULT NOTIFICATIONS
-- =====================================================================
INSERT INTO public.notifications (id, title_ar, title_en, body_ar, body_en, type, is_read)
VALUES
    ('notif_welcome', 'مرحباً بك في المنصة السحابية!', 'Welcome to Cloud Commerce!', 'تم ربط التطبيق بنجاح مع سحابة Supabase لمزامنة المنتجات والطلبات فورياً.', 'App successfully wired with Supabase for real-time commerce sync.', 'system', false),
    ('notif_promo', 'عروض ورموز خصم خاصة', 'Promo codes and special offers', 'استخدم أحد رموز الخصم المتاحة عند إتمام طلبك للحصول على الخصم.', 'Check the app for available promo codes at checkout.', 'promo', false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================================
-- SEED DEFAULT STORE CATEGORIES
-- =====================================================================
INSERT INTO public.categories (id, name_ar, name_en, business_type, product_count)
VALUES
    ('cat_raw_materials', 'المواد الأولية والخامات', 'Raw Materials', 'factory', 12),
    ('cat_machinery', 'المعدات وقطع الغيار', 'Machinery & Parts', 'factory', 8),
    ('cat_electronics', 'الإلكترونيات والأجهزة', 'Electronics & Gadgets', 'mall', 24),
    ('cat_fashion', 'الأزياء والملابس', 'Fashion & Apparel', 'mall', 40),
    ('cat_medicines', 'الأدوية والمضادات', 'Medicines & Rx', 'pharmacy', 35),
    ('cat_vitamins', 'الفيتامينات والمكملات', 'Vitamins & Supplements', 'pharmacy', 18),
    ('cat_main_dishes', 'الأطباق الرئيسية والمشويات', 'Main Courses & Grills', 'restaurant', 16),
    ('cat_beverages', 'المشروبات والعصائر', 'Beverages & Juices', 'restaurant', 10)
ON CONFLICT (id) DO UPDATE
SET name_ar = EXCLUDED.name_ar, name_en = EXCLUDED.name_en;

-- =====================================================================
-- STORAGE BUCKETS SETUP (For Massive Image & Media Hosting)
-- =====================================================================

-- Insert product-images and user-avatars storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('user-avatars', 'user-avatars', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('driver-documents', 'driver-documents', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Public read access for images
CREATE POLICY "Public Access for Product Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'product-images');

CREATE POLICY "Public upload for product images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Public Access for User Avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'user-avatars');

CREATE POLICY "Public upload for avatars"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'user-avatars');

CREATE POLICY "Public Access for Driver Documents"
ON storage.objects FOR SELECT
USING (bucket_id = 'driver-documents');

CREATE POLICY "Public upload for driver documents"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'driver-documents');
