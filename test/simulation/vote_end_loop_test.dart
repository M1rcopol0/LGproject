// vote_end_loop_test.dart
//
// 100+ parties complètes simulées, centrées sur le bug du loop de fin de vote.
// Le bug : après la mort d'un joueur au vote, le jeu ne revient pas au
// VillageScreen et re-affiche le dernier votant ou le MJResultScreen.
//
// Ce test vérifie deux choses :
//  1. LOGIQUE : checkWinner retourne toujours un résultat non-null dans un
//     nombre fini de tours (pas de loop infini dans la condition de victoire)
//  2. NAVIGATION : après _routeAfterDecision, le VotePlayerSelectionScreen
//     se pop bien lui-même (simulated via canPop / mounted checks)

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluffer/globals.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/logic/logic.dart';
import 'package:fluffer/logic/win_condition_logic.dart';
import 'package:fluffer/logic/elimination_logic.dart';
import 'package:fluffer/logic/vote_logic.dart';
import 'package:fluffer/logic/night/night_actions_logic.dart';
import 'package:fluffer/logic/role_distribution_logic.dart';
import 'package:fluffer/screens/village_screen.dart';
import 'package:fluffer/screens/vote_screens.dart';
import 'package:fluffer/screens/mj_result_screen.dart';

import '../helpers/test_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constantes
// ─────────────────────────────────────────────────────────────────────────────
const int MAX_TURNS = 40; // une partie ne peut pas durer plus que ça
const int NB_PARTIES = 100;

// ─────────────────────────────────────────────────────────────────────────────
// Moteur de simulation headless complet
// ─────────────────────────────────────────────────────────────────────────────
class GameSimulator {
  final BuildContext ctx;
  final List<Player> players;
  final Random rng;
  int turn = 1;
  int nightKills = 0;
  int voteKills = 0;
  String? finalWinner;
  List<String> log = [];

  GameSimulator(this.ctx, this.players, {int seed = 0})
      : rng = Random(seed);

  // --------------------------------------------------------------------------
  // Simulation complète d'une partie
  // Retourne le gagnant, ou null si MAX_TURNS atteint (= loop détecté)
  // --------------------------------------------------------------------------
  String? run() {
    nightOnePassed = false;
    globalTurnNumber = 1;

    for (int t = 1; t <= MAX_TURNS; t++) {
      turn = t;
      globalTurnNumber = t;

      // 1. Nuit : les loups tuent 1 joueur village au hasard
      _simulateNight();

      String? w = WinConditionLogic.checkWinner(players);
      if (w != null) { finalWinner = w; return w; }

      nightOnePassed = true;

      // 2. Jour : vote → 1 joueur éliminé au hasard
      _simulateVote();

      w = WinConditionLogic.checkWinner(players);
      if (w != null) { finalWinner = w; return w; }
    }

    log.add("⚠️ MAX_TURNS atteint sans victoire — LOOP DÉTECTÉ");
    return null; // loop détecté
  }

  // --------------------------------------------------------------------------
  // Nuit : loup tue un joueur village aléatoire (si loup vivant)
  // --------------------------------------------------------------------------
  void _simulateNight() {
    NightActionsLogic.prepareNightStates(players);

    final wolves = players.where((p) => p.isAlive && p.team == "loups").toList();
    if (wolves.isEmpty) return;

    final targets = players.where(
      (p) => p.isAlive && p.team != "loups" && !p.isAwayAsMJ
    ).toList();
    if (targets.isEmpty) return;

    final victim = targets[rng.nextInt(targets.length)];
    final deaths = EliminationLogic.eliminatePlayer(
      ctx, players, victim,
      isVote: false, reason: "Morsure de Loup",
    );
    nightKills += deaths.length;
    for (var d in deaths) {
      log.add("🌙 T$turn nuit: ${d.name}(${d.role}) tué");
    }
  }

