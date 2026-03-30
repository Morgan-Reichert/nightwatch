-- Table des achats utilisateurs
CREATE TABLE IF NOT EXISTS user_purchases (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id           TEXT NOT NULL,
  stripe_session_id TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_purchases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own purchases"   ON user_purchases FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own purchases" ON user_purchases FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Champs de personnalisation visuelle sur le profil
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS avatar_frame     TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS banner_gradient  TEXT DEFAULT NULL;
