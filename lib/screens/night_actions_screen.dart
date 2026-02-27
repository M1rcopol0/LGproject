import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';
import '../logic/night/night_actions_logic.dart';
import '../services/game_save_service.dart';
import '../night_interfaces/role_action_dispatcher.dart';
import '../logic/achievement_logic.dart';
import 'fin_screen.dart';
import '../widgets/morning_summary_dialog.dart';
import '../logic/logic.dart';
import '../night_interfaces/pokemon_interface.dart'; // Assurez-vous d'avoir ce fichier
import '../night_interfaces/chasseur_death_handler.dart';
import '../state/game_history.dart';

class NightActionsScreen extends StatefulWidget {
  final List<Player> players;
  const NightActionsScreen({super.key, required this.players});

  @override
  State<NightActionsScreen> createState() => _NightActionsScreenState();
}

class _NightActionsScreenState extends State<NightActionsScreen> {
  int currentActionIndex = 0;
  Map<Player, String> pendingDeaths = {};
  String? _exorcismeResult;
  bool _somnifereUsed = false;
  bool nightFinished = false;

  @override
  void initState() {
    super.initState();
    debugPrint("--------------------------------------------------");
    debugPrint("🌑 LOG [NightScreen] : Ouverture de la Nuit $globalTurnNumber");
    NightActionsLogic.prepareNightStates(widget.players);
    for (var p in widget.players) {
      p.isSelected = false;
    }
    _checkSkipAction();
  }

  void _checkSkipAction() {
    if (currentActionIndex >= nightActionsOrder.length) {
      _finishNight();
      return;
    }

    final action = nightActionsOrder[currentActionIndex];
    final roleName = action.role;

    if (roleName == "Phyl" && globalTurnNumber > 1) { debugPrint("📡 CAPTEUR [Dispatch] : SKIP Phyl (tour > 1)."); _nextAction(); return; }
    if (roleName == "Cupidon" && globalTurnNumber > 1) { debugPrint("📡 CAPTEUR [Dispatch] : SKIP Cupidon (tour > 1)."); _nextAction(); return; }

    bool shouldWakeUp = false;

    // --- LOGIQUE DE RÉVEIL ---
    if (roleName == "Loups-garous évolués") {
      shouldWakeUp = widget.players.any((p) => p.isAlive && p.isWolf);
    }
    else if (roleName == "Dresseur") {
      // Le Dresseur se réveille s'il est vivant (pour protéger)
      shouldWakeUp = widget.players.any((p) => p.role?.toLowerCase() == "dresseur" && p.isAlive);
    }
    else if (roleName == "Pokémon" || roleName == "Pokemon") {
      // Le Pokémon se réveille chaque nuit pour attaquer
      bool pokemonIsAlive = widget.players.any((p) => (p.role?.toLowerCase() == "pokémon" || p.role?.toLowerCase() == "pokemon") && p.isAlive);
      shouldWakeUp = pokemonIsAlive;
      if (shouldWakeUp) {
        debugPrint("🔍 CAPTEUR [Pokémon] : Pokémon vivant -> RÉVEIL pour attaquer !");
      }
    }
    else {
      // Cas général
      shouldWakeUp = widget.players.any((p) {
        final r = p.role?.toLowerCase() ?? "";
        final a = roleName.toLowerCase();
        if (r != a || !p.isAlive) return false;
        if (a == "somnifère") return p.somnifereUses > 0;
        if (a == "houston") return (globalTurnNumber % 2 != 0);
        if (a == "exorciste") return (globalTurnNumber == 2);
        return true;
      });
    }

    if (!shouldWakeUp) {
      debugPrint("📡 CAPTEUR [Dispatch] : SKIP $roleName (pas de joueur éligible).");
      Future.microtask(() => _nextAction());
    } else {
      playSfx(action.sound);
    }
  }

  void _nextAction() {
    if (!mounted) return;
    AchievementLogic.checkMidGameAchievements(context, widget.players);
    for (var p in widget.players) p.isSelected = false;

    if (currentActionIndex < nightActionsOrder.length - 1) {
      setState(() => currentActionIndex++);
      _checkSkipAction();
    } else {
      _finishNight();
    }
  }

