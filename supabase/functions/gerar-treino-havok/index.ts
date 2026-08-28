// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const ANTHROPIC_MODEL = "claude-haiku-4-5-20251001";

const LOCALE_LABELS: Record<string, string> = {
  pt: "português do Brasil",
  en: "English",
  it: "italiano",
};

function buildSystemPrompt(locale: string): string {
  const lang = LOCALE_LABELS[locale] ?? LOCALE_LABELS["pt"];
  return `Você é HAVOK, IA de personal training do BLDR. Tom técnico, direto, motivador.
Segurança é prioridade. Adapte sempre ao nível do usuário.
Responda SEMPRE em ${lang}. Nunca misture idiomas.
Responda APENAS com o JSON solicitado, sem markdown, sem texto antes ou depois.`.trim();
}

function buildPrompt(onboardingData: Record<string, unknown>): string {
  const mainGoal   = (onboardingData.main_goal as string)           || 'Equilíbrio';
  const goalPace   = (onboardingData.goal_pace as string)           || 'Moderado';
  const gender     = (onboardingData.gender as string)              || 'Não informado';
  const experience = (onboardingData.experience_level as string)    || 'Iniciante';
  const freqDays   = (onboardingData.workout_frequency_days as number) || 3;
  const duration   = (onboardingData.workout_duration_range as string) || '45-60 min';
  const environment = (onboardingData.workout_environment as string) || 'Academia Completa';
  const equipmentList = (onboardingData.home_equipment as string[]) || [];
  const focusList  = (onboardingData.muscle_focus as string[])      || [];
  const split      = (onboardingData.split_preference as string)    || 'Deixa a HAVOK decidir';

  let equipmentText = environment;
  if (environment === 'Casa com Equipamentos') {
    equipmentText = equipmentList.length > 0
      ? `Treino em casa usando: ${equipmentList.join(', ')}`
      : 'Treino em casa (assuma peso corporal ou halteres básicos)';
  }

  const focusText = focusList.length > 0
    ? `Priorizar: ${focusList.join(', ')}`
    : 'Foco equilibrado no corpo inteiro';

  return `Crie um treino personalizado (DIA 1) baseado nos dados abaixo.

Dados do usuário:
- Gênero: ${gender}
- Objetivo: ${mainGoal} (Ritmo: ${goalPace})
- Nível de experiência: ${experience}
- Frequência: ${freqDays} dias/semana
- Duração: ${duration}
- Ambiente: ${equipmentText}
- Foco muscular: ${focusText}
- Divisão preferida: ${split}

Instruções:
1. Se split for 'Deixa a HAVOK decidir': escolha a melhor estrutura para ${freqDays} dias e o foco indicado.
2. Se split específico: gere apenas o DIA 1 desse split.
3. Adapte ao ambiente — use apenas os equipamentos disponíveis.
4. Adapte ao objetivo: perda de gordura → 10-15 reps; ganho de massa → 8-12 reps.
5. Crie um nome poderoso em português.
6. Selecione 5 a 8 exercícios.

Retorne apenas JSON no schema:
{
  "nome": "Nome do Treino",
  "exercicios": [
    { "nome": "Exercício", "series": 4, "repeticoes": "8-12" }
  ]
}`;
}

async function callClaude(userMessage: string, systemPrompt: string, maxTokens = 2048): Promise<string> {
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
      system: systemPrompt,
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

    const { data: profile, error: profileError } = await supabaseClient
      .from("user_profiles")
      .select("onboarding_data")
      .eq("id", user.id)
      .single();

    if (profileError || !profile?.onboarding_data) {
      throw new Error(`Dados de onboarding não encontrados: ${profileError?.message}`);
    }

    const body = await req.json().catch(() => ({}));
    const locale = (body.locale as string) ?? "pt";
    const systemPrompt = buildSystemPrompt(locale);
    const prompt = buildPrompt(profile.onboarding_data);
    const rawText = await callClaude(prompt, systemPrompt);
    const workoutJson = JSON.parse(rawText.replace(/```json/g, "").replace(/```/g, "").trim());

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
    console.error("Erro fatal na Edge Function gerar-treino-havok:", error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
