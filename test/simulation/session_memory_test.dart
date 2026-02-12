import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluffer/globals.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/logic/role_distribution_logic.dart';

import '../helpers/test_helpers.dart';

/// Pool v3.0 : exclus Villageois, Kung-Fu Panda, Sorcière, Voyante, Chasseur, Cupidon, Saltimbanque
Map<String, List<String>> pickBanV3() => {
  "village": [
    "Archiviste", "Devin", "Dingo", "Zookeeper", "Enculateur du bled",
    "Exorciste", "Grand-mère", "Houston", "Maison", "Tardos", "Voyageur",
  ],
  "loups": [
    "Loup-garou chaman", "Loup-garou évolué", "Somnifère",
  ],
  "solo": [
    "Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Pokémon", "Ron-Aldo",
  ],
};

const _hostileRoles = [
  "Loup-garou chaman", "Loup-garou évolué", "Somnifère",
  "Chuchoteur", "Maître du temps", "Pantin", "Phyl",
  "Dresseur", "Pokémon", "Ron-Aldo",
];

void runSimulation(String label, int playerCount, int gameCount) {
  distributionMemory = {};

  List<Map<String, String>> allDistributions = [];

  for (int game = 1; game <= gameCount; game++) {
    globalPickBan = pickBanV3();

    List<Player> players = List.generate(
      playerCount,
      (i) => Player(name: "J${i + 1}", isPlaying: true),
    );

    RoleDistributionLogic.distribute(players);

    Map<String, String> gameResult = {};
    for (var p in players) {
      gameResult[p.name] = p.role ?? "???";
    }
    allDistributions.add(gameResult);
  }

  // === AFFICHAGE RECAP ===
  print("\n");
  print("=" * 80);
  print("  $label");
  print("=" * 80);

  for (int game = 0; game < gameCount; game++) {
    print("\n┌─────────────────────────────────────────────────────────┐");
    print("│  PARTIE ${game + 1}  —  $playerCount joueurs");
    print("├─────────────────────────────────────────────────────────┤");

    Map<String, String> result = allDistributions[game];
    List<MapEntry<String, String>> village = [];
    List<MapEntry<String, String>> hostile = [];

    for (var entry in result.entries) {
      if (_hostileRoles.contains(entry.value)) {
        hostile.add(entry);
      } else {
        village.add(entry);
      }
    }

    print("│  🟢 VILLAGE:");
    for (var e in village) {
      print("│    ${e.key.padRight(6)} → ${e.value}");
    }
    print("│  🔴 HOSTILES:");
    for (var e in hostile) {
      print("│    ${e.key.padRight(6)} → ${e.value}");
    }
    print("└─────────────────────────────────────────────────────────┘");
  }

  // === TABLEAU DE FRÉQUENCE ===
  print("\n");
  print("─" * 80);
  print("  MÉMOIRE DE SESSION FINALE");
  print("─" * 80);

  var sorted = distributionMemory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  int maxFreq = sorted.isEmpty ? 1 : sorted.first.value;

  print("┌────────────────────────────────┬───────┬──────────────────────┐");
  print("│  Rôle                          │ Freq  │                      │");
  print("├────────────────────────────────┼───────┼──────────────────────┤");
  for (var entry in sorted) {
    String bar = "█" * ((entry.value / maxFreq * 15).round());
    print("│  ${entry.key.padRight(28)} │  ${entry.value.toString().padLeft(2)}  │ $bar");
  }
  print("└────────────────────────────────┴───────┴──────────────────────┘");

  // === ANALYSE RÔLES PAR PARTIE ===
  print("\n");
  print("─" * 80);
  print("  RÔLES PAR PARTIE");
  print("─" * 80);

  Map<String, List<int>> roleInGames = {};
  for (int game = 0; game < gameCount; game++) {
    for (var role in allDistributions[game].values) {
      roleInGames.putIfAbsent(role, () => []);
      roleInGames[role]!.add(game + 1);
    }
  }

  var sortedRoles = roleInGames.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  print("┌────────────────────────────────┬──────────────────────────────┐");
  print("│  Rôle                          │ Apparitions                  │");
  print("├────────────────────────────────┼──────────────────────────────┤");
  for (var entry in sortedRoles) {
    String games = entry.value.map((g) => "P$g").join(", ");
    String count = "(${entry.value.length}/$gameCount)";
    print("│  ${entry.key.padRight(28)} │ $count $games".padRight(65) + "│");
  }
  print("└────────────────────────────────┴──────────────────────────────┘");

  // === RÔLES JAMAIS DISTRIBUÉS ===
  List<String> allPoolRoles = [
    ...pickBanV3()["village"]!, ...pickBanV3()["loups"]!, ...pickBanV3()["solo"]!,
  ];
  List<String> neverSeen = allPoolRoles.where((r) => !roleInGames.containsKey(r)).toList();
  if (neverSeen.isNotEmpty) {
    print("\n  ⚠️  Rôles jamais distribués : ${neverSeen.join(', ')}");
  } else {
    print("\n  ✅  Tous les rôles du pool ont été distribués au moins 1 fois !");
  }
}

void main() {
  setUp(() {
    resetGlobalState();
    SharedPreferences.setMockInitialValues({});
  });

  test('v3.0 — 5 parties à 7 joueurs', () {
    runSimulation("SIMULATION v3.0 — 5 PARTIES × 7 JOUEURS", 7, 5);

    // Vérif : pas de rôles exclus v3.0
    const excluded = ["Villageois", "Kung-Fu Panda", "Sorcière", "Voyante",
                      "Chasseur", "Cupidon", "Saltimbanque"];
    for (var role in distributionMemory.keys) {
      expect(excluded.contains(role), isFalse,
        reason: "Rôle exclu '$role' trouvé dans la distribution !");
    }
  });

  test('v3.0 — 5 parties à 13 joueurs', () {
    runSimulation("SIMULATION v3.0 — 5 PARTIES × 13 JOUEURS", 13, 5);

    const excluded = ["Villageois", "Kung-Fu Panda", "Sorcière", "Voyante",
                      "Chasseur", "Cupidon", "Saltimbanque"];
    for (var role in distributionMemory.keys) {
      expect(excluded.contains(role), isFalse,
        reason: "Rôle exclu '$role' trouvé dans la distribution !");
    }
  });
}
