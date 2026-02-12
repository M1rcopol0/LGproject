import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:fluffer/globals.dart';
import 'package:fluffer/models/player.dart';

/// Réinitialise TOUS les globals pour isoler chaque test.
void resetGlobalState() {
  globalTalker = TalkerFlutter.init(
    settings: TalkerSettings(maxHistoryItems: 10, useConsoleLogs: false),
  );

  isDayTime = false;
  globalTurnNumber = 1;
  hasVotedThisTurn = false;
  globalRolesDistributed = false;
  nightOnePassed = false;
  globalGovernanceMode = "MAIRE";
  globalTimerMinutes = 2.0;
  globalPlayers = [];

  // Achievement flags
  anybodyDeadYet = false;
  firstDeadPlayerName = null;
  wolfVotedWolf = false;
  pokemonDiedTour1 = false;
  pantinClutchSave = false;
  paradoxAchieved = false;
  chamanSniperAchieved = false;
  evolvedHungerAchieved = false;
  fanSacrificeAchieved = false;
  ultimateFanAchieved = false;
  parkingShotUnlocked = false;
  exorcistWin = false;

  // Night tracking
  nightChamanTarget = null;
  nightWolvesTarget = null;
  nightWolvesTargetSurvived = false;
  wolvesNightKills = 0;
  quicheSavedThisNight = 0;

  // Pick & Ban
  globalPickBan = {
    "village": [
      "Archiviste", "Devin", "Dingo", "Zookeeper", "Enculateur du bled",
      "Exorciste", "Grand-mère", "Houston", "Maison", "Tardos", "Voyageur", "Villageois",
      "Cupidon", "Sorcière", "Voyante", "Saltimbanque", "Chasseur", "Kung-Fu Panda"
    ],
    "loups": [
      "Loup-garou chaman", "Loup-garou évolué", "Somnifère",
    ],
    "solo": [
      "Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Pokémon", "Ron-Aldo"
    ],
  };
}

/// Crée un joueur avec des valeurs par défaut pratiques pour les tests.
Player makePlayer(String name, {
  String? role,
  String team = "village",
  bool isAlive = true,
  bool isPlaying = true,
}) {
  return Player(name: name, isPlaying: isPlaying)
    ..role = role
    ..team = team
    ..isAlive = isAlive;
}

/// Crée une liste de N joueurs "Player1", "Player2", etc.
List<Player> makePlayers(int count, {String role = "Villageois", String team = "village"}) {
  return List.generate(count, (i) => makePlayer("Player${i + 1}", role: role, team: team));
}

/// Helper pour obtenir un BuildContext dans les testWidgets.
Future<BuildContext> getTestContext(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
  return tester.element(find.byType(SizedBox));
}
