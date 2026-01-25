-- ============================================
-- SUPABASE CRON JOB KURULUMU
-- ============================================
-- 
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştır
-- 
-- ÖNEMLİ: Önce pg_cron extension'ını aktif etmen gerekiyor:
-- 1. Supabase Dashboard > Database > Extensions
-- 2. "pg_cron" extension'ını bul ve aktif et
-- 3. Sonra bu SQL'i çalıştır
--

-- pg_cron extension'ını aktif et (eğer yoksa)
create extension if not exists pg_cron;

-- Otomatik ödeme işlemlerini her dakika çalıştır (test için)
-- Production'da '0 1 * * *' kullan (her gün saat 01:00 UTC)
select cron.schedule(
  'process-automatic-payments',  -- Job adı
  '* * * * *',                         -- Cron expression: Her dakika (test için)
  $$select public.process_automatic_payments()$$
);

-- Cron job'ları kontrol etmek için:
-- select * from cron.job;

-- Cron job'ı silmek için (gerekirse):
-- select cron.unschedule('process-automatic-payments');
