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
Você é HAVOK, IA de elite especializada em performance atlética do BLDR CLUB.
Crie planos de treino específicos para o esporte solicitado — criativos, desafiadores e seguros.
Responda APENAS com o JSON solicitado, sem markdown, sem texto antes ou depois.
`.trim();

async function callClaude(userMessage: string, maxTokens = 3000): Promise<string> {
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
    const { sport } = await req.json();
    if (!sport) throw new Error('O campo "sport" é obrigatório.');

    const authHeader = req.headers.get("Authorization")!;
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Usuário não autenticado." }), {
        status: 401,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const prompt = `Crie um plano de treino de performance de 4 dias por semana para um atleta de ${sport}.

O plano deve ser específico para ${sport}, evitando respostas genéricas.

Retorne apenas JSON no schema:
{
  "title": "Plano de Performance: ${sport}",
  "subtitle": "subtítulo motivador de 1 linha",
  "planJson": {
    "dia_1": {
      "foco": "Explosão e Potência",
      "exercicios": [
        { "nome": "Exercício", "series": "4", "reps": "8-10", "descanso": "60-90s", "observacoes": "Dica de execução." }
      ]
    },
    "dia_2": {
      "foco": "Agilidade e Core",
      "exercicios": [
        { "nome": "Exercício", "series": "3", "reps": "12-15", "descanso": "60s", "observacoes": "Dica." }
      ]
    },
    "dia_3": {
      "foco": "Força Funcional específica para ${sport}",
      "exercicios": [
        { "nome": "Exercício", "series": "4", "reps": "10", "descanso": "90s", "observacoes": "Dica." }
      ]
    },
    "dia_4": {
      "foco": "Prevenção de Lesões e Mobilidade",
      "exercicios": [
        { "nome": "Exercício", "series": "2", "reps": "15", "descanso": "45s", "observacoes": "Dica." }
      ]
    }
  }
}`;

    const rawText = await callClaude(prompt);
    const aiResponseObject = JSON.parse(rawText.replace(/```json/g, "").replace(/```/g, "").trim());

    const finalResponse = {
      ...aiResponseObject,
      id: crypto.randomUUID(),
      sport,
      sportContextTag: sport.toLowerCase().replaceAll(" ", ""),
    };

    return new Response(JSON.stringify(finalResponse), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    console.error("Erro fatal na Edge Function gerar-plano-performance:", error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
});
