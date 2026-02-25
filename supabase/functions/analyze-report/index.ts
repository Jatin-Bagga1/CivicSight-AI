// supabase/functions/analyze-report/index.ts
// ═══════════════════════════════════════════════════════════════════
// Supabase Edge Function: Analyze Report Image with Gemini AI
// ═══════════════════════════════════════════════════════════════════
// Model: gemini-3-flash-preview (Gemini 3 Flash — Preview)
// Status: ✅ TESTED & WORKING
// Flow:
//   1. Receive image_url + citizen description from Flutter app
//   2. Fetch all active categories from Supabase `categories` table
//   3. Build detailed prompt with categories JSON
//   4. Send image (as base64) + prompt to Gemini 3 Flash API
//   5. Parse & validate structured JSON response
//   6. Detect mismatches, non-municipal images, and fraudulent reports
//   7. Return classification result OR rejection to Flutter app
// ═══════════════════════════════════════════════════════════════════

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── CORS Headers ───
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ─── Types ───
interface Category {
  id: number;
  name: string;
  example_issues: string;
  category_group: string;
  min_response_days: number;
  max_response_days: number;
}

interface ClassificationResult {
  category_id: number;
  category_name: string;
  category_group: string;
  severity: number;
  confidence: number;
  ai_description: string;
  due_date_days: number;
  suggested_priority: string;
  is_valid_report: boolean;
  rejection_reason: string | null;
  image_matches_description: boolean;
}

