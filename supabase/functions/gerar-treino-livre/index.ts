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
Você é HAVOK, IA de personal training do BLDR. Tom técnico, direto, motivador.
Segurança é prioridade. Interprete o pedido do usuário e crie um treino adequado.
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

async function canonicalizeWorkout(client: any, workout: Record<string, unknown>): Promise<any> {
  const exercises = workout.exercicios;
  if (!Array.isArray(exercises) || exercises.length < 1 || exercises.length > 12) {
    throw new Error('Treino HAVOK inválido.');
  }
  const canonical = [];
  for (const raw of exercises) {
    const exercise = raw as Record<string, unknown>;
    const name = typeof exercise?.nome === 'string' ? exercise.nome.trim() : '';
    if (!name) throw new Error('Exercício HAVOK sem nome.');
    const { data, error } = await client.from('exercises')
      .select('id, name, exercise_db_id').ilike('name', name).limit(2);
    if (error || !data || data.length !== 1) {
      throw new Error(`Exercício não resolvido ou ambíguo: ${name}`);
    }
    canonical.push({ ...exercise, nome: data[0].name, exercise_id: data[0].id,
      exercise_db_id: data[0].exercise_db_id ?? null, resolution: 'RESOLVED' });
  }
  return { ...workout, canonical: true, exercicios: canonical };
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

    const { userPrompt } = await req.json();
    if (!userPrompt || typeof userPrompt !== "string" || userPrompt.trim() === "") {
      throw new Error("O comando para gerar o treino está vazio ou inválido.");
    }

    const prompt = `Crie um treino específico baseado no pedido do usuário.

Pedido: "${userPrompt}"

Instruções:
1. Interprete o pedido e crie um treino que corresponda ao solicitado.
2. Crie um nome poderoso em português que reflita o pedido.
3. Selecione 5 a 8 exercícios com séries e repetições adequadas.

Retorne apenas JSON no schema:
{
  "nome": "Nome do Treino",
  "exercicios": [
    { "nome": "Exercício", "series": 4, "repeticoes": "8-12" }
  ]
}`;

    const rawText = await callClaude(prompt);
    const workoutJson = await canonicalizeWorkout(
      supabaseClient,
      JSON.parse(rawText.replace(/```json/g, "").replace(/```/g, "").trim()),
    );

    const { data: savedWorkout, error: insertError } = await supabaseClient
      .schema("bldr_club")
      .from("havok_workouts")
      .insert({
        user_id: user.id,
        workout_data: workoutJson,
        workout_name: workoutJson.nome,
      })
      .select()
      .single();

    if (insertError) throw new Error(`Erro ao salvar treino: ${insertError.message}`);

    return new Response(JSON.stringify(savedWorkout), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Erro fatal na Edge Function gerar-treino-livre:", error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
