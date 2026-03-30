import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

export interface CustomCard {
  id: string;
  title: string;
  value: string;
  icon?: string;
}

export interface Profile {
  id: string;
  user_id: string;
  pseudo: string;
  gender: 'male' | 'female';
  weight: number;
  height: number;
  age: number;
  avatar_url: string | null;
  emergency_contact: string | null;
  phone: string | null;
  bio: string | null;
  custom_cards?: CustomCard[];
  // Réseaux sociaux
  snapchat?: string | null;
  instagram?: string | null;
  tiktok?: string | null;
  // Infos perso
  city?: string | null;
  school?: string | null;
  job?: string | null;
  zodiac?: string | null;
  music_taste?: string | null;
  party_style?: string | null;
  // Shop
  avatar_frame?: string | null;
  banner_gradient?: string | null;
}

export interface DrinkEntry {
  id: string;
  user_id: string;
  party_id: string | null;
  name: string;
  volume_ml: number;
  abv: number;
  alcohol_grams: number;
  image_url: string | null;
  detected_by_ai: boolean | null;
  created_at: string;
}

export interface Party {
  id: string;
  name: string;
  code: string;
  created_by: string;
  is_active: boolean;
  created_at: string;
}

export interface PartyMember {
  id: string;
  party_id: string;
  user_id: string;
  joined_at: string;
  show_bac?: boolean;
}

export interface Story {
  id: string;
  user_id: string;
  party_id: string | null;
  image_url: string;
  caption: string | null;
  bac_at_post: number | null;
  expires_at: string;
  created_at: string;
}

export interface Friendship {
  id: string;
  requester_id: string;
  addressee_id: string;
  status: string;
  created_at: string;
}

export interface PartyPhoto {
  id: string;
  party_id: string;
  user_id: string;
  image_url: string;
  caption: string | null;
  created_at: string;
}

export interface MemberLocation {
  id: string;
  user_id: string;
  party_id: string;
  latitude: number;
  longitude: number;
  updated_at: string;
}

export interface PartyRequest {
  id: string;
  party_id: string;
  user_id: string;
  status: 'pending' | 'accepted' | 'rejected';
  created_at: string;
}

export interface PartyInvitation {
  id: string;
  party_id: string;
  inviter_id: string;
  invitee_id: string;
  status: 'pending' | 'accepted' | 'declined';
  created_at: string;
}

export interface PukeEvent {
  id: string;
  party_id: string;
  user_id: string;
  created_at: string;
}

export interface ShopEvent {
  id: string;
  party_id: string;
  user_id: string;
  created_at: string;
}

export function calculateAlcoholGrams(volumeMl: number, abv: number): number {
  return volumeMl * abv * 0.8;
}

export function calculateBAC(
  drinks: DrinkEntry[],
  weight: number,
  gender: 'male' | 'female',
  atTime?: number
): number {
  if (!weight || Number.isNaN(weight) || weight <= 0) return 0;
  const now = atTime || Date.now();
  const k = gender === 'female' ? 0.6 : 0.7;
  
  // Calculate remaining BAC for each drink, accounting for degradation
  let totalBAC = 0;
  drinks.forEach(d => {
    if (d.alcohol_grams <= 0) return;
    
    const drinkTime = new Date(d.created_at).getTime();
    const hoursSinceDrink = (now - drinkTime) / (1000 * 60 * 60);
    
    // BAC contribution from this drink = alcohol_grams / (weight * k)
    const bacFromDrink = d.alcohol_grams / (weight * k);
    
    // Alcohol degrades at 0.15 g/L per hour
    const remainingBAC = Math.max(0, bacFromDrink - 0.15 * hoursSinceDrink);
    totalBAC += remainingBAC;
  });
  
  return Math.max(0, parseFloat(totalBAC.toFixed(2)));
}

export function getTimeTo(targetBAC: number, currentBAC: number): number {
  if (currentBAC <= targetBAC) return 0;
  return (currentBAC - targetBAC) / 0.15;
}

export function getBACStatus(bac: number): 'safe' | 'warning' | 'danger' {
  if (bac < 0.2) return 'safe';
  if (bac < 0.5) return 'warning';
  return 'danger';
}