// ─── Build the Detailed Municipal Classifier Prompt ───
function buildClassificationPrompt(
  categories: Category[],
  citizenDescription: string | null
): string {
  const categoryBlock = categories
    .map(
      (cat) =>
        `  ────────────────────────────────────────
  ID: ${cat.id}
  Name: "${cat.name}"
  Group: "${cat.category_group}"
  Example Issues: ${cat.example_issues}
  Response Window: ${cat.min_response_days} – ${cat.max_response_days} days`
    )
    .join("\n\n");

  const validIds = categories.map((c) => c.id).join(", ");
  const validNames = categories.map((c) => `"${c.name}"`).join(", ");

  return `
════════════════════════════════════════════════════════════════════
                  CIVIC SIGHT AI — MUNICIPAL ISSUE CLASSIFIER
════════════════════════════════════════════════════════════════════

You are CIVIC SIGHT AI, a professional municipal infrastructure issue 
classification system deployed by a city government. You are the first 
automated triage layer in a civic issue reporting pipeline. Your output 
directly determines how quickly field workers are dispatched and which 
department handles the issue.

YOUR ROLE:
  • You receive a photograph taken by a citizen in a city/town.
  • You must carefully examine EVERY part of the image — foreground, 
    midground, background, ground surface, structures, sky, vegetation, 
    signage, and any visible infrastructure element.
  • You classify the image into EXACTLY ONE category from the database.
  • You rate the severity and your own confidence level.
  • You MUST verify that the image matches the citizen's description.
  • You MUST reject reports that are not legitimate municipal issues.
  • Your output is stored directly in the municipal reports database.

════════════════════════════════════════════════════════════════════
                         IMAGE ANALYSIS PROTOCOL
════════════════════════════════════════════════════════════════════

Follow this step-by-step analysis process internally before responding:

STEP 1 — SCENE ASSESSMENT:
  • What type of location is shown? (residential street, arterial road, 
    intersection, sidewalk, park, parking lot, construction zone, etc.)
  • What time of day and weather conditions are visible?
  • Is this urban, suburban, or rural?

STEP 2 — PRIMARY ISSUE IDENTIFICATION:
  • What is the MOST PROMINENT infrastructure issue visible?
  • Is there physical damage, deterioration, obstruction, or hazard?
  • What material is affected? (asphalt, concrete, metal, wood, soil, etc.)
  • What is the approximate size/scale of the issue?

STEP 3 — SAFETY & SEVERITY EVALUATION:
  • Does this pose an IMMEDIATE danger to pedestrians, cyclists, or drivers?
  • Could this cause injury, vehicle damage, or property damage?
  • Is this near a school, hospital, transit stop, or high-traffic area?
  • How urgently does this need attention?

STEP 4 — CATEGORY MATCHING:
  • Review ALL categories below and their example issues.
  • Match the primary visible issue to the BEST fitting category.
  • If multiple issues are visible, classify based on the MOST SEVERE one.
  • Consider the example issues as guidance — the actual issue does NOT need 
    to match examples exactly.

STEP 5 — CONFIDENCE CALIBRATION:
  • How clearly is the issue visible in the image?
  • Is the image quality sufficient for confident identification?
  • Could this reasonably be classified as a different category?
  • Are there any ambiguities in what the image shows?

STEP 6 — IMAGE vs DESCRIPTION VERIFICATION:
  • If a citizen description is provided, does the image ACTUALLY show 
    what the citizen described?
  • If the citizen says "pothole" but the image shows a clean road with 
    no issues — this is a MISMATCH. Reject the report.
  • If the citizen says "broken streetlight" but the image shows a cat — 
    this is INVALID. Reject the report.
  • Minor wording differences are OK (e.g., "hole in road" for a pothole).
  • The IMAGE is the source of truth. The description must be REASONABLY 
    consistent with what is visible.

STEP 7 — LEGITIMACY CHECK:
  • Is this image showing a REAL municipal/civic infrastructure issue?
  • Reject if the image is: a selfie, food, pet, meme, screenshot, 
    indoor personal photo, random object not related to civic issues,
    AI-generated fake, or any image that clearly has nothing to do with 
    public infrastructure.

════════════════════════════════════════════════════════════════════
                    CATEGORY DATABASE (FROM SUPABASE)
════════════════════════════════════════════════════════════════════

${categoryBlock}
  ────────────────────────────────────────

════════════════════════════════════════════════════════════════════
                     CITIZEN DESCRIPTION (OPTIONAL)
════════════════════════════════════════════════════════════════════

${
    citizenDescription && citizenDescription.trim().length > 0
      ? `The citizen provided this description: "${citizenDescription}"
  
  CRITICAL: You MUST verify that the image is RELEVANT to this description.
  
  Ask yourself:
    1. Does the image show anything related to what the citizen described?
    2. Could a reasonable person look at this image and agree it matches 
       the description?
    3. Is the citizen possibly trying to submit a fake or misleading report?
  
  If the image does NOT match the description:
    → Set is_valid_report to false
    → Set image_matches_description to false
    → Provide a clear rejection_reason explaining the mismatch
    → Still fill in the classification fields based on what the image 
      ACTUALLY shows (for audit logging purposes)`
      : `No description provided by the citizen. Classification is based entirely 
  on visual analysis of the image. Skip the description matching check.
  Set image_matches_description to true (no description to mismatch).`
  }

════════════════════════════════════════════════════════════════════
                         SEVERITY SCALE
════════════════════════════════════════════════════════════════════

Rate severity on a 1–5 scale:

  1 — COSMETIC:       Minor visual issue, no safety risk, no functional 
                      impact. E.g., small graffiti tag, slightly faded paint.

  2 — LOW:            Noticeable issue, minimal safety risk. May worsen 
                      over time. E.g., hairline road crack, minor litter.

  3 — MODERATE:       Clear issue requiring attention within standard 
                      timeframe. Some inconvenience or minor risk. 
                      E.g., medium pothole, overflowing bin, leaning sign.

  4 — HIGH:           Significant issue. Risk of injury or major 
                      inconvenience. Needs priority response. 
                      E.g., deep pothole on busy road, large branch 
                      over sidewalk, missing manhole cover on edge.

  5 — CRITICAL:       Immediate safety hazard. Emergency response needed. 
                      E.g., downed power line, open manhole on road, 
                      tree on power line, gushing water main break, 
                      collapsed road surface.

════════════════════════════════════════════════════════════════════
                      DUE DATE CALCULATION
════════════════════════════════════════════════════════════════════

Use this exact formula based on the matched category's response window:

  due_date_days = max_response_days - ((severity - 1) / 4) × (max_response_days - min_response_days)
  
  Round to the nearest whole number.
  
  Examples:
    • Severity 5 (critical) → due_date_days = min_response_days
    • Severity 1 (cosmetic) → due_date_days = max_response_days
    • Severity 3 (moderate) → midpoint between min and max

════════════════════════════════════════════════════════════════════
                      PRIORITY MAPPING
════════════════════════════════════════════════════════════════════

  • Severity 1 or 2  → suggested_priority: "low"
  • Severity 3       → suggested_priority: "medium"
  • Severity 4       → suggested_priority: "high"
  • Severity 5       → suggested_priority: "critical"

════════════════════════════════════════════════════════════════════
                      RESPONSE FORMAT
════════════════════════════════════════════════════════════════════

RESPOND WITH ONLY A SINGLE VALID JSON OBJECT. No markdown, no code 
fences, no explanation, no text before or after the JSON.

VALID CATEGORY IDs: ${validIds}
VALID CATEGORY NAMES: ${validNames}

{
  "category_id": <integer — must be one of: ${validIds}>,
  "category_name": "<string — must exactly match the name for the chosen ID>",
  "category_group": "<string — must exactly match the group for the chosen ID>",
  "severity": <integer 1-5>,
  "confidence": <float 0.0-1.0, two decimal places>,
  "ai_description": "<string — 1-2 sentences MAX, under 200 characters. Describe what is ACTUALLY visible in the image like a field inspector.>",
  "due_date_days": <integer — calculated using the formula above>,
  "suggested_priority": "<low|medium|high|critical>",
  "is_valid_report": <boolean — true if this is a legitimate municipal issue AND image matches description>,
  "rejection_reason": "<string or null — if is_valid_report is false, explain why. Otherwise null>",
  "image_matches_description": <boolean — true if no description provided OR image matches description. false if image contradicts the description>
}

════════════════════════════════════════════════════════════════════
                  REJECTION SCENARIOS (is_valid_report = false)
════════════════════════════════════════════════════════════════════

Set is_valid_report to FALSE and provide rejection_reason for ANY of these:

  1. IMAGE-DESCRIPTION MISMATCH:
     The citizen says "pothole on main street" but the image shows a 
     clean park with no issues.
     → rejection_reason: "Image does not match description. Description 
       mentions [X] but image shows [Y]."

  2. NOT A MUNICIPAL ISSUE:
     Image shows food, selfie, pet, indoor scene, personal items, memes, 
     screenshots, or anything unrelated to public infrastructure.
     → rejection_reason: "Image does not show a municipal infrastructure 
       issue. Image appears to show [what you see]."

  3. FRAUDULENT / MISLEADING:
     Image is clearly staged, edited, or AI-generated to fake an issue.
     → rejection_reason: "Image appears to be [staged/manipulated/AI-generated]. 
       Not a genuine field report."

  4. DUPLICATE IMAGE / STOCK PHOTO:
     Image appears to be a stock photo or downloaded from the internet 
     rather than a real photograph taken at the location.
     → rejection_reason: "Image appears to be a stock photo or downloaded 
       image, not a genuine on-site photograph."

  5. UNRECOGNIZABLE / TOO BLURRY:
     Image is so blurry, dark, or obscured that no issue can be identified.
     → rejection_reason: "Image quality too poor to identify any municipal 
       issue. Please retake the photo with better lighting/focus."

  NOTE: For rejected reports, STILL fill in category_id, severity, etc. 
  based on what the image ACTUALLY shows (for audit purposes). Use the 
  closest matching category, set severity to 1, and confidence to your 
  actual confidence in the visual assessment.

════════════════════════════════════════════════════════════════════
                      VALID REPORT SCENARIOS
════════════════════════════════════════════════════════════════════

Set is_valid_report to TRUE when:

  1. Image clearly shows a municipal infrastructure issue AND
  2. No description was provided (image-only report is fine) OR
  3. The description reasonably matches what is visible in the image
     (minor wording differences are acceptable)

════════════════════════════════════════════════════════════════════
                      CRITICAL RULES
════════════════════════════════════════════════════════════════════

  1. You MUST choose a category_id from the provided database ONLY.
  2. You MUST NOT invent new categories or IDs.
  3. category_name and category_group MUST match the chosen category_id.
  4. You MUST set is_valid_report to false if image doesn't match description.
  5. You MUST set is_valid_report to false if image is not a municipal issue.
  6. If is_valid_report is false, rejection_reason MUST NOT be null.
  7. If is_valid_report is true, rejection_reason MUST be null.
  8. NEVER output anything other than the JSON object.
  9. Your ai_description must describe what is ACTUALLY in the image,
     regardless of whether the report is valid or rejected.
  10. Be STRICT about mismatches — protect the system from fake reports.
`;
}

