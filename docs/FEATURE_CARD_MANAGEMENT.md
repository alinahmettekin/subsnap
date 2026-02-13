# Feature: Card Management (Ödeme Yöntemleri Yönetimi)

## Overview
This feature allows users to manage their payment cards (Credit/Debit) and link them to their subscriptions.

## Requirements
1. **Card CRUD**: Users can add, view, and remove cards.
2. **Subscription Linkage**: When adding or editing a subscription, users can select one of their saved cards as the payment method.
3. **Usage Limitation**:
    - **Free Users**: Can add a maximum of **2 cards**.
    - **Pro/Premium Users**: Unlimited cards.
4. **Data Display**: In subscription lists and details, the linked card (e.g., "Work Visa - 4242") should be visible.

## Database Schema Changes
The following changes have been applied to `supabase_schema.sql`:

### 1. New `cards` Table
- `id`: UUID (Primary Key)
- `user_id`: UUID (Reference to profiles)
- `card_name`: Text (e.g., "My Business Card")
- `last_four`: VarChar(4) (Last 4 digits for identification)
- `card_type`: Text (e.g., "visa", "mastercard")
- `expiry_date`: Text (MM/YY)
- `created_at`: Timestamp

### 2. Updated `subscriptions` Table
- Added `card_id`: UUID (Reference to cards, nullable)

### 3. Updated `payments` Table
- Added `card_id`: UUID (Reference to cards, nullable) - To track which card was used for a specific historical payment.

### 4. Card Limit Enforcement
A database trigger `enforce_card_limit` has been added to the `cards` table. It checks the user's `is_premium` status from the `profiles` table before allowing a new card insertion.

## UI/UX Tasks for Implementation
1. **Settings/Profile Page**: Add a "Payment Methods" (Ödeme Yöntemleri) section.
2. **Add/Edit Card Screen**: A form to enter card name, last 4 digits, type, and expiry.
3. **Subscription Form**: Add a dropdown to select a card from the user's saved cards.
4. **Logic**:
    - Fetch user's cards using a `cardsProvider`.
    - Before showing the "Add Card" button/screen, check the limit (if not premium and card count >= 2, show a "Upgrade to Pro" message).

## Technical Notes
- Use `lib/features/cards` for the new module.
- Implement `Card` model and `CardService` for Supabase interactions.
- `Subscription` and `Payment` models have been updated to include `cardId`.
