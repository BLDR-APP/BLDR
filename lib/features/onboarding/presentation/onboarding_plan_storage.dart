import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda localmente qual template corresponde a cada dia da semana do
/// plano gerado no onboarding (L4).
///
/// ⚠️ Não existe hoje uma associação treino↔dia real no domínio
/// (BACKLOG_FUNCIONAL.md B8) — isso é o mesmo contorno local usado pelo
/// botão "Adicionar ao plano" do HAVOK. O Dashboard lê daqui pra
/// preencher o hero card com o treino de hoje, mas isso não é uma fonte
/// de verdade do plano semanal — é só o resultado imediato do onboarding.
class OnboardingPlanStorage {
  static const _key = 'onboarding_plan_templates_by_weekday';

  /// [byWeekday] mapeia diaSemana (1..7) -> {'id': templateId, 'name': nome}.
  static Future<void> saveTemplatesByWeekday(
      Map<int, Map<String, String>> byWeekday) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = byWeekday.map((day, t) => MapEntry(day.toString(), t));
    await prefs.setString(_key, json.encode(encoded));
  }

  /// Template associado ao dia de hoje, se o plano do onboarding cobrir.
  static Future<Map<String, String>?> getTodayTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    final decoded = Map<String, dynamic>.from(json.decode(raw));
    final today = DateTime.now().weekday.toString();
    final entry = decoded[today];
    return entry is Map ? Map<String, String>.from(entry) : null;
  }
}