// ─── Validate AI Response Against Categories ───
function validateAndClamp(
  result: ClassificationResult,
  categories: Category[]
): ClassificationResult {
  const matched = categories.find((c) => c.id === result.category_id);

  if (!matched) {
    const byName = categories.find(
      (c) => c.name.toLowerCase() === result.category_name?.toLowerCase()
    );
    if (byName) {
      result.category_id = byName.id;
      result.category_name = byName.name;
      result.category_group = byName.category_group;
    } else {
      throw new Error(
        `AI returned invalid category_id: ${result.category_id}. Valid IDs: ${categories.map((c) => c.id).join(", ")}`
      );
    }
  } else {
    result.category_name = matched.name;
    result.category_group = matched.category_group;
  }

  result.severity = Math.min(5, Math.max(1, Math.round(result.severity)));
  result.confidence = Math.min(
    1.0,
    Math.max(0.0, parseFloat(result.confidence.toFixed(2)))
  );

  const cat = categories.find((c) => c.id === result.category_id)!;
  const calculatedDays =
    cat.max_response_days -
    ((result.severity - 1) / 4) *
      (cat.max_response_days - cat.min_response_days);
  result.due_date_days = Math.round(calculatedDays);
  result.due_date_days = Math.min(
    cat.max_response_days,
    Math.max(cat.min_response_days, result.due_date_days)
  );

  if (result.severity <= 2) result.suggested_priority = "low";
  else if (result.severity === 3) result.suggested_priority = "medium";
  else if (result.severity === 4) result.suggested_priority = "high";
  else result.suggested_priority = "critical";

  // Validate boolean fields
  if (typeof result.is_valid_report !== "boolean") {
    result.is_valid_report = true;
  }
  if (typeof result.image_matches_description !== "boolean") {
    result.image_matches_description = true;
  }

  // Enforce rejection_reason consistency
  if (!result.is_valid_report && !result.rejection_reason) {
    result.rejection_reason = "Report flagged as invalid by AI analysis.";
  }
  if (result.is_valid_report) {
    result.rejection_reason = null;
  }

  // If image doesn't match description, report must be invalid
  if (!result.image_matches_description) {
    result.is_valid_report = false;
    if (!result.rejection_reason) {
      result.rejection_reason =
        "Image does not match the provided description.";
    }
  }

  return result;
}

