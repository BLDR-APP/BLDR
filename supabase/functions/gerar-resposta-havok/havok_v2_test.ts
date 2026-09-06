import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  compactThreadSummary,
  contextDomains,
  normalizeOptionalResponseFields,
  responseIntentConstraint,
  responseSchemaPrompt,
  routeIntent,
  shouldRefreshThreadSummary,
  validateMemoryCandidates,
  validateNutritionSnapshot,
  validateResponseV2,
  whoopDailySelect,
} from "./havok_v2.ts";

const valid = {
  version: 2,
  intent: "WORKOUT_ANALYSIS",
  message: "Seu volume recente está consistente.",
  insights: [{
    type: "volume",
    title: "Volume",
    value: "12 séries",
    source: "user_workouts",
  }],
  artifact: null,
  actions: [{
    type: "OPEN_WORKOUT_ANALYTICS",
    label: "Ver análise",
    payload: {},
  }],
  followUpSuggestions: ["Como evoluir?"],
  memoryCandidates: [],
};

const validRecovery = {
  ...valid,
  intent: "RECOVERY_ANALYSIS",
  message: "Seu recovery está estável hoje.",
  insights: [{
    type: "recovery",
    title: "Recovery",
    value: "Estável",
    source: "whoop_daily_data",
  }],
  actions: [],
  followUpSuggestions: [],
};

Deno.test("router seleciona domínios compactos para recovery", () => {
  assertEquals(
    routeIntent("Como está minha recuperação e sono?"),
    "RECOVERY_ANALYSIS",
  );
  assertEquals(contextDomains("RECOVERY_ANALYSIS"), [
    "whoop",
    "activities",
    "workout",
    "memory",
  ]);
});

Deno.test("router reconhece recovery e preserva gatilhos existentes", () => {
  for (const message of [
    "meu recovery está como?",
    "como está meu recovery?",
    "analise meu recovery",
    "como está meu sono?",
    "analise meu hrv",
    "qual meu strain?",
    "dados do whoop",
    "estou com fadiga",
    "estou cansada",
    "como está minha recuperação?",
  ]) {
    assertEquals(routeIntent(message), "RECOVERY_ANALYSIS");
  }
  assertEquals(routeIntent("olá, tudo bem?"), "GENERAL");
});

Deno.test("contexto WHOOP usa os nomes reais das colunas de recovery", () => {
  assertEquals(whoopDailySelect.includes("resting_hr"), true);
  assertEquals(whoopDailySelect.includes("sleep_duration"), true);
  assertEquals(whoopDailySelect.includes("resting_heart_rate"), false);
  assertEquals(whoopDailySelect.includes("sleep_duration_minutes"), false);
});

Deno.test("aceita somente resposta V2 alinhada ao intent", () => {
  assertEquals(validateResponseV2(valid, "WORKOUT_ANALYSIS")?.version, 2);
  assertEquals(
    validateResponseV2({ ...valid, intent: "GENERAL" }, "WORKOUT_ANALYSIS"),
    null,
  );
});

Deno.test("aceita contrato válido para RECOVERY_ANALYSIS", () => {
  assertEquals(
    validateResponseV2(validRecovery, "RECOVERY_ANALYSIS")?.intent,
    "RECOVERY_ANALYSIS",
  );
});

Deno.test("aceita insights WHOOP de recovery dentro do limite do contrato", () => {
  const response = {
    ...validRecovery,
    insights: [
      { type: "recovery", title: "Recovery e strain", value: "78% · strain 11,2", source: "whoop_daily_data" },
      { type: "sleep", title: "Sono", value: "7h 42min · score 86", source: "whoop_daily_data" },
      { type: "hrv", title: "HRV", value: "42 ms", source: "whoop_daily_data" },
      { type: "resting_heart_rate", title: "Frequência cardíaca de repouso", value: "54 bpm", source: "whoop_daily_data" },
    ],
  };

  assertEquals(validateResponseV2(response, "RECOVERY_ANALYSIS")?.insights.length, 4);
  assertEquals(
    validateResponseV2({
      ...response,
      insights: [...response.insights, { type: "strain", title: "Strain", value: "11,2", source: "whoop_daily_data" }],
    }, "RECOVERY_ANALYSIS"),
    null,
  );
});

Deno.test("schema prompt explicita o contrato estrito de insights", () => {
  const prompt = responseSchemaPrompt();
  assertEquals(prompt.includes("de 0 a 4 itens"), true);
  assertEquals(prompt.includes("type, title, value e source como strings não vazias"), true);
  assertEquals(prompt.includes("métricas numéricas devem ser serializadas em value como texto"), true);
  assertEquals(prompt.includes('source "whoop_daily_data"'), true);
});

