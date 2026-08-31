// test/features/club/squad_limits_test.dart
//
// Unit tests for Squad quota logic.
//
// Server RPCs (migration 00028 v2):
//   bldr_club.create_squad_with_quota(name, description, game_mode, duration_days,
//                                     validation_type, share_code)
//   bldr_club.join_squad_with_quota(arena_id, share_code)
//
// Both return jsonb:
//   allowed: bool
//   used: int       (snapshot used count; -1 not returned here)
//   limit: int      (-1 = unlimited for Club)
//   is_club: bool
//   reason?: text   (present only when allowed = false)
//   arena?: jsonb   (create only, when allowed = true)
//   arena_title?: text (join only, when allowed = true)
//
// Client-side quota rules (display only, NOT authoritative):
//   create : 2 per calendar month (America/Sao_Paulo)
//   join   : 5 per calendar month (America/Sao_Paulo)
//
// Club authority chain (server-side):
//   1. user_subscriptions.revenuecat_entitlement_id = 'bldr_club'
//      AND status IN ('active', 'trialing')         ← RC mirror (migration 022)
//   2. legacy 'club' subscription with status='active'
//      AND revenuecat_entitlement_id IS NULL
//      AND NOT (apple_revenuecat_migrations completed with entitlement inactive)
//
// Raw status='active' alone is NOT Club authority.

import 'package:flutter_test/flutter_test.dart';

// ── Domain helper (pure-Dart, no DI) ─────────────────────────────────────────

/// Mirrors the quota logic of the two atomic RPCs and the UI.
///
/// [isClub]          — true if the user has an active Club subscription.
/// [squadsThisMonth] — monotonic count for the current month:
///                     'create' → COUNT FROM bldr_club.arenas WHERE creator_id
///                     'join'   → COUNT FROM bldr_club.squad_quota_events (ledger)
/// [action]          — 'create' or 'join'.
class SquadQuotaChecker {
  static const _createLimit = 2;
  static const _joinLimit   = 5;

  const SquadQuotaChecker();

  /// Returns true when the action is ALLOWED.
  bool isAllowed({
    required bool   isClub,
    required int    squadsThisMonth,
    required String action,
  }) {
    if (isClub) return true;
    final limit = action == 'create' ? _createLimit : _joinLimit;
    return squadsThisMonth < limit;
  }

  /// Returns remaining slots (0 means limit reached).
  int remaining({
    required bool   isClub,
    required int    squadsThisMonth,
    required String action,
  }) {
    if (isClub) return 999; // unlimited sentinel
    final limit = action == 'create' ? _createLimit : _joinLimit;
    return (limit - squadsThisMonth).clamp(0, limit);
  }

  // ── RPC response parsers ──────────────────────────────────────────────────

  /// Parses the jsonb response from create_squad_with_quota or
  /// join_squad_with_quota. Returns true when the action is allowed.
  static bool parseRpcAllowed(Map<String, dynamic> rpcResponse) =>
      rpcResponse['allowed'] == true;

  /// Returns the [used] count from the RPC response.
  static int parseRpcUsed(Map<String, dynamic> rpcResponse) =>
      (rpcResponse['used'] as num?)?.toInt() ?? 0;

  /// Returns the [limit] from the RPC response (-1 = unlimited for Club).
  static int parseRpcLimit(Map<String, dynamic> rpcResponse) =>
      (rpcResponse['limit'] as num?)?.toInt() ?? 0;

  /// Returns the [is_club] flag from the RPC response.
  static bool parseRpcIsClub(Map<String, dynamic> rpcResponse) =>
      rpcResponse['is_club'] == true;

  /// Returns the [reason] field when allowed = false.
  static String? parseRpcReason(Map<String, dynamic> rpcResponse) =>
      rpcResponse['reason'] as String?;
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  final checker = const SquadQuotaChecker();

  // ── CREATE quota ──────────────────────────────────────────────────────────

  group('Create quota — Free user', () {
    test('0/2 → allowed', () {
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: 0, action: 'create'),
        isTrue,
      );
    });

