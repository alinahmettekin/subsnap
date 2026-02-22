-- ==========================================
-- SubSnap Database Schema (Clean Install - Safe Update)
-- Features: 
-- 1. Cards: Soft Delete (is_deleted = true) to preserve history
-- 2. Subscriptions: HARD DELETE (rows removed) + Cascade
-- 3. No limits enforced in DB
-- 4. Automatic Past & Future Payment Generation
-- 5. Expanded Billing Periods
-- ==========================================

-- 0. Enable Extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    avatar_url TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own profile" ON profiles;
CREATE POLICY "Users can manage their own profile" ON profiles
    FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 2. Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    icon_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Everyone can view categories" ON categories;
CREATE POLICY "Everyone can view categories" ON categories
    FOR SELECT USING (true);

-- 3. Cards Table (SOFT DELETE)
CREATE TABLE IF NOT EXISTS cards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    card_name TEXT NOT NULL,
    last_four VARCHAR(4) NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE, -- SOFT DELETE FLAG KEPT
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cards' AND column_name='is_deleted') THEN 
        ALTER TABLE cards ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE; 
    END IF; 
END $$;

ALTER TABLE cards ENABLE ROW LEVEL SECURITY;

-- Cards Policies: Simplified to allow soft delete operations
DROP POLICY IF EXISTS "Users can manage their own cards" ON cards;
CREATE POLICY "Users can manage their own cards" ON cards
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 4. Services Table
CREATE TABLE IF NOT EXISTS services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    icon_name TEXT,
    default_billing_cycle TEXT DEFAULT 'monthly', -- ADDED DEFAULT CYCLE
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE services ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable read access for all users" ON services;
CREATE POLICY "Enable read access for all users" ON services FOR SELECT USING (true);

-- 5. Subscriptions Table (HARD DELETE - No is_deleted)
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    service_id UUID REFERENCES services(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'TRY',
    billing_period TEXT CHECK (billing_period IN ('weekly', 'monthly', '3_months', '6_months', 'yearly', 'custom')),
    start_date DATE DEFAULT CURRENT_DATE,
    next_payment_date DATE NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'trial')),
    -- REMOVED is_deleted column
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure billing_period check constraint is updated
ALTER TABLE subscriptions DROP CONSTRAINT IF EXISTS subscriptions_billing_period_check;
ALTER TABLE subscriptions ADD CONSTRAINT subscriptions_billing_period_check CHECK (billing_period IN ('weekly', 'monthly', '3_months', '6_months', 'yearly', 'custom'));

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Clean old policies
DROP POLICY IF EXISTS "Users see only active subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Users can update own subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Users can delete own subscriptions" ON subscriptions;

-- Subscriptions Policies (Standard - No is_deleted checks)
DROP POLICY IF EXISTS "Users can manage their own subscriptions" ON subscriptions;
CREATE POLICY "Users can manage their own subscriptions" ON subscriptions
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 6. Payments History Table
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE NOT NULL,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'TRY',
    due_date DATE NOT NULL,
    paid_at TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'skipped')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own payments" ON payments;
CREATE POLICY "Users can manage their own payments" ON payments
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 7. Support Requests Table
CREATE TABLE IF NOT EXISTS support_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('service_request', 'feedback')),
    content TEXT NOT NULL,
    service_name TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE support_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own requests" ON support_requests;
CREATE POLICY "Users can manage their own requests" ON support_requests
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ==========================================
-- Functions & Triggers
-- ==========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'avatar_url');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();
  DELETE FROM public.payments WHERE user_id = current_user_id;
  DELETE FROM public.subscriptions WHERE user_id = current_user_id;
  DELETE FROM public.cards WHERE user_id = current_user_id; 
  DELETE FROM public.support_requests WHERE user_id = current_user_id;
  DELETE FROM public.profiles WHERE id = current_user_id;
  DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;

-- Function: Generate Recurring Payments (CRON JOB FUNCTION)
CREATE OR REPLACE FUNCTION generate_recurring_payments()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    sub RECORD;
BEGIN
    FOR sub IN 
        SELECT * FROM public.subscriptions 
        WHERE next_payment_date <= current_date 
        AND status = 'active'
        -- No check for is_deleted here anymore
    LOOP
        INSERT INTO public.payments (
            subscription_id, 
            user_id,
            card_id,
            amount, 
            currency, 
            due_date, 
            paid_at, 
            status
        ) VALUES (
            sub.id,
            sub.user_id,
            sub.card_id,
            sub.amount, 
            sub.currency, 
            sub.next_payment_date, 
            NOW(), 
            'paid'
        );

        UPDATE public.subscriptions
        SET next_payment_date = CASE 
            WHEN billing_period = 'weekly' THEN next_payment_date + interval '1 week'
            WHEN billing_period = 'monthly' THEN next_payment_date + interval '1 month'
            WHEN billing_period = '3_months' THEN next_payment_date + interval '3 months'
            WHEN billing_period = '6_months' THEN next_payment_date + interval '6 months'
            WHEN billing_period = 'yearly' THEN next_payment_date + interval '1 year'
            ELSE next_payment_date + interval '1 month'
        END,
        updated_at = NOW()
        WHERE id = sub.id;
    END LOOP;
END;
$$;

SELECT cron.schedule(
    'generate-payments-daily', 
    '0 10 * * *',              
    $$SELECT generate_recurring_payments()$$
);

CREATE OR REPLACE FUNCTION generate_past_payments()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_calculation_date DATE;
    cutoff_date DATE;
    now_date DATE := CURRENT_DATE;
