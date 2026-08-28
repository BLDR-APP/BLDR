import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/club/domain/entities/club_community.dart';

/// Conteúdo editorial do BLDR Club (anúncios e eventos).
abstract class ClubCommunityRepository {
  Future<Result<List<ClubAnnouncement>>> announcements({int limit = 20});

  Future<Result<List<ClubEvent>>> events({int limit = 20});
}
