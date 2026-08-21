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
  return `Você é o HAVOK, treinador de IA do BLDR. Tom técnico e direto, sem cobrança
emocional. Frases curtas. Sem saudação, sem "Olá", sem enrolação.

LIMITES — nunca negociáveis, mesmo se o usuário insistir:
- Nunca diagnostica lesão, nunca recomenda medicamento ou dose.
- Nunca sugere meta calórica abaixo de 1200kcal/dia nem meta de peso fora
  de uma faixa saudável para a altura informada.
- Nunca inclui déficit agressivo, jejum prolongado ou restrição severa.
- Adapta volume e intensidade ao nível de experiência informado.
- Suplementação: whey, creatina e cafeína são consenso, pode incluir.
  Termogênico, hormônio, ou qualquer coisa que exija prescrição — nunca.
- Exercícios com lesão ativa: contorna a região afetada, nunca ignora.

Responda SEMPRE em ${lang}. Nunca misture idiomas.
Responda APENAS com o JSON solicitado, sem markdown, sem texto antes ou depois.`.trim();
}

function buildPrompt(onboardingData: Record<string, unknown>): string {
  const d = onboardingData ?? {};

  const gender          = (d.gender as string)               || '';
  const age             = (d.age as number)                  || 25;
  const height          = (d.height as number)               || 170;
  const weight          = (d.weight as number)               || 70;
  const goal            = (d.main_goal as string)            || '';
  const pace            = (d.goal_pace as string)            || 'Moderado';
  const activityLevel   = (d.activity_level as string)       || '';
  const experience      = (d.experience_level as string)     || '';
  const freqDays        = (d.workout_frequency_days as number) || 3;
  const duration        = (d.workout_duration_range as string) || '45-60 min';
  const environment     = (d.workout_environment as string)  || '';
  const split           = (d.split_preference as string)     || 'Deixa a HAVOK decidir';
  // Metas pré-calculadas pelo Flutter (Harris-Benedict + déficit/superávit por objetivo)
  const targetCalories  = (d.target_calories as number)      || 0;
  const targetProtein   = (d.target_protein as number)       || 0;
  const calculatedTdee  = (d.calculated_tdee as number)      || 0;

  const muscleFocus = Array.isArray(d.muscle_focus) && d.muscle_focus.length > 0
    ? (d.muscle_focus as string[]).join(', ') : null;
  const homeEquipment = Array.isArray(d.home_equipment) && d.home_equipment.length > 0
    ? (d.home_equipment as string[]).join(', ') : null;
  const injuries = Array.isArray(d.injuries)
    ? (d.injuries as string[]).filter(i => i !== 'Nenhuma lesão atual').join(', ') || null
    : null;
  const activities = Array.isArray(d.regular_activities) && d.regular_activities.length > 0
    ? (d.regular_activities as string[]).join(', ') : null;

  const lines = [
    `- Sexo: ${gender || 'não informado'}`,
    `- Idade: ${age} anos`,
    `- Altura: ${height} cm`,
    `- Peso: ${weight} kg`,
    `- Objetivo: ${goal || 'não informado'}`,
    goal !== 'Manter o Peso' ? `- Ritmo: ${pace}` : null,
    `- Nível de atividade diária (NEAT): ${activityLevel || 'não informado'}`,
    activities ? `- Atividades praticadas: ${activities}` : null,
    `- Experiência em treino: ${experience || 'não informado'}`,
    `- Frequência semanal: ${freqDays} dias`,
    `- Duração por sessão: ${duration}`,
    `- Ambiente: ${environment || 'não informado'}`,
    homeEquipment ? `- Equipamentos em casa: ${homeEquipment}` : null,
    muscleFocus ? `- Grupos musculares prioritários: ${muscleFocus}` : null,
    `- Divisão preferida: ${split}`,
    injuries ? `- Lesões/limitações: ${injuries}` : null,
  ].filter(Boolean).join('\n');

  const nutritionBlock = targetCalories > 0
    ? `Metas nutricionais já calculadas pelo app (use EXATAMENTE estes valores — não recalcule):
- TDEE: ${calculatedTdee} kcal/dia
- Meta calórica: ${targetCalories} kcal/dia
- Meta de proteína: ${targetProtein}g/dia
- Carboidratos e gordura: calcule a partir da meta calórica, descontando proteína (${targetProtein}g × 4 kcal) e distribuindo o restante em ~55% carb e ~25% gordura.

IMPORTANTE: metaCalorica e metaProteina no JSON de retorno devem ser exatamente ${targetCalories} e ${targetProtein}. Não arredonde nem ajuste esses valores.`
    : `Calcule metas nutricionais diárias adequadas ao objetivo e perfil informados.`;

  return `Crie um plano semanal de treino personalizado com base nos dados abaixo.
Distribua treino e descanso ao longo dos 7 dias da semana, respeitando
exatamente a frequência semanal pedida (${freqDays} dias de treino).

Dados do usuário:
${lines}

${nutritionBlock}

REGRAS PARA OS EXERCÍCIOS:
- Cada dia de treino deve ter entre 4 e 6 exercícios específicos e reais.
- Use nomes de exercícios em português do Brasil (ex: "Supino reto com barra",
  "Agachamento livre", "Rosca direta com halteres").
- Adapte ao ambiente (${environment || 'academia'}), experiência
  (${experience || 'intermediário'}) e lesões (${injuries || 'nenhuma'}).
- Priorize os grupos musculares: ${muscleFocus || 'todos os grupos'}.
- Dias de descanso: campo "exercicios" deve ser lista vazia [].
- NÃO invente exercícios — use apenas exercícios reais e conhecidos.
- Para cada exercício inclua APENAS: nome, series, repeticoes, descanso_segundos.
  NÃO incluir instrucao, notas, musculo_principal, observacoes — o app calcula isso.
- "repeticoes" sempre como string com faixa ou número: "8-12", "10-15", "12", etc.
- "nome" máximo 40 caracteres.

Retorne apenas JSON válido no schema abaixo, sem markdown, sem texto extra:
{
  "semana": [
    {
      "dia": "Segunda",
      "tipo": "treino",
      "nome": "Treino A — Peito e Tríceps",
      "exercicios": [
        {
          "nome": "Supino reto com barra",
          "series": 4,
          "repeticoes": "8-12",
          "descanso_segundos": 90
        }
      ]
    }
  ],
  "resumo": "string",
  "metaCalorica": 2200,
  "metaProteina": 150,
  "metaCarboidrato": 220,
  "metaGordura": 70
}

Os 7 dias da semana em ordem: Segunda, Terça, Quarta, Quinta, Sexta, Sábado, Domingo.
Inclua todos os 7 dias no array "semana".`;
}

