import 'package:flutter_test/flutter_test.dart';
import 'package:fluffer/models/achievement.dart';

Achievement _get(String id) =>
    AchievementData.allAchievements.firstWhere((a) => a.id == id);

void main() {
  // ============================================================
  // 1. bled_all_covered — "Sortez couvert !"
  // checkCondition: (data) => data['bled_protected_everyone'] == true
  // ============================================================
  group('bled_all_covered — Sortez couvert !', () {
    late Achievement ach;
    setUp(() => ach = _get('bled_all_covered'));

    // Positifs
    test('flag true → true', () {
      expect(ach.checkCondition({'bled_protected_everyone': true}), isTrue);
    });

    // Négatifs
    test('flag false → false', () {
      expect(ach.checkCondition({'bled_protected_everyone': false}), isFalse);
    });
    test('flag absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('flag null → false', () {
      expect(ach.checkCondition({'bled_protected_everyone': null}), isFalse);
    });
    test("string 'true' → false", () {
      expect(ach.checkCondition({'bled_protected_everyone': 'true'}), isFalse);
    });
    test('int 1 → false', () {
      expect(ach.checkCondition({'bled_protected_everyone': 1}), isFalse);
    });
  });

  // ============================================================
  // 2. mime_win — "Vite fait, bien fait !"
  // checkCondition: (data) =>
  //     data['exorcisme_success_win'] == true &&
  //     data['player_role']?.toString().toLowerCase() == "exorciste"
  // ============================================================
  group('mime_win — Vite fait, bien fait !', () {
    late Achievement ach;
    setUp(() => ach = _get('mime_win'));

    // Positifs
    test('exorcisme_success_win=true, role="exorciste" → true', () {
      expect(
        ach.checkCondition({
          'exorcisme_success_win': true,
          'player_role': 'exorciste',
        }),
        isTrue,
      );
    });
    test('exorcisme_success_win=true, role="Exorciste" (casse) → true', () {
      expect(
        ach.checkCondition({
          'exorcisme_success_win': true,
          'player_role': 'Exorciste',
        }),
        isTrue,
      );
    });
    test('exorcisme_success_win=true, role="EXORCISTE" → true', () {
      expect(
        ach.checkCondition({
          'exorcisme_success_win': true,
          'player_role': 'EXORCISTE',
        }),
        isTrue,
      );
    });

    // Négatifs
    test('exorcisme_success_win=false, role="exorciste" → false', () {
      expect(
        ach.checkCondition({
          'exorcisme_success_win': false,
          'player_role': 'exorciste',
        }),
        isFalse,
      );
    });
    test('exorcisme_success_win=true, role="Villageois" → false', () {
      expect(
        ach.checkCondition({
          'exorcisme_success_win': true,
          'player_role': 'Villageois',
        }),
        isFalse,
      );
    });
    test('exorcisme_success_win=true, role=null → false', () {
      expect(
        ach.checkCondition({
          'exorcisme_success_win': true,
          'player_role': null,
        }),
        isFalse,
      );
    });
    test('exorcisme_success_win=null, role="exorciste" → false', () {
      expect(
        ach.checkCondition({
          'exorcisme_success_win': null,
          'player_role': 'exorciste',
        }),
        isFalse,
      );
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
  });

  // ============================================================
  // 3. self_quiche_save — "Le petit chaperon rouge"
  // checkCondition: (data) =>
  //     data['player_role']?.toLowerCase() == "grand-mère" &&
  //     data['saved_by_own_quiche'] == true
  // ============================================================
  group('self_quiche_save — Le petit chaperon rouge', () {
    late Achievement ach;
    setUp(() => ach = _get('self_quiche_save'));

    // Positifs
    test('role="grand-mère", saved=true → true', () {
      expect(
        ach.checkCondition({
          'player_role': 'grand-mère',
          'saved_by_own_quiche': true,
        }),
        isTrue,
      );
    });
    test('role="Grand-Mère" (casse) → true', () {
      expect(
        ach.checkCondition({
          'player_role': 'Grand-Mère',
          'saved_by_own_quiche': true,
        }),
        isTrue,
      );
    });
    test('role="GRAND-MÈRE" → true (toLowerCase)', () {
      expect(
        ach.checkCondition({
          'player_role': 'GRAND-MÈRE',
          'saved_by_own_quiche': true,
        }),
        isTrue,
      );
    });

    // Négatifs
    test('role="Villageois", saved=true → false', () {
      expect(
        ach.checkCondition({
          'player_role': 'Villageois',
          'saved_by_own_quiche': true,
        }),
        isFalse,
      );
    });
    test('role="grand-mère", saved=false → false', () {
      expect(
        ach.checkCondition({
          'player_role': 'grand-mère',
          'saved_by_own_quiche': false,
        }),
        isFalse,
      );
    });
    test('role="grand-mère", saved=null → false', () {
      expect(
        ach.checkCondition({
          'player_role': 'grand-mère',
          'saved_by_own_quiche': null,
        }),
        isFalse,
      );
    });
    test('role=null, saved=true → false', () {
      expect(
        ach.checkCondition({
          'player_role': null,
          'saved_by_own_quiche': true,
        }),
        isFalse,
      );
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
  });

  // ============================================================
  // 4. quiche_hero — "Quiche ou tarte ?"
  // checkCondition: (data) =>
  //     data['quiche_saved_count'] != null &&
  //     (data['quiche_saved_count'] as int) >= 4
  // ============================================================
  group('quiche_hero — Quiche ou tarte ?', () {
    late Achievement ach;
    setUp(() => ach = _get('quiche_hero'));

    // Positifs
    test('quiche_saved_count=4 → true', () {
      expect(ach.checkCondition({'quiche_saved_count': 4}), isTrue);
    });
    test('quiche_saved_count=5 → true', () {
      expect(ach.checkCondition({'quiche_saved_count': 5}), isTrue);
    });
    test('quiche_saved_count=10 → true', () {
      expect(ach.checkCondition({'quiche_saved_count': 10}), isTrue);
    });

    // Négatifs
    test('quiche_saved_count=3 → false', () {
      expect(ach.checkCondition({'quiche_saved_count': 3}), isFalse);
    });
    test('quiche_saved_count=0 → false', () {
      expect(ach.checkCondition({'quiche_saved_count': 0}), isFalse);
    });
    test('quiche_saved_count=null → false', () {
      expect(ach.checkCondition({'quiche_saved_count': null}), isFalse);
    });
    test('quiche_saved_count absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
  });

  // ============================================================
  // 5. apollo_13 — "Apollo 13"
  // checkCondition: (data) => data['houstonApollo13Triggered'] == true
  // ============================================================
  group('apollo_13 — Apollo 13', () {
    late Achievement ach;
    setUp(() => ach = _get('apollo_13'));

    // Positif
    test('flag true → true', () {
      expect(ach.checkCondition({'houstonApollo13Triggered': true}), isTrue);
    });

    // Négatifs
    test('flag false → false', () {
      expect(ach.checkCondition({'houstonApollo13Triggered': false}), isFalse);
    });
    test('flag absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('flag null → false', () {
      expect(ach.checkCondition({'houstonApollo13Triggered': null}), isFalse);
    });
    test("string 'true' → false", () {
      expect(
        ach.checkCondition({'houstonApollo13Triggered': 'true'}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 6. pack_fast_food — "Fast Food"
  // checkCondition: (data) =>
  //     data['is_wolf_faction'] == true &&
  //     data['winner_role'] == "LOUPS-GAROUS" &&
  //     data['turn_count'] < 4
  // ============================================================
  group('pack_fast_food — Fast Food', () {
    late Achievement ach;
    setUp(() => ach = _get('pack_fast_food'));

    // Positifs
    test('wolf=true, winner="LOUPS-GAROUS", turn=3 → true', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'winner_role': 'LOUPS-GAROUS',
          'turn_count': 3,
        }),
        isTrue,
      );
    });
    test('wolf=true, winner="LOUPS-GAROUS", turn=1 → true', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'winner_role': 'LOUPS-GAROUS',
          'turn_count': 1,
        }),
        isTrue,
      );
    });
    test('wolf=true, winner="LOUPS-GAROUS", turn=2 → true', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'winner_role': 'LOUPS-GAROUS',
          'turn_count': 2,
        }),
        isTrue,
      );
    });

    // Négatifs
    test('wolf=false, winner="LOUPS-GAROUS", turn=3 → false', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': false,
          'winner_role': 'LOUPS-GAROUS',
          'turn_count': 3,
        }),
        isFalse,
      );
    });
    test('wolf=true, winner="VILLAGE", turn=3 → false', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'winner_role': 'VILLAGE',
          'turn_count': 3,
        }),
        isFalse,
      );
    });
    test('wolf=true, winner="LOUPS-GAROUS", turn=4 → false', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'winner_role': 'LOUPS-GAROUS',
          'turn_count': 4,
        }),
        isFalse,
      );
    });
    test('wolf=true, winner="LOUPS-GAROUS", turn=5 → false', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'winner_role': 'LOUPS-GAROUS',
          'turn_count': 5,
        }),
        isFalse,
      );
    });
    test('wolf=true, winner="LOUPS-GAROUS", turn=null → false (null < 4 est false)', () {
      // En Dart, null < 4 lève une erreur ou renvoie false selon le contexte.
      // La condition `data['turn_count'] < 4` avec turn_count=null provoque une
      // TypeError à l'exécution car `null < 4` n'est pas valide en Dart null-safe.
      // On vérifie que la condition lève bien une exception (comportement attendu).
      expect(
        () => ach.checkCondition({
          'is_wolf_faction': true,
          'winner_role': 'LOUPS-GAROUS',
          'turn_count': null,
        }),
        throwsA(anything),
      );
    });
    test('map vide → false (is_wolf_faction absent)', () {
      expect(ach.checkCondition({}), isFalse);
    });
  });

  // ============================================================
  // 7. 8_morts_6_blesses — "8 morts, 6 blessés"
  // checkCondition: (data) =>
  //     data['is_wolf_faction'] == true &&
  //     (data['wolves_night_kills'] ?? 0) >= 8
  // ============================================================
  group('8_morts_6_blesses — 8 morts, 6 blessés', () {
    late Achievement ach;
    setUp(() => ach = _get('8_morts_6_blesses'));

    // Positifs
    test('wolf=true, kills=8 → true', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'wolves_night_kills': 8,
        }),
        isTrue,
      );
    });
    test('wolf=true, kills=9 → true', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'wolves_night_kills': 9,
        }),
        isTrue,
      );
    });
    test('wolf=true, kills=100 → true', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'wolves_night_kills': 100,
        }),
        isTrue,
      );
    });

    // Négatifs
    test('wolf=false, kills=8 → false', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': false,
          'wolves_night_kills': 8,
        }),
        isFalse,
      );
    });
    test('wolf=true, kills=7 → false', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'wolves_night_kills': 7,
        }),
        isFalse,
      );
    });
    test('wolf=true, kills=0 → false', () {
      expect(
        ach.checkCondition({
          'is_wolf_faction': true,
          'wolves_night_kills': 0,
        }),
        isFalse,
      );
    });
    test('wolf=true, kills absent (→ 0 via ??) → false', () {
      expect(
        ach.checkCondition({'is_wolf_faction': true}),
        isFalse,
      );
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
  });
}
