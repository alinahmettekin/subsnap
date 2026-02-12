-- 1. Enable pg_cron extension (You might need to enable this from Supabase Dashboard -> Database -> Extensions)
create extension if not exists pg_cron;

-- 2. Modify payments table to support scheduling
-- Adding user_id for easier RLS and due_date for scheduling
alter table public.payments 
add column if not exists user_id uuid references auth.users(id),
add column if not exists due_date date,
add column if not exists currency text default '₺' check (currency in ('₺', '€', '$')),
drop constraint if exists payments_status_check;

alter table public.payments
add constraint payments_status_check check (status in ('paid', 'pending', 'overdue', 'skipped'));

-- Backfill user_id for existing payments
update public.payments p
set user_id = s.user_id
from public.subscriptions s
where p.subscription_id = s.id
and p.user_id is null;

-- Enable RLS
alter table public.payments enable row level security;

-- Update Policies
drop policy if exists "Users can view their own payments" on public.payments;
create policy "Users can view their own payments" 
on public.payments for select 
using (auth.uid() = user_id);

drop policy if exists "Users can update their own payments" on public.payments;
create policy "Users can update their own payments" 
on public.payments for update 
using (auth.uid() = user_id);

-- 3. Function to generate recurring payments
create or replace function generate_recurring_payments()
returns void
language plpgsql
security definer
as $$
begin
  -- Insert pending payments for subscriptions due in the next 30 days
  -- Prevents duplicates by checking if payment already exists
  insert into public.payments (subscription_id, user_id, amount, currency, due_date, status)
  select 
    s.id,
    s.user_id,
    s.amount, 
    s.currency, 
    s.next_payment_date, 
    'pending'
  from public.subscriptions s
  where s.next_payment_date <= current_date + interval '30 days'
  and s.status = 'active'
  and not exists (
    select 1 from public.payments p
    where p.subscription_id = s.id
    and p.due_date = s.next_payment_date
  );

  -- Update subscription next_payment_date for payments that are overdue
  update public.subscriptions
  set next_payment_date = case 
      when billing_period = 'monthly' then next_payment_date + interval '1 month'
      when billing_period = 'yearly' then next_payment_date + interval '1 year'
      else next_payment_date + interval '1 month'
    end
  where next_payment_date < current_date
  and status = 'active';
end;
$$;

-- 4. Schedule cron job (Runs heavily: every minute)
select cron.schedule(
  'generate-payments-minutely',
  '* * * * *',
  'select generate_recurring_payments()'
);
