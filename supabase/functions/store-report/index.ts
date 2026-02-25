// supabase/functions/store-report/index.ts
// ═══════════════════════════════════════════════════════════════════
// Supabase Edge Function: Store Report with AI Classification
// ═══════════════════════════════════════════════════════════════════
// Receives: citizen_id, description, image_url, classification, location
// Stores: reports + report_locations + report_images (3 tables)
// ═══════════════════════════════════════════════════════════════════

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const {
      citizen_id,
      description,
      image_url,
      classification,
      location,
    } = await req.json();

    // ─── Validate Required Fields ───
    if (!citizen_id || !description || !image_url || !classification || !location) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing required fields: citizen_id, description, image_url, classification, location",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ─── Init Supabase Client ───
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // ─── Step 1: Insert Report ───
    const reportData: Record<string, any> = {
      citizen_id: citizen_id,
      description: description,
      category_id: classification.category_id,
      ai_category_name: classification.category_name,
      ai_description: classification.ai_description,
      ai_severity: classification.severity,
      ai_confidence: Math.round(classification.confidence * 100 * 100) / 100, // 0.93 → 93.00
      ai_image_relevant: classification.image_matches_description ?? true,
      status: classification.is_valid_report ? "open" : "rejected",
      ai_processed_at: new Date().toISOString(),
    };

    const { data: report, error: reportError } = await supabase
      .from("reports")
      .insert(reportData)
      .select("id, report_number")
      .single();

    if (reportError) {
      throw new Error(`Failed to insert report: ${reportError.message}`);
    }

    console.log(`✅ Report created: #${report.report_number} (${report.id})`);

    // ─── Step 2: Insert Report Location ───
    const locationData: Record<string, any> = {
      report_id: report.id,
      latitude: location.latitude,
      longitude: location.longitude,
      location_source: location.location_source || "gps",
    };

    // Add optional location fields
    if (location.gps_accuracy_meters != null) locationData.gps_accuracy_meters = location.gps_accuracy_meters;
    if (location.formatted_address) locationData.formatted_address = location.formatted_address;
    if (location.street_number) locationData.street_number = location.street_number;
    if (location.street_name) locationData.street_name = location.street_name;
    if (location.neighbourhood) locationData.neighbourhood = location.neighbourhood;
    if (location.city) locationData.city = location.city;
    if (location.province) locationData.province = location.province;
    if (location.postal_code) locationData.postal_code = location.postal_code;
    if (location.country_code) locationData.country_code = location.country_code;
    if (location.location_description) locationData.location_description = location.location_description;

    const { error: locationError } = await supabase
      .from("report_locations")
      .insert(locationData);

    if (locationError) {
      console.error(`⚠️ Location insert failed: ${locationError.message}`);
      // Don't fail the whole request for location error
    } else {
      console.log(`✅ Location stored for report #${report.report_number}`);
    }

    // ─── Step 3: Insert Report Image ───
    const imageData = {
      report_id: report.id,
      image_url: image_url,
      is_primary: true,
      ai_analyzed: true,
    };

    const { error: imageError } = await supabase
      .from("report_images")
      .insert(imageData);

    if (imageError) {
      console.error(`⚠️ Image insert failed: ${imageError.message}`);
    } else {
      console.log(`✅ Image stored for report #${report.report_number}`);
    }

    // ─── Return Success ───
    return new Response(
      JSON.stringify({
        success: true,
        report_id: report.id,
        report_number: report.report_number,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error: any) {
    console.error("❌ store-report error:", error.message);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Internal server error",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
