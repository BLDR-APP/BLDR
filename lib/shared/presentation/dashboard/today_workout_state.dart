/// Estado do card "Treino de hoje" (Home v2). Função pura — testada.
/// Aplica, na ordem, as regras que o app já tinha:
/// treino não concluído → concluído hoje → template no plano de hoje →
/// `PlanDay.isRestDay` → sem plano.
enum TodayWorkoutState { inProgress, done, planned, rest, noPlan }

TodayWorkoutState resolveTodayWorkoutState({
  required bool hasUnfinishedWorkout,
  required bool completedToday,
  required bool hasTodayTemplate,
  required bool todayIsRestDay,
}) {
  if (hasUnfinishedWorkout) return TodayWorkoutState.inProgress;
  if (completedToday) return TodayWorkoutState.done;
  if (hasTodayTemplate) return TodayWorkoutState.planned;
  if (todayIsRestDay) return TodayWorkoutState.rest;
  return TodayWorkoutState.noPlan;
}
