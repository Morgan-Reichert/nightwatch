-- Add bio and phone columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT NULL;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