export function useProfile() {
  const { user } = useAuth();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchProfile = useCallback(async () => {
    if (!user) {
      setProfile(null);
      setLoading(false);
      return;
    }
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', user.id)
      .single();
    if (error) {
      // Supabase returns error when no row is found for single(); this is expected for new users.
      if (error.code !== 'PGRST116' && error.message !== 'No rows found') {
        console.error('Error fetching profile:', error.message);
      }
      setProfile(null);
      setLoading(false);
      return;
    }
    setProfile(data as Profile | null);
    setLoading(false);
  }, [user]);

  useEffect(() => { fetchProfile(); }, [fetchProfile]);

  // Realtime subscription — profile updates instantly
  useEffect(() => {
    if (!user) return;
    const channel = supabase.channel(`profile:${user.id}`)
      .on('postgres_changes', {
        event: 'UPDATE', schema: 'public', table: 'profiles',
        filter: `user_id=eq.${user.id}`,
      }, (payload) => {
        setProfile(payload.new as Profile);
      })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [user]);

  const createProfile = async (p: Omit<Profile, 'id' | 'user_id' | 'avatar_url' | 'emergency_contact'>) => {
    if (!user) return;
    const { data, error } = await supabase
      .from('profiles')
      .insert({ ...p, user_id: user.id })
      .select()
      .single();
    if (error) throw error;
    setProfile(data as Profile);
  };

  const updateProfile = async (updates: Partial<Profile>) => {
    if (!user || !profile) return;
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('user_id', user.id)
      .select()
      .single();
    if (error) throw error;
    setProfile(data as Profile);
  };

  return { profile, loading, createProfile, updateProfile, refetch: fetchProfile };
}

/** Fetch ALL drinks for the current user (across all parties) - used for global BAC */
export function useAllMyDrinks() {
  const { user } = useAuth();
  const [drinks, setDrinks] = useState<DrinkEntry[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchDrinks = useCallback(async () => {
    if (!user) {
      setLoading(false);
      return;
    }
    const { data, error } = await supabase
      .from('drinks')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    if (error) {
      console.error('Error fetching drinks:', error.message);
      setDrinks([]);
    } else {
      setDrinks((data || []) as DrinkEntry[]);
    }
    setLoading(false);
  }, [user]);

  useEffect(() => {
    fetchDrinks();
  }, [fetchDrinks]);

  return { drinks, loading, refetch: fetchDrinks };
}

export function useDrinks(partyId?: string | null) {
  const { user } = useAuth();
  const [drinks, setDrinks] = useState<DrinkEntry[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchDrinks = useCallback(async () => {
    if (!user) return;
    let query = supabase.from('drinks').select('*').order('created_at', { ascending: false });
    if (partyId) {
      query = query.eq('party_id', partyId);
    } else {
      query = query.eq('user_id', user.id);
    }
    const { data } = await query;
    setDrinks((data || []) as DrinkEntry[]);
    setLoading(false);
  }, [user, partyId]);

  useEffect(() => { fetchDrinks(); }, [fetchDrinks]);

  const addDrink = async (drink: { name: string; volume_ml: number; abv: number; party_id?: string; detected_by_ai?: boolean; image_url?: string }) => {
    if (!user) return;
    const alcohol_grams = calculateAlcoholGrams(drink.volume_ml, drink.abv);
    const { data, error } = await supabase
      .from('drinks')
      .insert({
        user_id: user.id,
        name: drink.name,
        volume_ml: drink.volume_ml,
        abv: drink.abv,
        alcohol_grams,
        party_id: drink.party_id || null,
        detected_by_ai: drink.detected_by_ai || false,
        image_url: drink.image_url || null,
      })
      .select()
      .single();
    if (error) throw error;
    setDrinks(prev => [data as DrinkEntry, ...prev]);
    return data as DrinkEntry;
  };

  const deleteDrink = async (id: string) => {
    await supabase.from('drinks').delete().eq('id', id);
    setDrinks(prev => prev.filter(d => d.id !== id));
  };

  const deleteAllDrinks = async (alcoholOnly?: boolean) => {
    if (!user) return;
    let query = supabase.from('drinks').delete().eq('user_id', user.id);
    if (alcoholOnly) query = query.gt('abv', 0);
    await query;
    await fetchDrinks();
  };

  return { drinks, loading, addDrink, deleteDrink, deleteAllDrinks, refetch: fetchDrinks };
}

export function useParties() {
  const { user } = useAuth();
  const [parties, setParties] = useState<Party[]>([]);
  const [currentParty, setCurrentParty] = useState<Party | null>(null);
  const [members, setMembers] = useState<(PartyMember & { profile?: Profile })[]>([]);

  const fetchMyParties = useCallback(async () => {
    if (!user) return;
    const { data: memberData } = await supabase
      .from('party_members')
      .select('party_id')
      .eq('user_id', user.id);
    if (!memberData?.length) { setParties([]); return; }
    const partyIds = memberData.map(m => m.party_id);
    const { data } = await supabase
      .from('parties')
      .select('*')
      .in('id', partyIds)
      .eq('is_active', true);
    setParties((data || []) as Party[]);
  }, [user]);

  useEffect(() => { fetchMyParties(); }, [fetchMyParties]);

  const createParty = async (name: string) => {
    if (!user) return;
    const { data, error } = await supabase
      .from('parties')
      .insert({ name, created_by: user.id })
      .select()
      .single();
    if (error) throw error;
    const party = data as Party;
    await supabase.from('party_members').insert({ party_id: party.id, user_id: user.id });
    setCurrentParty(party);
    await fetchMyParties();
    return party;
  };

  const joinParty = async (code: string) => {
    if (!user) return;
    const { data: party, error: findErr } = await supabase
      .from('parties')
      .select('*')
      .eq('code', code.toLowerCase().trim())
      .eq('is_active', true)
      .single();
    if (findErr || !party) throw new Error('Soirée introuvable');
    await supabase.from('party_members').insert({ party_id: party.id, user_id: user.id });
    setCurrentParty(party as Party);
    await fetchMyParties();
    return party as Party;
  };

  const leaveParty = async (partyId: string) => {
    if (!user) return;
    await supabase.from('party_members').delete().eq('party_id', partyId).eq('user_id', user.id);
    if (currentParty?.id === partyId) setCurrentParty(null);
    await fetchMyParties();
  };

  const deleteParty = async (partyId: string) => {
    if (!user) return;
    
    // Fetch party details
    const { data: party } = await supabase.from('parties').select('*').eq('id', partyId).single();
    
    // Only proceed if user is the creator
    if (party?.created_by !== user.id) return;
    
    // Send photos to admin email
    try {
      const { data: { user: adminUser } } = await supabase.auth.getUser();
      if (adminUser?.email) {
        await supabase.functions.invoke('send-party-photos', {
          body: {
            partyId,
            adminEmail: adminUser.email,
            partyName: party?.name || 'Soirée'
          }
        });
      }
    } catch (err) {
      console.error('Failed to send photos:', err);
    }
    
    // Delete the party
    await supabase.from('parties').update({ is_active: false }).eq('id', partyId).eq('created_by', user.id);
    if (currentParty?.id === partyId) setCurrentParty(null);
    await fetchMyParties();
  };

  const fetchMembers = useCallback(async (partyId: string) => {
    const { data: memberData } = await supabase
      .from('party_members')
      .select('*')
      .eq('party_id', partyId);
    if (!memberData) return;
    const userIds = memberData.map(m => m.user_id);
    const { data: profiles } = await supabase
      .from('profiles')
      .select('*')
      .in('user_id', userIds);
    const enriched = memberData.map(m => ({
      ...m,
      profile: (profiles || []).find(p => p.user_id === m.user_id) as Profile | undefined,
    }));
    setMembers(enriched);
  }, []);

  const toggleBacVisibility = async (partyId: string) => {
    if (!user) return;
    const myMember = members.find(m => m.user_id === user.id);
    const currentValue = myMember?.show_bac !== false;
    await supabase
      .from('party_members')
      .update({ show_bac: !currentValue })
      .eq('party_id', partyId)
      .eq('user_id', user.id);
    await fetchMembers(partyId);
  };

  return { parties, currentParty, setCurrentParty, members, createParty, joinParty, leaveParty, deleteParty, fetchMembers, toggleBacVisibility, refetch: fetchMyParties };
}

export function useStories(partyId?: string | null) {
  const { user } = useAuth();
  const [stories, setStories] = useState<(Story & { profile?: Profile })[]>([]);

  const fetchStories = useCallback(async () => {
    if (!user) return;
    
    // If partyId is provided, return stories from that party only
    if (partyId) {
      let query = supabase.from('stories').select('*').eq('party_id', partyId).order('created_at', { ascending: false });
      const { data } = await query;
      if (!data) return;
      const userIds = [...new Set(data.map(s => s.user_id))];
      const { data: profiles } = await supabase.from('profiles').select('*').in('user_id', userIds);
      setStories(data.map(s => ({
        ...s as Story,
        profile: (profiles || []).find(p => p.user_id === s.user_id) as Profile | undefined,
      })));
      return;
    }

    // If no partyId, fetch stories from friends only
    // First, get list of friends
    const { data: friendships } = await supabase
      .from('friendships')
      .select('*')
      .eq('status', 'accepted')
      .or(`requester_id.eq.${user.id},addressee_id.eq.${user.id}`);

    if (!friendships || friendships.length === 0) {
      setStories([]);
      return;
    }

    // Extract friend IDs
    const friendIds = friendships
      .map(f => f.requester_id === user.id ? f.addressee_id : f.requester_id)
      .filter(id => id !== user.id);

    // Add user's own ID to see their own stories
    const userIdsToShow = [...friendIds, user.id];

    // Fetch stories from friends and self only
    const { data } = await supabase
      .from('stories')
      .select('*')
      .in('user_id', userIdsToShow)
      .is('party_id', null) // Only personal stories, not party stories
      .order('created_at', { ascending: false });

    if (!data) return;
    const userIds = [...new Set(data.map(s => s.user_id))];
    const { data: profiles } = await supabase.from('profiles').select('*').in('user_id', userIds);
    setStories(data.map(s => ({
      ...s as Story,
      profile: (profiles || []).find(p => p.user_id === s.user_id) as Profile | undefined,
    })));
  }, [user, partyId]);

  useEffect(() => { fetchStories(); }, [fetchStories]);

  const addStory = async (imageFile: File, caption: string, bac: number, partyId?: string) => {
    if (!user) return;
    const fileName = `${user.id}/${Date.now()}.jpg`;
    const { error: uploadErr } = await supabase.storage.from('stories').upload(fileName, imageFile);
    if (uploadErr) throw uploadErr;
    const { data: urlData } = supabase.storage.from('stories').getPublicUrl(fileName);
    const { error } = await supabase.from('stories').insert({
      user_id: user.id,
      image_url: urlData.publicUrl,
      caption,
      bac_at_post: bac,
      party_id: partyId || null,
    });
    if (error) throw error;
    await fetchStories();
  };

  return { stories, addStory, refetch: fetchStories };
}

export function useFriendships() {
  const { user } = useAuth();
  const [friends, setFriends] = useState<(Friendship & { profile?: Profile })[]>([]);
  const [requests, setRequests] = useState<(Friendship & { profile?: Profile })[]>([]);

  const fetchAll = useCallback(async () => {
    if (!user) return;
    const { data } = await supabase
      .from('friendships')
      .select('*')
      .or(`requester_id.eq.${user.id},addressee_id.eq.${user.id}`);
    if (!data) return;
    const allUserIds = [...new Set(data.flatMap(f => [f.requester_id, f.addressee_id]))];
    const { data: profiles } = await supabase.from('profiles').select('*').in('user_id', allUserIds);

    const accepted = data
      .filter(f => f.status === 'accepted')
      .map(f => ({
        ...f as Friendship,
        profile: (profiles || []).find(p =>
          p.user_id === (f.requester_id === user.id ? f.addressee_id : f.requester_id)
        ) as Profile | undefined,
      }));
    setFriends(accepted);

    const pending = data
      .filter(f => f.status === 'pending' && f.addressee_id === user.id)
      .map(f => ({
        ...f as Friendship,
        profile: (profiles || []).find(p => p.user_id === f.requester_id) as Profile | undefined,
      }));
    setRequests(pending);
  }, [user]);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  const sendRequest = async (pseudo: string) => {
    if (!user) return;
    const { data: targetProfile } = await supabase
      .from('profiles')
      .select('user_id')
      .eq('pseudo', pseudo)
      .single();
    if (!targetProfile) throw new Error('Utilisateur introuvable');
    if (targetProfile.user_id === user.id) throw new Error('Tu ne peux pas t\'ajouter toi-même');
    const { error } = await supabase.from('friendships').insert({
      requester_id: user.id,
      addressee_id: targetProfile.user_id,
    });
    if (error) throw error;
    await fetchAll();
  };

  const acceptRequest = async (friendshipId: string) => {
    await supabase.from('friendships').update({ status: 'accepted' }).eq('id', friendshipId);
    await fetchAll();
  };

  const rejectRequest = async (friendshipId: string) => {
    await supabase.from('friendships').update({ status: 'rejected' }).eq('id', friendshipId);
    await fetchAll();
  };

  return { friends, requests, sendRequest, acceptRequest, rejectRequest, refetch: fetchAll };
}

export function useContactSuggestions() {
  const { user } = useAuth();
  const [contactSuggestions, setContactSuggestions] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);

  const checkContactsPermission = async (): Promise<boolean> => {
    // Check if we're on HTTPS (required for Contacts API)
    if (window.location.protocol !== 'https:' && window.location.hostname !== 'localhost') {
      setHasPermission(false);
      return false;
    }

    if (!('contacts' in navigator) && !('mozContacts' in navigator)) {
      setHasPermission(false);
      return false;
    }

    try {
      // Try modern Contacts API permission check
      if ('contacts' in navigator && 'permissions' in navigator) {
        const permission = await navigator.permissions.query({ name: 'contacts' as PermissionName });
        const granted = permission.state === 'granted';
        setHasPermission(granted);
        return granted;
      }

      // Fallback: try to access contacts directly (for Firefox OS)
      if ('mozContacts' in navigator) {
        setHasPermission(true);
        return true;
      }

      setHasPermission(false);
      return false;
    } catch (error) {
      console.warn('Contacts permission check failed:', error);
      setHasPermission(false);
      return false;
    }
  };

  const requestContactsPermission = async (): Promise<boolean> => {
    // Check if we're on HTTPS (required for Contacts API)
    if (window.location.protocol !== 'https:' && window.location.hostname !== 'localhost') {
      console.warn('Contacts API requires HTTPS');
      return false;
    }

    if (!('contacts' in navigator) && !('mozContacts' in navigator)) {
      console.warn('Contacts API not supported');
      return false;
    }

    try {
      // Try modern Contacts API first
      if ('contacts' in navigator) {
        const contacts = await (navigator as any).contacts.select(['tel'], { multiple: true });
        setHasPermission(true);
        return true;
      }

      // Fallback for Firefox OS
      if ('mozContacts' in navigator) {
        const contacts = await (navigator as any).mozContacts.getAll();
        setHasPermission(true);
        return true;
      }

      return false;
    } catch (error) {
      console.warn('Contacts access failed:', error);
      setHasPermission(false);
      return false;
    }
  };

  const findContactsOnApp = async (): Promise<Profile[]> => {
    if (!user) return [];

    setLoading(true);
    try {
      // Request contacts access
      const hasAccess = await requestContactsPermission();
      if (!hasAccess) {
        setLoading(false);
        return [];
      }

      // Get contacts
      const contacts = await (navigator as any).contacts.select(['tel'], { multiple: true });

      // Extract phone numbers and normalize them
      const phoneNumbers = contacts
        .flatMap((contact: any) => contact.tel || [])
        .map((tel: string) => normalizePhoneNumber(tel))
        .filter((tel: string) => tel.length > 0);

      if (phoneNumbers.length === 0) {
        setLoading(false);
        return [];
      }

      // Query database for matching phone numbers
      const { data: matchingProfiles, error } = await supabase
        .from('profiles')
        .select('*')
        .in('phone', phoneNumbers)
        .neq('user_id', user.id); // Exclude current user

      if (error) {
        console.error('Error finding contacts on app:', error);
        setLoading(false);
        return [];
      }

      // Filter out already friends
      const { data: friendships } = await supabase
        .from('friendships')
        .select('*')
        .or(`requester_id.eq.${user.id},addressee_id.eq.${user.id}`)
        .eq('status', 'accepted');

      const friendIds = new Set(
        (friendships || []).map(f =>
          f.requester_id === user.id ? f.addressee_id : f.requester_id
        )
      );

      const suggestions = (matchingProfiles as Profile[]).filter(
        profile => !friendIds.has(profile.user_id)
      );

      setContactSuggestions(suggestions);
      setLoading(false);
      return suggestions;
    } catch (error) {
      console.error('Error accessing contacts:', error);
      setLoading(false);
      return [];
    }
  };

  const normalizePhoneNumber = (phone: string): string => {
    // Remove all non-digit characters except +
    let normalized = phone.replace(/[^\d+]/g, '');

    // Remove leading + if present
    if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    }

    // Add French country code if not present (assuming French users)
    if (normalized.length === 10 && normalized.startsWith('0')) {
      normalized = '33' + normalized.substring(1);
    }

    return normalized;
  };

  const sendFriendRequestToContact = async (targetUserId: string) => {
    if (!user) return;

    const { error } = await supabase.from('friendships').insert({
      requester_id: user.id,
      addressee_id: targetUserId,
    });

    if (error) throw error;

    // Remove from suggestions
    setContactSuggestions(prev => prev.filter(p => p.user_id !== targetUserId));
  };

  return {
    contactSuggestions,
    loading,
    hasPermission,
    checkContactsPermission,
    findContactsOnApp,
    sendFriendRequestToContact,
  };
}

export function usePartyPhotos(partyId?: string | null) {
  const { user } = useAuth();
  const [photos, setPhotos] = useState<(PartyPhoto & { profile?: Profile })[]>([]);

  const fetchPhotos = useCallback(async () => {
    if (!user || !partyId) { setPhotos([]); return; }
    const { data } = await supabase
      .from('party_photos')
      .select('*')
      .eq('party_id', partyId)
      .order('created_at', { ascending: false });
    if (!data) return;
    const userIds = [...new Set(data.map(p => p.user_id))];
    const { data: profiles } = await supabase.from('profiles').select('*').in('user_id', userIds);
    setPhotos(data.map(p => ({
      ...p as PartyPhoto,
      profile: (profiles || []).find(pr => pr.user_id === p.user_id) as Profile | undefined,
    })));
  }, [user, partyId]);

  useEffect(() => { fetchPhotos(); }, [fetchPhotos]);

  const addPhoto = async (file: File, caption: string, partyId: string) => {
    if (!user) return;
    const fileName = `${partyId}/${user.id}_${Date.now()}.jpg`;
    const { error: uploadErr } = await supabase.storage.from('party-photos').upload(fileName, file);
    if (uploadErr) throw uploadErr;
    const { data: urlData } = supabase.storage.from('party-photos').getPublicUrl(fileName);
    const { error } = await supabase.from('party_photos').insert({
      party_id: partyId,
      user_id: user.id,
      image_url: urlData.publicUrl,
      caption: caption || null,
    });
    if (error) throw error;
    await fetchPhotos();
  };

  return { photos, addPhoto, refetch: fetchPhotos };
}

export function useMemberLocations(partyId?: string | null) {
  const { user } = useAuth();
  const [locations, setLocations] = useState<(MemberLocation & { profile?: Profile })[]>([]);

  const fetchLocations = useCallback(async () => {
    if (!user || !partyId) { setLocations([]); return; }
    const { data } = await supabase
      .from('member_locations')
      .select('*')
      .eq('party_id', partyId);
    if (!data) return;
    const userIds = [...new Set(data.map(l => l.user_id))];
    const { data: profiles } = await supabase.from('profiles').select('*').in('user_id', userIds);
    setLocations(data.map(l => ({
      ...l as MemberLocation,
      profile: (profiles || []).find(p => p.user_id === l.user_id) as Profile | undefined,
    })));
  }, [user, partyId]);

  useEffect(() => { fetchLocations(); }, [fetchLocations]);

  // Subscribe to realtime changes
  useEffect(() => {
    if (!partyId) return;
    const channel = supabase
      .channel(`locations-${partyId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'member_locations', filter: `party_id=eq.${partyId}` }, () => {
        fetchLocations();
      })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [partyId, fetchLocations]);

  const updateMyLocation = useCallback(async (partyId: string) => {
    if (!user) return;
    try {
      const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
        navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true })
      );
      const { error } = await supabase.from('member_locations').upsert({
        user_id: user.id,
        party_id: partyId,
        latitude: pos.coords.latitude,
        longitude: pos.coords.longitude,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'user_id,party_id' });
      if (error) throw error;
    } catch {
      // silently fail if location not available
    }
  }, [user]);

  return { locations, updateMyLocation, refetch: fetchLocations };
}

export function useMyPartyInvitations() {
  const { user } = useAuth();
  const [invitations, setInvitations] = useState<(PartyRequest & { profile?: Profile; party?: Party })[]>([]);

  const fetchInvitations = useCallback(async () => {
    if (!user) { setInvitations([]); return; }

    const { data: inviteData, error: inviteError } = await supabase
      .from('party_requests')
      .select('*')
      .eq('user_id', user.id)
      .eq('status', 'pending');

    if (inviteError) {
      console.error('Error fetching party invitations:', inviteError.message);
      setInvitations([]);
      return;
    }

    if (!inviteData || inviteData.length === 0) {
      setInvitations([]);
      return;
    }

    const partyIds = [...new Set(inviteData.map(r => r.party_id))].filter(Boolean);
    if (partyIds.length === 0) {
      setInvitations(inviteData as (PartyRequest & { party?: Party })[]);
      return;
    }

    const { data: parties, error: partyError } = await supabase
      .from('parties')
      .select('*')
      .in('id', partyIds);

    if (partyError) {
      console.error('Error fetching parties for invitations:', partyError.message);
      setInvitations(inviteData as (PartyRequest & { party?: Party })[]);
      return;
    }

    setInvitations((inviteData as PartyRequest[]).map((r) => ({
      ...r,
      party: (parties || []).find(p => p.id === r.party_id) as Party | undefined,
    })));
  }, [user]);

  useEffect(() => { 
    fetchInvitations(); 
  }, [fetchInvitations]);

  // Subscribe to realtime changes
  useEffect(() => {
    if (!user) return;
    const channel = supabase
      .channel(`party-requests-${user.id}`)
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: 'party_requests', 
          filter: `user_id=eq.${user.id}` 
        }, 
        () => {
          fetchInvitations();
        }
      )
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [user, fetchInvitations]);

  const acceptInvitation = async (invitationId: string, partyId: string) => {
    const { error: updateErr } = await supabase
      .from('party_requests')
      .update({ status: 'accepted' })
      .eq('id', invitationId);
    if (updateErr) throw updateErr;
    
    // Add user to party members
    const { error: joinErr } = await supabase.from('party_members').insert({
      party_id: partyId,
      user_id: user!.id,
    });
    if (joinErr && !joinErr.message.includes('duplicate')) throw joinErr;

    setInvitations(prev => prev.filter(inv => inv.id !== invitationId));
    await fetchInvitations();
  };

  const rejectInvitation = async (invitationId: string) => {
    const { error } = await supabase
      .from('party_requests')
      .update({ status: 'rejected' })
      .eq('id', invitationId);
    if (error) throw error;

    setInvitations(prev => prev.filter(inv => inv.id !== invitationId));
    await fetchInvitations();
  };

  return { invitations, acceptInvitation, rejectInvitation, refetch: fetchInvitations };
}

export function useInviteMember() {
  const { user } = useAuth();

  const inviteMember = async (partyId: string, userId: string) => {
    if (!user) return;
    const { error } = await supabase.from('party_requests').insert({
      party_id: partyId,
      user_id: userId,
    });
    if (error) {
      if (error.message.includes('duplicate')) {
        throw new Error('Un invitation est déjà en attente pour cet utilisateur');
      }
      throw error;
    }
  };

  return { inviteMember };
}

export function usePukeEvents(partyId?: string | null) {
  const { user } = useAuth();
  const [pukeEvents, setPukeEvents] = useState<PukeEvent[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchPukeEvents = useCallback(async () => {
    if (!partyId) {
      setLoading(false);
      return;
    }
    const { data, error } = await supabase
      .from('puke_events')
      .select('*')
      .eq('party_id', partyId)
      .order('created_at', { ascending: false });
    if (error) {
      console.error('Error fetching puke events:', error.message);
    }
    setPukeEvents(data as PukeEvent[] || []);
    setLoading(false);
  }, [partyId]);

  useEffect(() => { fetchPukeEvents(); }, [fetchPukeEvents]);

  const addPukeEvent = async () => {
    if (!user || !partyId) return;
    const { error } = await supabase
      .from('puke_events')
      .insert({ party_id: partyId, user_id: user.id });
    if (error) throw error;
    await fetchPukeEvents();
  };

  const deletePukeEvent = async (id: string) => {
    await supabase.from('puke_events').delete().eq('id', id);
    setPukeEvents(prev => prev.filter(e => e.id !== id));
  };

  const deleteAllPukeEvents = async () => {
    if (!user) return;
    await supabase.from('puke_events').delete().eq('user_id', user.id);
    setPukeEvents([]);
  };

  return { pukeEvents, loading, addPukeEvent, deletePukeEvent, deleteAllPukeEvents, refetch: fetchPukeEvents };
}

export function useShopEvents(partyId?: string | null) {
  const { user } = useAuth();
  const [shopEvents, setShopEvents] = useState<ShopEvent[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchShopEvents = useCallback(async () => {
    if (!partyId) {
      setLoading(false);
      return;
    }
    const { data, error } = await supabase
      .from('shop_events')
      .select('*')
      .eq('party_id', partyId)
      .order('created_at', { ascending: false });
    if (error) {
      console.error('Error fetching shop events:', error.message);
    }
    setShopEvents(data as ShopEvent[] || []);
    setLoading(false);
  }, [partyId]);

  useEffect(() => { fetchShopEvents(); }, [fetchShopEvents]);

  const addShopEvent = async () => {
    if (!user || !partyId) return;
    const { error } = await supabase
      .from('shop_events')
      .insert({ party_id: partyId, user_id: user.id });
    if (error) throw error;
    await fetchShopEvents();
  };

  const deleteShopEvent = async (id: string) => {
    await supabase.from('shop_events').delete().eq('id', id);
    setShopEvents(prev => prev.filter(e => e.id !== id));
  };

  const deleteAllShopEvents = async () => {
    if (!user) return;
    await supabase.from('shop_events').delete().eq('user_id', user.id);
    setShopEvents([]);
  };

  return { shopEvents, loading, addShopEvent, deleteShopEvent, deleteAllShopEvents, refetch: fetchShopEvents };
}

// --- Streak helpers ---
function isoWeek(date: Date): string {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

function computeStreakFromDates(dates: string[]): { weeks: number; alive: boolean } {
  if (!dates.length) return { weeks: 0, alive: false };
  const weeks = [...new Set(dates.map(d => isoWeek(new Date(d))))].sort().reverse();
  const currentWeek = isoWeek(new Date());
  const lastWeek = (() => { const d = new Date(); d.setDate(d.getDate() - 7); return isoWeek(d); })();
  const alive = weeks[0] === currentWeek || weeks[0] === lastWeek;
  if (!alive) return { weeks: 0, alive: false };
  let streak = 1;
  for (let i = 1; i < weeks.length; i++) {
    const prev = new Date(weeks[i - 1].replace('W', '') + '-1');
    const curr = new Date(weeks[i].replace('W', '') + '-1');
    if ((prev.getTime() - curr.getTime()) / (7 * 86400000) <= 1.5) streak++;
    else break;
  }
  return { weeks: streak, alive };
}

export function useStreakForUser(userId?: string) {
  const [streak, setStreak] = useState({ weeks: 0, alive: false });
  useEffect(() => {
    if (!userId) return;
    supabase.from('drinks').select('created_at').eq('user_id', userId).gt('abv', 0)
      .then(({ data }) => {
        if (data) setStreak(computeStreakFromDates(data.map(d => d.created_at)));
      });
  }, [userId]);
  return streak;
}

export function useUserStats(userId?: string) {
  const [stats, setStats] = useState({ drinks: 0, parties: 0, quiches: 0, bisous: 0, friends: 0 });
  useEffect(() => {
    if (!userId) return;
    Promise.all([
      supabase.from('drinks').select('id', { count: 'exact' }).eq('user_id', userId).gt('abv', 0),
      supabase.from('party_members').select('party_id', { count: 'exact' }).eq('user_id', userId),
      supabase.from('puke_events').select('id', { count: 'exact' }).eq('user_id', userId),
      supabase.from('shop_events').select('id', { count: 'exact' }).eq('user_id', userId),
      supabase.from('friendships').select('id', { count: 'exact' }).or(`requester_id.eq.${userId},addressee_id.eq.${userId}`).eq('status', 'accepted'),
    ]).then(([d, p, q, b, f]) => {
      setStats({ drinks: d.count || 0, parties: p.count || 0, quiches: q.count || 0, bisous: b.count || 0, friends: f.count || 0 });
    });
  }, [userId]);
  return stats;
}

export function useMyPurchases() {
  const { user } = useAuth();
  const [purchases, setPurchases] = useState<string[]>([]);
  useEffect(() => {
    if (!user) return;
    supabase.from('user_purchases').select('item_id').eq('user_id', user.id)
      .then(({ data }) => { if (data) setPurchases(data.map(p => p.item_id)); });
  }, [user]);
  const recordPurchase = async (itemId: string) => {
    if (!user) return;
    await supabase.from('user_purchases').upsert({ user_id: user.id, item_id: itemId });
    setPurchases(prev => [...new Set([...prev, itemId])]);
  };
  return { purchases, recordPurchase };
}

export async function isPseudoAvailable(pseudo: string, userId: string): Promise<boolean> {
  const { data } = await supabase
    .from('profiles')
    .select('user_id')
    .ilike('pseudo', pseudo.trim())
    .neq('user_id', userId)
    .maybeSingle();
  return !data;
}
