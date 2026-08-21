import 'package:bldr_fitness/features/achievements/domain/entities/achievement.dart';

/// Mapper TRANSITÓRIO: formato de map que os widgets de conquistas ainda
/// renderizam. Remover quando os widgets forem tipados. Não usar em código novo.
Map<String, dynamic> achievementToLegacyMap(Achievement a) => {
      'id': a.id,
      'name': a.name,
      'description': a.description,
      'category': a.category,
      'icon_name': a.iconName,
      'xp_value': a.xpValue,
      'criteria_type': a.criteriaType,
      'criteria_value': a.criteriaValue,
    };
