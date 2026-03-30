-- Party Requests table
CREATE TABLE public.party_requests (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  party_id UUID NOT NULL REFERENCES public.parties(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(party_id, user_id)
);

ALTER TABLE public.party_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view party requests for their parties" ON public.party_requests FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR party_id IN (SELECT id FROM public.parties WHERE created_by = auth.uid()));

CREATE POLICY "Users can request to join parties" ON public.party_requests FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Party creators can update request status" ON public.party_requests FOR UPDATE TO authenticated
  USING (party_id IN (SELECT id FROM public.parties WHERE created_by = auth.uid()));

CREATE POLICY "Users can delete their request" ON public.party_requests FOR DELETE TO authenticated
  USING (auth.uid() = user_id);