Deno.test("recovery não persiste métricas WHOOP como memória", () => {
  assertEquals(
    validateResponseV2(
      { ...validRecovery, memoryCandidates: [] },
      "RECOVERY_ANALYSIS",
    )?.intent,
    "RECOVERY_ANALYSIS",
  );
  for (const key of ["recovery", "hrv", "strain"]) {
    assertEquals(
      validateResponseV2({
        ...validRecovery,
        memoryCandidates: [{
          operation: "create",
          category: "context",
          key,
          value: "métrica temporária",
        }],
      }, "RECOVERY_ANALYSIS"),
      null,
    );
  }
});

Deno.test("aceita memoryCandidate estável e o prompt proíbe métricas voláteis", () => {
  assertEquals(
    validateResponseV2({
      ...valid,
      memoryCandidates: [{
        operation: "create",
        category: "equipment",
        key: "halteres",
        value: true,
        confidence: 0.9,
      }],
    }, "WORKOUT_ANALYSIS")?.memoryCandidates.length,
    1,
  );
  const prompt = responseSchemaPrompt();
  assertEquals(prompt.includes("MemoryCandidates: envie []"), true);
  assertEquals(prompt.includes("recovery, strain, HRV, resting heart rate/RHR, sono"), true);
  assertEquals(prompt.includes("Para RECOVERY_ANALYSIS, normalmente envie memoryCandidates: []"), true);
});

Deno.test("normaliza insights opcionais sem descartar a resposta", () => {
  const insight = { type: "recovery", title: "Recovery", value: "78%", source: "whoop_daily_data" };
  const fiveInsights = normalizeOptionalResponseFields({
    ...validRecovery,
    insights: [insight, insight, insight, insight, insight],
  });
  assertEquals(fiveInsights.insightsDropped, true);
  assertEquals((fiveInsights.response as { insights: unknown[] }).insights.length, 4);
  assertEquals(validateResponseV2(fiveInsights.response, "RECOVERY_ANALYSIS")?.message, validRecovery.message);

  const mixedInsights = normalizeOptionalResponseFields({
    ...validRecovery,
    insights: [insight, { type: "recovery" }, { ...insight, title: "Sono" }],
  });
  assertEquals((mixedInsights.response as { insights: unknown[] }).insights.length, 2);
  assertEquals(validateResponseV2(mixedInsights.response, "RECOVERY_ANALYSIS")?.insights.length, 2);

  const nonArrayInsights = normalizeOptionalResponseFields({ ...validRecovery, insights: {} });
  assertEquals((nonArrayInsights.response as { insights: unknown[] }).insights.length, 0);
  assertEquals(validateResponseV2(nonArrayInsights.response, "RECOVERY_ANALYSIS")?.insights.length, 0);
});

Deno.test("normaliza memoryCandidates opcionais sem persistir métricas voláteis", () => {
  const volatileMemory = normalizeOptionalResponseFields({
    ...validRecovery,
    memoryCandidates: [{ operation: "create", category: "context", key: "recovery hoje", value: "80" }],
  });
  assertEquals(volatileMemory.memoryCandidatesDropped, true);
  assertEquals((volatileMemory.response as { memoryCandidates: unknown[] }).memoryCandidates.length, 0);
  assertEquals(validateResponseV2(volatileMemory.response, "RECOVERY_ANALYSIS")?.message, validRecovery.message);

  const stableMemory = normalizeOptionalResponseFields({
    ...valid,
    memoryCandidates: [{ operation: "create", category: "equipment", key: "halteres", value: true }],
  });
  assertEquals((stableMemory.response as { memoryCandidates: unknown[] }).memoryCandidates.length, 1);
  assertEquals(validateResponseV2(stableMemory.response, "WORKOUT_ANALYSIS")?.memoryCandidates.length, 1);
});

Deno.test("normalização não relaxa campos essenciais, artifact ou actions", () => {
  assertEquals(
    validateResponseV2(
      normalizeOptionalResponseFields({ ...validRecovery, message: "" }).response,
      "RECOVERY_ANALYSIS",
    ),
    null,
  );
  assertEquals(
    validateResponseV2(
      normalizeOptionalResponseFields({ ...validRecovery, intent: "GENERAL" }).response,
      "RECOVERY_ANALYSIS",
    ),
    null,
  );
  assertEquals(
    validateResponseV2(
      normalizeOptionalResponseFields({ ...validRecovery, artifact: { type: "workout", data: { exercicios: [] } } }).response,
      "RECOVERY_ANALYSIS",
    ),
    null,
  );
  assertEquals(
    validateResponseV2(
      normalizeOptionalResponseFields({
        ...validRecovery,
        actions: [{ type: "INVALID", label: "Abrir", payload: {} }],
      }).response,
      "RECOVERY_ANALYSIS",
    ),
    null,
  );
});