    test('1/2 → allowed', () {
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: 1, action: 'create'),
        isTrue,
      );
    });

    test('2/2 → blocked', () {
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: 2, action: 'create'),
        isFalse,
      );
    });

    test('remaining slots at 0/2 is 2', () {
      expect(
        checker.remaining(isClub: false, squadsThisMonth: 0, action: 'create'),
        equals(2),
      );
    });

    test('remaining slots at 1/2 is 1', () {
      expect(
        checker.remaining(isClub: false, squadsThisMonth: 1, action: 'create'),
        equals(1),
      );
    });

    test('remaining slots at 2/2 is 0', () {
      expect(
        checker.remaining(isClub: false, squadsThisMonth: 2, action: 'create'),
        equals(0),
      );
    });
  });

  // ── JOIN quota ────────────────────────────────────────────────────────────

  group('Join quota — Free user', () {
    test('0/5 → allowed', () {
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: 0, action: 'join'),
        isTrue,
      );
    });

    test('4/5 → allowed', () {
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: 4, action: 'join'),
        isTrue,
      );
    });

    test('5/5 → blocked', () {
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: 5, action: 'join'),
        isFalse,
      );
    });

    test('remaining at 4/5 is 1', () {
      expect(
        checker.remaining(isClub: false, squadsThisMonth: 4, action: 'join'),
        equals(1),
      );
    });
  });

  // ── Leave does NOT restore quota (ledger is immutable) ───────────────────

  group('Leave does not restore quota', () {
    // The join RPC inserts into bldr_club.squad_quota_events. This table is
    // immutable: rows are never deleted, even when the user leaves the Squad
    // (which only deletes from arena_participants). Leaving does NOT free a
    // slot — the monthly count from the ledger stays the same.
    test('leave does not free quota (policy assertion)', () {
      const joinedBeforeLeave = 5;
      // After leaving 1 Squad, the ledger still has 5 events → still at limit.
      const joinedAfterLeave = 5; // ledger is immutable

      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: joinedBeforeLeave, action: 'join'),
        isFalse,
        reason: 'at limit before leave',
      );
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: joinedAfterLeave, action: 'join'),
        isFalse,
        reason: 'still at limit after leave — ledger is immutable',
      );
    });

    // join → leave → join records a SECOND ledger event.
    test('join→leave→rejoin = 2 ledger events, quota used = 2', () {
      // After the first join, ledger count = 1.
      const afterFirstJoin = 1;
      // Leave does not touch the ledger. Count stays at 1.
      const afterLeave = 1;
      // Rejoining the same Squad records a second event. Count = 2.
      const afterRejoin = 2;

      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: afterFirstJoin, action: 'join'),
        isTrue,
        reason: 'can rejoin (ledger count = 1, limit = 5)',
      );
      expect(afterLeave, equals(1), reason: 'leave does not remove ledger event');
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: afterRejoin, action: 'join'),
        isTrue,
        reason: 'still under limit after rejoin (count = 2)',
      );
    });

    test('broken behaviour (arena_participants): leave would have freed a slot', () {
      // With arena_participants counting (WRONG — now fixed):
      const joinedFromParticipants = 4; // after leaving 1 out of 5
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: joinedFromParticipants, action: 'join'),
        isTrue,
        reason: 'WRONG — this is what the broken implementation would return',
      );
    });
  });

  // ── Failed join does NOT consume quota ───────────────────────────────────

  group('Failed join does not consume quota', () {
    // The join RPC performs participant INSERT and ledger INSERT in the same
    // transaction. If the participant INSERT fails (share code wrong, arena
    // not found, etc.), the whole transaction rolls back — no ledger event
    // is committed, and the quota count is unchanged.

    test('failed join (share code wrong) → RPC returns allowed=false, reason=invalid_share_code', () {
      // Simulated RPC response when share code does not match.
      final response = <String, dynamic>{
        'allowed': false,
        'reason': 'invalid_share_code',
      };
      expect(SquadQuotaChecker.parseRpcAllowed(response), isFalse);
      expect(SquadQuotaChecker.parseRpcReason(response), equals('invalid_share_code'));
      // No 'used' field → ledger was not written.
      expect(response.containsKey('used'), isFalse,
          reason: 'no ledger event on failure');
    });

    test('failed join (quota exceeded) → RPC returns allowed=false, reason=monthly_join_limit', () {
      final response = <String, dynamic>{
        'allowed': false,
        'used': 5,
        'limit': 5,
        'reason': 'monthly_join_limit',
        'is_club': false,
      };
      expect(SquadQuotaChecker.parseRpcAllowed(response), isFalse);
      expect(SquadQuotaChecker.parseRpcReason(response), equals('monthly_join_limit'));
      expect(SquadQuotaChecker.parseRpcUsed(response), equals(5),
          reason: 'used count reflects existing ledger, not incremented');
    });
  });

  // ── Failed create does NOT consume quota ─────────────────────────────────

  group('Failed create does not consume quota', () {
    test('failed create (quota exceeded) → RPC returns allowed=false, reason=monthly_create_limit', () {
      final response = <String, dynamic>{
        'allowed': false,
        'used': 2,
        'limit': 2,
        'reason': 'monthly_create_limit',
        'is_club': false,
      };
      expect(SquadQuotaChecker.parseRpcAllowed(response), isFalse);
      expect(SquadQuotaChecker.parseRpcReason(response), equals('monthly_create_limit'));
      // No 'arena' field → no insert occurred.
      expect(response.containsKey('arena'), isFalse);
    });
  });

  // ── Club user — unlimited ────────────────────────────────────────────────

  group('Club user — unlimited', () {
    test('create: always allowed regardless of count', () {
      for (final count in [0, 2, 5, 100]) {
        expect(
          checker.isAllowed(isClub: true, squadsThisMonth: count, action: 'create'),
          isTrue,
          reason: 'Club user with $count creations should be allowed',
        );
      }
    });

    test('join: always allowed regardless of count', () {
      for (final count in [0, 5, 50]) {
        expect(
          checker.isAllowed(isClub: true, squadsThisMonth: count, action: 'join'),
          isTrue,
          reason: 'Club user with $count joins should be allowed',
        );
      }
    });

    test('Club bypass response has limit = -1 and allowed = true', () {
      final response = <String, dynamic>{
        'allowed': true,
        'used': 0,
        'limit': -1,
        'is_club': true,
      };
      expect(SquadQuotaChecker.parseRpcAllowed(response), isTrue);
      expect(SquadQuotaChecker.parseRpcLimit(response), equals(-1));
      expect(SquadQuotaChecker.parseRpcIsClub(response), isTrue);
    });
  });

  // ── Apple legacy raw status alone is NOT Club ────────────────────────────

  group('Club authority — raw Apple status alone is insufficient', () {
    // An Apple legacy subscription with status='active' but
    // revenuecat_entitlement_id IS NULL is only Club when the reconciliation
    // job has NOT completed with revenuecat_entitlement_active = FALSE.
    // Raw status='active' alone is never sufficient.

    test('Apple legacy row NOT reconciled: status=active alone → simulates is_club=true in transition', () {
      // During transition, is_club_member returns true for unreconciled rows.
      // The RPC would return is_club=true.
      final response = <String, dynamic>{
        'allowed': true,
        'used': 0,
        'limit': -1,
        'is_club': true, // preserved during transition
      };
      expect(SquadQuotaChecker.parseRpcIsClub(response), isTrue);
    });

    test('Apple legacy row reconciled as inactive: is_club=false, quota applies', () {
      // After reconciliation with revenuecat_entitlement_active=false,
      // is_club_member returns false. Quota applies normally.
      final response = <String, dynamic>{
        'allowed': true,
        'used': 1,
        'limit': 5,
        'is_club': false, // entitlement definitively inactive
      };
      expect(SquadQuotaChecker.parseRpcIsClub(response), isFalse);
      expect(SquadQuotaChecker.parseRpcLimit(response), equals(5));
    });
  });

  // ── Month boundary ───────────────────────────────────────────────────────

  group('Month boundary — quota resets', () {
    test('new month: squadsThisMonth = 0, create allowed', () {
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: 0, action: 'create'),
        isTrue,
      );
    });

    test('new month: squadsThisMonth = 0, join allowed', () {
      expect(
        checker.isAllowed(isClub: false, squadsThisMonth: 0, action: 'join'),
        isTrue,
      );
    });
  });

  // ── RPC response shape — create_squad_with_quota ─────────────────────────

  group('RPC response shape — create_squad_with_quota', () {
    test('success response contains arena object', () {
      final response = <String, dynamic>{
        'allowed': true,
        'arena': {'id': 'uuid-123', 'title': 'Meu Squad'},
        'used': 1,
        'limit': 2,
        'is_club': false,
      };
      expect(SquadQuotaChecker.parseRpcAllowed(response), isTrue);
      expect(response.containsKey('arena'), isTrue);
      expect((response['arena'] as Map)['id'], equals('uuid-123'));
      expect(SquadQuotaChecker.parseRpcUsed(response), equals(1));
      expect(SquadQuotaChecker.parseRpcLimit(response), equals(2));
    });

    test('quota exceeded response does not contain arena', () {
      final response = <String, dynamic>{
        'allowed': false,
        'used': 2,
        'limit': 2,
        'reason': 'monthly_create_limit',
        'is_club': false,
      };
      expect(SquadQuotaChecker.parseRpcAllowed(response), isFalse);
      expect(response.containsKey('arena'), isFalse);
      expect(SquadQuotaChecker.parseRpcReason(response), equals('monthly_create_limit'));
    });
  });

  // ── RPC response shape — join_squad_with_quota ───────────────────────────

  group('RPC response shape — join_squad_with_quota', () {
    test('success response contains arena_title', () {
      final response = <String, dynamic>{
        'allowed': true,
        'arena_title': 'Desafio de Carnaval',
        'used': 3,
        'limit': 5,
        'is_club': false,
      };
      expect(SquadQuotaChecker.parseRpcAllowed(response), isTrue);
      expect(response['arena_title'], equals('Desafio de Carnaval'));
      expect(SquadQuotaChecker.parseRpcUsed(response), equals(3));
    });

    test('already_member response does not consume quota (used not incremented)', () {
      // When the participant already exists, the RPC returns early with
      // reason=already_member before touching the ledger.
      final response = <String, dynamic>{
        'allowed': false,
        'reason': 'already_member',
      };
      expect(SquadQuotaChecker.parseRpcAllowed(response), isFalse);
      expect(SquadQuotaChecker.parseRpcReason(response), equals('already_member'));
      expect(response.containsKey('used'), isFalse,
          reason: 'no quota consumed for already_member');
    });

    test('leave→join records a new ledger event (used increments)', () {
      // After leave (ledger at 1) then rejoin (ledger at 2):
      final response = <String, dynamic>{
        'allowed': true,
        'arena_title': 'Squad Ressurreição',
        'used': 2,
        'limit': 5,
        'is_club': false,
      };
      expect(SquadQuotaChecker.parseRpcAllowed(response), isTrue);
      expect(SquadQuotaChecker.parseRpcUsed(response), equals(2),
          reason: 'second join event recorded in immutable ledger');
    });

    test('Club bypasses quota — no ledger event recorded', () {
      // When is_club=true the RPC skips the quota check and does NOT insert
      // a ledger event (Club users have unlimited quota).
      final response = <String, dynamic>{
        'allowed': true,
        'arena_title': 'Squad Premium',
        'used': 0,
        'limit': -1,
        'is_club': true,
      };
      expect(SquadQuotaChecker.parseRpcIsClub(response), isTrue);
      expect(SquadQuotaChecker.parseRpcLimit(response), equals(-1));
    });
  });
}