BEGIN
    current_calculation_date := NEW.next_payment_date;
    cutoff_date := COALESCE(NEW.start_date, NEW.created_at::date, '2024-01-01');

    LOOP
        IF NEW.billing_period = 'weekly' THEN
            current_calculation_date := current_calculation_date - interval '1 week';
        ELSIF NEW.billing_period = 'monthly' THEN
            current_calculation_date := current_calculation_date - interval '1 month';
        ELSIF NEW.billing_period = '3_months' THEN
            current_calculation_date := current_calculation_date - interval '3 months';
        ELSIF NEW.billing_period = '6_months' THEN
            current_calculation_date := current_calculation_date - interval '6 months';
        ELSIF NEW.billing_period = 'yearly' THEN
            current_calculation_date := current_calculation_date - interval '1 year';
        ELSE
            current_calculation_date := current_calculation_date - interval '1 month';
        END IF;

        EXIT WHEN current_calculation_date < cutoff_date;
        EXIT WHEN current_calculation_date > now_date;

        INSERT INTO public.payments (
            user_id,
            subscription_id,
            card_id,
            amount,
            currency,
            due_date,
            paid_at,
            status
        ) VALUES (
            NEW.user_id,
            NEW.id,
            NEW.card_id,
            NEW.amount,
            NEW.currency,
            current_calculation_date,
            current_calculation_date,
            'paid'
        );
    END LOOP;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_subscription_created_generate_history ON public.subscriptions;
CREATE TRIGGER on_subscription_created_generate_history
    AFTER INSERT ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION generate_past_payments();


-- ==========================================
-- Seed Data
-- ==========================================
INSERT INTO categories (name, icon_name) VALUES
('Dijital Platformlar', 'film'),
('Araçlar', 'tools'),
('Finans', 'attach_money'),
('İş & Kariyer', 'work'),
('Yazılım', 'code'),
('Eğitim', 'school'),
('Tasarım', 'palette'),
('Yapay Zeka', 'ai'),
('Alışveriş', 'shopping_bag'),
('Mobil Operatörler', 'phone'),
('İnternet Servis Sağlayıcıları', 'wifi'),
('Vergi & Kamu', 'legal'),
('Faturalar', 'bill'),
('Diğer', 'other')
ON CONFLICT (name) DO UPDATE SET 
    icon_name = EXCLUDED.icon_name;

DO $$
DECLARE
    cat_streaming uuid; cat_utility uuid; cat_mobile uuid; cat_isp uuid; 
    cat_software uuid; cat_design uuid; cat_ai uuid; cat_gov uuid; cat_bills uuid;
BEGIN
    SELECT id INTO cat_streaming FROM categories WHERE name = 'Dijital Platformlar';
    SELECT id INTO cat_utility FROM categories WHERE name = 'Araçlar';
    SELECT id INTO cat_mobile FROM categories WHERE name = 'Mobil Operatörler';
    SELECT id INTO cat_isp FROM categories WHERE name = 'İnternet Servis Sağlayıcıları';
    SELECT id INTO cat_software FROM categories WHERE name = 'Yazılım';
    SELECT id INTO cat_design FROM categories WHERE name = 'Tasarım';
    SELECT id INTO cat_ai FROM categories WHERE name = 'Yapay Zeka';
    SELECT id INTO cat_gov FROM categories WHERE name = 'Vergi & Kamu';
    SELECT id INTO cat_bills FROM categories WHERE name = 'Fatura';

    INSERT INTO services (name, icon_name, default_billing_cycle, category_id) VALUES
    ('Netflix', 'netflix', 'monthly', cat_streaming),
    ('Spotify', 'spotify', 'monthly', cat_streaming),
    ('YouTube Premium', 'youtube', 'monthly', cat_streaming),
    ('Disney+', 'disney_plus', 'monthly', cat_streaming),
    ('Amazon Prime', 'amazon', 'monthly', cat_streaming),
    ('Apple Music', 'apple_music', 'monthly', cat_streaming),
    ('Exxen', 'exxen', 'monthly', cat_streaming),
    ('iCloud', 'icloud', 'monthly', cat_utility),
    ('Google One', 'google_one', 'monthly', cat_utility),
    ('Turkcell', 'turkcell', 'monthly', cat_mobile),
    ('Vodafone', 'vodafone', 'monthly', cat_mobile),
    ('Vodafone Net', 'vodafone', 'monthly', cat_isp),
    ('Türk Telekom', 'turktelekom', 'monthly', cat_mobile),
    ('TurkNet', 'turknet', 'monthly', cat_isp),
    ('Superonline', 'turkcell', 'monthly', cat_isp),
    ('Türk Telekom İnternet', 'turktelekom', 'monthly', cat_isp),
    ('GitHub ', 'github', 'monthly', cat_software),
    ('Cursor', 'cursor', 'monthly', cat_software),
    ('Adobe Creative Cloud', 'adobe_creative_cloud', 'monthly', cat_design),
    ('Figma', 'figma', 'monthly', cat_design),
    ('ChatGPT', 'chatgpt', 'monthly', cat_ai),
    ('Claude', 'claude', 'monthly', cat_ai),
    ('Motorlu Taşıtlar Vergisi', 'car', '6_months', cat_gov),
    ('Elektrik', 'electric', 'monthly', cat_bills),
    ('Su', 'water', 'monthly', cat_bills),
    ('Doğalgaz', 'gas', 'monthly', cat_bills),
    ('Digiturk', 'digiturk', 'yearly', cat_streaming)
    ON CONFLICT (name) DO UPDATE SET 
        category_id = EXCLUDED.category_id, 
        default_billing_cycle = EXCLUDED.default_billing_cycle,
        icon_name = EXCLUDED.icon_name;
END $$;
