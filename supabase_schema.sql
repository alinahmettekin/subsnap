-- 1. Create Profiles table (Extends Supabase Auth)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    avatar_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own profile" ON profiles;
CREATE POLICY "Users can manage their own profile" ON profiles
    FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 2. Create Categories table
CREATE TABLE IF NOT EXISTS categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    icon_name TEXT,
    color TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $$ 
BEGIN 
    ALTER TABLE categories RENAME COLUMN icon TO icon_name; 
EXCEPTION 
    WHEN OTHERS THEN NULL; 
END $$;

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read categories
DROP POLICY IF EXISTS "Users can view categories" ON categories;
CREATE POLICY "Everyone can view categories" ON categories
    FOR SELECT USING (true);

-- Only service_role (admins) can insert/update/delete (implicitly denied for others by default)

-- 3. Create Cards table
CREATE TABLE IF NOT EXISTS cards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    card_name TEXT NOT NULL,
    last_four VARCHAR(4) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE cards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own cards" ON cards;
CREATE POLICY "Users can manage their own cards" ON cards
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Function to check card limit for non-premium users
CREATE OR REPLACE FUNCTION check_card_limit()
RETURNS TRIGGER AS $$
DECLARE
    card_count INTEGER;
    is_premium_user BOOLEAN;
BEGIN
    SELECT is_premium INTO is_premium_user FROM profiles WHERE id = NEW.user_id;

    IF NOT COALESCE(is_premium_user, FALSE) THEN
        SELECT COUNT(*) INTO card_count FROM cards WHERE user_id = NEW.user_id;
        IF card_count >= 2 THEN
            RAISE EXCEPTION 'Non-premium users can only have a maximum of 2 cards.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_card_limit ON cards;
CREATE TRIGGER enforce_card_limit
    BEFORE INSERT ON cards
    FOR EACH ROW EXECUTE PROCEDURE check_card_limit();

-- 4. Create Services table (Predefined services like Netflix, Spotify)
CREATE TABLE IF NOT EXISTS services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    icon_name TEXT, -- e.g. 'spotify', 'netflix' for FontAwesome lookup
    color TEXT, -- Hex code, e.g. '#1DB954'
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    default_price NUMERIC(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE services ENABLE ROW LEVEL SECURITY;

-- Allow read access to everyone for services
DROP POLICY IF EXISTS "Enable read access for all users" ON services;
CREATE POLICY "Enable read access for all users" ON services FOR SELECT USING (true);

-- 5. Create Subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    service_id UUID REFERENCES services(id) ON DELETE SET NULL, -- Link to predefined service
    name TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    billing_period TEXT CHECK (billing_period IN ('monthly', 'yearly', 'custom')),
    next_payment_date DATE NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'trial')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own subscriptions" ON subscriptions;
CREATE POLICY "Users can manage their own subscriptions" ON subscriptions
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 6. Create Payments history table
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Ensure cascading delete from auth.users
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE NOT NULL,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    amount NUMERIC(10, 2) NOT NULL,
    paid_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'paid' CHECK (status IN ('paid', 'skipped')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own payments" ON payments;
CREATE POLICY "Users can manage their own payments" ON payments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM subscriptions 
            WHERE subscriptions.id = payments.subscription_id 
            AND subscriptions.user_id = auth.uid()
        )
    );

-- 7. Functions & Triggers

-- Trigger for updated_at
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

-- Trigger for automatic profile creation on signup
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

-- 8. Insert default categories (Idempotent)
-- 7.5 Create Support Requests table
CREATE TABLE IF NOT EXISTS support_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('service_request', 'feedback')),
    content TEXT NOT NULL,
    service_name TEXT, -- Only for service_request
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE support_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own requests" ON support_requests;
CREATE POLICY "Users can manage their own requests" ON support_requests
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 8. Insert default categories
-- Ensure name is unique for global categories


-- 9. Insert default services with Category Links
-- Ensure service name is unique
CREATE UNIQUE INDEX IF NOT EXISTS services_name_key ON services (name);

DO $$
DECLARE
    cat_streaming uuid;
    cat_utility uuid;
    cat_finance uuid;
    cat_work uuid;
    cat_software uuid;
    cat_education uuid;
    cat_design uuid;
    cat_ai uuid;
    cat_shopping uuid;
    cat_mobile uuid;
    cat_isp uuid;
    cat_other uuid;
