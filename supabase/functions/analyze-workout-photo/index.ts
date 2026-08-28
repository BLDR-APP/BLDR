// supabase/functions/analyze-workout-photo/index.ts
//
// Receives a base64-encoded image, sends it to Claude claude-haiku-4-5 with the
// workout-sheet extraction prompt, and returns the parsed exercise list.
//
// Expected request body:
//   { "imageBase64": "<base64 string>", "mediaType": "image/jpeg" | "image/png" | ... }
//
// Response:
//   { "exercises": [ { "nameEN": "...", "sets": N, "reps": N, "rest": N }, ... ] }

// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";
const CLAUDE_MODEL   = "claude-haiku-4-5";

const SYSTEM_PROMPT = `You are a fitness assistant. Analyze the workout sheet in the image and extract all exercises, sets, reps, and rest periods. Return the result as a JSON array with the following structure:
[
  {
    "nameEN": "exercise name in English, compatible with ExerciseDB",
    "sets": number,
    "reps": number,
    "rest": number in seconds
  }
]
Return only the JSON array, no explanation or markdown.`;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Authenticate user
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const {
      data: { user },
    } = await supabaseClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Não autenticado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const imageBase64: string = body.imageBase64;
    const mediaType: string   = body.mediaType ?? "image/jpeg";

    if (!imageBase64) {
      return new Response(
        JSON.stringify({ error: "imageBase64 é obrigatório" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const apiKey = Deno.env.get("BLDR-API-KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "Chave da API não configurada" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Call Claude API
    const claudeResponse = await fetch(CLAUDE_API_URL, {
      method: "POST",
      headers: {
        "Content-Type":            "application/json",
        "x-api-key":               apiKey,
        "anthropic-version":       "2023-06-01",
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type:       "base64",
                  media_type: mediaType,
                  data:       imageBase64,
                },
              },
              {
                type: "text",
                text: "Extract the workout exercises from this image.",
              },
            ],
          },
        ],
      }),
    });

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      return new Response(
        JSON.stringify({ error: `Claude API error: ${errText}` }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const claudeData = await claudeResponse.json();
    const rawText: string =
      claudeData?.content?.[0]?.text ?? "[]";

    // Parse JSON from Claude's response
    let exercises: unknown[] = [];
    try {
      // Strip possible markdown code fences
      const cleaned = rawText
        .replace(/^```json\s*/i, "")
        .replace(/^```\s*/i, "")
        .replace(/```\s*$/i, "")
        .trim();
      exercises = JSON.parse(cleaned);
    } catch (_) {
      exercises = [];
    }

    return new Response(JSON.stringify({ exercises }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
