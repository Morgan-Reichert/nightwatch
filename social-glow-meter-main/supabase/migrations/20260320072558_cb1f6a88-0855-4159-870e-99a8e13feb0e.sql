
-- Party photos table
CREATE TABLE public.party_photos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  party_id UUID NOT NULL REFERENCES public.parties(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  image_url TEXT NOT NULL,
  caption TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.party_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Party members can view photos" ON public.party_photos
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can upload their own photos" ON public.party_photos
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own photos" ON public.party_photos
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Member locations table
CREATE TABLE public.member_locations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  party_id UUID NOT NULL REFERENCES public.parties(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(user_id, party_id)
);

ALTER TABLE public.member_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Party members can view locations" ON public.member_locations
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can upsert their own location" ON public.member_locations
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own location" ON public.member_locations
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Enable realtime for locations
ALTER PUBLICATION supabase_realtime ADD TABLE public.member_locations;

-- Storage bucket for party photos
INSERT INTO storage.buckets (id, name, public) VALUES ('party-photos', 'party-photos', true);

-- Storage policies for party-photos bucket
CREATE POLICY "Anyone can view party photos" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'party-photos');

CREATE POLICY "Authenticated users can upload party photos" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'party-photos');

CREATE POLICY "Users can delete their own party photos" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'party-photos');