// ─── Main Handler ───
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ─── 1. Parse Request ───
    const { image_url, description } = await req.json();

    if (!image_url || typeof image_url !== "string") {
      return new Response(
        JSON.stringify({ success: false, error: "image_url is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ─── 2. Init Supabase Client ───
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // ─── 3. Fetch Active Categories from Database ───
    const { data: categories, error: catError } = await supabase
      .from("categories")
      .select(
        "id, name, example_issues, category_group, min_response_days, max_response_days"
      )
      .eq("is_active", true)
      .order("id");

    if (catError) {
      throw new Error(`Failed to fetch categories: ${catError.message}`);
    }

    if (!categories || categories.length === 0) {
      throw new Error("No active categories found in database");
    }

    console.log(
      `✅ Fetched ${categories.length} active categories from database`
    );

    // ─── 4. Build Prompt ───
    const prompt = buildClassificationPrompt(
      categories as Category[],
      description || null
    );

    // ─── 5. Fetch Image & Convert to Base64 ───
    console.log(`📸 Fetching image from: ${image_url}`);
    const imageResponse = await fetch(image_url);

    if (!imageResponse.ok) {
      throw new Error(
        `Failed to fetch image: ${imageResponse.status} ${imageResponse.statusText}`
      );
    }

    const imageBuffer = await imageResponse.arrayBuffer();
    const imageBytes = new Uint8Array(imageBuffer);

    let base64Image = "";
    const CHUNK_SIZE = 8192;
    for (let i = 0; i < imageBytes.length; i += CHUNK_SIZE) {
      const chunk = imageBytes.subarray(i, i + CHUNK_SIZE);
      base64Image += String.fromCharCode(...chunk);
    }
    base64Image = btoa(base64Image);

    const contentType =
      imageResponse.headers.get("content-type") || "image/jpeg";

    console.log(
      `✅ Image ready. Size: ${imageBytes.length} bytes, Type: ${contentType}`
    );

    // ─── 6. Call Gemini 3 Flash API ───
    // ─── 6. Call Gemini 3 Flash API with Aggressive Retry ───
    const geminiModel = "gemini-3-flash-preview";
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`;

    const geminiPayload = {
      contents: [
        {
          parts: [
            { text: prompt },
            {
              inline_data: {
                mime_type: contentType,
                data: base64Image,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: "application/json",
        responseSchema: {
          type: "object",
          properties: {
            category_id: { type: "integer" },
            category_name: { type: "string" },
            category_group: { type: "string" },
            severity: { type: "integer" },
            confidence: { type: "number" },
            ai_description: { type: "string" },
            due_date_days: { type: "integer" },
            suggested_priority: { type: "string" },
            is_valid_report: { type: "boolean" },
            rejection_reason: { type: "string", nullable: true },
            image_matches_description: { type: "boolean" },
          },
          required: [
            "category_id",
            "category_name",
            "category_group",
            "severity",
            "confidence",
            "ai_description",
            "due_date_days",
            "suggested_priority",
            "is_valid_report",
            "rejection_reason",
            "image_matches_description",
          ],
        },
      },
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" },
      ],
    };

    // Retry config: 4 attempts with exponential backoff
    // Attempt 1: immediate
    // Attempt 2: wait 2 seconds
    // Attempt 3: wait 4 seconds
    // Attempt 4: wait 8 seconds
    const MAX_RETRIES = 4;
    const RETRY_DELAYS = [0, 2000, 4000, 8000]; // milliseconds

    let geminiResult: any = null;
    let lastError = "";

    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
      // Wait before retry (0ms on first attempt)
      if (RETRY_DELAYS[attempt] > 0) {
        console.log(
          `⏳ Waiting ${RETRY_DELAYS[attempt] / 1000}s before retry...`
        );
        await new Promise((r) => setTimeout(r, RETRY_DELAYS[attempt]));
      }

      console.log(
        `🤖 Calling ${geminiModel} (attempt ${attempt + 1}/${MAX_RETRIES})`
      );

      try {
        const geminiResponse = await fetch(geminiUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(geminiPayload),
        });

        if (geminiResponse.ok) {
          geminiResult = await geminiResponse.json();
          console.log(
            `✅ ${geminiModel} responded successfully on attempt ${attempt + 1}`
          );
          break;
        }

        const status = geminiResponse.status;
        const errorBody = await geminiResponse.text();
        lastError = `${status}: ${errorBody.substring(0, 200)}`;

        if (status === 503 || status === 429) {
          // Server overloaded or rate limited — retry
          console.warn(
            `⚠️ Attempt ${attempt + 1} failed (${status}). ${
              attempt < MAX_RETRIES - 1
                ? "Will retry..."
                : "No more retries."
            }`
          );
          continue;
        }

        // Non-retryable error (400, 401, 403, etc.) — stop immediately
        throw new Error(`Gemini API error (${status}): ${errorBody}`);

      } catch (fetchError: any) {
        // Network error — retry
        if (fetchError.message.includes("Gemini API error")) {
          throw fetchError; // Re-throw non-retryable errors
        }
        lastError = fetchError.message;
        console.warn(
          `⚠️ Attempt ${attempt + 1} network error: ${fetchError.message}. ${
            attempt < MAX_RETRIES - 1 ? "Will retry..." : "No more retries."
          }`
        );
      }
    }

    if (!geminiResult) {
      throw new Error(
        `Gemini 3 Flash is currently overloaded after ${MAX_RETRIES} attempts. Last error: ${lastError}. Please try again in a moment.`
      );
    }

    // ─── 7. Parse Gemini 3 Flash Response ───
    console.log(
      `Gemini response candidates: ${geminiResult?.candidates?.length || 0}`
    );

    const parts = geminiResult?.candidates?.[0]?.content?.parts || [];
    let rawText = "";

    for (const part of parts) {
      if (part.text && !part.thought) {
        rawText = part.text;
        break;
      }
    }

    if (!rawText) {
      for (let i = parts.length - 1; i >= 0; i--) {
        if (parts[i].text) {
          rawText = parts[i].text;
          break;
        }
      }
    }

    if (!rawText) {
      console.error(
        "Full Gemini response:",
        JSON.stringify(geminiResult, null, 2)
      );
      throw new Error(
        "Gemini returned empty response. Check logs for full response."
      );
    }

    console.log(`📝 Gemini raw response: ${rawText.substring(0, 400)}`);

    const jsonString = rawText
      .replace(/^```json?\s*/i, "")
      .replace(/\s*```$/i, "")
      .trim();

    let classification: ClassificationResult;
    try {
      classification = JSON.parse(jsonString);
    } catch (parseError: any) {
      console.error(`JSON parse failed. Raw text: ${rawText}`);
      throw new Error(
        `Failed to parse Gemini JSON: ${parseError.message}. Raw: ${rawText.substring(0, 500)}`
      );
    }

    // ─── 8. Validate & Clamp ───
    classification = validateAndClamp(
      classification,
      categories as Category[]
    );

    // ─── 9. Log Result ───
    if (classification.is_valid_report) {
      console.log(
        `✅ VALID REPORT: ${classification.category_name} | Severity: ${classification.severity} | Confidence: ${classification.confidence} | Priority: ${classification.suggested_priority} | Due: ${classification.due_date_days} days`
      );
    } else {
      console.log(
        `❌ REJECTED REPORT: ${classification.rejection_reason} | Image shows: ${classification.ai_description}`
      );
    }

    // ─── 10. Return Result ───
    return new Response(
      JSON.stringify({
        success: true,
        classification,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error: any) {
    console.error("❌ analyze-report error:", error.message);

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