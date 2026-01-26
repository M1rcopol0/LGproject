import 'dart:math';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'globals.dart';
import 'logic.dart';
import 'night_actions_logic.dart';
import 'game_save_service.dart';
import 'night_interfaces/role_action_dispatcher.dart';

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

    // PHASE 0 : Mise à jour des états au crépuscule (Zookeeper / Quiche)
    // On passe une map vide car on ne résout pas encore les morts.
    NightActionsLogic.resolveNight(context, widget.players, {});

    for (var p in widget.players) {
      p.isSelected = false;
    }

    _checkSkipAction();
  }

  // ==========================================================
  // LOGIQUE DE NAVIGATION
  // ==========================================================

  void _checkSkipAction() {
    if (currentActionIndex >= nightActionsOrder.length) {
      _finishNight();
      return;
    }

    final action = nightActionsOrder[currentActionIndex];

    // Phyl n'agit qu'au tour 1
    if (action.role == "Phyl" && globalTurnNumber > 1) {
      _nextAction();
      return;
    }

    bool shouldWakeUp = false;

    if (action.role == "Loups-garous évolués") {
      shouldWakeUp = widget.players.any((p) => p.isAlive && p.isWolf && !p.isEffectivelyAsleep);
    } else if (action.role == "Dresseur") {
      shouldWakeUp = widget.players.any((p) =>
      (p.role?.toLowerCase() == "dresseur" || p.role?.toLowerCase() == "pokémon") && p.isAlive);
    } else {
      shouldWakeUp = widget.players.any((p) {
        final r = p.role?.toLowerCase() ?? "";
        final a = action.role.toLowerCase();

        if (r != a) return false;
        if (!p.isAlive || p.isEffectivelyAsleep) return false;

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
    for (var p in widget.players) { p.isSelected = false; }

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

    // CALCUL FINAL : Résolution des morts et des raisons de décès
    final result = NightActionsLogic.resolveNight(
      context,
      widget.players,
      pendingDeaths,
      exorcistChoice: _exorcismeResult,
      somnifereActive: _somnifereUsed,
    );

    playSfx((result.deadPlayers.isEmpty && !result.villageIsNarcoleptic) ? "oiseau.mp3" : "cloche.mp3");

    _showMorningPopup(result);
  }

  // ==========================================================
  // CONSTRUCTION DE L'INTERFACE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (nightFinished) return const Scaffold(backgroundColor: Color(0xFF0A0E21), body: SizedBox.shrink());

    final action = nightActionsOrder[currentActionIndex];

    Player actor = widget.players.firstWhere(
          (p) => p.role?.toLowerCase() == action.role.toLowerCase() && p.isAlive,
      orElse: () => widget.players.firstWhere((p) => p.isWolf && p.isAlive,
          orElse: () => Player(name: "Inconnu")),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text("NUIT $globalTurnNumber - ${action.role.toUpperCase()}"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
              action.role == "Loups-garous évolués" ? "MEURTRE DES LOUPS" : "AU TOUR DE : ${formatPlayerName(actor.name)}",
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                  action.instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)
              )
          ),
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
              onSomnifere: (used) {
                if (used) _somnifereUsed = true;
                _nextAction();
              },
              onNext: _nextAction,
              showPopUp: (title, msg) => _showPop(title, msg, onDismiss: _nextAction),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HELPERS UI & DIALOGUES
  // ==========================================================

  void _showPop(String title, String msg, {VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (onDismiss != null) onDismiss();
              },
              child: const Text("OK", style: TextStyle(color: Colors.orangeAccent))
          )
        ],
      ),
    );
  }

  void _showMorningPopup(NightResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("🌅 RÉVEIL DU VILLAGE", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.villageIsNarcoleptic)
                const Text("💤 Village KO (Somnifère) !\n", style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),

              if (result.deadPlayers.isEmpty)
                const Text("🕊️ Personne n'est mort cette nuit.", style: TextStyle(color: Colors.greenAccent))
              else ...[
                const Text("💀 DÉCÈS :", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...result.deadPlayers.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text("- ${p.name} (${p.role})\n  ${result.deathReasons[p.name]}",
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                )),
              ],

              if (result.revealedRoleMessage != null || result.houstonMessage != null) ...[
                const Divider(color: Colors.white24, height: 30),
                if (result.revealedRoleMessage != null)
                  Text(result.revealedRoleMessage!, style: const TextStyle(color: Colors.cyanAccent)),
                if (result.houstonMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(result.houstonMessage!, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              // CORRECTIF BUG INCRÉMENTATION :
              // Le passage de Nuit N -> Jour N ne change PAS le globalTurnNumber.
              // Le tour ne changera qu'après le VOTE du Jour N via GameLogic.nextTurn().
              setState(() {
                isDayTime = true;
              });

              await GameSaveService.saveGame();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("VOIR LE VILLAGE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}