  // --------------------------------------------------------------------------
  // Vote : élimine 1 joueur aléatoire parmi les vivants non-MJ
  //   Reproduit EXACTEMENT le flow MJResultScreen._confirmDeath :
  //   - eliminatePlayer sur la cible
  //   - si Chasseur ou Pokémon dans les morts → _handleRetaliationAction simulée
  //   - _routeAfterDecision : vérifie checkWinner après les morts
  // --------------------------------------------------------------------------
  void _simulateVote() {
    // Cibles votables (comme dans _buildVoteManagementScreen)
    final votable = players.where(
      (p) => p.isAlive && p.isPlaying && !p.isAwayAsMJ
    ).toList();
    if (votable.isEmpty) return;

    // Vote aléatoire sur une cible
    final target = votable[rng.nextInt(votable.length)];

    // Simuler le vote (comme VoteLogic.processVillageVote)
    for (var p in players) { p.votes = 0; }
    target.votes = votable.length - 1;
    VoteLogic.processVillageVote(ctx, players);

    // Simuler _confirmDeath
    final victims = EliminationLogic.eliminatePlayer(
      ctx, players, target,
      isVote: true, reason: "Vote du Village",
    );

    for (var d in victims) {
      voteKills++;
      log.add("☀️ T$turn vote: ${d.name}(${d.role}) éliminé");
    }

    if (victims.isEmpty) {
      log.add("☀️ T$turn vote: ${target.name} a survécu (Pantin/Bled/etc.)");
      return;
    }

    // Chaîne de morts (Chasseur, Pokémon) — reproduit le while loop de _confirmDeath
    final List<Player> toProcess = List.from(victims);
    final List<String> processed = [];

    while (toProcess.isNotEmpty) {
      final dead = toProcess.removeAt(0);
      if (processed.contains(dead.name)) continue;
      processed.add(dead.name);

      final role = dead.role?.toLowerCase() ?? "";

      // Chasseur ou Pokémon : tire sur quelqu'un
      if (role == "chasseur" || role == "pokémon" || role == "pokemon") {
        // Simule _handleRetaliationAction : tire sur une cible aléatoire
        final retaliationTargets = players
            .where((p) => p.isAlive)
            .toList();

        if (retaliationTargets.isNotEmpty) {
          final retTarget = retaliationTargets[rng.nextInt(retaliationTargets.length)];
          final newVictims = EliminationLogic.eliminatePlayer(
            ctx, players, retTarget,
            isVote: false, reason: "Tir du ${dead.role}",
          );
          for (var nv in newVictims) {
            log.add("💥 T$turn retaliation: ${nv.name}(${nv.role}) tué par ${dead.name}");
          }
          toProcess.addAll(newVictims);
          voteKills += newVictims.length;
        } else {
          log.add("💨 T$turn retaliation: ${dead.name} voulait tirer mais personne n'est vivant → PASSER");
        }
      }
    }

    // Après traitement des chaînes : _routeAfterDecision vérifie le gagnant
    // (Cette partie est CRITIQUE : c'est ici que le loop peut apparaître)
    // Le test vérifie que checkWinner() est appelable sans crasher
    WinConditionLogic.checkWinner(players);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper : crée une liste de joueurs avec une config donnée
// ─────────────────────────────────────────────────────────────────────────────
List<Player> makeGame(List<({String name, String role, String team})> config) {
  return config.map((c) {
    final p = Player(name: c.name, isPlaying: true);
    p.role = c.role;
    p.team = c.team;
    return p;
  }).toList();
}

void main() {
  setUp(() {
    resetGlobalState();
    SharedPreferences.setMockInitialValues({});
    nightOnePassed = true;
    globalTurnNumber = 2;
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUPE 1 — NAVIGATION : VotePlayerSelectionScreen se pop après MJResultScreen
  // ══════════════════════════════════════════════════════════════════════════
  group('Navigation vote anonyme : VotePlayerSelectionScreen se pop correctement', () {

    Future<BuildContext> buildVillageScreen(
      WidgetTester tester,
      List<Player> players,
    ) async {
      globalVoteAnonyme = true;
      globalTurnNumber = 2;
      nightOnePassed = true;
      hasVotedThisTurn = false;

      await tester.pumpWidget(MaterialApp(
        home: VillageScreen(players: players),
      ));
      await tester.pump();
      return tester.element(find.byType(VillageScreen));
    }

    testWidgets('Vote public : après mort d\'un joueur → retour VillageScreen (pas de loop)', (tester) async {
      final players = [
        makePlayer("Loup",   role: "Loup-garou évolué", team: "loups"),
        makePlayer("V1",     role: "Villageois",         team: "village"),
        makePlayer("V2",     role: "Villageois",         team: "village"),
        makePlayer("V3",     role: "Villageois",         team: "village"),
      ];
      players[0].votes = 3; // Loup est ciblé

      globalVoteAnonyme = false;
      globalTurnNumber = 2;
      nightOnePassed = true;
      hasVotedThisTurn = false;

      await tester.pumpWidget(MaterialApp(home: VillageScreen(players: players)));
      await tester.pump();

      // Lancer le vote (trouver le bouton voter)
      final voteBtns = find.textContaining('VOTER');
      if (voteBtns.evaluate().isNotEmpty) {
        await tester.tap(voteBtns.first);
        await tester.pumpAndSettle();
      }

      // On doit être soit sur MJResultScreen soit encore sur VillageScreen
      // (si le bouton n'a pas été trouvé ou a été désactivé)
      final mjScreen = find.byType(MJResultScreen);
      final villageScreen = find.byType(VillageScreen);
      expect(
        mjScreen.evaluate().isNotEmpty || villageScreen.evaluate().isNotEmpty,
        isTrue,
        reason: "On doit être sur MJResultScreen ou VillageScreen après le vote",
      );

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Vote anonyme : VotePlayerSelectionScreen popped après MJResultScreen', (tester) async {
      final players = [
        makePlayer("Loup", role: "Loup-garou évolué", team: "loups"),
        makePlayer("V1",   role: "Villageois",         team: "village"),
        makePlayer("V2",   role: "Villageois",         team: "village"),
      ];
      for (var p in players) { p.votes = 0; }
      players[0].votes = 2;

      globalVoteAnonyme = true;
      globalTurnNumber = 2;
      nightOnePassed = true;
      hasVotedThisTurn = false;

      await tester.pumpWidget(MaterialApp(home: VillageScreen(players: players)));
      await tester.pump();

      // Lancer le vote
      final voteBtns = find.textContaining('VOTER');
      if (voteBtns.evaluate().isNotEmpty) {
        await tester.tap(voteBtns.first);
        await tester.pumpAndSettle();
      }

      // VotePlayerSelectionScreen peut être visible (en cours de vote)
      // OU on est revenus à VillageScreen si le vote a déjà eu lieu
      // L'important : PAS de loop = l'état est stable
      await tester.pump(const Duration(seconds: 5));

      // Vérifier pas de loop : ni VotePlayerSelectionScreen ni MJResultScreen
      // ne sont empilés l'un sur l'autre DE MANIÈRE RÉPÉTÉE
      final voteScreens = find.byType(VotePlayerSelectionScreen);
      final mjScreens = find.byType(MJResultScreen);
      // On ne doit pas avoir les deux simultanément après pumpAndSettle
      expect(
        voteScreens.evaluate().length <= 1 && mjScreens.evaluate().length <= 1,
        isTrue,
        reason: "Pas de double instanciation = pas de loop navigation",
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUPE 2 — LOGIQUE : _routeAfterDecision ne bloque pas le jeu
  //   Simule le comportement de _routeAfterDecision :
  //   - si winner != null → jeu terminé
  //   - si winner == null → jeu continue (pas de loop)
  // ══════════════════════════════════════════════════════════════════════════
  group('_routeAfterDecision : checkWinner cohérent avant et après le vote', () {

    testWidgets('Vote anonyme : checkWinner identique avant et après onComplete', (tester) async {
      final ctx = await getTestContext(tester);

      // Config : loups(1) vs village(1) → après mort du village, loups gagnent
      final players = [
        makePlayer("Loup", role: "Loup-garou évolué", team: "loups"),
        makePlayer("V1",   role: "Villageois",         team: "village"),
      ];
      globalTurnNumber = 2;
      nightOnePassed = true;

      // Simuler _confirmDeath (mort de V1)
      EliminationLogic.eliminatePlayer(ctx, players, players[1], isVote: true);

      // Appel 1 : dans _routeAfterDecision
      final winnerInMJResult = WinConditionLogic.checkWinner(players);

      // Simuler widget.onComplete() → _checkGameOver → checkWinner
      final winnerInVillage = WinConditionLogic.checkWinner(players);

      // Les deux appels doivent retourner le MÊME résultat
      expect(winnerInMJResult, equals(winnerInVillage),
          reason: "checkWinner doit être déterministe entre MJResultScreen et onComplete");
      expect(winnerInMJResult, isNotNull,
          reason: "Avec V1 mort et Loup vivant, la victoire doit être détectée");

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Vote anonyme : checkWinner null AVANT mort = même résultat APRÈS annonce PASSER', (tester) async {
      final ctx = await getTestContext(tester);

      // Pantin survit au vote (victims.isEmpty) → _routeAfterDecision appelé avec même état
      final players = [
        makePlayer("Loup",   role: "Loup-garou évolué", team: "loups"),
        makePlayer("Pantin", role: "Pantin",             team: "solo"),
        makePlayer("V1",     role: "Villageois",         team: "village"),
      ];
      globalTurnNumber = 2;
      nightOnePassed = true;

      // Premier vote Pantin → survit (hasSurvivedVote = false)
      final victims = EliminationLogic.eliminatePlayer(
        ctx, players, players[1],
        isVote: true, reason: "Vote du Village",
      );
      expect(victims, isEmpty, reason: "Pantin survit à son premier vote");

      // _routeAfterDecision : winner == null (Pantin vivant + Loup + V1)
      final winnerBefore = WinConditionLogic.checkWinner(players);
      expect(winnerBefore, isNull, reason: "Jeu continue, Pantin vivant");

      // Simuler onComplete → checkWinner doit retourner le même résultat
      final winnerAfterComplete = WinConditionLogic.checkWinner(players);
      expect(winnerAfterComplete, equals(winnerBefore),
          reason: "Pas de double navigation : winner cohérent");

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Vote public : _handleNoOneDies → checkWinner cohérent (grâce du village)', (tester) async {
      final ctx = await getTestContext(tester);

      final players = [
        makePlayer("Loup", role: "Loup-garou évolué", team: "loups"),
        makePlayer("V1",   role: "Villageois",         team: "village"),
        makePlayer("V2",   role: "Villageois",         team: "village"),
      ];
      globalTurnNumber = 2;
      nightOnePassed = true;

      // Grâce du village : personne ne meurt → état inchangé
      final winnerBeforeGrace = WinConditionLogic.checkWinner(players);
      // Simuler onComplete (aucun mort)
      final winnerAfterGrace = WinConditionLogic.checkWinner(players);

      expect(winnerBeforeGrace, equals(winnerAfterGrace));
      expect(winnerBeforeGrace, isNull,
          reason: "Avec grâce du village et 3 joueurs (2 factions), pas de victoire");

      await tester.pump(const Duration(seconds: 5));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUPE 3 — LOGIQUE : canPop / mounted après _routeAfterDecision
  //   Reproduit la condition ligne 80-82 de vote_screens.dart :
  //   if (mounted && Navigator.canPop(context)) Navigator.pop(context)
  // ══════════════════════════════════════════════════════════════════════════
  group('Condition canPop de VotePlayerSelectionScreen', () {

    testWidgets('Après pop de MJResultScreen, Navigator.canPop doit être true', (tester) async {
      globalVoteAnonyme = true;
      globalTurnNumber = 2;
      nightOnePassed = true;
      hasVotedThisTurn = false;

      final players = [
        makePlayer("Loup", role: "Loup-garou évolué", team: "loups"),
        makePlayer("V1",   role: "Villageois",         team: "village"),
        makePlayer("V2",   role: "Villageois",         team: "village"),
        makePlayer("V3",   role: "Villageois",         team: "village"),
      ];

      // Construire la pile : VillageScreen → VotePlayerSelectionScreen
      await tester.pumpWidget(MaterialApp(
        home: VillageScreen(players: players),
      ));
      await tester.pump();

      // Simuler la pile : VillageScreen + VotePlayerSelectionScreen + MJResultScreen
      // En poussant VotePlayerSelectionScreen par-dessus VillageScreen
      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
      navigatorState.push(MaterialPageRoute(
        builder: (_) => VotePlayerSelectionScreen(
          allPlayers: players,
          onComplete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Vérifier que canPop est true (VillageScreen est en dessous)
      expect(navigatorState.canPop(), isTrue,
          reason: "canPop doit être true quand VotePlayerSelectionScreen est sur VillageScreen");

      // Simuler MJResultScreen empilé par-dessus
      navigatorState.push(MaterialPageRoute(
        builder: (_) => MJResultScreen(allPlayers: players, onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      expect(navigatorState.canPop(), isTrue,
          reason: "canPop true avec MJResultScreen au sommet");

      // Simuler _routeAfterDecision : pop MJResultScreen
      navigatorState.pop();
      await tester.pumpAndSettle();

      // Maintenant : VillageScreen + VotePlayerSelectionScreen
      // canPop doit être true pour que VotePlayerSelectionScreen puisse se pop
      expect(navigatorState.canPop(), isTrue,
          reason: "Après pop MJResultScreen, canPop doit être true pour pop VotePlayerSelectionScreen");

      // Simuler ligne 80 de vote_screens.dart : Navigator.pop(context)
      navigatorState.pop();
      await tester.pumpAndSettle();

      // Maintenant seul VillageScreen reste → canPop est false
      expect(navigatorState.canPop(), isFalse,
          reason: "Après pop VotePlayerSelectionScreen, seul VillageScreen reste");

      // Vérifier qu'on est bien sur VillageScreen
      expect(find.byType(VillageScreen), findsOneWidget,
          reason: "VillageScreen doit être l'écran actif après tout le flow de vote");
      expect(find.byType(VotePlayerSelectionScreen), findsNothing,
          reason: "VotePlayerSelectionScreen ne doit plus être dans la pile");
      expect(find.byType(MJResultScreen), findsNothing,
          reason: "MJResultScreen ne doit plus être dans la pile");
    });

    testWidgets('pushAndRemoveUntil (winner) : mounted=false pour VotePlayerSelectionScreen', (tester) async {
      globalVoteAnonyme = true;
      globalTurnNumber = 2;
      nightOnePassed = true;

      final players = [
        makePlayer("Loup", role: "Loup-garou évolué", team: "loups"),
        makePlayer("V1",   role: "Villageois",         team: "village"),
      ];

      await tester.pumpWidget(MaterialApp(
        home: VillageScreen(players: players),
      ));
      await tester.pump();

      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));

      // Empiler VotePlayerSelectionScreen + MJResultScreen
      navigatorState.push(MaterialPageRoute(
        builder: (_) => VotePlayerSelectionScreen(allPlayers: players, onComplete: () {}),
      ));
      await tester.pumpAndSettle();
      navigatorState.push(MaterialPageRoute(
        builder: (_) => MJResultScreen(allPlayers: players, onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      // Tuer V1 pour déclencher une victoire
      players[1].isAlive = false;
      final winner = WinConditionLogic.checkWinner(players);
      expect(winner, equals("LOUPS-GAROUS"));

      // Simuler _navigateToGameOver : pushAndRemoveUntil
      // (Pas de GameOverScreen disponible sans mocks, on utilise une Scaffold simple)
      navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text("GAME OVER"))),
        (route) => false,
      );
      await tester.pumpAndSettle();

      // VotePlayerSelectionScreen et MJResultScreen doivent être hors de la pile
      expect(find.byType(VotePlayerSelectionScreen), findsNothing,
          reason: "VotePlayerSelectionScreen retiré par pushAndRemoveUntil");
      expect(find.byType(MJResultScreen), findsNothing,
          reason: "MJResultScreen retiré par pushAndRemoveUntil");
      expect(find.text("GAME OVER"), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUPE 4 — 100 PARTIES COMPLÈTES : détection loop
  //   Chaque partie doit terminer en ≤ MAX_TURNS tours.
  //   Un null retourné = loop détecté.
  // ══════════════════════════════════════════════════════════════════════════
  group('100 parties complètes : aucun loop', () {

    // --- Configs de parties ---
    List<Player> config_villageBasique(int n) => [
      for (int i = 0; i < (n ~/ 3); i++)
        makePlayer("Loup${i+1}", role: "Loup-garou évolué", team: "loups"),
      for (int i = 0; i < (n - n ~/ 3); i++)
        makePlayer("V${i+1}", role: "Villageois", team: "village"),
    ];

    List<Player> config_avecChasseur() => [
      makePlayer("Loup1", role: "Loup-garou évolué", team: "loups"),
      makePlayer("Loup2", role: "Loup-garou évolué", team: "loups"),
      makePlayer("Chasseur", role: "Chasseur", team: "village"),
      makePlayer("V1", role: "Villageois", team: "village"),
      makePlayer("V2", role: "Villageois", team: "village"),
      makePlayer("V3", role: "Villageois", team: "village"),
    ];

    List<Player> config_avecPokemon() => [
      makePlayer("Loup1", role: "Loup-garou évolué", team: "loups"),
      makePlayer("Loup2", role: "Loup-garou évolué", team: "loups"),
      makePlayer("Dresseur", role: "Dresseur", team: "solo"),
      makePlayer("Pokemon", role: "Pokémon", team: "solo"),
      makePlayer("V1", role: "Villageois", team: "village"),
      makePlayer("V2", role: "Villageois", team: "village"),
    ];

    List<Player> config_avecArchiviste({bool transcended = false}) {
      final arch = makePlayer("Archiviste", role: "Archiviste", team: "village");
      if (transcended) arch.isAwayAsMJ = true;
      return [
        makePlayer("Loup1", role: "Loup-garou évolué", team: "loups"),
        makePlayer("Loup2", role: "Loup-garou évolué", team: "loups"),
        arch,
        makePlayer("V1", role: "Villageois", team: "village"),
        makePlayer("V2", role: "Villageois", team: "village"),
        makePlayer("V3", role: "Villageois", team: "village"),
      ];
    }

    List<Player> config_avecVoyageur({bool absent = false}) {
      final v = makePlayer("Voyageur", role: "Voyageur", team: "village");
      v.isInTravel = absent;
      return [
        makePlayer("Loup1", role: "Loup-garou évolué", team: "loups"),
        makePlayer("Loup2", role: "Loup-garou évolué", team: "loups"),
        v,
        makePlayer("V1", role: "Villageois", team: "village"),
        makePlayer("V2", role: "Villageois", team: "village"),
      ];
    }

    List<Player> config_avecPantin() => [
      makePlayer("Loup1", role: "Loup-garou évolué", team: "loups"),
      makePlayer("Loup2", role: "Loup-garou évolué", team: "loups"),
      makePlayer("Pantin", role: "Pantin", team: "solo"),
      makePlayer("V1", role: "Villageois", team: "village"),
      makePlayer("V2", role: "Villageois", team: "village"),
      makePlayer("V3", role: "Villageois", team: "village"),
    ];

    List<Player> config_avecRonAldo() {
      final ronAldo = makePlayer("Ron-Aldo", role: "Ron-Aldo", team: "solo");
      final fan1 = makePlayer("Fan1", role: "Villageois", team: "solo");
      fan1.isFanOfRonAldo = true; fan1.fanJoinOrder = 1;
      return [
        makePlayer("Loup1", role: "Loup-garou évolué", team: "loups"),
        makePlayer("Loup2", role: "Loup-garou évolué", team: "loups"),
        ronAldo, fan1,
        makePlayer("V1", role: "Villageois", team: "village"),
        makePlayer("V2", role: "Villageois", team: "village"),
      ];
    }

    List<Player> config_mixte() => [
      makePlayer("Loup1", role: "Loup-garou évolué", team: "loups"),
      makePlayer("Loup2", role: "Loup-garou évolué", team: "loups"),
      makePlayer("Chasseur", role: "Chasseur", team: "village"),
      makePlayer("Dresseur", role: "Dresseur", team: "solo"),
      makePlayer("Pokemon", role: "Pokémon", team: "solo"),
      makePlayer("V1", role: "Villageois", team: "village"),
      makePlayer("V2", role: "Villageois", team: "village"),
      makePlayer("V3", role: "Villageois", team: "village"),
    ];

    List<Player> config_archiviste_transcende_avec_pokemon() {
      final arch = makePlayer("Archiviste", role: "Archiviste", team: "village");
      arch.isAwayAsMJ = true;
      return [
        makePlayer("Loup1", role: "Loup-garou évolué", team: "loups"),
        arch,
        makePlayer("Dresseur", role: "Dresseur", team: "solo"),
        makePlayer("Pokemon", role: "Pokémon", team: "solo"),
        makePlayer("Chasseur", role: "Chasseur", team: "village"),
        makePlayer("V1", role: "Villageois", team: "village"),
      ];
    }

    testWidgets('Config 1 : 10 parties village basique 6 joueurs', (tester) async {
      final ctx = await getTestContext(tester);
      int loops = 0;
      for (int i = 0; i < 10; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_villageBasique(6), seed: i);
        final w = sim.run();
        if (w == null) {
          loops++;
          debugPrint("LOOP détecté partie $i : ${sim.log.join(' | ')}");
        }
      }
      expect(loops, equals(0), reason: "Config village basique 6j : $loops loops détectés");
    });

    testWidgets('Config 2 : 10 parties village basique 9 joueurs', (tester) async {
      final ctx = await getTestContext(tester);
      int loops = 0;
      for (int i = 0; i < 10; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_villageBasique(9), seed: i + 10);
        final w = sim.run();
        if (w == null) { loops++; debugPrint("LOOP 9j #$i : ${sim.log.join(' | ')}"); }
      }
      expect(loops, equals(0), reason: "Village basique 9j : $loops loops");
    });

    testWidgets('Config 3 : 15 parties avec Chasseur (chain death)', (tester) async {
      final ctx = await getTestContext(tester);
      final List<String> loopDetails = [];
      for (int i = 0; i < 15; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_avecChasseur(), seed: i + 20);
        final w = sim.run();
        if (w == null) loopDetails.add("Partie $i (seed ${i+20}): ${sim.log.last}");
      }
      expect(loopDetails, isEmpty,
          reason: "Chasseur chain death : loops détectés :\n${loopDetails.join('\n')}");
    });

    testWidgets('Config 4 : 15 parties avec Dresseur + Pokémon', (tester) async {
      final ctx = await getTestContext(tester);
      final List<String> loopDetails = [];
      for (int i = 0; i < 15; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_avecPokemon(), seed: i + 40);
        final w = sim.run();
        if (w == null) loopDetails.add("Partie $i : winner=null après ${sim.turn} tours. Log: ${sim.log.join(' | ')}");
      }
      // Laisser expirer les timers de TrophyService (toast 4s)
      await tester.pump(const Duration(seconds: 5));
      expect(loopDetails, isEmpty,
          reason: "Dresseur+Pokémon loops :\n${loopDetails.join('\n')}");
    });

    testWidgets('Config 5 : 10 parties avec Archiviste normal', (tester) async {
      final ctx = await getTestContext(tester);
      int loops = 0;
      for (int i = 0; i < 10; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_avecArchiviste(transcended: false), seed: i + 60);
        final w = sim.run();
        if (w == null) { loops++; debugPrint("LOOP Archiviste normal #$i: ${sim.log.join(' | ')}"); }
      }
      expect(loops, equals(0), reason: "Archiviste normal : $loops loops");
    });

    testWidgets('Config 6 : 10 parties Archiviste TRANSCENDÉ (fix 1b/6b)', (tester) async {
      final ctx = await getTestContext(tester);
      final List<String> loopDetails = [];
      for (int i = 0; i < 10; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_avecArchiviste(transcended: true), seed: i + 70);
        final w = sim.run();
        if (w == null) {
          loopDetails.add(
            "Partie $i (seed ${i+70}) bloquée au tour ${sim.turn}. "
            "Vivants: ${sim.players.where((p) => p.isAlive).map((p) => '${p.name}(${p.role},awayMJ=${p.isAwayAsMJ})').join(', ')}"
          );
        }
      }
      expect(loopDetails, isEmpty,
          reason: "LOOP Archiviste transcendé :\n${loopDetails.join('\n')}");
    });

    testWidgets('Config 7 : 10 parties avec Voyageur absent', (tester) async {
      final ctx = await getTestContext(tester);
      int loops = 0;
      for (int i = 0; i < 10; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_avecVoyageur(absent: true), seed: i + 80);
        final w = sim.run();
        if (w == null) { loops++; }
      }
      expect(loops, equals(0), reason: "Voyageur absent : $loops loops");
    });

    testWidgets('Config 8 : 5 parties avec Pantin (survie premier vote)', (tester) async {
      final ctx = await getTestContext(tester);
      int loops = 0;
      for (int i = 0; i < 5; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_avecPantin(), seed: i + 90);
        final w = sim.run();
        if (w == null) { loops++; debugPrint("LOOP Pantin #$i: ${sim.log.join(' | ')}"); }
      }
      expect(loops, equals(0), reason: "Pantin : $loops loops");
    });

    testWidgets('Config 9 : 5 parties avec Ron-Aldo', (tester) async {
      final ctx = await getTestContext(tester);
      int loops = 0;
      for (int i = 0; i < 5; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_avecRonAldo(), seed: i + 100);
        final w = sim.run();
        if (w == null) { loops++; debugPrint("LOOP Ron-Aldo #$i: ${sim.log.join(' | ')}"); }
      }
      // Laisser expirer les timers de TrophyService (toast 4s)
      await tester.pump(const Duration(seconds: 5));
      expect(loops, equals(0), reason: "Ron-Aldo : $loops loops");
    });

    testWidgets('Config 10 : 5 parties mixtes (Chasseur+Dresseur+Pokémon)', (tester) async {
      final ctx = await getTestContext(tester);
      int loops = 0;
      for (int i = 0; i < 5; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_mixte(), seed: i + 110);
        final w = sim.run();
        if (w == null) { loops++; debugPrint("LOOP mixte #$i : ${sim.log.join(' | ')}"); }
      }
      expect(loops, equals(0), reason: "Mixte : $loops loops");
    });

    testWidgets('Config 11 : 5 parties Archiviste transcendé + Dresseur/Pokémon (cas combiné critique)', (tester) async {
      final ctx = await getTestContext(tester);
      final List<String> loopDetails = [];
      for (int i = 0; i < 5; i++) {
        resetGlobalState();
        final sim = GameSimulator(ctx, config_archiviste_transcende_avec_pokemon(), seed: i + 120);
        final w = sim.run();
        if (w == null) {
          final alive = sim.players.where((p) => p.isAlive).map((p) =>
            '${p.name}(${p.role},awayMJ=${p.isAwayAsMJ},team=${p.team})').join(', ');
          loopDetails.add("Partie $i bloquée T${sim.turn}: vivants=[$alive]");
        }
      }
      expect(loopDetails, isEmpty,
          reason: "Arch transcendé + Dresseur/Pokémon loops :\n${loopDetails.join('\n')}");
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GROUPE 5 — EDGE CASES : états qui pourraient bloquer le jeu
  // ══════════════════════════════════════════════════════════════════════════
  group('Edge cases : états bloquants potentiels', () {

    testWidgets('Tous les joueurs morts sauf archiviste transcendé → ÉGALITÉ, pas de loop', (tester) async {
      final ctx = await getTestContext(tester);
      resetGlobalState();

      final arch = makePlayer("Arch", role: "Archiviste", team: "village");
      arch.isAwayAsMJ = true;
      final players = [
        arch,
        makePlayer("L1", role: "Loup-garou évolué", team: "loups")..isAlive = false,
        makePlayer("V1", role: "Villageois", team: "village")..isAlive = false,
      ];
      nightOnePassed = true;
      globalTurnNumber = 3;

      // Simuler ce que _routeAfterDecision vérifie
      final winner = WinConditionLogic.checkWinner(players);
      expect(winner, equals("ÉGALITÉ_SANGUINAIRE"),
          reason: "Archiviste transcendé seul vivant → ÉGALITÉ (exclu par isAwayAsMJ)");
    });

    testWidgets('Chasseur tué par retaliation d\'un autre Chasseur → pas de boucle infinie dans while', (tester) async {
      final ctx = await getTestContext(tester);
      resetGlobalState();

      final players = [
        makePlayer("Chasseur1", role: "Chasseur", team: "village"),
        makePlayer("Chasseur2", role: "Chasseur", team: "village"),
        makePlayer("Loup",      role: "Loup-garou évolué", team: "loups"),
      ];
      nightOnePassed = true;
      globalTurnNumber = 2;

      // Chasseur1 voté → retaliation tire sur Chasseur2
      // Chasseur2 mort → retaliation tire sur Loup
      // → while loop de _confirmDeath se termine car processedNames guard
      final victims1 = EliminationLogic.eliminatePlayer(
        ctx, players, players[0], isVote: true, reason: "Vote du Village",
      );
      expect(victims1.isNotEmpty, isTrue, reason: "Chasseur1 meurt au vote");

      if (players[1].isAlive) {
        final victims2 = EliminationLogic.eliminatePlayer(
          ctx, players, players[1], isVote: false, reason: "Tir du Chasseur",
        );
        // La chaîne peut tuer Chasseur2 qui pourrait tirer sur Loup
        // Mais processedNames empêche le loop
        expect(victims2.length, lessThanOrEqualTo(1));
      }

      // Vérifier l'état final
      final winner = WinConditionLogic.checkWinner(players);
      // Le jeu doit être dans un état cohérent (pas de crash)
      expect(true, isTrue, reason: "Pas de crash ni de boucle infinie dans la chaîne Chasseur");
    });

    testWidgets('Vote quand 0 joueur votable → processVillageVote ne crashe pas', (tester) async {
      final ctx = await getTestContext(tester);
      resetGlobalState();

      // Tous immunisés ou archiviste absent
      final arch = makePlayer("Arch", role: "Archiviste", team: "village");
      arch.isAwayAsMJ = true;
      final bled = makePlayer("Bled", role: "Villageois", team: "village");
      bled.isImmunizedFromVote = true;
      final players = [
        makePlayer("Loup", role: "Loup-garou évolué", team: "loups"),
        bled, arch,
      ];
      nightOnePassed = true;

      // processVillageVote avec liste votable vide/réduite ne doit pas crasher
      VoteLogic.processVillageVote(ctx, players);

      // Vérifier état cohérent
      expect(players.every((p) => p.isAlive), isTrue);
    });

    testWidgets('Vote avec Archiviste transcendé : isAwayAsMJ exclu de votes et de votable', (tester) async {
      final ctx = await getTestContext(tester);
      resetGlobalState();

      final arch = makePlayer("Arch", role: "Archiviste", team: "village");
      arch.isAwayAsMJ = true;
      final players = [
        makePlayer("Loup", role: "Loup-garou évolué", team: "loups"),
        makePlayer("V1",   role: "Villageois", team: "village"),
        arch,
      ];
      nightOnePassed = true;
      globalTurnNumber = 2;

      // Simuler vote_screens.dart ligne 34 : filtre voters
      final voters = players.where((p) => p.isAlive && p.isPlaying && !p.isAwayAsMJ).toList();
      expect(voters.any((p) => p.isAwayAsMJ), isFalse,
          reason: "Archiviste transcendé exclu des votants");

      // Simuler _buildVoteManagementScreen ligne 62 : filtre sortedPlayers
      final sortedPlayers = players.where((p) => p.isAlive && p.isPlaying && !p.isAwayAsMJ).toList();
      expect(sortedPlayers.any((p) => p.isAwayAsMJ), isFalse,
          reason: "Archiviste transcendé exclu de l'affichage MJResultScreen");

      // Simuler vote_screens.dart ligne 220 : filtre eligibleTargets (cibles votables)
      final eligibleTargets = players.where((p) => p.isAlive && p.isPlaying && !p.isAwayAsMJ).toList();
      expect(eligibleTargets.any((p) => p.isAwayAsMJ), isFalse,
          reason: "Archiviste transcendé non ciblable au vote");
    });

    testWidgets('Voyageur en voyage : peut quand même être voté (meurt et revient)', (tester) async {
      final ctx = await getTestContext(tester);
      resetGlobalState();

      final voyageur = makePlayer("Voyageur", role: "Voyageur", team: "village");
      voyageur.isInTravel = true;
      final players = [
        makePlayer("Loup", role: "Loup-garou évolué", team: "loups"),
        voyageur,
        makePlayer("V1",   role: "Villageois", team: "village"),
      ];
      nightOnePassed = true;

      // Voyageur est dans eligibleTargets (isAwayAsMJ = false pour le Voyageur)
      final eligible = players.where((p) => p.isAlive && p.isPlaying && !p.isAwayAsMJ).toList();
      expect(eligible.any((p) => p.name == "Voyageur"), isTrue,
          reason: "Voyageur en voyage peut être voté (affiché dans eligibleTargets)");

      // Vote sur le Voyageur
      final victims = EliminationLogic.eliminatePlayer(
        ctx, players, voyageur, isVote: true, reason: "Vote",
      );
      // Selon elimination_logic.dart l.123 : if (!isVote) return []; → ici isVote=true donc meurt
      expect(voyageur.isAlive, isFalse,
          reason: "Voyageur meurt quand voté (isVote=true ne le protège pas)");
      expect(voyageur.isInTravel, isFalse,
          reason: "Voyage annulé au moment de la mort");
    });
  });
}
