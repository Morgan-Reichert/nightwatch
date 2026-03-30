-- Add custom_cards column to profiles table for personalized profile cards
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS custom_cards JSONB DEFAULT '[]'::jsonb;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_custom_cards ON profiles USING GIN(custom_cards);
