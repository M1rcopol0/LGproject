import 'dart:async';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'globals.dart';
import 'night_actions_logic.dart';
import 'game_save_service.dart';
import 'night_interfaces/role_action_dispatcher.dart';
import 'achievement_logic.dart';
import 'fin.dart';
import 'widgets/morning_summary_dialog.dart';

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

    if (roleName == "Phyl" && globalTurnNumber > 1) {
      _nextAction(); return;
    }
    if (roleName == "Cupidon" && globalTurnNumber > 1) {
      _nextAction(); return;
    }

    bool shouldWakeUp = false;
    if (roleName == "Loups-garous évolués") {
      shouldWakeUp = widget.players.any((p) => p.isAlive && p.isWolf);
    } else if (roleName == "Dresseur") {
      shouldWakeUp = widget.players.any((p) =>
      (p.role?.toLowerCase() == "dresseur" || p.role?.toLowerCase() == "pokémon") && p.isAlive);
    } else {
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
      Future.microtask(() => _nextAction());
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

    debugPrint("🧪 LOG [Résolution] : Calcul final de la nuit.");

    // --- DEBUG ---
    debugPrint("🔴 DEBUG_TRACE [3] : Valeur brute _exorcismeResult = '$_exorcismeResult'");

    // CORRECTION : On vérifie simplement "SUCCESS" (envoyé par l'interface corrigée)
    bool isExorcismWin = (_exorcismeResult == "SUCCESS");

    if (isExorcismWin) {
      debugPrint("🔴 DEBUG_TRACE [4] : isExorcismWin = TRUE. Victoire détectée.");
    } else {
      debugPrint("🔴 DEBUG_TRACE [4] : isExorcismWin = FALSE.");
    }

    final result = NightActionsLogic.resolveNight(
      context,
      widget.players,
      pendingDeaths,
      somnifereActive: _somnifereUsed,
      exorcistSuccess: isExorcismWin,
    );

    debugPrint("🔴 DEBUG_TRACE [6] : Retour NightResult.exorcistVictory = ${result.exorcistVictory}");

    if (result.exorcistVictory) {
      exorcistWin = true;
      debugPrint("🔴 DEBUG_TRACE [7] : Variable GLOBALE exorcistWin mise à TRUE.");
    }

    playSfx((result.deadPlayers.isEmpty && !result.villageIsNarcoleptic)
        ? "oiseau.mp3"
        : "cloche.mp3");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MorningSummaryDialog(
        result: result,
        players: widget.players,
        onConfirm: () async {
          debugPrint("🔴 DEBUG_TRACE [8] : Bouton Confirm du Matin pressé.");

          if (result.exorcistVictory) {
            debugPrint("🔴 DEBUG_TRACE [9] : Victoire Exorciste ! Redirection GameOver.");
            Navigator.pop(ctx);
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: "EXORCISTE", players: widget.players)),
                    (route) => false
            );
            return;
          }

          for (String name in result.revealedPlayerNames) {
            try { widget.players.firstWhere((pl) => pl.name == name).isRevealedByDevin = true; } catch (_) {}
          }

          await AchievementLogic.checkMidGameAchievements(context, widget.players);
          setState(() => isDayTime = true);
          await GameSaveService.saveGame();

          if (mounted) {
            Navigator.pop(ctx);
            Navigator.pop(context); // Retour vers GameMenuScreen
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (nightFinished) return const Scaffold(backgroundColor: Color(0xFF0A0E21), body: SizedBox.shrink());

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
                debugPrint("✝️ DEBUG [Dispatcher] : Callback Exorciste reçu : '$res'");
                _exorcismeResult = res;
                _nextAction();
              },
              onSomnifere: (used) { if (used) _somnifereUsed = true; _nextAction(); },
              onNext: _nextAction,
              showPopUp: (title, msg) => _showPop(title, msg, onDismiss: _nextAction),
              onDirectKill: (target, reason) {
                setState(() => pendingDeaths[target] = reason);
                debugPrint("🩸 LOG [Action] : Mort directe enregistrée pour ${target.name} ($reason)");
              },
            ),
          ),
        ],
      ),
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
}