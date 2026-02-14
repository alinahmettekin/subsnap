-- Create services table
CREATE TABLE public.services (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    icon_name text, -- e.g. 'spotify', 'netflix' for FontAwesome lookup
    color text, -- Hex code, e.g. '#1DB954'
    category_id uuid REFERENCES public.categories(id),
    default_price numeric,
    created_at timestamptz DEFAULT now()
);

-- Add service_id to subscriptions
ALTER TABLE public.subscriptions 
ADD COLUMN service_id uuid REFERENCES public.services(id);

-- Insert some initial data (Popular services)
-- Note: You'll need to replace 'CATEGORY_ID_HERE' with actual UUIDs from your categories table if you want strict linking
-- For now, we just insert names/colors
INSERT INTO public.services (name, icon_name, color) VALUES
('Netflix', 'film', '#E50914'),
('Spotify', 'spotify', '#1DB954'),
('YouTube Premium', 'youtube', '#FF0000'),
('Amazon Prime', 'amazon', '#00A8E1'),
('Apple Music', 'apple', '#FA243C'),
('Disney+', 'circlePlay', '#113CCF'),
('iCloud', 'cloud', '#007AFF'),
('Dropbox', 'dropbox', '#0061FF'),
('Exxen', 'tv', '#FFC600'),
('BluTV', 'movie', '#0096D6');
