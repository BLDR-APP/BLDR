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
  return `
Você é o HAVOK, treinador de IA do BLDR. Tom técnico e direto, sem cobrança
emocional. Frases curtas.

Quando o contexto incluir "perfil_usuario", use esses dados para personalizar
as respostas e os treinos gerados:
- objetivo: meta principal do usuário (ex: "Ganho de massa", "Perda de peso")
- nivel: experiência do usuário (ex: "Iniciante", "Intermediário", "Avançado")
- dias_treino_semana: quantos dias por semana o usuário treina
- lesoes: lista de lesões ou restrições físicas — NUNCA prescrever exercícios
  que agravem as lesões listadas
- foco_muscular: grupos musculares de interesse
- ambiente: local de treino ("Academia", "Casa", etc.)
- sexo e idade: para ajustar intensidade e volume
Nunca mencione diretamente ao usuário que leu o perfil dele — apenas incorpore
as informações naturalmente.

Responda SEMPRE em ${lang}. Nunca misture idiomas.

LIMITES — nunca negociáveis, mesmo se o usuário insistir:
- Nunca diagnostica lesão, nunca recomenda medicamento ou dose.
- Nunca sugere déficit calórico abaixo de 1200kcal/dia nem meta de peso fora
  de uma faixa saudável para a altura informada.
- Nunca valida jejum prolongado para emagrecer, "compensar" comida com
  treino extra, ou pular refeição para bater meta.
- Suplementação: whey, creatina e cafeína são consenso, pode falar sobre eles
  livremente. Termogênico, hormônio, ou qualquer coisa que exija prescrição —
  nunca recomenda.
- Nunca diz para treinar com dor relatada durante o movimento. Adapta o
  treino contornando a região e recomenda avaliação profissional.
- Ao recusar qualquer um dos itens acima, SEMPRE oferece o que consegue
  fazer em vez de só recusar. Nunca é um beco sem saída.
- Fora do escopo dele (algo que não sabe): diz que não sabe. Nunca inventa.

Responda SEMPRE em JSON válido, sem markdown, sem texto antes ou depois do JSON.
Schema obrigatório:
{"message": "resposta em texto para o usuário", "artifact": {"type": "workout" | "recipe" | null, "data": object | null} | null}

Quando artifact.type = "workout", artifact.data DEVE seguir EXATAMENTE este schema:
{
  "nome": "Nome do treino em português",
  "foco": "Grupo muscular principal",
  "duracao_minutos": 45,
  "exercicios": [
    {
      "nome": "Nome do exercício em português",
      "series": 4,
      "repeticoes": "8-12",
      "descanso_segundos": 90,
      "instrucao": "Dica de execução curta (opcional)"
    }
  ],
  "observacoes": "Nota opcional sobre o treino"
}
OBRIGATÓRIO no artifact de treino:
- Chaves SEMPRE em português: nome, exercicios, series, repeticoes, descanso_segundos
- NUNCA usar name, exercises, sets, reps, rest_seconds
- exercicios deve ter entre 4 e 8 itens
- nome do exercício sempre em português do Brasil
- repeticoes como string: "8-12", "10-15", "12", etc.
`.trim();
}

function buildPrompt(
  context: Record<string, unknown>,
  history: { role: string; content: string }[],
  userMessage: string,
): string {
  const streak = context?.streak as { days?: number; at_risk?: boolean } | undefined;
  const streakLine = streak
    ? `\nStreak atual: ${streak.days} dias consecutivos. ${streak.at_risk ? "Ainda não treinou hoje — streak em risco." : "Já treinou hoje."}\n`
    : "";

  const whoop = context?.whoop as { recovery?: number; strain?: number; sleep?: number; hrv?: number } | undefined;
  const whoopLine = whoop
    ? `\nDados Whoop de hoje: Recovery ${whoop.recovery ?? "--"}%, Strain ${whoop.strain ?? "--"}/21, Sleep ${whoop.sleep ?? "--"}%, HRV ${whoop.hrv ?? "--"}ms.\n`
    : "";

  const historyText = history
    .map((m) => `${m.role === "user" ? "Usuário" : "HAVOK"}: ${m.content}`)
    .join("\n");

  return `Contexto do usuário:
${JSON.stringify(context ?? {})}
${streakLine}${whoopLine}
Histórico recente (mais antigas primeiro):
${historyText || "(início da conversa)"}

Nova mensagem do usuário:
${userMessage}`;
}

async function callClaude(userMessage: string, systemPrompt: string, maxTokens = 1024): Promise<string> {
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
    const threadId = body.threadId as string;
    const userMessage = (body.userMessage as string ?? "").trim();
    const context = body.context ?? {};
    const locale = (context.locale as string) ?? "pt";
    const systemPrompt = buildSystemPrompt(locale);
    if (!threadId) throw new Error("threadId é obrigatório.");
    if (!userMessage) throw new Error("Mensagem vazia.");

    const { data: thread, error: threadError } = await supabaseClient
      .schema("bldr_club")
      .from("havok_threads")
      .select("id")
      .eq("id", threadId)
      .eq("user_id", user.id)
      .single();
    if (threadError || !thread) throw new Error("Thread não encontrada.");

    const { data: historyRows } = await supabaseClient
      .schema("bldr_club")
      .from("havok_messages")
      .select("role, content")
      .eq("thread_id", threadId)
      .order("created_at", { ascending: false })
      .limit(20);
    const history = (historyRows ?? []).reverse();

    const { error: insertUserError } = await supabaseClient
      .schema("bldr_club")
      .from("havok_messages")
      .insert({ thread_id: threadId, role: "user", content: userMessage });
    if (insertUserError) {
      throw new Error(`Erro ao salvar mensagem: ${insertUserError.message}`);
    }

    const prompt = buildPrompt(context, history, userMessage);
    const rawText = await callClaude(prompt, systemPrompt);

    const parsed = JSON.parse(rawText.replace(/```json/g, "").replace(/```/g, "").trim());
    const assistantMessage: string = parsed.message ?? "Não consegui gerar uma resposta agora.";
    const artifact = parsed.artifact ?? null;
    const artifactType = artifact?.type ?? null;
    const artifactData = artifact?.data ?? null;

    const { data: savedMessage, error: insertAssistantError } = await supabaseClient
      .schema("bldr_club")
      .from("havok_messages")
      .insert({
        thread_id: threadId,
        role: "assistant",
        content: assistantMessage,
        artifact_type: artifactType,
        artifact_data: artifactData,
      })
      .select()
      .single();
    if (insertAssistantError) {
      throw new Error(`Erro ao salvar resposta: ${insertAssistantError.message}`);
    }

    return new Response(
      JSON.stringify(savedMessage),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 },
    );
  } catch (error) {
    console.error("Erro fatal na Edge Function gerar-resposta-havok:", error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
