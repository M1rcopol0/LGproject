import 'package:flutter_test/flutter_test.dart';
import 'package:fluffer/models/achievement.dart';

Achievement _get(String id) =>
    AchievementData.allAchievements.firstWhere((a) => a.id == id);

void main() {
  // ============================================================
  // 1. archiviste_king — "Le roi du CDI"
  // checkCondition: (data) => data['archiviste_king_qualified'] == true,
  // ============================================================
  group('archiviste_king', () {
    late Achievement achievement;
    setUp(() => achievement = _get('archiviste_king'));

    test('flag true → true', () {
      expect(achievement.checkCondition({'archiviste_king_qualified': true}), isTrue);
    });

    test('flag false → false', () {
      expect(achievement.checkCondition({'archiviste_king_qualified': false}), isFalse);
    });

    test('flag absent → false', () {
      expect(achievement.checkCondition({}), isFalse);
    });

    test('flag null → false', () {
      expect(achievement.checkCondition({'archiviste_king_qualified': null}), isFalse);
    });

    test("valeur string 'true' → false", () {
      expect(achievement.checkCondition({'archiviste_king_qualified': 'true'}), isFalse);
    });

    test('valeur entier 1 → false', () {
      expect(achievement.checkCondition({'archiviste_king_qualified': 1}), isFalse);
    });

    test('map avec clé différente → false', () {
      expect(achievement.checkCondition({'archiviste_prince_qualified': true}), isFalse);
    });
  });

  // ============================================================
  // 2. archiviste_prince — "Le prince du CDI"
  // checkCondition: (data) => data['archiviste_prince_qualified'] == true,
  // ============================================================
  group('archiviste_prince', () {
    late Achievement achievement;
    setUp(() => achievement = _get('archiviste_prince'));

    test('flag true → true', () {
      expect(achievement.checkCondition({'archiviste_prince_qualified': true}), isTrue);
    });

    test('flag false → false', () {
      expect(achievement.checkCondition({'archiviste_prince_qualified': false}), isFalse);
    });

    test('flag absent → false', () {
      expect(achievement.checkCondition({}), isFalse);
    });

    test('flag null → false', () {
      expect(achievement.checkCondition({'archiviste_prince_qualified': null}), isFalse);
    });

    test("valeur string 'true' → false", () {
      expect(achievement.checkCondition({'archiviste_prince_qualified': 'true'}), isFalse);
    });

    test('valeur entier 1 → false', () {
      expect(achievement.checkCondition({'archiviste_prince_qualified': 1}), isFalse);
    });

    test('map avec clé king au lieu de prince → false', () {
      expect(achievement.checkCondition({'archiviste_king_qualified': true}), isFalse);
    });
  });

  // ============================================================
  // 3. cha_cha_smooth — "Cha cha real smooth"
  // checkCondition: (data) =>
  //   (data['player_role']?.toString().toLowerCase().contains("archiviste") ?? false) &&
  //   (data['winner_role']?.toString().toUpperCase() == "ARCHIVISTE" ||
  //    data['winner_role']?.toString().toUpperCase() == "SOLO") &&
  //   data['team']?.toString().toLowerCase() == "solo",
  // ============================================================
  group('cha_cha_smooth', () {
    late Achievement achievement;
    setUp(() => achievement = _get('cha_cha_smooth'));

    test('POSITIF : role="Archiviste", winner_role="ARCHIVISTE", team="solo" → true', () {
      expect(achievement.checkCondition({
        'player_role': 'Archiviste',
        'winner_role': 'ARCHIVISTE',
        'team': 'solo',
      }), isTrue);
    });

    test('POSITIF : role="Archiviste", winner_role="SOLO", team="solo" → true', () {
      expect(achievement.checkCondition({
        'player_role': 'Archiviste',
        'winner_role': 'SOLO',
        'team': 'solo',
      }), isTrue);
    });

    test('POSITIF : role="archiviste" (minuscule), winner_role="ARCHIVISTE", team="solo" → true', () {
      expect(achievement.checkCondition({
        'player_role': 'archiviste',
        'winner_role': 'ARCHIVISTE',
        'team': 'solo',
      }), isTrue);
    });

    test('POSITIF : role="ARCHIVISTE" (majuscules), winner_role="archiviste", team="solo" → true', () {
      expect(achievement.checkCondition({
        'player_role': 'ARCHIVISTE',
        'winner_role': 'archiviste',
        'team': 'solo',
      }), isTrue);
    });

    test('POSITIF : role="Archiviste Pro" (contains), winner_role="ARCHIVISTE", team="solo" → true', () {
      expect(achievement.checkCondition({
        'player_role': 'Archiviste Pro',
        'winner_role': 'ARCHIVISTE',
        'team': 'solo',
      }), isTrue);
    });

    test('NÉGATIF : role="Loup-garou", winner_role="ARCHIVISTE", team="solo" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'Loup-garou',
        'winner_role': 'ARCHIVISTE',
        'team': 'solo',
      }), isFalse);
    });

    test('NÉGATIF : role="Archiviste", winner_role="VILLAGE", team="solo" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'Archiviste',
        'winner_role': 'VILLAGE',
        'team': 'solo',
      }), isFalse);
    });

    test('NÉGATIF : role="Archiviste", winner_role="ARCHIVISTE", team="village" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'Archiviste',
        'winner_role': 'ARCHIVISTE',
        'team': 'village',
      }), isFalse);
    });

    test('NÉGATIF : role=null, winner_role="ARCHIVISTE", team="solo" → false', () {
      expect(achievement.checkCondition({
        'player_role': null,
        'winner_role': 'ARCHIVISTE',
        'team': 'solo',
      }), isFalse);
    });

    test('NÉGATIF : role="Archiviste", winner_role=null, team="solo" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'Archiviste',
        'winner_role': null,
        'team': 'solo',
      }), isFalse);
    });
  });

  // ============================================================
  // 4. double_check_devin — "Il fallait en être sûr..."
  // checkCondition: (data) => data['devin_revealed_same_twice'] == true,
  // ============================================================
  group('double_check_devin', () {
    late Achievement achievement;
    setUp(() => achievement = _get('double_check_devin'));

    test('flag true → true', () {
      expect(achievement.checkCondition({'devin_revealed_same_twice': true}), isTrue);
    });

    test('flag false → false', () {
      expect(achievement.checkCondition({'devin_revealed_same_twice': false}), isFalse);
    });

    test('flag absent → false', () {
      expect(achievement.checkCondition({}), isFalse);
    });

    test('flag null → false', () {
      expect(achievement.checkCondition({'devin_revealed_same_twice': null}), isFalse);
    });

    test("valeur string 'true' → false", () {
      expect(achievement.checkCondition({'devin_revealed_same_twice': 'true'}), isFalse);
    });

    test('valeur entier 1 → false', () {
      expect(achievement.checkCondition({'devin_revealed_same_twice': 1}), isFalse);
    });

    test('map vide → false', () {
      expect(achievement.checkCondition({}), isFalse);
    });
  });

  // ============================================================
  // 5. messmerde — "Messmerde"
  // checkCondition: (data) =>
  //   data['player_role']?.toLowerCase() == "devin" &&
  //   data['is_player_alive'] == true &&
  //   (data['devin_reveals_count'] ?? 0) == 0 &&
  //   data['winner_role'] != null,
  // ============================================================
  group('messmerde', () {
    late Achievement achievement;
    setUp(() => achievement = _get('messmerde'));

    test('POSITIF : role="devin", alive=true, reveals=0, winner_role="VILLAGE" → true', () {
      expect(achievement.checkCondition({
        'player_role': 'devin',
        'is_player_alive': true,
        'devin_reveals_count': 0,
        'winner_role': 'VILLAGE',
      }), isTrue);
    });

    test('POSITIF : role="Devin" (capitale), alive=true, reveals=0, winner_role="LOUPS-GAROUS" → true', () {
      expect(achievement.checkCondition({
        'player_role': 'Devin',
        'is_player_alive': true,
        'devin_reveals_count': 0,
        'winner_role': 'LOUPS-GAROUS',
      }), isTrue);
    });

    test('POSITIF : role="devin", alive=true, reveals absent (null → 0), winner_role="VILLAGE" → true', () {
      expect(achievement.checkCondition({
        'player_role': 'devin',
        'is_player_alive': true,
        'winner_role': 'VILLAGE',
      }), isTrue);
    });

    test('NÉGATIF : role="Villageois", alive=true, reveals=0, winner_role="VILLAGE" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'Villageois',
        'is_player_alive': true,
        'devin_reveals_count': 0,
        'winner_role': 'VILLAGE',
      }), isFalse);
    });

    test('NÉGATIF : role="devin", alive=false, reveals=0, winner_role="VILLAGE" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'devin',
        'is_player_alive': false,
        'devin_reveals_count': 0,
        'winner_role': 'VILLAGE',
      }), isFalse);
    });

    test('NÉGATIF : role="devin", alive=true, reveals=1, winner_role="VILLAGE" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'devin',
        'is_player_alive': true,
        'devin_reveals_count': 1,
        'winner_role': 'VILLAGE',
      }), isFalse);
    });

    test('NÉGATIF : role="devin", alive=true, reveals=0, winner_role=null → false', () {
      expect(achievement.checkCondition({
        'player_role': 'devin',
        'is_player_alive': true,
        'devin_reveals_count': 0,
        'winner_role': null,
      }), isFalse);
    });

    test('NÉGATIF : map vide → false', () {
      expect(achievement.checkCondition({}), isFalse);
    });
  });

  // ============================================================
  // 6. crazy_dingo_vote — "Le plus taré des dingos"
  // checkCondition: (data) =>
  //   data['player_role']?.toString().toLowerCase() == "dingo" &&
  //   data['dingo_self_voted_all_game'] == true &&
  //   data['is_player_alive'] == true &&
  //   data['winner_role'] != null,
  // ============================================================
  group('crazy_dingo_vote', () {
    late Achievement achievement;
    setUp(() => achievement = _get('crazy_dingo_vote'));

    test('POSITIF : role="dingo", self_voted=true, alive=true, winner_role="VILLAGE", vote_anonyme=true → true', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_self_voted_all_game': true,
        'is_player_alive': true,
        'winner_role': 'VILLAGE',
        'vote_anonyme': true,
      }), isTrue);
    });

    test('POSITIF : role="Dingo" (casse différente), self_voted=true, alive=true, winner_role="LOUPS-GAROUS", vote_anonyme=true → true', () {
      expect(achievement.checkCondition({
        'player_role': 'Dingo',
        'dingo_self_voted_all_game': true,
        'is_player_alive': true,
        'winner_role': 'LOUPS-GAROUS',
        'vote_anonyme': true,
      }), isTrue);
    });

    test('NÉGATIF : role="Villageois", self_voted=true, alive=true, winner_role="VILLAGE" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'Villageois',
        'dingo_self_voted_all_game': true,
        'is_player_alive': true,
        'winner_role': 'VILLAGE',
      }), isFalse);
    });

    test('NÉGATIF : role="dingo", self_voted=false, alive=true, winner_role="VILLAGE" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_self_voted_all_game': false,
        'is_player_alive': true,
        'winner_role': 'VILLAGE',
      }), isFalse);
    });

    test('NÉGATIF : role="dingo", self_voted=true, alive=false, winner_role="VILLAGE" → false', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_self_voted_all_game': true,
        'is_player_alive': false,
        'winner_role': 'VILLAGE',
      }), isFalse);
    });

    test('NÉGATIF : role="dingo", self_voted=true, alive=true, winner_role=null → false', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_self_voted_all_game': true,
        'is_player_alive': true,
        'winner_role': null,
      }), isFalse);
    });

    test('NÉGATIF : map vide → false', () {
      expect(achievement.checkCondition({}), isFalse);
    });
  });

  // ============================================================
  // 7. bad_shooter — "Mauvais tireur"
  // checkCondition: (data) =>
  //   data['player_role']?.toString().toLowerCase() == "dingo" &&
  //   (data['dingo_shots_fired'] ?? 0) >= 1 &&
  //   (data['dingo_shots_hit'] ?? 0) == 0,
  // ============================================================
  group('bad_shooter', () {
    late Achievement achievement;
    setUp(() => achievement = _get('bad_shooter'));

    test('POSITIF : role="dingo", fired=1, hit=0, winner_role non-null → true', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_shots_fired': 1,
        'dingo_shots_hit': 0,
        'winner_role': 'VILLAGE',
      }), isTrue);
    });

    test('POSITIF : role="dingo", fired=3, hit=0, winner_role non-null → true', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_shots_fired': 3,
        'dingo_shots_hit': 0,
        'winner_role': 'LOUPS-GAROUS',
      }), isTrue);
    });

    test('POSITIF : role="dingo", fired=1, hit absent, winner_role non-null → true', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_shots_fired': 1,
        'winner_role': 'VILLAGE',
      }), isTrue);
    });

    test('NÉGATIF : role="Villageois", fired=1, hit=0 → false', () {
      expect(achievement.checkCondition({
        'player_role': 'Villageois',
        'dingo_shots_fired': 1,
        'dingo_shots_hit': 0,
      }), isFalse);
    });

    test('NÉGATIF : role="dingo", fired=0, hit=0 → false', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_shots_fired': 0,
        'dingo_shots_hit': 0,
      }), isFalse);
    });

    test('NÉGATIF : role="dingo", fired=1, hit=1 → false', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_shots_fired': 1,
        'dingo_shots_hit': 1,
      }), isFalse);
    });

    test('NÉGATIF : role="dingo", fired=3, hit=2 → false', () {
      expect(achievement.checkCondition({
        'player_role': 'dingo',
        'dingo_shots_fired': 3,
        'dingo_shots_hit': 2,
      }), isFalse);
    });

    test('NÉGATIF : map vide → false', () {
      expect(achievement.checkCondition({}), isFalse);
    });
  });

  // ============================================================
  // 8. parking_shot — "Un tir du parking !"
  // checkCondition: (data) => data['parking_shot_achieved'] == true,
  // ============================================================
  group('parking_shot', () {
    late Achievement achievement;
    setUp(() => achievement = _get('parking_shot'));

    test('flag true → true', () {
      expect(achievement.checkCondition({'parking_shot_achieved': true}), isTrue);
    });

    test('flag false → false', () {
      expect(achievement.checkCondition({'parking_shot_achieved': false}), isFalse);
    });

    test('flag absent → false', () {
      expect(achievement.checkCondition({}), isFalse);
    });

    test('flag null → false', () {
      expect(achievement.checkCondition({'parking_shot_achieved': null}), isFalse);
    });

    test("valeur string 'true' → false", () {
      expect(achievement.checkCondition({'parking_shot_achieved': 'true'}), isFalse);
    });

    test('valeur entier 1 → false', () {
      expect(achievement.checkCondition({'parking_shot_achieved': 1}), isFalse);
    });

    test('map avec autre clé présente → false', () {
      expect(achievement.checkCondition({'bad_shooter': true}), isFalse);
    });
  });
}
