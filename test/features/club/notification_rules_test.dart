import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/club/domain/entities/notification_category.dart';

void main() {
  test('tipo pelo campo type e, sem ele, pelo título', () {
    expect(NotificationRules.kind('ranking', ''), NotificationKind.ranking);
    expect(NotificationRules.kind('info', 'Pedro reagiu ao seu PR'),
        NotificationKind.reaction);
    expect(NotificationRules.kind('wearable_activity', null),
        NotificationKind.wearable);
    expect(NotificationRules.kind(null, 'Aviso'), NotificationKind.info);
  });

  test('abas Social e Performance; avisos só em Todas', () {
    expect(
        NotificationRules.inTab(
            NotificationKind.follow, NotificationTab.social),
        isTrue);
    expect(
        NotificationRules.inTab(
            NotificationKind.challenge, NotificationTab.performance),
        isTrue);
    expect(
        NotificationRules.inTab(
            NotificationKind.challenge, NotificationTab.social),
        isFalse);
    expect(
        NotificationRules.inTab(NotificationKind.info, NotificationTab.social),
        isFalse);
    expect(NotificationRules.inTab(NotificationKind.info, NotificationTab.all),
        isTrue);
  });

  test('grupos pelo dia do calendário', () {
    final now = DateTime(2026, 11, 19, 0, 30);
    expect(NotificationRules.group(DateTime(2026, 11, 19, 0, 5), now),
        NotificationGroup.today);
    expect(NotificationRules.group(DateTime(2026, 11, 18, 23, 50), now),
        NotificationGroup.yesterday);
    expect(NotificationRules.group(DateTime(2026, 11, 14), now),
        NotificationGroup.thisWeek);
    expect(NotificationRules.group(DateTime(2026, 11, 1), now),
        NotificationGroup.older);
  });
}
