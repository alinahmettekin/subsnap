-- ==========================================
-- SubSnap Database Schema (Clean Install)
-- ==========================================

-- 1. Profiles Table (Extends Supabase Auth)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    avatar_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies for Profiles
CREATE POLICY "Users can manage their own profile" ON profiles
    FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 2. Categories Table (Global Categories)
CREATE TABLE IF NOT EXISTS categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    icon_name TEXT,
    color TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Policies for Categories
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'categories' 
        AND policyname = 'Everyone can view categories'
    ) THEN
        CREATE POLICY "Everyone can view categories" ON categories
            FOR SELECT USING (true);
    END IF;
END $$;

-- 3. Cards Table
CREATE TABLE IF NOT EXISTS cards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    card_name TEXT NOT NULL,
    last_four VARCHAR(4) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE cards ENABLE ROW LEVEL SECURITY;

-- Policies for Cards
CREATE POLICY "Users can manage their own cards" ON cards
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Function: Check Card Limit (Max 2 cards for non-premium users)
CREATE OR REPLACE FUNCTION check_card_limit()
RETURNS TRIGGER AS $$
DECLARE
    card_count INTEGER;
    is_premium_user BOOLEAN;
BEGIN
    SELECT is_premium INTO is_premium_user FROM profiles WHERE id = NEW.user_id;

    -- If user is NOT premium (or unknown), check count
    IF NOT COALESCE(is_premium_user, FALSE) THEN
        SELECT COUNT(*) INTO card_count FROM cards WHERE user_id = NEW.user_id;
        IF card_count >= 2 THEN
            RAISE EXCEPTION 'Non-premium users can only have a maximum of 2 cards.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Enforce Card Limit
DROP TRIGGER IF EXISTS enforce_card_limit ON cards;
CREATE TRIGGER enforce_card_limit
    BEFORE INSERT ON cards
    FOR EACH ROW EXECUTE PROCEDURE check_card_limit();

-- 4. Services Table (Predefined Services like Netflix, Spotify)
CREATE TABLE IF NOT EXISTS services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    icon_name TEXT, -- e.g. 'spotify', 'netflix' for FontAwesome lookup
    color TEXT, -- Hex code, e.g. '#1DB954'
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    default_price NUMERIC(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE services ENABLE ROW LEVEL SECURITY;

-- Policies for Services
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'services' 
        AND policyname = 'Enable read access for all users'
    ) THEN
        CREATE POLICY "Enable read access for all users" ON services FOR SELECT USING (true);
    END IF;
END $$;

-- 5. Subscriptions Table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    service_id UUID REFERENCES services(id) ON DELETE SET NULL, -- Optional link to predefined service
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

-- Policies for Subscriptions
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
    paid_at TIMESTAMP WITH TIME ZONE, -- Nullable (null = pending)
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'skipped')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Policies for Payments
CREATE POLICY "Users can manage their own payments" ON payments
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 7. Support Requests Table
CREATE TABLE IF NOT EXISTS support_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('service_request', 'feedback')),
    content TEXT NOT NULL,
    service_name TEXT, -- Only for service_request
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE support_requests ENABLE ROW LEVEL SECURITY;

-- Policies for Support Requests
CREATE POLICY "Users can manage their own requests" ON support_requests
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());


-- ==========================================
-- Functions & Triggers
-- ==========================================

-- Function: Auto-update 'updated_at' column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Function: Handle New User Signup (Auto-create Profile)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'avatar_url');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: On Auth User Created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- Function: Delete User Account (GDPR/KVKK Compliance)
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();

  -- Delete related data (Cascade handles most, but explicit deletion is safer for order)
  DELETE FROM public.payments WHERE user_id = current_user_id;
  DELETE FROM public.subscriptions WHERE user_id = current_user_id;
  DELETE FROM public.cards WHERE user_id = current_user_id;
  DELETE FROM public.support_requests WHERE user_id = current_user_id;
  
  -- Delete Profile
  DELETE FROM public.profiles WHERE id = current_user_id;

  -- Delete Auth User
  DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;


-- ==========================================
-- Seed Data (Initial Data)
-- ==========================================