Deno.test("fixa o intent esperado sem reclassificação", () => {
  for (
    const intent of [
      "RECOVERY_ANALYSIS",
      "WORKOUT_ANALYSIS",
      "NUTRITION_ANALYSIS",
    ] as const
  ) {
    const constraint = responseIntentConstraint(intent);
    assertEquals(constraint.includes(`Intent esperado: ${intent}`), true);
    assertEquals(
      constraint.includes(
        `"intent" do seu JSON DEVE ser exatamente "${intent}"`,
      ),
      true,
    );
    assertEquals(
      constraint.includes("Não reclassifique a intenção do usuário."),
      true,
    );
    assertEquals(
      constraint.includes("Não escolha outro intent da enum permitida."),
      true,
    );
  }
});

Deno.test("rejeita cada categoria do contrato V2", () => {
  const invalidCases: Array<[string, unknown, string]> = [
    ["root", null, "RECOVERY_ANALYSIS"],
    ["version", { ...validRecovery, version: 1 }, "RECOVERY_ANALYSIS"],
    ["intent", { ...validRecovery, intent: "GENERAL" }, "RECOVERY_ANALYSIS"],
    ["message ausente", { ...validRecovery, message: "" }, "RECOVERY_ANALYSIS"],
    [
      "insights",
      { ...validRecovery, insights: [{ type: "recovery" }] },
      "RECOVERY_ANALYSIS",
    ],
    ["artifact", {
      ...validRecovery,
      artifact: { type: "workout", data: { exercicios: [] } },
    }, "RECOVERY_ANALYSIS"],
    ["actions", {
      ...validRecovery,
      actions: [{ type: "INVALID", label: "Abrir", payload: {} }],
    }, "RECOVERY_ANALYSIS"],
    [
      "suggestions",
      { ...validRecovery, followUpSuggestions: [""] },
      "RECOVERY_ANALYSIS",
    ],
    ["memory", {
      ...validRecovery,
      memoryCandidates: [{
        operation: "create",
        category: "context",
        key: "recovery",
        value: "80",
      }],
    }, "RECOVERY_ANALYSIS"],
  ];

  for (const [, response, intent] of invalidCases) {
    assertEquals(validateResponseV2(response, intent as never), null);
  }
});

Deno.test("rejeita ação arbitrária e memory de métrica volátil", () => {
  assertEquals(
    validateResponseV2({
      ...valid,
      actions: [{
        type: "OPEN_WORKOUT_ANALYTICS",
        label: "Abrir",
        payload: { route: "/admin" },
      }],
    }, "WORKOUT_ANALYSIS"),
    null,
  );
  assertEquals(
    validateResponseV2({
      ...valid,
      actions: [{
        type: "START_WORKOUT",
        label: "Iniciar",
        payload: { rpc: "admin_override" },
      }],
    }, "WORKOUT_ANALYSIS"),
    null,
  );
  assertEquals(
    validateMemoryCandidates([{
      operation: "create",
      category: "context",
      key: "recovery hoje",
      value: "80",
    }]),
    null,
  );
});

Deno.test("forget é uma operação explícita e válida", () => {
  assertEquals(
    validateMemoryCandidates([{
      operation: "forget",
      category: "nutrition_preference",
      key: "peixe",
    }])?.length,
    1,
  );
});

Deno.test("snapshot nutricional aceita somente totais determinísticos plausíveis", () => {
  const snapshot = validateNutritionSnapshot({
    date: "2026-08-31",
    caloriesConsumed: 2100,
    protein: 155,
    carbs: 220,
    fat: 60,
    calorieGoal: 2400,
    proteinGoal: 180,
    carbsGoal: 250,
    fatGoal: 70,
    mealsCount: 3,
    generatedAt: "2026-08-31T10:00:00.000Z",
  });
  assertEquals(snapshot?.protein, 155);
  assertEquals(
    validateNutritionSnapshot({ ...snapshot!, caloriesConsumed: -1 }),
    null,
  );
});

Deno.test("resumo de thread só é atualizado no limiar e em blocos de seis", () => {
  assertEquals(shouldRefreshThreadSummary(11), false);
  assertEquals(shouldRefreshThreadSummary(12), true);
  assertEquals(shouldRefreshThreadSummary(17), false);
  assertEquals(shouldRefreshThreadSummary(18), true);
  assertEquals(
    compactThreadSummary([{ role: "user", content: "  Prefiro   halteres. " }]),
    "Usuário: Prefiro halteres.",
  );
});
