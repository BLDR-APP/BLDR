import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { compactThreadSummary, contextDomains, routeIntent, shouldRefreshThreadSummary, validateMemoryCandidates, validateNutritionSnapshot, validateResponseV2 } from './havok_v2.ts'

const valid = {
  version: 2,
  intent: 'WORKOUT_ANALYSIS',
  message: 'Seu volume recente está consistente.',
  insights: [{ type: 'volume', title: 'Volume', value: '12 séries', source: 'user_workouts' }],
  artifact: null,
  actions: [{ type: 'OPEN_WORKOUT_ANALYTICS', label: 'Ver análise', payload: {} }],
  followUpSuggestions: ['Como evoluir?'],
  memoryCandidates: [],
}

Deno.test('router seleciona domínios compactos para recovery', () => {
  assertEquals(routeIntent('Como está minha recuperação e sono?'), 'RECOVERY_ANALYSIS')
  assertEquals(contextDomains('RECOVERY_ANALYSIS'), ['whoop', 'activities', 'workout', 'memory'])
})

Deno.test('aceita somente resposta V2 alinhada ao intent', () => {
  assertEquals(validateResponseV2(valid, 'WORKOUT_ANALYSIS')?.version, 2)
  assertEquals(validateResponseV2({ ...valid, intent: 'GENERAL' }, 'WORKOUT_ANALYSIS'), null)
})

Deno.test('rejeita ação arbitrária e memory de métrica volátil', () => {
  assertEquals(validateResponseV2({ ...valid, actions: [{ type: 'OPEN_WORKOUT_ANALYTICS', label: 'Abrir', payload: { route: '/admin' } }] }, 'WORKOUT_ANALYSIS'), null)
  assertEquals(validateResponseV2({ ...valid, actions: [{ type: 'START_WORKOUT', label: 'Iniciar', payload: { rpc: 'admin_override' } }] }, 'WORKOUT_ANALYSIS'), null)
  assertEquals(validateMemoryCandidates([{ operation: 'create', category: 'context', key: 'recovery hoje', value: '80' }]), null)
})

Deno.test('forget é uma operação explícita e válida', () => {
  assertEquals(validateMemoryCandidates([{ operation: 'forget', category: 'nutrition_preference', key: 'peixe' }])?.length, 1)
})

Deno.test('snapshot nutricional aceita somente totais determinísticos plausíveis', () => {
  const snapshot = validateNutritionSnapshot({
    date: '2026-08-31', caloriesConsumed: 2100, protein: 155, carbs: 220,
    fat: 60, calorieGoal: 2400, proteinGoal: 180, carbsGoal: 250, fatGoal: 70,
    mealsCount: 3, generatedAt: '2026-08-31T10:00:00.000Z',
  })
  assertEquals(snapshot?.protein, 155)
  assertEquals(validateNutritionSnapshot({ ...snapshot!, caloriesConsumed: -1 }), null)
})

Deno.test('resumo de thread só é atualizado no limiar e em blocos de seis', () => {
  assertEquals(shouldRefreshThreadSummary(11), false)
  assertEquals(shouldRefreshThreadSummary(12), true)
  assertEquals(shouldRefreshThreadSummary(17), false)
  assertEquals(shouldRefreshThreadSummary(18), true)
  assertEquals(compactThreadSummary([{ role: 'user', content: '  Prefiro   halteres. ' }]), 'Usuário: Prefiro halteres.')
})