BEGIN
    -- 1. Kategorileri Ekle/Güncelle (Türkçe)
    INSERT INTO categories (name, color, icon_name) VALUES ('Dijital Platformlar', '#E50914', 'film') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('Araçlar', '#007AFF', 'cloud') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('Finans', '#34C759', 'attach_money') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('İş & Kariyer', '#5856D6', 'work') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('Yazılım', '#FF9500', 'code') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('Eğitim', '#FF2D55', 'school') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('Tasarım', '#AF52DE', 'palette') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('Yapay Zeka', '#00C7BE', 'psychology') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('Alışveriş', '#FF3B30', 'shopping_bag') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    
    -- Yeni Kategoriler
    INSERT INTO categories (name, color, icon_name) VALUES ('Mobil Operatörler', '#34C759', 'phone') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('İnternet Servis Sağlayıcıları', '#007AFF', 'wifi') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;
    INSERT INTO categories (name, color, icon_name) VALUES ('Diğer', '#95A5A6', 'more_horiz') ON CONFLICT (name) DO UPDATE SET color = EXCLUDED.color;

    -- 2. ID'leri Değişkenlere Ata (Garanti Yöntem)
    SELECT id INTO cat_streaming FROM categories WHERE name = 'Dijital Platformlar';
    SELECT id INTO cat_utility FROM categories WHERE name = 'Araçlar';
    SELECT id INTO cat_finance FROM categories WHERE name = 'Finans';
    SELECT id INTO cat_work FROM categories WHERE name = 'İş & Kariyer';
    SELECT id INTO cat_software FROM categories WHERE name = 'Yazılım';
    SELECT id INTO cat_education FROM categories WHERE name = 'Eğitim';
    SELECT id INTO cat_design FROM categories WHERE name = 'Tasarım';
    SELECT id INTO cat_ai FROM categories WHERE name = 'Yapay Zeka';
    SELECT id INTO cat_shopping FROM categories WHERE name = 'Alışveriş';
    SELECT id INTO cat_mobile FROM categories WHERE name = 'Mobil Operatörler';
    SELECT id INTO cat_isp FROM categories WHERE name = 'İnternet Servis Sağlayıcıları';
    SELECT id INTO cat_other FROM categories WHERE name = 'Diğer';

    -- 3. Servisleri Ekle (Kategori ID'leri ile)
    -- Streaming & Entertainment (Dijital Platformlar)
    INSERT INTO services (name, icon_name, color, default_price, category_id) VALUES
    ('Netflix', 'film', '#E50914', 199.99, cat_streaming),
    ('Spotify', 'music', '#1DB954', 59.99, cat_streaming),
    ('YouTube Premium', 'youtube', '#FF0000', 57.99, cat_streaming),
    ('Disney+', 'disney', '#113CCF', 134.99, cat_streaming),
    ('Amazon Prime', 'amazon', '#00A8E1', 39.00, cat_streaming),
    ('Apple Music', 'apple', '#FA243C', 39.99, cat_streaming),
    ('BluTV', 'blutv', '#1F2833', 99.90, cat_streaming),
    ('Exxen', 'exxen', '#FFCC00', 129.90, cat_streaming),
    ('Tod TV', 'tv', '#4B0082', 0, cat_streaming),
    ('Gain', 'tv', '#E60000', 0, cat_streaming),
    ('Mubi', 'film', '#000000', 0, cat_streaming)
    ON CONFLICT (name) DO UPDATE SET category_id = EXCLUDED.category_id, default_price = EXCLUDED.default_price;

    -- Utility / Cloud (Araçlar)
    INSERT INTO services (name, icon_name, color, default_price, category_id) VALUES
    ('iCloud', 'cloud', '#007AFF', 12.99, cat_utility),
    ('Dropbox', 'dropbox', '#0061FF', 0, cat_utility),
    ('Google One', 'google', '#4285F4', 9.99, cat_utility)
    ON CONFLICT (name) DO UPDATE SET category_id = EXCLUDED.category_id, default_price = EXCLUDED.default_price;
    
    -- Mobil Operatörler
    INSERT INTO services (name, icon_name, color, default_price, category_id) VALUES
    ('Turkcell', 'phone', '#2D3E50', 0, cat_mobile),
    ('Vodafone', 'phone', '#E60000', 0, cat_mobile),
    ('Türk Telekom', 'phone', '#002855', 0, cat_mobile)
    ON CONFLICT (name) DO UPDATE SET category_id = EXCLUDED.category_id, default_price = EXCLUDED.default_price, icon_name = EXCLUDED.icon_name;

    -- İnternet Servis Sağlayıcıları
    INSERT INTO services (name, icon_name, color, default_price, category_id) VALUES
    ('TurkNet', 'wifi', '#D9232E', 399.90, cat_isp),
    ('Millenicom', 'wifi', '#FF6600', 349.90, cat_isp),
    ('Netspeed', 'wifi', '#1E88E5', 329.00, cat_isp),
    ('Türk Telekom İnternet', 'wifi', '#002855', 0, cat_isp),
    ('Superonline', 'wifi', '#FFC107', 0, cat_isp),
    ('Turkcell Superonline', 'wifi', '#FFC107', 0, cat_isp),
    ('Vodafone Net', 'wifi', '#E60000', 0, cat_isp),
    ('Kablonet', 'wifi', '#E53935', 0, cat_isp)
    ON CONFLICT (name) DO UPDATE SET category_id = EXCLUDED.category_id, icon_name = EXCLUDED.icon_name;

    -- Software / Dev (Yazılım)
    INSERT INTO services (name, icon_name, color, default_price, category_id) VALUES
    ('JetBrains', 'code', '#000000', 0, cat_software),
    ('GitHub Copilot', 'github', '#000000', 10.00, cat_software),
    ('Vercel', 'triangle', '#000000', 20.00, cat_software),
    ('SubSnap', 'sparkles', '#6200EE', 0, cat_software)
    ON CONFLICT (name) DO UPDATE SET category_id = EXCLUDED.category_id, default_price = EXCLUDED.default_price;

    -- Design (Tasarım)
    INSERT INTO services (name, icon_name, color, default_price, category_id) VALUES
    ('Adobe Creative Cloud', 'adobe', '#FF0000', 0, cat_design),
    ('Figma', 'figma', '#F24E1E', 15.00, cat_design),
    ('Canva', 'palette', '#00C4CC', 0, cat_design),
    ('Freepik', 'image', '#3D6AF2', 12.00, cat_design)
    ON CONFLICT (name) DO UPDATE SET category_id = EXCLUDED.category_id, default_price = EXCLUDED.default_price;
    
    -- AI (Yapay Zeka)
    INSERT INTO services (name, icon_name, color, default_price, category_id) VALUES
    ('ChatGPT Plus', 'chatgpt', '#10A37F', 20.00, cat_ai),
    ('Claude Pro', 'claude', '#D97757', 20.00, cat_ai),
    ('Gemini Advanced', 'gemini', '#4285F4', 0, cat_ai),
    ('Antigravity', 'rocket', '#8E24AA', 0, cat_ai),
    ('Midjourney', 'robot', '#FFFFFF', 10.00, cat_ai)
    ON CONFLICT (name) DO UPDATE SET category_id = EXCLUDED.category_id, default_price = EXCLUDED.default_price;

END $$;

-- 10. Delete User Function (GDPR/KVKK)
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();

  -- 1. Önce bağımlı tabloları temizle (Foreign Key hatasını önlemek için)
  DELETE FROM public.payments WHERE user_id = current_user_id;
  DELETE FROM public.subscriptions WHERE user_id = current_user_id;
  DELETE FROM public.cards WHERE user_id = current_user_id;
  -- Categories are now global, no user-specific categories to delete.
  -- DELETE FROM public.categories WHERE user_id = current_user_id; 
  DELETE FROM public.support_requests WHERE user_id = current_user_id;
  
  -- 2. Profil tablosunu temizle
  DELETE FROM public.profiles WHERE id = current_user_id;

  -- 3. En son Auth kullanıcısını sil
  DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;

-- 11. FORCE FIX: Ensure Foreign Keys have ON DELETE CASCADE (Idempotent Fix)
-- This block ensures that even if the tables already exist with restrictive constraints,
-- they are updated to allow cascading deletes.
DO $$
BEGIN
    -- Fix 'payments' table foreign key
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'payments_user_id_fkey' AND table_name = 'payments') THEN
        ALTER TABLE payments DROP CONSTRAINT payments_user_id_fkey;
    END IF;
    
    ALTER TABLE payments
    ADD CONSTRAINT payments_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES auth.users(id)
    ON DELETE CASCADE;

    -- Fix 'subscriptions' table foreign key (just in case)
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'subscriptions_user_id_fkey' AND table_name = 'subscriptions') THEN
        ALTER TABLE subscriptions DROP CONSTRAINT subscriptions_user_id_fkey;
    END IF;

    ALTER TABLE subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES profiles(id) -- Or auth.users, depending on preference. Profiles cascades from users, so it's safe.
    ON DELETE CASCADE;
    
EXCEPTION
    WHEN OTHERS THEN NULL; -- Ignore if already correct or other minor issues
END $$;

-- 12. FORCE FIX: Remove user_id from categories (Migration)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'categories' AND column_name = 'user_id') THEN
        ALTER TABLE categories DROP COLUMN user_id;
    END IF;
    
    -- Clean up old indexes if they exist
    DROP INDEX IF EXISTS categories_name_default_key;
    DROP INDEX IF EXISTS categories_name_user_key;
    
    -- Ensure new unique constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'categories_name_key' AND table_name = 'categories') THEN
         ALTER TABLE categories ADD CONSTRAINT categories_name_key UNIQUE (name);
    END IF;
END $$;
