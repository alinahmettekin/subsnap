-- ===========================================
-- Trigger Function: Generate Past Payments
-- ===========================================
-- This function runs automatically after a new subscription is created.
-- It generates historical 'paid' records starting from the next_payment_date backwards
-- until 2024-01-01, simulating that the user has been using the app for a while.

create or replace function generate_past_payments()
returns trigger
language plpgsql
security definer
as $$
declare
    current_calculation_date date;
    cutoff_date date := '2024-01-01';
    now_date date := current_date;
begin
    -- Start from one cycle BEFORE the upcoming payment date
    current_calculation_date := NEW.next_payment_date;

    -- Loop to generate past payments
    loop
        -- Decrement date based on billing period
        if NEW.billing_period = 'monthly' then
            current_calculation_date := current_calculation_date - interval '1 month';
        elsif NEW.billing_period = 'yearly' then
            current_calculation_date := current_calculation_date - interval '1 year';
        else
            current_calculation_date := current_calculation_date - interval '1 month'; -- Default to monthly if unknown
        end if;

        -- Break conditions:
        -- 1. If we go before the cutoff date (Jan 1, 2024)
        exit when current_calculation_date < cutoff_date;
        
        -- 2. If the calculated date is in the future (shouldn't happen with correct logic, but safe guard)
        -- We only want PAST payments.
        exit when current_calculation_date > now_date;

        -- Insert the past payment record
        insert into public.payments (
            user_id,
            subscription_id,
            card_id,
            amount,
            currency,
            due_date,
            paid_at,
            status
        ) values (
            NEW.user_id,
            NEW.id,
            NEW.card_id,
            NEW.amount,
            NEW.currency,
            current_calculation_date,
            current_calculation_date, -- paid exactly on due date
            'paid'
        );
        
    end loop;

    return NEW;
end;
$$;

-- Create the Trigger
drop trigger if exists on_subscription_created_generate_history on public.subscriptions;

create trigger on_subscription_created_generate_history
    after insert on public.subscriptions
    for each row
    execute function generate_past_payments();