  void _finishNight() {
    if (nightFinished) return;
    setState(() => nightFinished = true);
    nightOnePassed = true;
    stopMusic();

    bool isExorcismWin = (_exorcismeResult == "SUCCESS");

    debugPrint("🔍 CAPTEUR [NightEnd] : Résolution de la nuit. pendingDeaths: ${pendingDeaths.length}, exorcisme: $_exorcismeResult, somnifère: $_somnifereUsed.");

    // Résolution des morts programmées (Loup, Sorcière, etc. ET Pokémon si actif)
    final result = NightActionsLogic.resolveNight(
      context,
      widget.players,
      pendingDeaths,
      somnifereActive: _somnifereUsed,
      exorcistSuccess: isExorcismWin,
    );

    // Si le Pokémon a tué quelqu'un via pendingDeaths, c'est résolu ici.
    // La victime est dans result.deadPlayers.

    if (result.exorcistVictory) {
      exorcistWin = true;
    }

    // Enregistrement dans l'historique
    if (result.deadPlayers.isNotEmpty) {
      gameHistory.add(TurnHistoryEntry(
        turn: globalTurnNumber,
        phase: "nuit",
        eliminations: result.deadPlayers.map((p) => EliminationRecord(
          playerName: p.name,
          role: p.role ?? "?",
          team: p.team,
          reason: result.deathReasons[p.name] ?? "Cause inconnue",
        )).toList(),
      ));
    }

    playSfx((result.deadPlayers.isEmpty && !result.villageIsNarcoleptic)
        ? "oiseau.mp3"
        : "cloche.mp3");

    // --- AFFICHAGE DU RÉSUMÉ ---
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MorningSummaryDialog(
        result: result,
        players: widget.players,
        onConfirm: () async {
          debugPrint("🔴 CAPTEUR [Matin] : Bouton Confirm pressé.");
          bool summaryDialogClosed = false;

          // 1. GESTION DES MORTS NOCTURNES SPÉCIALES (Chasseur, Pokémon — chaînes de morts)
          List<Player> playersToProcess = List.from(result.deadPlayers);
          List<String> processedNames = [];

          while (playersToProcess.isNotEmpty) {
            final p = playersToProcess.removeAt(0);
            if (processedNames.contains(p.name)) continue;
            processedNames.add(p.name);

            final String? role = p.role?.toLowerCase();

            // Si le Dresseur meurt : RIEN DE SPÉCIAL (Le Pokémon survit)
            if (role == "dresseur") {
              debugPrint("🔍 CAPTEUR [Mort] : Le Dresseur est mort. Le Pokémon devient indépendant.");
            }

            // Si le Chasseur meurt : VENGEANCE
            else if (role == "chasseur") {
              debugPrint("🔍 CAPTEUR [Mort] : Le Chasseur est mort ! Vengeance...");

              if (!summaryDialogClosed) {
                Navigator.pop(ctx);
                summaryDialogClosed = true;
              }

              final chasseurResult = await ChasseurDeathHandler.handleVengeance(
                context: context,
                allPlayers: widget.players,
                chasseur: p,
              );
              final List<Player> newVictims = chasseurResult.$1;
              final String? directTargetName = chasseurResult.$2;

              if (newVictims.isNotEmpty) {
                addToHistory(globalTurnNumber, "nuit", newVictims.map((v) => EliminationRecord(
                  playerName: v.name,
                  role: v.role ?? "?",
                  team: v.team,
                  reason: (v.isLinked && v.name != directTargetName)
                      ? "💔 Chagrin d'amour (${v.lover?.name ?? '?'})"
                      : "Tir du Chasseur",
                )).toList());
              }

              playersToProcess.addAll(newVictims);

              // --- CHECK VICTOIRE IMMÉDIAT APRÈS VENGEANCE ---
              String? winner = GameLogic.checkWinner(widget.players);
              if (winner != null) {
                debugPrint("🏆 CAPTEUR [Victoire] : Victoire détectée après vengeance Chasseur ($winner).");
                if (mounted) _navigateToGameOver(winner);
                return;
              }
            }

            // Si le Pokémon meurt : VENGEANCE
            else if (role == "pokémon" || role == "pokemon") {
              debugPrint("🔍 CAPTEUR [Mort] : Le Pokémon est mort ! Vengeance...");

              if (!summaryDialogClosed) {
                Navigator.pop(ctx);
                summaryDialogClosed = true;
              }

              final pokemonResult = await PokemonDeathHandler.handleVengeance(
                  context: context,
                  allPlayers: widget.players,
                  pokemon: p
              );
              final List<Player> newVictims = pokemonResult.$1;
              final String? directTargetName = pokemonResult.$2;

              if (newVictims.isNotEmpty) {
                addToHistory(globalTurnNumber, "nuit", newVictims.map((v) => EliminationRecord(
                  playerName: v.name,
                  role: v.role ?? "?",
                  team: v.team,
                  reason: (v.isLinked && v.name != directTargetName)
                      ? "💔 Chagrin d'amour (${v.lover?.name ?? '?'})"
                      : "Vengeance du Pokémon",
                )).toList());
              }

              playersToProcess.addAll(newVictims);

              // --- CHECK VICTOIRE IMMÉDIAT APRÈS VENGEANCE ---
              String? winner = GameLogic.checkWinner(widget.players);
              if (winner != null) {
                debugPrint("🏆 CAPTEUR [Victoire] : Victoire détectée après vengeance Pokémon ($winner).");
                if (mounted) _navigateToGameOver(winner);
                return;
              }
            }
          }

          // 2. CHECK VICTOIRE (Si la nuit a tué le dernier loup par exemple)
          if (result.exorcistVictory) {
            if (!summaryDialogClosed) Navigator.pop(ctx);
            _navigateToGameOver("VILLAGE");
            return;
          }

          String? winner = GameLogic.checkWinner(widget.players);
          if (winner != null) {
            debugPrint("🏆 CAPTEUR [Victoire] : Victoire détectée au matin ($winner).");
            if (!summaryDialogClosed) Navigator.pop(ctx);
            _navigateToGameOver(winner);
            return; // STOP TOTAL
          }

          // 3. SUITE DU JEU (Si personne n'a gagné)
          for (String name in result.revealedPlayerNames) {
            try { widget.players.firstWhere((pl) => pl.name == name).isRevealedByDevin = true; } catch (_) {}
          }

          await AchievementLogic.checkMidGameAchievements(context, widget.players);
          setState(() => isDayTime = true);
          await GameSaveService.saveGame();

          if (mounted) {
            if (!summaryDialogClosed) Navigator.pop(ctx);
            Navigator.pop(context); // Retour vers VillageScreen
          }
        },
      ),
    );
  }

  void _navigateToGameOver(String winner) {
    debugPrint("🚀 CAPTEUR [Navigation] : Départ vers GameOverScreen ($winner)...");
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => GameOverScreen(
              winnerType: winner,
              players: List.from(widget.players)),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
        (Route<dynamic> route) => false,
    );
  }

  void _showPop(String title, String msg, {VoidCallback? onDismiss}) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(msg, style: const TextStyle(color: Colors.white70)),
      actions: [TextButton(onPressed: () { Navigator.pop(ctx); if (onDismiss != null) onDismiss(); }, child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (nightFinished) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: Center(
          child: Icon(Icons.wb_sunny, color: Colors.orangeAccent, size: 60),
        ),
      );
    }
    final action = nightActionsOrder[currentActionIndex];
    Player actor;
    try {
      actor = widget.players.firstWhere((p) => p.role?.toLowerCase() == action.role.toLowerCase() && p.isAlive);
    } catch (_) {
      actor = widget.players.firstWhere((p) => p.isWolf && p.isAlive, orElse: () => Player(name: "Inconnu"));
    }

    String title = "NUIT $globalTurnNumber - ${action.role.toUpperCase()}";
    if (action.role.contains("Loup")) title = "NUIT $globalTurnNumber - LOUPS-GAROUS";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 16)), centerTitle: true, automaticallyImplyLeading: false, backgroundColor: Colors.transparent),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(action.role.contains("Loup") ? "⚖️ CONSEIL DES LOUPS" : "🎭 AU TOUR DE : ${formatPlayerName(actor.name)}",
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(action.instruction, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic))),
          const Divider(color: Colors.white10, thickness: 1, indent: 40, endIndent: 40),

          Expanded(
            child: RoleActionDispatcher(
              action: action,
              actor: actor,
              allPlayers: widget.players,
              pendingDeaths: pendingDeaths,
              onExorcisme: (res) {
                _exorcismeResult = res;
                _nextAction();
              },
              onSomnifere: (used) { if (used) _somnifereUsed = true; _nextAction(); },
              onNext: _nextAction,
              showPopUp: (title, msg) => _showPop(title, msg, onDismiss: _nextAction),

              // --- C'est ici que l'attaque du Pokémon est enregistrée ---
              onDirectKill: (target, reason) {
                setState(() => pendingDeaths[target] = reason);
                debugPrint("🩸 CAPTEUR [Action] : Mort directe enregistrée pour ${target.name} ($reason)");
              },
            ),
          ),
        ],
      ),
    );
  }
}