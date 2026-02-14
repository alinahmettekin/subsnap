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
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE, -- NULL for global/default categories
    name TEXT NOT NULL,
    icon TEXT,
    color TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own categories" ON categories;
CREATE POLICY "Users can manage their own categories" ON categories
    FOR ALL USING (user_id IS NULL OR user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE UNIQUE INDEX IF NOT EXISTS categories_name_default_key ON categories (name) WHERE user_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS categories_name_user_key ON categories (name, user_id) WHERE user_id IS NOT NULL;

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
INSERT INTO categories (name, icon, color) VALUES
('Entertainment', 'movie', '#FF5733'),
('Streaming', 'play_circle', '#E74C3C'),
('Software', 'code', '#3498DB'),
('Utility', 'settings', '#F1C40F'),
('Education', 'school', '#2ECC71'),
('Other', 'more_horiz', '#95A5A6')
ON CONFLICT (name) WHERE user_id IS NULL DO NOTHING;

-- 9. Insert default services
-- First, ensure name is unique to handle conflicts
CREATE UNIQUE INDEX IF NOT EXISTS services_name_key ON services (name);

INSERT INTO services (name, icon_name, color, default_price) VALUES
('Netflix', 'film', '#E50914', 199.99),
('Spotify', 'spotify', '#1DB954', 59.99),
('YouTube Premium', 'youtube', '#FF0000', 57.99),
('Amazon Prime', 'amazon', '#00A8E1', 39.00),
('Apple Music', 'apple', '#FA243C', 19.99),
('Disney+', 'circlePlay', '#113CCF', 134.99),
('iCloud', 'cloud', '#007AFF', 12.99),
('Dropbox', 'dropbox', '#0061FF', 0),
('Exxen', 'tv', '#FFC600', 99.90),
('BluTV', 'movie', '#0096D6', 149.90)
ON CONFLICT (name) DO NOTHING;
