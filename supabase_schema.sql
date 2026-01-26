-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create categories table (global, kullanıcı bazlı değil)
create table public.categories (
  id uuid not null default uuid_generate_v4() primary key,
  name text not null unique,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create profiles table (subscriptions ve payments'tan ÖNCE oluşturulmalı)
create table public.profiles (
  id uuid not null references auth.users(id) on delete cascade primary key,
  email text,
  display_name text,
  avatar_url text,
  is_pro boolean not null default false,
  pro_expiry timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for profiles
alter table public.profiles enable row level security;

-- Profiles policies
create policy "Public profiles are viewable by everyone"
on public.profiles for select
using (true);

create policy "Users can insert their own profile"
on public.profiles for insert
with check (auth.uid() = id);

create policy "Users can update their own profiles"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Users can delete their own profile"
on public.profiles for delete
using (auth.uid() = id);

-- Create subscriptions table
create table public.subscriptions (
  id uuid not null default uuid_generate_v4() primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  amount numeric not null,
  currency text not null default 'USD',
  billing_cycle text not null check (billing_cycle in ('monthly', 'yearly', 'weekly', 'daily')),
  next_payment_date timestamp with time zone not null,
  category_id uuid references public.categories(id) on delete set null,
  is_paused boolean not null default false,
  paused_until timestamp with time zone,
  notify_1_day_before boolean not null default true,
  notify_3_days_before boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create subscription_templates table (global, kullanıcı bazlı değil)
create table public.subscription_templates (
  id uuid not null default uuid_generate_v4() primary key,
  name text not null unique,
  icon_name text not null, -- SimpleIcons icon name (örn: 'netflix', 'youtube')
  default_billing_cycle text not null check (default_billing_cycle in ('monthly', 'yearly', 'weekly', 'daily')),
  category_id uuid references public.categories(id) on delete set null,
  display_order integer not null default 0, -- Sıralama için
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Insert default categories (20 tane + Diğer)
insert into public.categories (name) values
  ('Entertainment'),
  ('Streaming'),
  ('Music'),
  ('Software'),
  ('Cloud Storage'),
  ('Gaming'),
  ('News'),
  ('Fitness'),
  ('Education'),
  ('Productivity'),
  ('Social Media'),
  ('Shopping'),
  ('Utilities'),
  ('Finance'),
  ('Health'),
  ('Travel'),
  ('Food & Delivery'),
  ('Photography'),
  ('Security'),
  ('Diğer')
on conflict (name) do nothing;

-- Insert default subscription templates
-- Kategoriler zaten insert edildi, şimdi template'leri ekle
insert into public.subscription_templates (name, icon_name, default_billing_cycle, category_id, display_order)
select 
  t.name,
  t.icon_name,
  t.default_billing_cycle,
  c.id as category_id,
  t.display_order
from (values
  -- Entertainment & Streaming
  ('Netflix', 'netflix', 'monthly', 'Entertainment', 1),
  ('YouTube Premium', 'youtube', 'monthly', 'Entertainment', 2),
  ('Spotify', 'spotify', 'monthly', 'Music', 3),
  ('Apple Music', 'applemusic', 'monthly', 'Music', 4),
  ('Amazon Prime', 'amazon', 'monthly', 'Shopping', 5),
  -- Productivity & Software
  ('ChatGPT', 'openai', 'monthly', 'Productivity', 6),
  ('Canva', 'canva', 'monthly', 'Productivity', 7),
  ('Cursor', 'cursor', 'monthly', 'Software', 8),
  ('Notion', 'notion', 'monthly', 'Productivity', 9),
  ('Figma', 'figma', 'monthly', 'Software', 10),
  ('Adobe Creative Cloud', 'adobe', 'monthly', 'Software', 11),
  ('Microsoft 365', 'microsoft', 'monthly', 'Productivity', 12),
  ('Google Workspace', 'google', 'monthly', 'Productivity', 13),
  -- Cloud Storage
  ('Dropbox', 'dropbox', 'monthly', 'Cloud Storage', 14),
  ('iCloud', 'icloud', 'monthly', 'Cloud Storage', 15),
  -- Gaming
  ('Xbox Game Pass', 'xbox', 'monthly', 'Gaming', 16),
  ('PlayStation Plus', 'playstation', 'monthly', 'Gaming', 17),
  ('Steam', 'steam', 'monthly', 'Gaming', 18),
  -- Social & Communication
  ('Discord Nitro', 'discord', 'monthly', 'Social Media', 19),
  ('LinkedIn Premium', 'linkedin', 'monthly', 'Social Media', 20),
  ('Twitch', 'twitch', 'monthly', 'Entertainment', 21)
) as t(name, icon_name, default_billing_cycle, category_name, display_order)
left join public.categories c on c.name = t.category_name
on conflict (name) do nothing;

-- Enable Row Level Security (RLS)
alter table public.subscriptions enable row level security;
alter table public.categories enable row level security;

-- Subscriptions policies
create policy "Users can view their own subscriptions"
on public.subscriptions for select
using (auth.uid() = user_id);

create policy "Users can insert their own subscriptions"
on public.subscriptions for insert
with check (auth.uid() = user_id);

create policy "Users can update their own subscriptions"
on public.subscriptions for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their own subscriptions"
on public.subscriptions for delete
using (auth.uid() = user_id);

-- Categories policies (herkes okuyabilir)
create policy "Anyone can view categories"
on public.categories for select
using (true);

-- Subscription templates policies (herkes okuyabilir)
create policy "Anyone can view subscription templates"
on public.subscription_templates for select
using (true);

-- Create a function to handle updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create a trigger for updated_at
drop trigger if exists handle_updated_at on public.subscriptions;
create trigger handle_updated_at
before update on public.subscriptions
for each row
execute procedure public.handle_updated_at();

-- ============================================
-- BACKEND: Otomatik Ödeme İşlemleri
-- ============================================

-- Function: Bir sonraki ödeme tarihini hesapla
create or replace function public.calculate_next_payment_date(
  payment_date timestamp with time zone,
  cycle text
) returns timestamp with time zone as $$
begin
  case cycle
    when 'monthly' then
      return payment_date + interval '1 month';
    when 'yearly' then
      return payment_date + interval '1 year';
    when 'weekly' then
      return payment_date + interval '7 days';
    when 'daily' then
      return payment_date + interval '1 day';
    else
      return payment_date + interval '1 month';
  end case;
end;
$$ language plpgsql;

-- Function: Otomatik ödeme işlemlerini yap
create or replace function public.process_automatic_payments()
returns void as $$
declare
  subscription_record record;
  v_current_payment_date timestamp with time zone;
  v_next_payment_date timestamp with time zone;
  v_payment_count integer;
  v_max_payments integer := 12; -- Güvenlik için maksimum 12 döngü
begin
  -- Tüm aktif abonelikleri kontrol et (dondurulmamış ve ödeme tarihi geçmiş)
  for subscription_record in
    select *
    from public.subscriptions
    where is_paused = false
      and next_payment_date < now()
      and (paused_until is null or paused_until < now())
  loop
    -- Eğer paused_until geçmişse, dondurmayı kaldır
    if subscription_record.paused_until is not null 
       and subscription_record.paused_until < now() then
      update public.subscriptions
      set is_paused = false,
          paused_until = null
      where id = subscription_record.id;
    end if;

    -- Ödeme tarihi geçmişse otomatik ödeme kayıtları oluştur
    v_current_payment_date := subscription_record.next_payment_date;
    v_payment_count := 0;

    -- Birden fazla döngü geçmiş olabilir, hepsini işle
    while v_current_payment_date < now() and v_payment_count < v_max_payments loop
      -- Ödeme kaydı oluştur
      insert into public.payments (
        subscription_id,
        user_id,
        payment_date,
        amount,
        currency
      ) values (
        subscription_record.id,
        subscription_record.user_id,
        v_current_payment_date,
        subscription_record.amount,
        subscription_record.currency
      );

      -- Bir sonraki ödeme tarihini hesapla
      v_next_payment_date := public.calculate_next_payment_date(
        v_current_payment_date,
        subscription_record.billing_cycle
      );
      
      v_current_payment_date := v_next_payment_date;
      v_payment_count := v_payment_count + 1;
    end loop;

    -- Eğer ödeme yapıldıysa, next_payment_date'i güncelle
    if v_payment_count > 0 then
      update public.subscriptions
      set next_payment_date = v_current_payment_date
      where id = subscription_record.id;
    end if;
  end loop;
end;
$$ language plpgsql security definer;

-- NOT: pg_cron extension'ı Supabase'de varsayılan olarak aktif değil
-- Supabase Dashboard > Database > Extensions'dan pg_cron'u aktif etmen gerekiyor
-- Sonra şu SQL'i çalıştır:
-- 
-- select cron.schedule(
--   'process-automatic-payments',  -- job name
--   '0 1 * * *',                   -- Her gün saat 01:00'da çalış (UTC)
--   $$select public.process_automatic_payments()$$
-- );

-- Create payments table
create table public.payments (
  id uuid not null default uuid_generate_v4() primary key,
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  payment_date timestamp with time zone not null default timezone('utc'::text, now()),
  amount numeric not null,
  currency text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for payments
alter table public.payments enable row level security;

-- Payments policies
create policy "Users can view their own payments"
on public.payments for select
using (auth.uid() = user_id);

create policy "Users can insert their own payments"
on public.payments for insert
with check (auth.uid() = user_id);

create policy "Users can delete their own payments"
on public.payments for delete
using (auth.uid() = user_id);

-- Function: Handle new user profile creation
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name, avatar_url)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;-- Trigger: On auth user created
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Trigger for updated_at on profiles
drop trigger if exists handle_updated_at_profiles on public.profiles;
create trigger handle_updated_at_profiles
before update on public.profiles
for each row
execute procedure public.handle_updated_at();

-- ============================================
-- ACHIEVEMENTS SYSTEM
-- ============================================

-- Create achievements table
create table public.achievements (
  id text primary key, -- 'first_sub', 'five_subs', etc.
  name text not null,
  description text not null,
  icon_name text not null, -- FontAwesome or custom icon name
  points integer not null default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create user_achievements table
create table public.user_achievements (
  user_id uuid not null references public.profiles(id) on delete cascade,
  achievement_id text not null references public.achievements(id) on delete cascade,
  earned_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (user_id, achievement_id)
);

-- Enable RLS
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;

-- Policies
create policy "Anyone can view achievements" on public.achievements for select using (true);
create policy "Users can view their own earned achievements" on public.user_achievements for select using (auth.uid() = user_id);
create policy "Users can insert their own earned achievements" on public.user_achievements for insert with check (auth.uid() = user_id);
create policy "Users can update their own earned achievements" on public.user_achievements for update using (auth.uid() = user_id);

-- Insert default achievements
insert into public.achievements (id, name, description, icon_name, points) values
  ('profile_setup', 'Hoş Geldin!', 'Profilini başarıyla tamamladın.', 'user_check', 10),
  ('first_sub', 'İlk Adım', 'İlk aboneliğini ekledin.', 'plus_circle', 20),
  ('five_subs', 'Koleksiyoncu', '5 farklı aboneliği takip ediyorsun.', 'list_check', 50),
  ('ten_subs', 'Usta Takipçi', '10 farklı aboneliği başarıyla yönetiyorsun.', 'trophy', 100)
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  icon_name = excluded.icon_name,
  points = excluded.points;