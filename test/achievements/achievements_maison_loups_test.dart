import 'package:flutter_test/flutter_test.dart';
import 'package:fluffer/models/achievement.dart';

Achievement _get(String id) =>
    AchievementData.allAchievements.firstWhere((a) => a.id == id);

void main() {
  // ==========================================
  // 1. house_collapse — "Assurance Tous Risques"
  // ==========================================
  group('house_collapse', () {
    late Achievement ach;
    setUp(() => ach = _get('house_collapse'));

    test('house_collapsed == true → true', () {
      expect(ach.checkCondition({'house_collapsed': true}), isTrue);
    });
    test('house_collapsed == false → false', () {
      expect(ach.checkCondition({'house_collapsed': false}), isFalse);
    });
    test('house_collapsed absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('house_collapsed == null → false', () {
      expect(ach.checkCondition({'house_collapsed': null}), isFalse);
    });
    test("house_collapsed == 'true' (string) → false", () {
      expect(ach.checkCondition({'house_collapsed': 'true'}), isFalse);
    });
    test('house_collapsed == 1 (int) → false', () {
      expect(ach.checkCondition({'house_collapsed': 1}), isFalse);
    });
    test('autres clés présentes, house_collapsed absent → false', () {
      expect(ach.checkCondition({'player_role': 'maison', 'winner_role': 'VILLAGE'}), isFalse);
    });
    test('house_collapsed == true avec autres clés → true', () {
      expect(ach.checkCondition({'house_collapsed': true, 'player_role': 'maison'}), isTrue);
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('house_collapsed == false avec autres données → false', () {
      expect(ach.checkCondition({'house_collapsed': false, 'winner_role': 'VILLAGE', 'is_player_alive': true}), isFalse);
    });
  });

  // ==========================================
  // 2. assurance_habitation — "Assurance habitation"
  // ==========================================
  group('assurance_habitation', () {
    late Achievement ach;
    setUp(() => ach = _get('assurance_habitation'));

    test('assurance_habitation_triggered == true → true', () {
      expect(ach.checkCondition({'assurance_habitation_triggered': true}), isTrue);
    });
    test('assurance_habitation_triggered == false → false', () {
      expect(ach.checkCondition({'assurance_habitation_triggered': false}), isFalse);
    });
    test('assurance_habitation_triggered absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('assurance_habitation_triggered == null → false', () {
      expect(ach.checkCondition({'assurance_habitation_triggered': null}), isFalse);
    });
    test("assurance_habitation_triggered == 'true' (string) → false", () {
      expect(ach.checkCondition({'assurance_habitation_triggered': 'true'}), isFalse);
    });
    test('assurance_habitation_triggered == 1 (int) → false', () {
      expect(ach.checkCondition({'assurance_habitation_triggered': 1}), isFalse);
    });
    test('autres clés présentes mais clé absente → false', () {
      expect(ach.checkCondition({'player_role': 'maison', 'house_collapsed': true}), isFalse);
    });
    test('true avec autres données → true', () {
      expect(ach.checkCondition({'assurance_habitation_triggered': true, 'player_role': 'maison'}), isTrue);
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('false avec beaucoup de clés → false', () {
      expect(ach.checkCondition({
        'assurance_habitation_triggered': false,
        'house_collapsed': true,
        'player_role': 'maison',
        'is_player_alive': true,
      }), isFalse);
    });
  });

  // ==========================================
  // 3. crazy_casa — "Crazy Casa"
  // ==========================================
  group('crazy_casa', () {
    late Achievement ach;
    setUp(() => ach = _get('crazy_casa'));

    test('POSITIF : role="maison", winner="VILLAGE", alive=true → true', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'winner_role': 'VILLAGE',
        'is_player_alive': true,
      }), isTrue);
    });
    test('POSITIF : role="Maison" (casse mixte), winner="VILLAGE", alive=true → true', () {
      expect(ach.checkCondition({
        'player_role': 'Maison',
        'winner_role': 'VILLAGE',
        'is_player_alive': true,
      }), isTrue);
    });
    test('POSITIF : role="MAISON" (tout majuscule), winner="VILLAGE", alive=true → true', () {
      expect(ach.checkCondition({
        'player_role': 'MAISON',
        'winner_role': 'VILLAGE',
        'is_player_alive': true,
      }), isTrue);
    });
    test('NÉGATIF : role="Villageois", winner="VILLAGE", alive=true → false', () {
      expect(ach.checkCondition({
        'player_role': 'Villageois',
        'winner_role': 'VILLAGE',
        'is_player_alive': true,
      }), isFalse);
    });
    test('NÉGATIF : role="maison", winner="LOUPS-GAROUS", alive=true → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'winner_role': 'LOUPS-GAROUS',
        'is_player_alive': true,
      }), isFalse);
    });
    test('NÉGATIF : role="maison", winner="VILLAGE", alive=false → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'winner_role': 'VILLAGE',
        'is_player_alive': false,
      }), isFalse);
    });
    test('NÉGATIF : role=null, winner="VILLAGE", alive=true → false', () {
      expect(ach.checkCondition({
        'player_role': null,
        'winner_role': 'VILLAGE',
        'is_player_alive': true,
      }), isFalse);
    });
    test('NÉGATIF : map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('NÉGATIF : winner absent, role="maison", alive=true → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'is_player_alive': true,
      }), isFalse);
    });
    test('NÉGATIF : alive absent, role="maison", winner="VILLAGE" → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'winner_role': 'VILLAGE',
      }), isFalse);
    });
  });

  // ==========================================
  // 4. welcome_wolf — "La prochaine fois je n'ouvrirai pas..."
  // ==========================================
  group('welcome_wolf', () {
    late Achievement ach;
    setUp(() => ach = _get('welcome_wolf'));

    test('maison_hosted_wolf == true → true', () {
      expect(ach.checkCondition({'maison_hosted_wolf': true}), isTrue);
    });
    test('maison_hosted_wolf == false → false', () {
      expect(ach.checkCondition({'maison_hosted_wolf': false}), isFalse);
    });
    test('maison_hosted_wolf absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('maison_hosted_wolf == null → false', () {
      expect(ach.checkCondition({'maison_hosted_wolf': null}), isFalse);
    });
    test("maison_hosted_wolf == 'true' (string) → false", () {
      expect(ach.checkCondition({'maison_hosted_wolf': 'true'}), isFalse);
    });
    test('maison_hosted_wolf == 1 (int) → false', () {
      expect(ach.checkCondition({'maison_hosted_wolf': 1}), isFalse);
    });
    test('true avec autres données → true', () {
      expect(ach.checkCondition({'maison_hosted_wolf': true, 'player_role': 'maison'}), isTrue);
    });
    test('false avec autres données → false', () {
      expect(ach.checkCondition({'maison_hosted_wolf': false, 'player_role': 'maison', 'winner_role': 'VILLAGE'}), isFalse);
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('clé différente présente, maison_hosted_wolf absent → false', () {
      expect(ach.checkCondition({'player_role': 'maison', 'is_player_alive': true}), isFalse);
    });
  });

  // ==========================================
  // 5. epstein_house — "Epstein House"
  // ==========================================
  group('epstein_house', () {
    late Achievement ach;
    setUp(() => ach = _get('epstein_house'));

    test('POSITIF : role="maison", hosted=2 → true', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'hosted_enemies_count': 2,
      }), isTrue);
    });
    test('POSITIF : role="maison", hosted=5 → true', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'hosted_enemies_count': 5,
      }), isTrue);
    });
    test('POSITIF : role="Maison" (casse mixte), hosted=2 → true', () {
      expect(ach.checkCondition({
        'player_role': 'Maison',
        'hosted_enemies_count': 2,
      }), isTrue);
    });
    test('NÉGATIF : role="Villageois", hosted=2 → false', () {
      expect(ach.checkCondition({
        'player_role': 'Villageois',
        'hosted_enemies_count': 2,
      }), isFalse);
    });
    test('NÉGATIF : role="maison", hosted=1 → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'hosted_enemies_count': 1,
      }), isFalse);
    });
    test('NÉGATIF : role="maison", hosted=0 → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'hosted_enemies_count': 0,
      }), isFalse);
    });
    test('NÉGATIF : role="maison", hosted absent (→ 0) → false', () {
      expect(ach.checkCondition({'player_role': 'maison'}), isFalse);
    });
    test('NÉGATIF : map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('NÉGATIF : role="maison", hosted=null (→ 0) → false', () {
      expect(ach.checkCondition({'player_role': 'maison', 'hosted_enemies_count': null}), isFalse);
    });
    test('NÉGATIF : role absent, hosted=3 → false', () {
      expect(ach.checkCondition({'hosted_enemies_count': 3}), isFalse);
    });
  });

  // ==========================================
  // 6. house_fast_death — "Vous auriez pu toquer !"
  // ==========================================
  group('house_fast_death', () {
    late Achievement ach;
    setUp(() => ach = _get('house_fast_death'));

    test('POSITIF : role="maison", turn=1, death="direct_hit" → true', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'turn_count': 1,
        'death_cause': 'direct_hit',
      }), isTrue);
    });
    test('POSITIF : role="MAISON" (tout majuscule), turn=1, death="direct_hit" → true', () {
      expect(ach.checkCondition({
        'player_role': 'MAISON',
        'turn_count': 1,
        'death_cause': 'direct_hit',
      }), isTrue);
    });
    test('NÉGATIF : role="Villageois", turn=1, death="direct_hit" → false', () {
      expect(ach.checkCondition({
        'player_role': 'Villageois',
        'turn_count': 1,
        'death_cause': 'direct_hit',
      }), isFalse);
    });
    test('NÉGATIF : role="maison", turn=2, death="direct_hit" → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'turn_count': 2,
        'death_cause': 'direct_hit',
      }), isFalse);
    });
    test('NÉGATIF : role="maison", turn=1, death="autre" → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'turn_count': 1,
        'death_cause': 'autre',
      }), isFalse);
    });
    test('NÉGATIF : role="maison", turn=1, death=null → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'turn_count': 1,
        'death_cause': null,
      }), isFalse);
    });
    test('NÉGATIF : role="maison", turn=null, death="direct_hit" → false (null != 1)', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'turn_count': null,
        'death_cause': 'direct_hit',
      }), isFalse);
    });
    test('NÉGATIF : map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('NÉGATIF : role="maison", turn absent, death="direct_hit" → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'death_cause': 'direct_hit',
      }), isFalse);
    });
    test('NÉGATIF : role="maison", turn=1, death absent → false', () {
      expect(ach.checkCondition({
        'player_role': 'maison',
        'turn_count': 1,
      }), isFalse);
    });
  });

  // ==========================================
  // 7. tardos_oups — "Oups..."
  // ==========================================
  group('tardos_oups', () {
    late Achievement ach;
    setUp(() => ach = _get('tardos_oups'));

    test('tardos_suicide == true → true', () {
      expect(ach.checkCondition({'tardos_suicide': true}), isTrue);
    });
    test('tardos_suicide == false → false', () {
      expect(ach.checkCondition({'tardos_suicide': false}), isFalse);
    });
    test('tardos_suicide absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('tardos_suicide == null → false', () {
      expect(ach.checkCondition({'tardos_suicide': null}), isFalse);
    });
    test("tardos_suicide == 'true' (string) → false", () {
      expect(ach.checkCondition({'tardos_suicide': 'true'}), isFalse);
    });
    test('tardos_suicide == 1 (int) → false', () {
      expect(ach.checkCondition({'tardos_suicide': 1}), isFalse);
    });
    test('true avec autres données → true', () {
      expect(ach.checkCondition({'tardos_suicide': true, 'player_role': 'tardos'}), isTrue);
    });
    test('false avec autres données → false', () {
      expect(ach.checkCondition({'tardos_suicide': false, 'player_role': 'tardos', 'winner_role': 'VILLAGE'}), isFalse);
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('clé différente présente, tardos_suicide absent → false', () {
      expect(ach.checkCondition({'player_role': 'tardos', 'is_player_alive': false}), isFalse);
    });
  });

  // ==========================================
  // 8. 11_septembre — "11 septembre"
  // ==========================================
  group('11_septembre', () {
    late Achievement ach;
    setUp(() => ach = _get('11_septembre'));

    test('11_septembre_triggered == true → true', () {
      expect(ach.checkCondition({'11_septembre_triggered': true}), isTrue);
    });
    test('11_septembre_triggered == false → false', () {
      expect(ach.checkCondition({'11_septembre_triggered': false}), isFalse);
    });
    test('11_septembre_triggered absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('11_septembre_triggered == null → false', () {
      expect(ach.checkCondition({'11_septembre_triggered': null}), isFalse);
    });
    test("11_septembre_triggered == 'true' (string) → false", () {
      expect(ach.checkCondition({'11_septembre_triggered': 'true'}), isFalse);
    });
    test('11_septembre_triggered == 1 (int) → false', () {
      expect(ach.checkCondition({'11_septembre_triggered': 1}), isFalse);
    });
    test('true avec autres données → true', () {
      expect(ach.checkCondition({'11_septembre_triggered': true, 'tardos_suicide': false}), isTrue);
    });
    test('false avec autres données → false', () {
      expect(ach.checkCondition({'11_septembre_triggered': false, 'player_role': 'tardos'}), isFalse);
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('clé self_destruct_triggered=true mais 11_septembre absent → false', () {
      expect(ach.checkCondition({'self_destruct_triggered': true}), isFalse);
    });
  });

  // ==========================================
  // 9. self_destruct — "Self-destruct"
  // ==========================================
  group('self_destruct', () {
    late Achievement ach;
    setUp(() => ach = _get('self_destruct'));

    test('self_destruct_triggered == true → true', () {
      expect(ach.checkCondition({'self_destruct_triggered': true}), isTrue);
    });
    test('self_destruct_triggered == false → false', () {
      expect(ach.checkCondition({'self_destruct_triggered': false}), isFalse);
    });
    test('self_destruct_triggered absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('self_destruct_triggered == null → false', () {
      expect(ach.checkCondition({'self_destruct_triggered': null}), isFalse);
    });
    test("self_destruct_triggered == 'true' (string) → false", () {
      expect(ach.checkCondition({'self_destruct_triggered': 'true'}), isFalse);
    });
    test('self_destruct_triggered == 1 (int) → false', () {
      expect(ach.checkCondition({'self_destruct_triggered': 1}), isFalse);
    });
    test('true avec autres données → true', () {
      expect(ach.checkCondition({'self_destruct_triggered': true, '11_septembre_triggered': false}), isTrue);
    });
    test('false avec autres données → false', () {
      expect(ach.checkCondition({'self_destruct_triggered': false, 'player_role': 'tardos'}), isFalse);
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('clé 11_septembre_triggered=true mais self_destruct absent → false', () {
      expect(ach.checkCondition({'11_septembre_triggered': true}), isFalse);
    });
  });

  // ==========================================
  // 10. traveler_sniper — "I'm back."
  // ==========================================
  group('traveler_sniper', () {
    late Achievement ach;
    setUp(() => ach = _get('traveler_sniper'));

    test('traveler_killed_wolf == true → true', () {
      expect(ach.checkCondition({'traveler_killed_wolf': true}), isTrue);
    });
    test('traveler_killed_wolf == false → false', () {
      expect(ach.checkCondition({'traveler_killed_wolf': false}), isFalse);
    });
    test('traveler_killed_wolf absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('traveler_killed_wolf == null → false', () {
      expect(ach.checkCondition({'traveler_killed_wolf': null}), isFalse);
    });
    test("traveler_killed_wolf == 'true' (string) → false", () {
      expect(ach.checkCondition({'traveler_killed_wolf': 'true'}), isFalse);
    });
    test('traveler_killed_wolf == 1 (int) → false', () {
      expect(ach.checkCondition({'traveler_killed_wolf': 1}), isFalse);
    });
    test('true avec autres données → true', () {
      expect(ach.checkCondition({'traveler_killed_wolf': true, 'player_role': 'voyageur'}), isTrue);
    });
    test('false avec autres données → false', () {
      expect(ach.checkCondition({'traveler_killed_wolf': false, 'player_role': 'voyageur'}), isFalse);
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('clé différente présente, traveler_killed_wolf absent → false', () {
      expect(ach.checkCondition({'player_role': 'voyageur', 'is_player_alive': true}), isFalse);
    });
  });

  // ==========================================
  // 11. chaman_sniper — "Exécution Ciblée"
  // ==========================================
  group('chaman_sniper', () {
    late Achievement ach;
    setUp(() => ach = _get('chaman_sniper'));

    test('chaman_sniper_achieved == true + bon rôle → true', () {
      expect(ach.checkCondition({'chaman_sniper_achieved': true, 'player_role': 'Loup-garou chaman'}), isTrue);
    });
    test('chaman_sniper_achieved == true sans rôle → false (bug global flag)', () {
      expect(ach.checkCondition({'chaman_sniper_achieved': true}), isFalse);
    });
    test('chaman_sniper_achieved == true + mauvais rôle → false', () {
      expect(ach.checkCondition({'chaman_sniper_achieved': true, 'player_role': 'Loup-garou'}), isFalse);
    });
    test('chaman_sniper_achieved == false → false', () {
      expect(ach.checkCondition({'chaman_sniper_achieved': false}), isFalse);
    });
    test('chaman_sniper_achieved absent → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('chaman_sniper_achieved == null → false', () {
      expect(ach.checkCondition({'chaman_sniper_achieved': null}), isFalse);
    });
    test("chaman_sniper_achieved == 'true' (string) → false", () {
      expect(ach.checkCondition({'chaman_sniper_achieved': 'true'}), isFalse);
    });
    test('chaman_sniper_achieved == 1 (int) → false', () {
      expect(ach.checkCondition({'chaman_sniper_achieved': 1}), isFalse);
    });
    test('false avec autres données → false', () {
      expect(ach.checkCondition({'chaman_sniper_achieved': false, 'player_role': 'Loup-garou chaman'}), isFalse);
    });
    test('map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('clé différente présente, chaman_sniper_achieved absent → false', () {
      expect(ach.checkCondition({'player_role': 'Loup-garou chaman', 'winner_role': 'LOUPS-GAROUS'}), isFalse);
    });
  });

  // ==========================================
  // 12. chaman_double_agent — "Infiltration Totale"
  // ==========================================
  group('chaman_double_agent', () {
    late Achievement ach;
    setUp(() => ach = _get('chaman_double_agent'));

    test('POSITIF : role="Loup-garou chaman", winner="LOUPS-GAROUS", votes=0, vote_anonyme=true → true', () {
      expect(ach.checkCondition({
        'player_role': 'Loup-garou chaman',
        'winner_role': 'LOUPS-GAROUS',
        'totalVotesReceivedDuringGame': 0,
        'vote_anonyme': true,
      }), isTrue);
    });
    test('POSITIF : role="Loup-garou chaman", winner="LOUPS-GAROUS", votes absent (→ 0), vote_anonyme=true → true', () {
      expect(ach.checkCondition({
        'player_role': 'Loup-garou chaman',
        'winner_role': 'LOUPS-GAROUS',
        'vote_anonyme': true,
      }), isTrue);
    });
    test('NÉGATIF : toutes conditions OK mais vote_anonyme=false → false', () {
      expect(ach.checkCondition({
        'player_role': 'Loup-garou chaman',
        'winner_role': 'LOUPS-GAROUS',
        'totalVotesReceivedDuringGame': 0,
        'vote_anonyme': false,
      }), isFalse);
    });
    test('NÉGATIF : role="Loup-garou" (sans chaman), winner="LOUPS-GAROUS", votes=0 → false', () {
      expect(ach.checkCondition({
        'player_role': 'Loup-garou',
        'winner_role': 'LOUPS-GAROUS',
        'totalVotesReceivedDuringGame': 0,
      }), isFalse);
    });
    test('NÉGATIF : role="Loup-garou chaman", winner="VILLAGE", votes=0 → false', () {
      expect(ach.checkCondition({
        'player_role': 'Loup-garou chaman',
        'winner_role': 'VILLAGE',
        'totalVotesReceivedDuringGame': 0,
      }), isFalse);
    });
    test('NÉGATIF : role="Loup-garou chaman", winner="LOUPS-GAROUS", votes=1 → false', () {
      expect(ach.checkCondition({
        'player_role': 'Loup-garou chaman',
        'winner_role': 'LOUPS-GAROUS',
        'totalVotesReceivedDuringGame': 1,
      }), isFalse);
    });
    test('NÉGATIF : role=null, winner="LOUPS-GAROUS", votes=0 → false', () {
      expect(ach.checkCondition({
        'player_role': null,
        'winner_role': 'LOUPS-GAROUS',
        'totalVotesReceivedDuringGame': 0,
      }), isFalse);
    });
    test('NÉGATIF : map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('POSITIF : role="loup-garou chaman" (tout minuscule), vote_anonyme=true → true', () {
      expect(ach.checkCondition({
        'player_role': 'loup-garou chaman',
        'winner_role': 'LOUPS-GAROUS',
        'totalVotesReceivedDuringGame': 0,
        'vote_anonyme': true,
      }), isTrue);
    });
    test('POSITIF : role="Loup-Garou Chaman" (casse mixte), vote_anonyme=true → true', () {
      expect(ach.checkCondition({
        'player_role': 'Loup-Garou Chaman',
        'winner_role': 'LOUPS-GAROUS',
        'totalVotesReceivedDuringGame': 0,
        'vote_anonyme': true,
      }), isTrue);
    });
    test('NÉGATIF : role="Loup-garou chaman", winner absent, votes=0 → false', () {
      expect(ach.checkCondition({
        'player_role': 'Loup-garou chaman',
        'totalVotesReceivedDuringGame': 0,
      }), isFalse);
    });
  });

  // ==========================================
  // 13. evolved_alpha — "Alpha Dominant"
  // ==========================================
  group('evolved_alpha', () {
    late Achievement ach;
    setUp(() => ach = _get('evolved_alpha'));

    test('POSITIF : wolf=true, winner="LOUPS-GAROUS", wolves_alive=1, alive=true → true', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_alive_count': 1,
        'is_player_alive': true,
      }), isTrue);
    });
    test('NÉGATIF : wolf=false, winner="LOUPS-GAROUS", wolves_alive=1, alive=true → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': false,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_alive_count': 1,
        'is_player_alive': true,
      }), isFalse);
    });
    test('NÉGATIF : wolf=true, winner="VILLAGE", wolves_alive=1, alive=true → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'VILLAGE',
        'wolves_alive_count': 1,
        'is_player_alive': true,
      }), isFalse);
    });
    test('NÉGATIF : wolf=true, winner="LOUPS-GAROUS", wolves_alive=2, alive=true → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_alive_count': 2,
        'is_player_alive': true,
      }), isFalse);
    });
    test('NÉGATIF : wolf=true, winner="LOUPS-GAROUS", wolves_alive=1, alive=false → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_alive_count': 1,
        'is_player_alive': false,
      }), isFalse);
    });
    test('NÉGATIF : map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('NÉGATIF : wolves_alive absent, reste ok → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'is_player_alive': true,
      }), isFalse);
    });
    test('NÉGATIF : alive absent, reste ok → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_alive_count': 1,
      }), isFalse);
    });
    test('NÉGATIF : wolf=null, reste ok → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': null,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_alive_count': 1,
        'is_player_alive': true,
      }), isFalse);
    });
    test('NÉGATIF : wolves_alive=0, reste ok → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_alive_count': 0,
        'is_player_alive': true,
      }), isFalse);
    });
  });

  // ==========================================
  // 14. evolved_hunger — "Fringale Nocturne"
  // ==========================================
  group('evolved_hunger', () {
    late Achievement ach;
    setUp(() => ach = _get('evolved_hunger'));

    test('POSITIF : wolf=true, hunger=true → true', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'evolved_hunger_achieved': true,
      }), isTrue);
    });
    test('NÉGATIF : wolf=false, hunger=true → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': false,
        'evolved_hunger_achieved': true,
      }), isFalse);
    });
    test('NÉGATIF : wolf=true, hunger=false → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'evolved_hunger_achieved': false,
      }), isFalse);
    });
    test('NÉGATIF : wolf=true, hunger=null → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'evolved_hunger_achieved': null,
      }), isFalse);
    });
    test('NÉGATIF : map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('NÉGATIF : wolf absent, hunger=true → false', () {
      expect(ach.checkCondition({'evolved_hunger_achieved': true}), isFalse);
    });
    test('NÉGATIF : wolf=true, hunger absent → false', () {
      expect(ach.checkCondition({'is_wolf_faction': true}), isFalse);
    });
    test('NÉGATIF : wolf=null, hunger=true → false', () {
      expect(ach.checkCondition({'is_wolf_faction': null, 'evolved_hunger_achieved': true}), isFalse);
    });
    test("NÉGATIF : wolf='true' (string), hunger=true → false", () {
      expect(ach.checkCondition({'is_wolf_faction': 'true', 'evolved_hunger_achieved': true}), isFalse);
    });
    test('POSITIF : wolf=true, hunger=true avec données supplémentaires → true', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'evolved_hunger_achieved': true,
        'winner_role': 'LOUPS-GAROUS',
        'is_player_alive': true,
      }), isTrue);
    });
  });

  // ==========================================
  // 15. clean_paws — "Montrez patte blanche"
  // ==========================================
  group('clean_paws', () {
    late Achievement ach;
    setUp(() => ach = _get('clean_paws'));

    test('POSITIF : wolf=true, winner="LOUPS-GAROUS", kills=0 → true', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_night_kills': 0,
      }), isTrue);
    });
    test('NÉGATIF : wolf=false, winner="LOUPS-GAROUS", kills=0 → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': false,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_night_kills': 0,
      }), isFalse);
    });
    test('NÉGATIF : wolf=true, winner="VILLAGE", kills=0 → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'VILLAGE',
        'wolves_night_kills': 0,
      }), isFalse);
    });
    test('NÉGATIF : wolf=true, winner="LOUPS-GAROUS", kills=1 → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_night_kills': 1,
      }), isFalse);
    });
    test('NÉGATIF : wolf=true, winner="LOUPS-GAROUS", kills=null → false (null != 0)', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_night_kills': null,
      }), isFalse);
    });
    test('NÉGATIF : map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('NÉGATIF : kills absent, reste ok → false (absent est différent de 0)', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
      }), isFalse);
    });
    test('NÉGATIF : wolf=null, winner="LOUPS-GAROUS", kills=0 → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': null,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_night_kills': 0,
      }), isFalse);
    });
    test('NÉGATIF : wolf=true, winner absent, kills=0 → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'wolves_night_kills': 0,
      }), isFalse);
    });
    test('NÉGATIF : kills=2, reste ok → false', () {
      expect(ach.checkCondition({
        'is_wolf_faction': true,
        'winner_role': 'LOUPS-GAROUS',
        'wolves_night_kills': 2,
      }), isFalse);
    });
  });

  // ==========================================
  // 16. somni_blackout — "Nuit Éternelle"
  // ==========================================
  group('somni_blackout', () {
    late Achievement ach;
    setUp(() => ach = _get('somni_blackout'));

    test('POSITIF : role="Somnifère", winner="LOUPS-GAROUS", uses=0 → true', () {
      expect(ach.checkCondition({
        'player_role': 'Somnifère',
        'winner_role': 'LOUPS-GAROUS',
        'somnifere_uses_left': 0,
      }), isTrue);
    });
    test('NÉGATIF : uses absent (→ 1 via ?? 1, donc ≠ 0) → false', () {
      expect(ach.checkCondition({
        'player_role': 'Somnifère',
        'winner_role': 'LOUPS-GAROUS',
      }), isFalse);
    });
    test('NÉGATIF : role="Loup-garou", winner="LOUPS-GAROUS", uses=0 → false', () {
      expect(ach.checkCondition({
        'player_role': 'Loup-garou',
        'winner_role': 'LOUPS-GAROUS',
        'somnifere_uses_left': 0,
      }), isFalse);
    });
    test('NÉGATIF : role="Somnifère", winner="VILLAGE", uses=0 → false', () {
      expect(ach.checkCondition({
        'player_role': 'Somnifère',
        'winner_role': 'VILLAGE',
        'somnifere_uses_left': 0,
      }), isFalse);
    });
    test('NÉGATIF : role="Somnifère", winner="LOUPS-GAROUS", uses=1 → false', () {
      expect(ach.checkCondition({
        'player_role': 'Somnifère',
        'winner_role': 'LOUPS-GAROUS',
        'somnifere_uses_left': 1,
      }), isFalse);
    });
    test('NÉGATIF : role="somnifère" (minuscule, pas de toLowerCase) → false', () {
      expect(ach.checkCondition({
        'player_role': 'somnifère',
        'winner_role': 'LOUPS-GAROUS',
        'somnifere_uses_left': 0,
      }), isFalse);
    });
    test('NÉGATIF : map vide → false', () {
      expect(ach.checkCondition({}), isFalse);
    });
    test('NÉGATIF : role absent, winner="LOUPS-GAROUS", uses=0 → false', () {
      expect(ach.checkCondition({
        'winner_role': 'LOUPS-GAROUS',
        'somnifere_uses_left': 0,
      }), isFalse);
    });
    test('NÉGATIF : uses=null (null via ?? 1 → 1 ≠ 0) → false', () {
      expect(ach.checkCondition({
        'player_role': 'Somnifère',
        'winner_role': 'LOUPS-GAROUS',
        'somnifere_uses_left': null,
      }), isFalse);
    });
    test('NÉGATIF : role="SOMNIFÈRE" (tout majuscule, pas de toLowerCase) → false', () {
      expect(ach.checkCondition({
        'player_role': 'SOMNIFÈRE',
        'winner_role': 'LOUPS-GAROUS',
        'somnifere_uses_left': 0,
      }), isFalse);
    });
  });
}
