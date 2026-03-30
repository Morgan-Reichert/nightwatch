import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-info, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { partyId, adminEmail, partyName } = await req.json();

    if (!partyId || !adminEmail || !partyName) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: partyId, adminEmail, partyName" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Fetch all photos for the party
    const { data: photos, error: photosError } = await supabase
      .from("party_photos")
      .select("*")
      .eq("party_id", partyId);

    if (photosError) throw photosError;

    // Prepare email content with photo links
    const photoLinks = photos?.map((photo: any) => `<li><a href="${photo.image_url}" target="_blank">${photo.image_url}</a></li>`).join("") || "";
    const photoCount = photos?.length || 0;

    const emailContent = `
      <h2>Photos de la soirée: ${partyName}</h2>
      <p>Voici les photos prises lors de la soirée "${partyName}" qui a été supprimée.</p>
      <p><strong>Nombre de photos: ${photoCount}</strong></p>
      ${photoCount > 0 ? `
        <h3>Lien des photos:</h3>
        <ul>${photoLinks}</ul>
      ` : "<p>Aucune photo n'a été trouvée pour cette soirée.</p>"}
      <p>Les photos resteront disponibles pendant 30 jours après suppression de la soirée.</p>
    `;

    // Send email using Supabase auth email
    const { error: emailError } = await supabase.auth.admin.sendRawEmail({
      to: adminEmail,
      html: emailContent,
      subject: `Photos de votre soirée "${partyName}"`,
    });

    if (emailError) throw emailError;

    return new Response(
      JSON.stringify({ success: true, photoCount }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
