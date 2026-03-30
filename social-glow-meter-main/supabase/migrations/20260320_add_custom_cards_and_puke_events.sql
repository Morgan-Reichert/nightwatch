-- Add custom_cards column to profiles if it doesn't exist
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS custom_cards JSONB DEFAULT '[]'::jsonb;

-- Create puke_events table to track vomit incidents
CREATE TABLE IF NOT EXISTS public.puke_events (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  party_id UUID NOT NULL REFERENCES public.parties(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create shop_events table to track kiss/smooch incidents
CREATE TABLE IF NOT EXISTS public.shop_events (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  party_id UUID NOT NULL REFERENCES public.parties(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.puke_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Party members can view puke events" ON public.puke_events
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can log their own puke events" ON public.puke_events
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Party members can view shop events" ON public.shop_events
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can log their own shop events" ON public.shop_events
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_profiles_custom_cards ON public.profiles USING GIN(custom_cards);
CREATE INDEX IF NOT EXISTS idx_puke_events_party_id ON public.puke_events(party_id);
CREATE INDEX IF NOT EXISTS idx_puke_events_user_id ON public.puke_events(user_id);
CREATE INDEX IF NOT EXISTS idx_puke_events_created_at ON public.puke_events(created_at);
CREATE INDEX IF NOT EXISTS idx_shop_events_party_id ON public.shop_events(party_id);
CREATE INDEX IF NOT EXISTS idx_shop_events_user_id ON public.shop_events(user_id);
CREATE INDEX IF NOT EXISTS idx_shop_events_created_at ON public.shop_events(created_at);

