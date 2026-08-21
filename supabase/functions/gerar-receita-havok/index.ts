// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const ANTHROPIC_MODEL = "claude-haiku-4-5-20251001";

const SYSTEM_PROMPT = `
Você é HAVOK, IA especialista em nutrição esportiva do BLDR.
Crie receitas saudáveis, práticas e com macros adequados para atletas.
Responda APENAS com o JSON solicitado, sem markdown, sem texto antes ou depois.
`.trim();

async function callClaude(userMessage: string, maxTokens = 2048): Promise<string> {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) throw new Error("ANTHROPIC_API_KEY não configurada.");

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "anthropic-version": "2023-06-01",
      "x-api-key": apiKey,
    },
    body: JSON.stringify({
      model: ANTHROPIC_MODEL,
      max_tokens: maxTokens,
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: userMessage }],
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`Erro na API da Anthropic: ${response.status} ${errorBody}`);
  }

  const data = await response.json();
  const text = data.content?.[0]?.text;
  if (!text) throw new Error("Claude não retornou resposta.");
  return text;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error("Usuário não autenticado.");

    const { userQuery } = await req.json();
    if (!userQuery || typeof userQuery !== "string" || userQuery.trim() === "") {
      throw new Error("O pedido da receita está vazio ou inválido.");
    }

    const { data: profile } = await supabaseClient
      .from("user_profiles")
      .select("onboarding_data")
      .eq("id", user.id)
      .single();

    const dietaryPreferences =
      (profile?.onboarding_data?.dietary_preferences as string[] | undefined)?.join(", ") ||
      "Sem restrições";

    const prompt = `Gere uma receita saudável baseada no pedido abaixo.

Pedido: "${userQuery}"
Preferências alimentares: ${dietaryPreferences}

Instruções:
1. Crie um nome criativo e apetitoso.
2. Liste ingredientes simples.
3. Descreva o preparo em passos curtos.
4. Forneça estimativa de macros.

Retorne apenas JSON no schema:
{
  "nome": "Nome da Receita",
  "descricao": "Descrição curta e atrativa.",
  "ingredientes": ["150g de peito de frango", "200g de batata doce"],
  "preparo": ["Cozinhe a batata doce.", "Grelhe o frango."],
  "macros": {
    "calorias_aprox": 450,
    "proteinas_g": 40,
    "carboidratos_g": 50,
    "gorduras_g": 10
  }
}`;

    const rawText = await callClaude(prompt);
    const recipeJson = JSON.parse(rawText.replace(/```json/g, "").replace(/```/g, "").trim());

    return new Response(JSON.stringify(recipeJson), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Erro fatal na Edge Function gerar-receita-havok:", error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