async function callClaude(userMessage: string, systemPrompt: string, maxTokens = 8192): Promise<string> {
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

    const body = await req.json();
    const onboardingData = body.onboardingData ?? {};
    const locale = (body.locale as string) ?? "pt";
    const systemPrompt = buildSystemPrompt(locale);

    const targetCalories = (onboardingData.target_calories as number) || 0;
    const targetProtein  = (onboardingData.target_protein as number)  || 0;

    const prompt = buildPrompt(onboardingData);
    const rawText = await callClaude(prompt, systemPrompt);

    // Sanitizar: remover markdown fences e caracteres de controle inválidos em JSON
    const sanitized = rawText
      .replace(/```json\s*/gi, "")
      .replace(/```\s*/g, "")
      .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "")
      .trim();

    let plano: Record<string, unknown>;
    try {
      plano = JSON.parse(sanitized);
    } catch (parseError) {
      console.error("[gerar-plano-havok] JSON parse error:", parseError);
      console.error("[gerar-plano-havok] raw length:", rawText.length);
      console.error("[gerar-plano-havok] sanitized length:", sanitized.length);
      console.error("[gerar-plano-havok] last 300 chars:", sanitized.slice(-300));
      return new Response(
        JSON.stringify({
          error: "json_parse_error",
          message: "Claude retornou JSON inválido ou truncado",
          rawLength: rawText.length,
          sanitizedLength: sanitized.length,
          tail: sanitized.slice(-200),
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Safety net: garantir que os valores críticos batem com o Flutter
    if (targetCalories > 0 && plano.metaCalorica !== targetCalories) {
      console.warn(
        `TDEE divergência: LLM retornou ${plano.metaCalorica}, esperado ${targetCalories}. Corrigindo.`
      );
      plano.metaCalorica = targetCalories;
    }
    if (targetProtein > 0 && plano.metaProteina !== targetProtein) {
      console.warn(
        `Proteína divergência: LLM retornou ${plano.metaProteina}, esperado ${targetProtein}. Corrigindo.`
      );
      plano.metaProteina = targetProtein;
    }
    // Recalcular carb/gordura se o LLM os baseou no valor errado
    if (targetCalories > 0 && targetProtein > 0) {
      const proteinCal = plano.metaProteina * 4;
      const remaining  = plano.metaCalorica - proteinCal;
      if (!plano.metaCarboidrato) plano.metaCarboidrato = Math.round(remaining * 0.55 / 4);
      if (!plano.metaGordura)     plano.metaGordura     = Math.round(remaining * 0.25 / 9);
    }

    return new Response(JSON.stringify(plano), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("[gerar-plano-havok] Erro fatal:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 },
    );
  }
});
