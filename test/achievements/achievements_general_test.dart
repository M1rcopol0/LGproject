import 'package:flutter_test/flutter_test.dart';
import 'package:fluffer/models/achievement.dart';

Achievement _get(String id) =>
    AchievementData.allAchievements.firstWhere((a) => a.id == id);

void main() {
  // ============================================================
  // 1. lone_wolf — "En solitaire"
  // ============================================================
  group('lone_wolf', () {
    late Achievement a;
    setUp(() => a = _get('lone_wolf'));

    // POSITIF
    test('POSITIF : roles={SOLO:1}, winner_role="ARCHIVISTE" → true', () {
      expect(
        a.checkCondition({'roles': {'SOLO': 1}, 'winner_role': 'ARCHIVISTE'}),
        isTrue,
      );
    });

    test('POSITIF : roles={SOLO:3}, winner_role="DRESSEUR" → true', () {
      expect(
        a.checkCondition({'roles': {'SOLO': 3}, 'winner_role': 'DRESSEUR'}),
        isTrue,
      );
    });

    test('POSITIF : roles={SOLO:1}, winner_role="RON-ALDO" → true', () {
      expect(
        a.checkCondition({'roles': {'SOLO': 1}, 'winner_role': 'RON-ALDO'}),
        isTrue,
      );
    });

    // NÉGATIF
    test('NÉGATIF : roles={SOLO:0}, winner_role="ARCHIVISTE" → false', () {
      expect(
        a.checkCondition({'roles': {'SOLO': 0}, 'winner_role': 'ARCHIVISTE'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={} (SOLO absent → 0), winner_role="ARCHIVISTE" → false', () {
      expect(
        a.checkCondition({'roles': <String, dynamic>{}, 'winner_role': 'ARCHIVISTE'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={SOLO:1}, winner_role="VILLAGE" → false', () {
      expect(
        a.checkCondition({'roles': {'SOLO': 1}, 'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={SOLO:1}, winner_role="LOUPS-GAROUS" → false', () {
      expect(
        a.checkCondition({'roles': {'SOLO': 1}, 'winner_role': 'LOUPS-GAROUS'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={SOLO:1}, winner_role=null → false', () {
      expect(
        a.checkCondition({'roles': {'SOLO': 1}, 'winner_role': null}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={SOLO:1}, winner_role="" → false', () {
      expect(
        a.checkCondition({'roles': {'SOLO': 1}, 'winner_role': ''}),
        isFalse,
      );
    });

    test('NÉGATIF : data["roles"] absent, winner_role="ARCHIVISTE" → false', () {
      expect(
        a.checkCondition({'winner_role': 'ARCHIVISTE'}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 2. village_hero — "Héros du Village"
  // Condition : roles['VILLAGE'] >= 1 AND winner_role == "VILLAGE"
  // ============================================================
  group('village_hero', () {
    late Achievement a;
    setUp(() => a = _get('village_hero'));

    test('POSITIF : roles={VILLAGE:1}, winner_role="VILLAGE" → true', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 1}, 'winner_role': 'VILLAGE'}),
        isTrue,
      );
    });

    test('POSITIF : roles={VILLAGE:5}, winner_role="VILLAGE" → true (cumulatif)', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 5}, 'winner_role': 'VILLAGE'}),
        isTrue,
      );
    });

    test('NÉGATIF : roles={VILLAGE:1}, winner_role="LOUPS-GAROUS" → false (village perd)', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 1}, 'winner_role': 'LOUPS-GAROUS'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={VILLAGE:1}, winner_role=null → false', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 1}, 'winner_role': null}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={VILLAGE:1}, winner_role absent → false', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 1}}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={VILLAGE:0}, winner_role="VILLAGE" → false', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 0}, 'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={}, winner_role="VILLAGE" → false', () {
      expect(
        a.checkCondition({'roles': <String, dynamic>{}, 'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={LOUPS-GAROUS:1}, winner_role="VILLAGE" → false (VILLAGE absent)', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 1}, 'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('NÉGATIF : data["roles"]=null, winner_role="VILLAGE" → false', () {
      expect(
        a.checkCondition({'roles': null, 'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 3. wolf_pack — "Membre de la Meute"
  // Condition : roles['LOUPS-GAROUS'] >= 1 AND winner_role == "LOUPS-GAROUS"
  // ============================================================
  group('wolf_pack', () {
    late Achievement a;
    setUp(() => a = _get('wolf_pack'));

    test('POSITIF : roles={LOUPS-GAROUS:1}, winner_role="LOUPS-GAROUS" → true', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 1}, 'winner_role': 'LOUPS-GAROUS'}),
        isTrue,
      );
    });

    test('POSITIF : roles={LOUPS-GAROUS:5}, winner_role="LOUPS-GAROUS" → true (cumulatif)', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 5}, 'winner_role': 'LOUPS-GAROUS'}),
        isTrue,
      );
    });

    test('NÉGATIF : roles={LOUPS-GAROUS:1}, winner_role="VILLAGE" → false (loups perdent)', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 1}, 'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={LOUPS-GAROUS:1}, winner_role=null → false', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 1}, 'winner_role': null}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={LOUPS-GAROUS:1}, winner_role absent → false', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 1}}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={LOUPS-GAROUS:0}, winner_role="LOUPS-GAROUS" → false', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 0}, 'winner_role': 'LOUPS-GAROUS'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={}, winner_role="LOUPS-GAROUS" → false', () {
      expect(
        a.checkCondition({'roles': <String, dynamic>{}, 'winner_role': 'LOUPS-GAROUS'}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={VILLAGE:1}, winner_role="LOUPS-GAROUS" → false (LOUPS-GAROUS absent)', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 1}, 'winner_role': 'LOUPS-GAROUS'}),
        isFalse,
      );
    });

    test('NÉGATIF : data["roles"]=null, winner_role="LOUPS-GAROUS" → false', () {
      expect(
        a.checkCondition({'roles': null, 'winner_role': 'LOUPS-GAROUS'}),
        isFalse,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 4. canaclean — "Le Canaclean"
  // ============================================================
  group('canaclean', () {
    late Achievement a;
    setUp(() => a = _get('canaclean'));

    test('POSITIF : canaclean_present=true → true', () {
      expect(
        a.checkCondition({'canaclean_present': true}),
        isTrue,
      );
    });

    test('NÉGATIF : canaclean_present=false → false', () {
      expect(
        a.checkCondition({'canaclean_present': false}),
        isFalse,
      );
    });

    test('NÉGATIF : canaclean_present absent → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : canaclean_present=null → false', () {
      expect(
        a.checkCondition({'canaclean_present': null}),
        isFalse,
      );
    });

    test('NÉGATIF : canaclean_present="true" (string) → false', () {
      expect(
        a.checkCondition({'canaclean_present': 'true'}),
        isFalse,
      );
    });

    test('NÉGATIF : canaclean_present=1 (int) → false', () {
      expect(
        a.checkCondition({'canaclean_present': 1}),
        isFalse,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : autre clé présente mais pas canaclean_present → false', () {
      expect(
        a.checkCondition({'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('POSITIF : canaclean_present=true avec autres données → true', () {
      expect(
        a.checkCondition({'canaclean_present': true, 'winner_role': 'VILLAGE', 'turn_count': 5}),
        isTrue,
      );
    });

    test('NÉGATIF : canaclean_present=0 (int) → false', () {
      expect(
        a.checkCondition({'canaclean_present': 0}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 5. choix_cornelien — "Un choix cornélien"
  // ============================================================
  group('choix_cornelien', () {
    late Achievement a;
    setUp(() => a = _get('choix_cornelien'));

    test('POSITIF : choix_valid=true, winner_role="VILLAGE" → true', () {
      expect(
        a.checkCondition({'choix_cornelien_valid': true, 'winner_role': 'VILLAGE'}),
        isTrue,
      );
    });

    test('POSITIF : choix_valid=true, winner_role="LOUPS-GAROUS" → true', () {
      expect(
        a.checkCondition({'choix_cornelien_valid': true, 'winner_role': 'LOUPS-GAROUS'}),
        isTrue,
      );
    });

    test('POSITIF : choix_valid=true, winner_role=0 (int non-null) → true', () {
      expect(
        a.checkCondition({'choix_cornelien_valid': true, 'winner_role': 0}),
        isTrue,
      );
    });

    test('NÉGATIF : choix_valid=false, winner_role="VILLAGE" → false', () {
      expect(
        a.checkCondition({'choix_cornelien_valid': false, 'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('NÉGATIF : choix_valid=true, winner_role=null → false', () {
      expect(
        a.checkCondition({'choix_cornelien_valid': true, 'winner_role': null}),
        isFalse,
      );
    });

    test('NÉGATIF : choix_valid=null, winner_role="VILLAGE" → false', () {
      expect(
        a.checkCondition({'choix_cornelien_valid': null, 'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : choix_valid absent, winner_role="VILLAGE" → false', () {
      expect(
        a.checkCondition({'winner_role': 'VILLAGE'}),
        isFalse,
      );
    });

    test('NÉGATIF : choix_valid=true, winner_role absent → false', () {
      expect(
        a.checkCondition({'choix_cornelien_valid': true}),
        isFalse,
      );
    });

    test('POSITIF : choix_valid=true, winner_role="DRESSEUR" (solo) → true', () {
      expect(
        a.checkCondition({'choix_cornelien_valid': true, 'winner_role': 'DRESSEUR'}),
        isTrue,
      );
    });
  });

  // ============================================================
  // 6. first_blood — "Premier Sang"
  // ============================================================
  group('first_blood', () {
    late Achievement a;
    setUp(() => a = _get('first_blood'));

    test('POSITIF : is_first_blood=true → true', () {
      expect(
        a.checkCondition({'is_first_blood': true}),
        isTrue,
      );
    });

    test('NÉGATIF : is_first_blood=false → false', () {
      expect(
        a.checkCondition({'is_first_blood': false}),
        isFalse,
      );
    });

    test('NÉGATIF : is_first_blood absent → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : is_first_blood=null → false', () {
      expect(
        a.checkCondition({'is_first_blood': null}),
        isFalse,
      );
    });

    test('NÉGATIF : is_first_blood="true" (string) → false', () {
      expect(
        a.checkCondition({'is_first_blood': 'true'}),
        isFalse,
      );
    });

    test('NÉGATIF : is_first_blood=1 (int) → false', () {
      expect(
        a.checkCondition({'is_first_blood': 1}),
        isFalse,
      );
    });

    test('POSITIF : is_first_blood=true avec autres données → true', () {
      expect(
        a.checkCondition({'is_first_blood': true, 'turn_count': 1, 'player_role': 'VILLAGEOIS'}),
        isTrue,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : clé différente, valeur true → false', () {
      expect(
        a.checkCondition({'is_last_blood': true}),
        isFalse,
      );
    });

    test('NÉGATIF : is_first_blood=0 (int) → false', () {
      expect(
        a.checkCondition({'is_first_blood': 0}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 7. first_win — "Première Victoire"
  // ============================================================
  group('first_win', () {
    late Achievement a;
    setUp(() => a = _get('first_win'));

    test('POSITIF : totalWins=1 → true', () {
      expect(
        a.checkCondition({'totalWins': 1}),
        isTrue,
      );
    });

    test('POSITIF : totalWins=10 → true', () {
      expect(
        a.checkCondition({'totalWins': 10}),
        isTrue,
      );
    });

    test('NÉGATIF : totalWins=0 → false', () {
      expect(
        a.checkCondition({'totalWins': 0}),
        isFalse,
      );
    });

    test('NÉGATIF : totalWins absent → false (→ 0)', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : totalWins=null → false (null ?? 0 = 0)', () {
      expect(
        a.checkCondition({'totalWins': null}),
        isFalse,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('POSITIF : totalWins=2 → true', () {
      expect(
        a.checkCondition({'totalWins': 2}),
        isTrue,
      );
    });

    test('POSITIF : totalWins=100 → true', () {
      expect(
        a.checkCondition({'totalWins': 100}),
        isTrue,
      );
    });

    test('NÉGATIF : totalWins=-1 → false (< 1)', () {
      expect(
        a.checkCondition({'totalWins': -1}),
        isFalse,
      );
    });

    test('NÉGATIF : autre clé présente mais totalWins absent → false', () {
      expect(
        a.checkCondition({'player_role': 'VILLAGEOIS'}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 8. louis_croix_v — "Louis croix V bâton"
  // ============================================================
  group('louis_croix_v', () {
    late Achievement a;
    setUp(() => a = _get('louis_croix_v'));

    test('POSITIF : louis_croix_v_triggered=true → true', () {
      expect(
        a.checkCondition({'louis_croix_v_triggered': true}),
        isTrue,
      );
    });

    test('NÉGATIF : louis_croix_v_triggered=false → false', () {
      expect(
        a.checkCondition({'louis_croix_v_triggered': false}),
        isFalse,
      );
    });

    test('NÉGATIF : louis_croix_v_triggered absent → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : louis_croix_v_triggered=null → false', () {
      expect(
        a.checkCondition({'louis_croix_v_triggered': null}),
        isFalse,
      );
    });

    test('NÉGATIF : louis_croix_v_triggered="true" (string) → false', () {
      expect(
        a.checkCondition({'louis_croix_v_triggered': 'true'}),
        isFalse,
      );
    });

    test('NÉGATIF : louis_croix_v_triggered=1 (int) → false', () {
      expect(
        a.checkCondition({'louis_croix_v_triggered': 1}),
        isFalse,
      );
    });

    test('POSITIF : true avec autres données → true', () {
      expect(
        a.checkCondition({'louis_croix_v_triggered': true, 'winner_role': 'VILLAGE'}),
        isTrue,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : autre clé booléenne true → false', () {
      expect(
        a.checkCondition({'is_first_blood': true}),
        isFalse,
      );
    });

    test('NÉGATIF : louis_croix_v_triggered=0 → false', () {
      expect(
        a.checkCondition({'louis_croix_v_triggered': 0}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 9. veteran_village — "Ancien du Village"
  // ============================================================
  group('veteran_village', () {
    late Achievement a;
    setUp(() => a = _get('veteran_village'));

    test('POSITIF : roles={VILLAGE:10} → true', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 10}}),
        isTrue,
      );
    });

    test('POSITIF : roles={VILLAGE:15} → true', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 15}}),
        isTrue,
      );
    });

    test('NÉGATIF : roles={VILLAGE:9} → false', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 9}}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={VILLAGE:0} → false', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 0}}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={} → false', () {
      expect(
        a.checkCondition({'roles': <String, dynamic>{}}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={LOUPS-GAROUS:10} → false (mauvais rôle)', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 10}}),
        isFalse,
      );
    });

    test('NÉGATIF : data["roles"] absent → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={VILLAGE:1} → false (insuffisant)', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 1}}),
        isFalse,
      );
    });

    test('POSITIF : roles={VILLAGE:100} → true', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 100}}),
        isTrue,
      );
    });

    test('NÉGATIF : data["roles"]=null → false', () {
      expect(
        a.checkCondition({'roles': null}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 10. hotel_training — "Formation hôtelière"
  // ============================================================
  group('hotel_training', () {
    late Achievement a;
    setUp(() => a = _get('hotel_training'));

    test('POSITIF : cumulative_hosted_count=10 → true', () {
      expect(
        a.checkCondition({'cumulative_hosted_count': 10}),
        isTrue,
      );
    });

    test('POSITIF : cumulative_hosted_count=20 → true', () {
      expect(
        a.checkCondition({'cumulative_hosted_count': 20}),
        isTrue,
      );
    });

    test('NÉGATIF : cumulative_hosted_count=9 → false', () {
      expect(
        a.checkCondition({'cumulative_hosted_count': 9}),
        isFalse,
      );
    });

    test('NÉGATIF : cumulative_hosted_count=0 → false', () {
      expect(
        a.checkCondition({'cumulative_hosted_count': 0}),
        isFalse,
      );
    });

    test('NÉGATIF : cumulative_hosted_count absent → false (→ 0)', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : cumulative_hosted_count=null → false (null ?? 0 = 0)', () {
      expect(
        a.checkCondition({'cumulative_hosted_count': null}),
        isFalse,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('POSITIF : cumulative_hosted_count=100 → true', () {
      expect(
        a.checkCondition({'cumulative_hosted_count': 100}),
        isTrue,
      );
    });

    test('NÉGATIF : cumulative_hosted_count=1 → false', () {
      expect(
        a.checkCondition({'cumulative_hosted_count': 1}),
        isFalse,
      );
    });

    test('NÉGATIF : autre clé numérique ≥ 10 → false si hosted_count absent', () {
      expect(
        a.checkCondition({'cumulative_travels': 10}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 11. terminator_travel — "I'll be back."
  // ============================================================
  group('terminator_travel', () {
    late Achievement a;
    setUp(() => a = _get('terminator_travel'));

    test('POSITIF : cumulative_travels=5 → true', () {
      expect(
        a.checkCondition({'cumulative_travels': 5}),
        isTrue,
      );
    });

    test('POSITIF : cumulative_travels=10 → true', () {
      expect(
        a.checkCondition({'cumulative_travels': 10}),
        isTrue,
      );
    });

    test('NÉGATIF : cumulative_travels=4 → false', () {
      expect(
        a.checkCondition({'cumulative_travels': 4}),
        isFalse,
      );
    });

    test('NÉGATIF : cumulative_travels=0 → false', () {
      expect(
        a.checkCondition({'cumulative_travels': 0}),
        isFalse,
      );
    });

    test('NÉGATIF : cumulative_travels absent → false (→ 0)', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : cumulative_travels=null → false (null ?? 0 = 0)', () {
      expect(
        a.checkCondition({'cumulative_travels': null}),
        isFalse,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('POSITIF : cumulative_travels=50 → true', () {
      expect(
        a.checkCondition({'cumulative_travels': 50}),
        isTrue,
      );
    });

    test('NÉGATIF : cumulative_travels=1 → false', () {
      expect(
        a.checkCondition({'cumulative_travels': 1}),
        isFalse,
      );
    });

    test('NÉGATIF : cumulative_travels=-1 → false', () {
      expect(
        a.checkCondition({'cumulative_travels': -1}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 12. villageois_eternal — "On pouvait pas redistribuer les rôles ?"
  // ============================================================
  group('villageois_eternal', () {
    late Achievement a;
    setUp(() => a = _get('villageois_eternal'));

    test('POSITIF : roleGamesPlayed={VILLAGEOIS:5} → true', () {
      expect(
        a.checkCondition({'roleGamesPlayed': {'VILLAGEOIS': 5}}),
        isTrue,
      );
    });

    test('POSITIF : roleGamesPlayed={VILLAGEOIS:10} → true', () {
      expect(
        a.checkCondition({'roleGamesPlayed': {'VILLAGEOIS': 10}}),
        isTrue,
      );
    });

    test('NÉGATIF : roleGamesPlayed={VILLAGEOIS:4} → false', () {
      expect(
        a.checkCondition({'roleGamesPlayed': {'VILLAGEOIS': 4}}),
        isFalse,
      );
    });

    test('NÉGATIF : roleGamesPlayed={VILLAGEOIS:0} → false', () {
      expect(
        a.checkCondition({'roleGamesPlayed': {'VILLAGEOIS': 0}}),
        isFalse,
      );
    });

    test('NÉGATIF : roleGamesPlayed={} → false (VILLAGEOIS absent → 0)', () {
      expect(
        a.checkCondition({'roleGamesPlayed': <String, dynamic>{}}),
        isFalse,
      );
    });

    test('NÉGATIF : roleGamesPlayed={LOUPS-GAROUS:10} → false (mauvais rôle)', () {
      expect(
        a.checkCondition({'roleGamesPlayed': {'LOUPS-GAROUS': 10}}),
        isFalse,
      );
    });

    test('NÉGATIF : data["roleGamesPlayed"] absent → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : map vide → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('POSITIF : roleGamesPlayed={VILLAGEOIS:5} inclut victoires ET défaites → true', () {
      // Ce succès compte les parties jouées, pas uniquement les victoires
      expect(
        a.checkCondition({'roleGamesPlayed': {'VILLAGEOIS': 5}, 'winner_role': 'LOUPS-GAROUS'}),
        isTrue,
      );
    });

    test('NÉGATIF : roleGamesPlayed={VILLAGEOIS:4, LOUPS-GAROUS:10} → false (VILLAGEOIS < 5)', () {
      expect(
        a.checkCondition({'roleGamesPlayed': {'VILLAGEOIS': 4, 'LOUPS-GAROUS': 10}}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 13. veteran_wolf — "Vétéran de la Meute"
  // ============================================================
  group('veteran_wolf', () {
    late Achievement a;
    setUp(() => a = _get('veteran_wolf'));

    test('POSITIF : roles={LOUPS-GAROUS:10} → true', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 10}}),
        isTrue,
      );
    });

    test('POSITIF : roles={LOUPS-GAROUS:25} → true', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 25}}),
        isTrue,
      );
    });

    test('NÉGATIF : roles={LOUPS-GAROUS:9} → false', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 9}}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={LOUPS-GAROUS:0} → false', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 0}}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={VILLAGE:10} → false (mauvaise faction)', () {
      expect(
        a.checkCondition({'roles': {'VILLAGE': 10}}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={} → false', () {
      expect(
        a.checkCondition({'roles': <String, dynamic>{}}),
        isFalse,
      );
    });

    test('NÉGATIF : data["roles"] absent → false', () {
      expect(
        a.checkCondition(<String, dynamic>{}),
        isFalse,
      );
    });

    test('NÉGATIF : roles={LOUPS-GAROUS:1} → false (insuffisant)', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 1}}),
        isFalse,
      );
    });

    test('POSITIF : roles={LOUPS-GAROUS:10, VILLAGE:1} → true (LOUPS-GAROUS ≥ 10)', () {
      expect(
        a.checkCondition({'roles': {'LOUPS-GAROUS': 10, 'VILLAGE': 1}}),
        isTrue,
      );
    });

    test('NÉGATIF : data["roles"]=null → false', () {
      expect(
        a.checkCondition({'roles': null}),
        isFalse,
      );
    });
  });
}
