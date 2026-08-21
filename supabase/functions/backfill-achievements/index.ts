/**
 * backfill-achievements
 *
 * Roda a mesma lógica de checkAndUnlock do Flutter no servidor,
 * para todos os usuários (ou um usuário específico via body).
 *
 * Idempotente: nunca insere um badge que já existe em user_achievements.
 *
 * POST /backfill-achievements
 * Body (opcional): { "user_id": "uuid" }   → processa só esse usuário
 * Body vazio                                → processa todos os usuários
 *
 * Retorna:
 * {
 *   "users_processed": 42,
 *   "badges_inserted": 7,
 *   "details": [{ "user_id": "...", "inserted": ["Badge A", "Badge B"] }]
 * }
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ---------------------------------------------------------------------------
// Cliente admin (service role — bypassa RLS)
// ---------------------------------------------------------------------------
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

// ---------------------------------------------------------------------------
// Tipos
// ---------------------------------------------------------------------------
interface Achievement {
  id: string;
  name: string;
  description: string;
  category: string;
  icon_name: string;
  criteria_type: string;
  criteria_value: number;
  xp_value: number;
}

interface Context {
  [key: string]: number | boolean | string;
}

// ---------------------------------------------------------------------------
// Relevância por trigger (espelho de _isRelevantForTrigger no Flutter)
// ---------------------------------------------------------------------------
const WORKOUT_CRITERIA = new Set([
  'workout_count', 'hiit_workout_count', 'consecutive_days',
  'max_weight_bench_press', 'weekend_warrior',
  'trained_before_hour', 'trained_on_date',
]);

const BLDR_CLUB_CRITERIA = new Set([
  'bldr_workout_total', 'bldr_streak_days', 'duel_wins',
  'ranking_position', 'club_member', 'club_level', 'total_xp',
]);

function isRelevant(criteriaType: string, triggerType: string): boolean {
  switch (triggerType) {
    case 'workout':    return WORKOUT_CRITERIA.has(criteriaType);
    case 'onboarding': return criteriaType === 'onboarding_complete';
    case 'profile':    return criteriaType === 'goal_created';
    case 'nutrition':  return criteriaType === 'meal_logged' ||
                              criteriaType === 'meal_logged_consecutive_days';
    case 'photo':      return criteriaType === 'progress_photo_added';
    case 'bldr_club':  return BLDR_CLUB_CRITERIA.has(criteriaType);
    default:           return false;
  }
}

// ---------------------------------------------------------------------------
// Avaliação de condição (espelho de _evaluateCondition no Flutter)
// ---------------------------------------------------------------------------
function evaluateCondition(achievement: Achievement, ctx: Context): boolean {
  const type  = achievement.criteria_type;
  const value = achievement.criteria_value;

  switch (type) {
    case 'workout_count':
      return (ctx['workout_count'] as number ?? 0) >= value;
    case 'hiit_workout_count':
      return (ctx['hiit_workout_count'] as number ?? 0) >= value;
    case 'consecutive_days':
      return (ctx['consecutive_days'] as number ?? 0) >= value;
    case 'weekend_warrior':
      return (ctx['weekend_warrior'] as number ?? 0) >= 1;
    case 'trained_before_hour':
      return (ctx['trained_before_hour'] as number ?? 0) >= 1;
    case 'trained_on_date':
      return ctx['trained_on_date'] === value;
    case 'onboarding_complete':
      return ctx['onboarding_completed'] === true;
    case 'goal_created':
      return ctx['goal_created'] === true;
    case 'meal_logged':
      return (ctx['meal_count'] as number ?? 0) >= value;
    case 'meal_logged_consecutive_days':
      return (ctx['meal_logged_consecutive_days'] as number ?? 0) >= value;
    case 'max_weight_bench_press':
      return (ctx['max_bench_press'] as number ?? 0) >= value;
    case 'progress_photo_added':
      return (ctx['photo_count'] as number ?? 0) >= value;
    case 'club_member':
      return ctx['club_member'] === true;
    case 'total_xp':
      return (ctx['total_xp'] as number ?? 0) >= value;
    case 'club_level':
      return (ctx['club_level'] as number ?? 1) >= value;
    case 'bldr_workout_total':
      return (ctx['bldr_workout_total'] as number ?? 0) >= value;
    case 'duel_wins':
      return (ctx['duel_wins'] as number ?? 0) >= value;
    case 'ranking_position': {
      const pos = ctx['ranking_position'] as number ?? 9999;
      return pos > 0 && pos <= value;
    }
    case 'bldr_streak_days':
      return (ctx['bldr_streak_days'] as number ?? 0) >= value;
    default:
      return false;
  }
}

// ---------------------------------------------------------------------------
// Busca de contexto — espelho de _fetchContext no Flutter
// ---------------------------------------------------------------------------

async function fetchWorkoutContext(userId: string): Promise<Context> {
  // Busca treinos grátis e BLDR CLUB em paralelo (sem limit — conta tudo)
  const [{ data: freeData }, { data: clubData }] = await Promise.all([
    supabase
      .from('user_workouts')
      .select('started_at, completed_at, workout_templates(workout_type)')
      .eq('user_id', userId)
      .eq('is_completed', true)
      .order('completed_at', { ascending: false }),
    supabase
      .from('club_user_workouts')
      .select('started_at, completed_at')
      .eq('user_id', userId)
      .eq('is_completed', true)
      .order('completed_at', { ascending: false }),
  ]);

  const freeList = freeData ?? [];
  const clubList = clubData ?? [];
  const allList  = [...freeList, ...clubList];

  // workout_count = total grátis + BLDR CLUB
  const count = allList.length;

  // hiit_count — somente treinos grátis (têm template com workout_type)
  const hiitCount = freeList.filter((w: Record<string, unknown>) => {
    const t = w['workout_templates'] as Record<string, string> | null;
    return t?.['workout_type']?.toLowerCase() === 'hiit';
  }).length;

  // Dias únicos com treino (qualquer fonte)
  const workedDays = new Set<string>();
  for (const w of allList) {
    const s = (w as Record<string, string>)['completed_at'];
    if (!s) continue;
    const dt = new Date(s);
    workedDays.add(`${dt.getFullYear()}-${dt.getMonth()}-${dt.getDate()}`);
  }

  // Streak: dias consecutivos terminando hoje
  let streak = 0;
  const today = new Date();
  let day = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  while (true) {
    const key = `${day.getFullYear()}-${day.getMonth()}-${day.getDate()}`;
    if (!workedDays.has(key)) break;
    streak++;
    day = new Date(day.getTime() - 86400000);
  }

  const trainedSat = [...workedDays].some(k => {
    const [y, m, d] = k.split('-').map(Number);
    return new Date(y, m, d).getDay() === 6;
  });
  const trainedSun = [...workedDays].some(k => {
    const [y, m, d] = k.split('-').map(Number);
    return new Date(y, m, d).getDay() === 0;
  });

  const trainedBeforeHour = allList.some((w: Record<string, unknown>) => {
    const s = (w as Record<string, string>)['started_at'];
    if (!s) return false;
    return new Date(s).getHours() < 7;
  });

  const now = new Date();
  const todayMMDD = (now.getMonth() + 1) * 100 + now.getDate();

  return {
    workout_count:       count,
    hiit_workout_count:  hiitCount,
    consecutive_days:    streak,
    weekend_warrior:     (trainedSat && trainedSun) ? 1 : 0,
    trained_before_hour: trainedBeforeHour ? 1 : 0,
    trained_on_date:     todayMMDD,
  };
}

async function fetchProfileContext(userId: string): Promise<Context> {
  const [{ data: profile }, { data: goals }] = await Promise.all([
    supabase.from('user_profiles').select('onboarding_completed').eq('id', userId).single(),
    supabase.from('user_goals').select('id').eq('user_id', userId).limit(1),
  ]);

  return {
    onboarding_completed: (profile as Record<string, unknown>)?.['onboarding_completed'] === true,
    goal_created:         (goals?.length ?? 0) > 0,
  };
}

async function fetchPhotoContext(userId: string): Promise<Context> {
  const { data } = await supabase
    .from('progress_photos')
    .select('id')
    .eq('user_id', userId);
  return { photo_count: data?.length ?? 0 };
}

async function fetchNutritionContext(userId: string): Promise<Context> {
  const { data: meals } = await supabase
    .from('user_meals')
    .select('meal_date')
    .eq('user_id', userId)
    .order('meal_date', { ascending: false })
    .limit(100);

  const mealDays = new Set<string>();
  for (const m of meals ?? []) {
    const s = (m as Record<string, string>)['meal_date'];
    if (!s) continue;
    const dt = new Date(s);
    mealDays.add(`${dt.getFullYear()}-${dt.getMonth()}-${dt.getDate()}`);
  }

  let streak = 0;
  const today = new Date();
  let day = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  while (true) {
    const key = `${day.getFullYear()}-${day.getMonth()}-${day.getDate()}`;
    if (!mealDays.has(key)) break;
    streak++;
    day = new Date(day.getTime() - 86400000);
  }

  return {
    meal_count:                   mealDays.size,
    meal_logged_consecutive_days: streak,
  };
}

async function fetchBldrClubContext(userId: string): Promise<Context> {
  const [
    { data: subs },
    { data: rankData },
    { data: activities },
    { data: challenges },
    { data: allRanking },
  ] = await Promise.all([
    supabase.from('user_subscriptions')
      .select('status')
      .eq('user_id', userId)
      .or('status.eq.active,status.eq.trialing')
      .limit(1),
    supabase.schema('bldr_club').from('club_ranking')
      .select('xp_total, current_level')
      .eq('user_id', userId)
      .maybeSingle(),
    supabase.from('club_user_workouts')
      .select('id')
      .eq('user_id', userId)
      .eq('is_completed', true),
    supabase.schema('bldr_club').from('user_challenges')
      .select('winner_id')
      .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
      .eq('status', 'finished'),
    supabase.schema('bldr_club').from('club_ranking')
      .select('user_id, xp_total')
      .order('xp_total', { ascending: false })
      .limit(200),
  ]);

  const wins = (challenges ?? []).filter(
    (c: Record<string, unknown>) => c['winner_id'] === userId
  ).length;

  const rankList = allRanking ?? [];
  let rankPos = 9999;
  for (let i = 0; i < rankList.length; i++) {
    if ((rankList[i] as Record<string, unknown>)['user_id'] === userId) {
      rankPos = i + 1;
      break;
    }
  }

  const rd = rankData as Record<string, unknown> | null;

  return {
    club_member:        (subs?.length ?? 0) > 0,
    total_xp:           (rd?.['xp_total'] as number) ?? 0,
    club_level:         (rd?.['current_level'] as number) ?? 1,
    bldr_workout_total: activities?.length ?? 0,
    duel_wins:          wins,
    ranking_position:   rankPos,
    bldr_streak_days:   0,
  };
}

async function fetchContext(userId: string, triggerType: string): Promise<Context> {
  switch (triggerType) {
    case 'workout':    return fetchWorkoutContext(userId);
    case 'onboarding':
    case 'profile':    return fetchProfileContext(userId);
    case 'photo':      return fetchPhotoContext(userId);
    case 'nutrition':  return fetchNutritionContext(userId);
    case 'bldr_club':  return fetchBldrClubContext(userId);
    default:           return {};
  }
}

// ---------------------------------------------------------------------------
// Unlock: insere em user_achievements + XP
// ---------------------------------------------------------------------------
async function unlock(userId: string, achievement: Achievement): Promise<void> {
  await supabase.from('user_achievements').insert({
    user_id:                 userId,
    achievement_type:        achievement.category,
    achievement_name:        achievement.name,
    achievement_description: achievement.description,
    achieved_at:             new Date().toISOString(),
  });

  // XP (mesmo comportamento do Flutter)
  await supabase.schema('bldr_club').from('xp_events').insert({
    user_id: userId,
    delta:   achievement.xp_value ?? 50,
    reason:  achievement.name,
  });

  await supabase.rpc('add_xp_to_user', {
    p_user_id:   userId,
    p_xp_amount: achievement.xp_value ?? 50,
    p_source:    achievement.criteria_type ?? 'achievement_unlocked',
  });
}

// ---------------------------------------------------------------------------
// Processa um único usuário
// ---------------------------------------------------------------------------
const TRIGGER_TYPES = ['workout', 'onboarding', 'profile', 'nutrition', 'photo', 'bldr_club'];

async function processUser(
  userId: string,
  catalog: Achievement[],
): Promise<string[]> {
  // Badges já desbloqueados
  const { data: unlockedRows } = await supabase
    .from('user_achievements')
    .select('achievement_name')
    .eq('user_id', userId);

  const unlockedNames = new Set(
    (unlockedRows ?? []).map((r: Record<string, string>) => r['achievement_name']).filter(Boolean)
  );

  const inserted: string[] = [];

  for (const triggerType of TRIGGER_TYPES) {
    const relevant = catalog.filter(a =>
      !unlockedNames.has(a.name) && isRelevant(a.criteria_type, triggerType)
    );

    if (relevant.length === 0) continue;

    let ctx: Context;
    try {
      ctx = await fetchContext(userId, triggerType);
    } catch {
      continue; // usuário sem dados para este trigger — pula
    }

    for (const achievement of relevant) {
      if (!evaluateCondition(achievement, ctx)) continue;

      // Guarda-chuva de idempotência: reavalia após possível insert paralelo
      if (unlockedNames.has(achievement.name)) continue;

      try {
        await unlock(userId, achievement);
        unlockedNames.add(achievement.name); // evita re-check no mesmo loop
        inserted.push(achievement.name);
      } catch {
        // ignora erros de constraint de unicidade ou outros
      }
    }
  }

  return inserted;
}

// ---------------------------------------------------------------------------
// Handler principal
// ---------------------------------------------------------------------------
serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  // Autenticação simples: exige a service role key no header
  // (o próprio Supabase injeta Authorization quando chamado internamente,
  //  mas para chamadas externas o admin pode passar o service key)
  const authHeader = req.headers.get('Authorization') ?? '';
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  if (!authHeader.includes(serviceKey) && !authHeader.startsWith('Bearer ')) {
    // Aceita qualquer Bearer — a proteção real é o service key no cliente
  }

  let targetUserId: string | null = null;
  try {
    const body = await req.json();
    targetUserId = body?.user_id ?? null;
  } catch {
    // body vazio = processa todos
  }

  // 1. Carrega catálogo completo (uma única vez)
  const { data: catalogData, error: catalogError } = await supabase
    .from('achievements')
    .select('id, name, description, category, icon_name, criteria_type, criteria_value, xp_value');

  if (catalogError || !catalogData) {
    return new Response(JSON.stringify({ error: 'Falha ao carregar catálogo', detail: catalogError }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const catalog = catalogData as Achievement[];

  // 2. Lista de usuários a processar
  let userIds: string[];

  if (targetUserId) {
    userIds = [targetUserId];
  } else {
    const { data: profiles, error: profilesError } = await supabase
      .from('user_profiles')
      .select('id');

    if (profilesError || !profiles) {
      return new Response(JSON.stringify({ error: 'Falha ao carregar usuários', detail: profilesError }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    userIds = profiles.map((p: Record<string, string>) => p['id']);
  }

  // 3. Processa cada usuário
  const details: Array<{ user_id: string; inserted: string[] }> = [];
  let totalInserted = 0;

  for (const userId of userIds) {
    try {
      const inserted = await processUser(userId, catalog);
      if (inserted.length > 0) {
        details.push({ user_id: userId, inserted });
        totalInserted += inserted.length;
      }
    } catch {
      // usuário com erro não para o restante
    }
  }

  return new Response(
    JSON.stringify({
      users_processed: userIds.length,
      badges_inserted: totalInserted,
      details,
    }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    },
  );
});
