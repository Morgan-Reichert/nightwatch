-- Normalise les pseudos existants en minuscules pour éviter les doublons
-- (optionnel, à adapter selon votre besoin)
-- UPDATE profiles SET pseudo = LOWER(TRIM(pseudo));

-- Contrainte d'unicité insensible à la casse
CREATE UNIQUE INDEX IF NOT EXISTS profiles_pseudo_unique
  ON profiles (LOWER(TRIM(pseudo)));
