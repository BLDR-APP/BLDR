// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MODEL = "claude-haiku-4-5-20251001";

const LOCALE_LABELS: Record<string, string> = {
  pt: "português do Brasil",
  en: "English",
  it: "italiano",
};

function buildSystemPrompt(locale: string): string {
  const lang = LOCALE_LABELS[locale] ?? LOCALE_LABELS["pt"];
  return `Você é o HAVOK, treinador de IA do BLDR. Gere UM insight curto e acionável baseado nos dados do usuário.
Regras:
- Máximo 2 frases
- Tom direto, sem saudação, sem "Olá"
- Sempre termine com uma ação concreta ("Beba mais água", "Faça uma caminhada leve", "Sua proteína está baixa — adicione X")
- Se recovery Whoop < 33%: foque em descanso
- Se streak at_risk=true: mencione o streak
- Se proteína < 50% da meta: mencione proteína
- Nunca invente dados que não estão no contexto
- Responda SEMPRE em ${lang}
Responda APENAS com o texto do insight, sem JSON, sem markdown, sem aspas.`.trim();
}

function buildUserPrompt(ctx: Record<string, unknown>): string {
  const parts: string[] = ["Dados do usuário hoje:"];

  const streak = ctx.streak as { days?: number; at_risk?: boolean } | undefined;
  if (streak) {
    parts.push(`Streak: ${streak.days} dias. ${streak.at_risk ? "Ainda não treinou hoje (streak em risco)." : "Já treinou hoje."}`);
  }

  const whoop = ctx.whoop as { recovery?: number; strain?: number; sleep?: number; hrv?: number } | undefined;
  if (whoop) {
    parts.push(`Whoop: Recovery ${whoop.recovery ?? "--"}%, Strain ${whoop.strain ?? "--"}/21, Sleep ${whoop.sleep ?? "--"}%, HRV ${whoop.hrv ?? "--"}ms.`);
  }

  const nutrition = ctx.nutrition as { proteinG?: number; proteinGoalG?: number; proteinPercentOfGoal?: number; caloriesConsumed?: number } | undefined;
  if (nutrition) {
    parts.push(`Nutrição: ${nutrition.proteinG}g proteína de ${nutrition.proteinGoalG}g meta (${nutrition.proteinPercentOfGoal}%), ${nutrition.caloriesConsumed} kcal consumidas.`);
  }

  const workouts = ctx.workouts as { completedThisWeek?: number } | undefined;
  if (workouts) {
    parts.push(`Treinos esta semana: ${workouts.completedThisWeek}.`);
  }

  const weight = ctx.weight as { latestKg?: number } | undefined;
  if (weight) {
    parts.push(`Peso registrado: ${weight.latestKg} kg.`);
  }

  if (parts.length === 1) {
    parts.push("Nenhum dado disponível ainda.");
  }

  return parts.join("\n");
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) throw new Error("ANTHROPIC_API_KEY não configurada.");

    const body = await req.json();
    const ctx = (body.context ?? {}) as Record<string, unknown>;
    const locale = (ctx.locale as string) ?? "pt";

    const systemPrompt = buildSystemPrompt(locale);
    const userPrompt = buildUserPrompt(ctx);

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "anthropic-version": "2023-06-01",
        "x-api-key": apiKey,
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 120,
        system: systemPrompt,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });

    if (!response.ok) {
      const err = await response.text();
      throw new Error(`Claude API error: ${response.status} — ${err}`);
    }

    const data = await response.json();
    const insight = (data.content?.[0]?.text ?? "").trim();

    return new Response(
      JSON.stringify({ insight }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 },
    );
  } catch (error) {
    console.error("Erro em gerar-insight-havok:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 },
    );
  }
});