-- 8. Insert Default Categories
INSERT INTO categories (name, color, icon_name) VALUES
('Dijital Platformlar', '#E50914', 'film'),
('Araçlar', '#007AFF', 'cloud'),
('Finans', '#34C759', 'attach_money'),
('İş & Kariyer', '#5856D6', 'work'),
('Yazılım', '#FF9500', 'code'),
('Eğitim', '#FF2D55', 'school'),
('Tasarım', '#AF52DE', 'palette'),
('Yapay Zeka', '#00C7BE', 'psychology'),
('Alışveriş', '#FF3B30', 'shopping_bag'),
('Mobil Operatörler', '#34C759', 'phone'),
('İnternet Servis Sağlayıcıları', '#007AFF', 'wifi'),
('Diğer', '#95A5A6', 'more_horiz')
ON CONFLICT (name) DO UPDATE SET 
    color = EXCLUDED.color,
    icon_name = EXCLUDED.icon_name;

-- 9. Insert Default Services
DO $$
DECLARE
    -- Category IDs
    cat_streaming uuid;
    cat_utility uuid;
    cat_mobile uuid;
    cat_isp uuid;
    cat_software uuid;
    cat_design uuid;
    cat_ai uuid;
BEGIN
    -- Get IDs
    SELECT id INTO cat_streaming FROM categories WHERE name = 'Dijital Platformlar';
    SELECT id INTO cat_utility FROM categories WHERE name = 'Araçlar';
    SELECT id INTO cat_mobile FROM categories WHERE name = 'Mobil Operatörler';
    SELECT id INTO cat_isp FROM categories WHERE name = 'İnternet Servis Sağlayıcıları';
    SELECT id INTO cat_software FROM categories WHERE name = 'Yazılım';
    SELECT id INTO cat_design FROM categories WHERE name = 'Tasarım';
    SELECT id INTO cat_ai FROM categories WHERE name = 'Yapay Zeka';

    -- Insert Services
    INSERT INTO services (name, icon_name, color, default_price, category_id) VALUES
    -- Streaming
    ('Netflix', 'film', '#E50914', 199.99, cat_streaming),
    ('Spotify', 'music', '#1DB954', 59.99, cat_streaming),
    ('YouTube Premium', 'youtube', '#FF0000', 57.99, cat_streaming),
    ('Disney+', 'disney', '#113CCF', 134.99, cat_streaming),
    ('Amazon Prime', 'amazon', '#00A8E1', 39.00, cat_streaming),
    ('Apple Music', 'apple', '#FA243C', 39.99, cat_streaming),
    ('BluTV', 'blutv', '#1F2833', 99.90, cat_streaming),
    ('Exxen', 'exxen', '#FFCC00', 129.90, cat_streaming),
    
    -- Cloud/Utility
    ('iCloud', 'cloud', '#007AFF', 12.99, cat_utility),
    ('Google One', 'google', '#4285F4', 9.99, cat_utility),
    
    -- Mobile
    ('Turkcell', 'phone', '#2D3E50', 0, cat_mobile),
    ('Vodafone', 'phone', '#E60000', 0, cat_mobile),
    ('Türk Telekom', 'phone', '#002855', 0, cat_mobile),

    -- ISP
    ('TurkNet', 'wifi', '#D9232E', 399.90, cat_isp),
    ('Superonline', 'wifi', '#FFC107', 0, cat_isp),
    ('Türk Telekom İnternet', 'wifi', '#002855', 0, cat_isp),

    -- Software
    ('GitHub Copilot', 'github', '#000000', 10.00, cat_software),
    ('JetBrains', 'code', '#000000', 0, cat_software),

    -- Design
    ('Adobe Creative Cloud', 'adobe', '#FF0000', 0, cat_design),
    ('Figma', 'figma', '#F24E1E', 15.00, cat_design),
    
    -- AI
    ('ChatGPT Plus', 'chatgpt', '#10A37F', 20.00, cat_ai),
    ('Claude Pro', 'claude', '#D97757', 20.00, cat_ai),
    ('Gemini Advanced', 'gemini', '#4285F4', 0, cat_ai)

    ON CONFLICT (name) DO UPDATE SET 
        category_id = EXCLUDED.category_id, 
        default_price = EXCLUDED.default_price,
        icon_name = EXCLUDED.icon_name,
        color = EXCLUDED.color;
END $$;
