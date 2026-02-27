import 'package:flutter_test/flutter_test.dart';
import 'package:fluffer/models/achievement.dart';

Achievement _get(String id) =>
    AchievementData.allAchievements.firstWhere((a) => a.id == id);

void main() {
  // ============================================================
  // 1. pokemon_fail — "C'est pas très efficace..."
  // checkCondition: (data) =>
  //     (data['player_role']?.toString().toLowerCase() == "pokémon" ||
  //      data['player_role']?.toString().toLowerCase() == "pokemon") &&
  //     data['pokemon_died_t1'] == true,
  // ============================================================
  group('pokemon_fail', () {
    late Achievement a;
    setUp(() => a = _get('pokemon_fail'));

    // POSITIFS
    test('role="pokémon" (minuscule accent) + died_t1=true → true', () {
      expect(
        a.checkCondition({'player_role': 'pokémon', 'pokemon_died_t1': true}),
        isTrue,
      );
    });

    test('role="Pokémon" (majuscule accent) + died_t1=true → true', () {
      expect(
        a.checkCondition({'player_role': 'Pokémon', 'pokemon_died_t1': true}),
        isTrue,
      );
    });

    test('role="pokemon" (sans accent) + died_t1=true → true', () {
      expect(
        a.checkCondition({'player_role': 'pokemon', 'pokemon_died_t1': true}),
        isTrue,
      );
    });

    test('role="POKÉMON" (tout majuscule avec accent) + died_t1=true → true via toLowerCase', () {
      expect(
        a.checkCondition({'player_role': 'POKÉMON', 'pokemon_died_t1': true}),
        isTrue,
      );
    });

    // NÉGATIFS
    test('role="Dresseur" + died_t1=true → false (Dresseur ne doit pas obtenir ce succès)', () {
      expect(
        a.checkCondition({'player_role': 'Dresseur', 'pokemon_died_t1': true}),
        isFalse,
      );
    });

    test('role="pokémon" + died_t1=false → false', () {
      expect(
        a.checkCondition({'player_role': 'pokémon', 'pokemon_died_t1': false}),
        isFalse,
      );
    });

    test('role="pokémon" + died_t1=null → false', () {
      expect(
        a.checkCondition({'player_role': 'pokémon', 'pokemon_died_t1': null}),
        isFalse,
      );
    });

    test('role="pokémon" + died_t1 absent → false', () {
      expect(
        a.checkCondition({'player_role': 'pokémon'}),
        isFalse,
      );
    });

    test('role=null + died_t1=true → false', () {
      expect(
        a.checkCondition({'player_role': null, 'pokemon_died_t1': true}),
        isFalse,
      );
    });

    test('map vide → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 2. master_no_pokemon — "Maître sans Pokémon"
  // checkCondition: (data) =>
  //     data['player_role'] == "Dresseur" &&
  //     data['winner_role'] == "DRESSEUR" &&
  //     data['pokemon_is_dead_at_end'] == true,
  // Note : comparaison EXACTE (sensible à la casse).
  // ============================================================
  group('master_no_pokemon', () {
    late Achievement a;
    setUp(() => a = _get('master_no_pokemon'));

    // POSITIF
    test('role="Dresseur" + winner="DRESSEUR" + dead_at_end=true → true', () {
      expect(
        a.checkCondition({
          'player_role': 'Dresseur',
          'winner_role': 'DRESSEUR',
          'pokemon_is_dead_at_end': true,
        }),
        isTrue,
      );
    });

    // NÉGATIFS
    test('role="dresseur" (minuscule) + winner="DRESSEUR" + dead_at_end=true → false (casse exacte)', () {
      expect(
        a.checkCondition({
          'player_role': 'dresseur',
          'winner_role': 'DRESSEUR',
          'pokemon_is_dead_at_end': true,
        }),
        isFalse,
      );
    });

    test('role="Dresseur" + winner="dresseur" (minuscule) + dead_at_end=true → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Dresseur',
          'winner_role': 'dresseur',
          'pokemon_is_dead_at_end': true,
        }),
        isFalse,
      );
    });

    test('role="Dresseur" + winner="DRESSEUR" + dead_at_end=false → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Dresseur',
          'winner_role': 'DRESSEUR',
          'pokemon_is_dead_at_end': false,
        }),
        isFalse,
      );
    });

    test('role="Dresseur" + winner="DRESSEUR" + dead_at_end=null → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Dresseur',
          'winner_role': 'DRESSEUR',
          'pokemon_is_dead_at_end': null,
        }),
        isFalse,
      );
    });

    test('role="Pokémon" + winner="DRESSEUR" + dead_at_end=true → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Pokémon',
          'winner_role': 'DRESSEUR',
          'pokemon_is_dead_at_end': true,
        }),
        isFalse,
      );
    });

    test('role="Dresseur" + winner="VILLAGE" + dead_at_end=true → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Dresseur',
          'winner_role': 'VILLAGE',
          'pokemon_is_dead_at_end': true,
        }),
        isFalse,
      );
    });

    test('role=null + winner="DRESSEUR" + dead_at_end=true → false', () {
      expect(
        a.checkCondition({
          'player_role': null,
          'winner_role': 'DRESSEUR',
          'pokemon_is_dead_at_end': true,
        }),
        isFalse,
      );
    });

    test('map vide → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });

    test('role="Dresseur" + winner="DRESSEUR" + dead_at_end=false avec ancienne clé pokemon_died_t1=true → false', () {
      // L'ancienne clé "pokemon_died_t1" ne doit pas déclencher ce succès.
      expect(
        a.checkCondition({
          'player_role': 'Dresseur',
          'winner_role': 'DRESSEUR',
          'pokemon_is_dead_at_end': false,
          'pokemon_died_t1': true,
        }),
        isFalse,
      );
    });
  });

  // ============================================================
  // 3. electric_phoenix — "Phénix Électrique"
  // checkCondition: (data) =>
  //     (data['player_role'] == "Pokémon" || data['player_role'] == "Pokémon") &&
  //     data['winner_role'] == "DRESSEUR" &&
  //     data['was_revived'] == true &&
  //     data['is_player_alive'] == true,
  // Note : comparaison exacte — seule la valeur exacte "Pokémon" (avec accent) fonctionne.
  // ============================================================
  group('electric_phoenix', () {
    late Achievement a;
    setUp(() => a = _get('electric_phoenix'));

    // POSITIF
    test('role="Pokémon" + winner="DRESSEUR" + revived=true + alive=true → true', () {
      expect(
        a.checkCondition({
          'player_role': 'Pokémon',
          'winner_role': 'DRESSEUR',
          'was_revived': true,
          'is_player_alive': true,
        }),
        isTrue,
      );
    });

    // NÉGATIFS
    test('role="pokemon" (sans accent) + winner="DRESSEUR" + revived=true + alive=true → true (toLowerCase actif)', () {
      expect(
        a.checkCondition({
          'player_role': 'pokemon',
          'winner_role': 'DRESSEUR',
          'was_revived': true,
          'is_player_alive': true,
        }),
        isTrue,
      );
    });

    test('role="Pokémon" + winner="VILLAGE" + revived=true + alive=true → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Pokémon',
          'winner_role': 'VILLAGE',
          'was_revived': true,
          'is_player_alive': true,
        }),
        isFalse,
      );
    });

    test('role="Pokémon" + winner="DRESSEUR" + revived=false + alive=true → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Pokémon',
          'winner_role': 'DRESSEUR',
          'was_revived': false,
          'is_player_alive': true,
        }),
        isFalse,
      );
    });

    test('role="Pokémon" + winner="DRESSEUR" + revived=true + alive=false → false (doit être vivant)', () {
      expect(
        a.checkCondition({
          'player_role': 'Pokémon',
          'winner_role': 'DRESSEUR',
          'was_revived': true,
          'is_player_alive': false,
        }),
        isFalse,
      );
    });

    test('role="Dresseur" + winner="DRESSEUR" + revived=true + alive=true → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Dresseur',
          'winner_role': 'DRESSEUR',
          'was_revived': true,
          'is_player_alive': true,
        }),
        isFalse,
      );
    });

    test('role=null + winner="DRESSEUR" + revived=true + alive=true → false', () {
      expect(
        a.checkCondition({
          'player_role': null,
          'winner_role': 'DRESSEUR',
          'was_revived': true,
          'is_player_alive': true,
        }),
        isFalse,
      );
    });

    test('map vide → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });

    test('role="Pokémon" + winner="DRESSEUR" + revived=null + alive=true → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Pokémon',
          'winner_role': 'DRESSEUR',
          'was_revived': null,
          'is_player_alive': true,
        }),
        isFalse,
      );
    });

    test('role="Pokémon" + winner="DRESSEUR" + revived=true + alive=null → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Pokémon',
          'winner_role': 'DRESSEUR',
          'was_revived': true,
          'is_player_alive': null,
        }),
        isFalse,
      );
    });
  });

  // ============================================================
  // 4. time_paradox — "Paradoxe Temporel"
  // checkCondition: (data) =>
  //     data['player_role']?.toString().toLowerCase() == "maître du temps" &&
  //     data['paradox_achieved'] == true,
  // ============================================================
  group('time_paradox', () {
    late Achievement a;
    setUp(() => a = _get('time_paradox'));

    // POSITIFS
    test('role="maître du temps" (minuscules) + paradox=true → true', () {
      expect(
        a.checkCondition({'player_role': 'maître du temps', 'paradox_achieved': true}),
        isTrue,
      );
    });

    test('role="Maître du temps" (casse mixte) + paradox=true → true', () {
      expect(
        a.checkCondition({'player_role': 'Maître du temps', 'paradox_achieved': true}),
        isTrue,
      );
    });

    test('role="MAÎTRE DU TEMPS" (tout majuscule) + paradox=true → true', () {
      expect(
        a.checkCondition({'player_role': 'MAÎTRE DU TEMPS', 'paradox_achieved': true}),
        isTrue,
      );
    });

    // NÉGATIFS
    test('role="Villageois" + paradox=true → false', () {
      expect(
        a.checkCondition({'player_role': 'Villageois', 'paradox_achieved': true}),
        isFalse,
      );
    });

    test('role="maître du temps" + paradox=false → false', () {
      expect(
        a.checkCondition({'player_role': 'maître du temps', 'paradox_achieved': false}),
        isFalse,
      );
    });

    test('role="maître du temps" + paradox=null → false', () {
      expect(
        a.checkCondition({'player_role': 'maître du temps', 'paradox_achieved': null}),
        isFalse,
      );
    });

    test('role=null + paradox=true → false', () {
      expect(
        a.checkCondition({'player_role': null, 'paradox_achieved': true}),
        isFalse,
      );
    });

    test('map vide → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 5. time_perfect — "Timing Précis"
  // checkCondition: (data) =>
  //     data['player_role'] == "Maître du temps" &&
  //     data['winner_role'] == "MAÎTRE DU TEMPS" &&
  //     data['turn_count'] == 5,
  // Note : comparaison EXACTE (sensible à la casse).
  // ============================================================
  group('time_perfect', () {
    late Achievement a;
    setUp(() => a = _get('time_perfect'));

    // POSITIF
    test('role="Maître du temps" + winner="MAÎTRE DU TEMPS" + turn=5 → true', () {
      expect(
        a.checkCondition({
          'player_role': 'Maître du temps',
          'winner_role': 'MAÎTRE DU TEMPS',
          'turn_count': 5,
        }),
        isTrue,
      );
    });

    // NÉGATIFS
    test('role="maître du temps" (minuscule) + winner="MAÎTRE DU TEMPS" + turn=5 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'maître du temps',
          'winner_role': 'MAÎTRE DU TEMPS',
          'turn_count': 5,
        }),
        isFalse,
      );
    });

    test('role="Maître du temps" + winner="maître du temps" (minuscule) + turn=5 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Maître du temps',
          'winner_role': 'maître du temps',
          'turn_count': 5,
        }),
        isFalse,
      );
    });

    test('role="Maître du temps" + winner="MAÎTRE DU TEMPS" + turn=4 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Maître du temps',
          'winner_role': 'MAÎTRE DU TEMPS',
          'turn_count': 4,
        }),
        isFalse,
      );
    });

    test('role="Maître du temps" + winner="MAÎTRE DU TEMPS" + turn=6 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Maître du temps',
          'winner_role': 'MAÎTRE DU TEMPS',
          'turn_count': 6,
        }),
        isFalse,
      );
    });

    test('role="Maître du temps" + winner="VILLAGE" + turn=5 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Maître du temps',
          'winner_role': 'VILLAGE',
          'turn_count': 5,
        }),
        isFalse,
      );
    });

    test('map vide → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 6. pantin_clutch — "Vote Décisif"
  // checkCondition: (data) => data['pantin_clutch_triggered'] == true,
  // ============================================================
  group('pantin_clutch', () {
    late Achievement a;
    setUp(() => a = _get('pantin_clutch'));

    test('pantin_clutch_triggered=true → true', () {
      expect(
        a.checkCondition({'pantin_clutch_triggered': true}),
        isTrue,
      );
    });

    test('pantin_clutch_triggered=false → false', () {
      expect(
        a.checkCondition({'pantin_clutch_triggered': false}),
        isFalse,
      );
    });

    test('pantin_clutch_triggered absent → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });

    test('pantin_clutch_triggered=null → false', () {
      expect(
        a.checkCondition({'pantin_clutch_triggered': null}),
        isFalse,
      );
    });

    test('pantin_clutch_triggered="true" (string) → false', () {
      expect(
        a.checkCondition({'pantin_clutch_triggered': 'true'}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 7. phyl_silent_assassin — "Assassin Silencieux"
  // checkCondition: (data) =>
  //     data['player_role'] == "Phyl" &&
  //     data['winner_role'] == "PHYL" &&
  //     data['turn_count'] <= 2,
  // ============================================================
  group('phyl_silent_assassin', () {
    late Achievement a;
    setUp(() => a = _get('phyl_silent_assassin'));

    // POSITIFS
    test('role="Phyl" + winner="PHYL" + turn=1 → true', () {
      expect(
        a.checkCondition({
          'player_role': 'Phyl',
          'winner_role': 'PHYL',
          'turn_count': 1,
        }),
        isTrue,
      );
    });

    test('role="Phyl" + winner="PHYL" + turn=2 → true', () {
      expect(
        a.checkCondition({
          'player_role': 'Phyl',
          'winner_role': 'PHYL',
          'turn_count': 2,
        }),
        isTrue,
      );
    });

    // NÉGATIFS
    test('role="phyl" (minuscule) + winner="PHYL" + turn=2 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'phyl',
          'winner_role': 'PHYL',
          'turn_count': 2,
        }),
        isFalse,
      );
    });

    test('role="Phyl" + winner="phyl" (minuscule) + turn=2 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Phyl',
          'winner_role': 'phyl',
          'turn_count': 2,
        }),
        isFalse,
      );
    });

    test('role="Phyl" + winner="PHYL" + turn=3 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Phyl',
          'winner_role': 'PHYL',
          'turn_count': 3,
        }),
        isFalse,
      );
    });

    test('role="Phyl" + winner="VILLAGE" + turn=2 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Phyl',
          'winner_role': 'VILLAGE',
          'turn_count': 2,
        }),
        isFalse,
      );
    });

    test('role="Villageois" + winner="PHYL" + turn=2 → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Villageois',
          'winner_role': 'PHYL',
          'turn_count': 2,
        }),
        isFalse,
      );
    });

    test('map vide → false (turn_count absent, null <= 2 lève une erreur ou est false)', () {
      // En Dart, null <= 2 lèverait une erreur de type — la condition entière est false
      // car les premières comparaisons échouent déjà.
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 8. ultimate_fan — "Fan Ultime"
  // checkCondition: (data) => data['ultimate_fan_action'] == true,
  // ============================================================
  group('ultimate_fan', () {
    late Achievement a;
    setUp(() => a = _get('ultimate_fan'));

    test('ultimate_fan_action=true → true', () {
      expect(
        a.checkCondition({'ultimate_fan_action': true}),
        isTrue,
      );
    });

    test('ultimate_fan_action=false → false', () {
      expect(
        a.checkCondition({'ultimate_fan_action': false}),
        isFalse,
      );
    });

    test('ultimate_fan_action absent → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });

    test('ultimate_fan_action=null → false', () {
      expect(
        a.checkCondition({'ultimate_fan_action': null}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 9. fan_sacrifice — "Garde du Corps"
  // checkCondition: (data) => data['sacrificed'] == true || data['is_fan_sacrifice'] == true,
  // ============================================================
  group('fan_sacrifice', () {
    late Achievement a;
    setUp(() => a = _get('fan_sacrifice'));

    // POSITIFS
    test('sacrificed=true → true', () {
      expect(
        a.checkCondition({'sacrificed': true}),
        isTrue,
      );
    });

    test('is_fan_sacrifice=true → true', () {
      expect(
        a.checkCondition({'is_fan_sacrifice': true}),
        isTrue,
      );
    });

    test('sacrificed=true ET is_fan_sacrifice=true → true', () {
      expect(
        a.checkCondition({'sacrificed': true, 'is_fan_sacrifice': true}),
        isTrue,
      );
    });

    // NÉGATIFS
    test('sacrificed=false + is_fan_sacrifice=false → false', () {
      expect(
        a.checkCondition({'sacrificed': false, 'is_fan_sacrifice': false}),
        isFalse,
      );
    });

    test('sacrificed=null + is_fan_sacrifice=null → false', () {
      expect(
        a.checkCondition({'sacrificed': null, 'is_fan_sacrifice': null}),
        isFalse,
      );
    });

    test('sacrificed absent + is_fan_sacrifice absent → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });

    test('map vide → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 10. siuuu_win — "Le GOAT"
  // checkCondition: (data) =>
  //     data['player_role']?.toString().trim() == "Ron-Aldo" &&
  //     data['is_fan'] == false &&
  //     data['winner_role'] == "RON-ALDO",
  // ============================================================
  group('siuuu_win', () {
    late Achievement a;
    setUp(() => a = _get('siuuu_win'));

    // POSITIFS
    test('role="Ron-Aldo" + is_fan=false + winner="RON-ALDO" → true', () {
      expect(
        a.checkCondition({
          'player_role': 'Ron-Aldo',
          'is_fan': false,
          'winner_role': 'RON-ALDO',
        }),
        isTrue,
      );
    });

    test('role=" Ron-Aldo " (espaces) + is_fan=false + winner="RON-ALDO" → true (trim)', () {
      expect(
        a.checkCondition({
          'player_role': ' Ron-Aldo ',
          'is_fan': false,
          'winner_role': 'RON-ALDO',
        }),
        isTrue,
      );
    });

    // NÉGATIFS
    test('role="Ron-Aldo" + is_fan=true + winner="RON-ALDO" → false (fan ne gagne pas ce succès)', () {
      expect(
        a.checkCondition({
          'player_role': 'Ron-Aldo',
          'is_fan': true,
          'winner_role': 'RON-ALDO',
        }),
        isFalse,
      );
    });

    test('role="Ron-Aldo" + is_fan=null + winner="RON-ALDO" → false (null != false en Dart)', () {
      expect(
        a.checkCondition({
          'player_role': 'Ron-Aldo',
          'is_fan': null,
          'winner_role': 'RON-ALDO',
        }),
        isFalse,
      );
    });

    test('role="ron-aldo" (minuscule) + is_fan=false + winner="RON-ALDO" → false', () {
      expect(
        a.checkCondition({
          'player_role': 'ron-aldo',
          'is_fan': false,
          'winner_role': 'RON-ALDO',
        }),
        isFalse,
      );
    });

    test('role="Ron-Aldo" + is_fan=false + winner="VILLAGE" → false', () {
      expect(
        a.checkCondition({
          'player_role': 'Ron-Aldo',
          'is_fan': false,
          'winner_role': 'VILLAGE',
        }),
        isFalse,
      );
    });

    test('role=null + is_fan=false + winner="RON-ALDO" → false', () {
      expect(
        a.checkCondition({
          'player_role': null,
          'is_fan': false,
          'winner_role': 'RON-ALDO',
        }),
        isFalse,
      );
    });

    test('map vide → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });
  });

  // ============================================================
  // 11. coupe_maison — "Ramenez la coupe à la maison"
  // checkCondition: (data) => data['ramenez_la_coupe'] == true,
  // ============================================================
  group('coupe_maison', () {
    late Achievement a;
    setUp(() => a = _get('coupe_maison'));

    test('ramenez_la_coupe=true → true', () {
      expect(
        a.checkCondition({'ramenez_la_coupe': true}),
        isTrue,
      );
    });

    test('ramenez_la_coupe=false → false', () {
      expect(
        a.checkCondition({'ramenez_la_coupe': false}),
        isFalse,
      );
    });

    test('ramenez_la_coupe absent → false', () {
      expect(
        a.checkCondition({}),
        isFalse,
      );
    });

    test('ramenez_la_coupe=null → false', () {
      expect(
        a.checkCondition({'ramenez_la_coupe': null}),
        isFalse,
      );
    });

    test('ramenez_la_coupe="true" (string) → false', () {
      expect(
        a.checkCondition({'ramenez_la_coupe': 'true'}),
        isFalse,
      );
    });
  });
}
