-- Persist service type, brand, colors, and contact information in Supabase.
CREATE TABLE IF NOT EXISTS public.app_settings (
    id TEXT PRIMARY KEY CHECK (id = 'brand'),
    settings JSONB NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "App settings are publicly readable" ON public.app_settings;
DROP POLICY IF EXISTS "Authenticated users can insert app settings" ON public.app_settings;
DROP POLICY IF EXISTS "Authenticated users can update app settings" ON public.app_settings;

CREATE POLICY "App settings are publicly readable"
ON public.app_settings FOR SELECT USING (TRUE);

CREATE POLICY "Authenticated users can insert app settings"
ON public.app_settings FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update app settings"
ON public.app_settings FOR UPDATE
USING (auth.uid() IS NOT NULL)
WITH CHECK (auth.uid() IS NOT NULL);

GRANT SELECT ON public.app_settings TO anon, authenticated;
GRANT INSERT, UPDATE ON public.app_settings TO authenticated;

INSERT INTO public.app_settings (id, settings)
VALUES (
    'brand',
    '{
      "brand_id": "temp_market",
      "brand_name_ar": "tempMarket",
      "brand_name_en": "tempMarket",
      "slogan_ar": "",
      "slogan_en": "",
      "primary_color": 4280640491,
      "secondary_color": 4279548070,
      "accent_color": 4294286859,
      "business_type": "general",
      "hotline": "",
      "whatsapp_number": "",
      "email": "",
      "address_ar": "",
      "address_en": ""
    }'::JSONB
)
ON CONFLICT (id) DO NOTHING;

NOTIFY pgrst, 'reload schema';
