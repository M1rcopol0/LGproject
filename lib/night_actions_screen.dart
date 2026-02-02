import 'dart:async';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'globals.dart';
import 'logic.dart';
import 'night_actions_logic.dart';
import 'game_save_service.dart';
import 'night_interfaces/role_action_dispatcher.dart';
import 'fin.dart';

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

    // PHASE 0 : PRÉ-RÉSOLUTION
    NightActionsLogic.prepareNightStates(widget.players);

    for (var p in widget.players) {
      p.isSelected = false;
    }

    _checkSkipAction();
  }

  // ==========================================================
  // LOGIQUE DE NAVIGATION ET FILTRAGE
  // ==========================================================

  void _checkSkipAction() {
    if (currentActionIndex >= nightActionsOrder.length) {
      _finishNight();
      return;
    }

    final action = nightActionsOrder[currentActionIndex];

    // Phyl n'agit qu'à la Nuit 1
    if (action.role == "Phyl" && globalTurnNumber > 1) {
      debugPrint("⏭️ LOG [Skip] : Phyl (Action réservée à la Nuit 1).");
      _nextAction();
      return;
    }

    bool shouldWakeUp = false;

    if (action.role == "Loups-garous évolués") {
      shouldWakeUp = widget.players.any((p) => p.isAlive && p.isWolf);
    } else if (action.role == "Dresseur") {
      shouldWakeUp = widget.players.any((p) =>
      (p.role?.toLowerCase() == "dresseur" ||
          p.role?.toLowerCase() == "pokémon") &&
          p.isAlive);
    } else {
      shouldWakeUp = widget.players.any((p) {
        final r = p.role?.toLowerCase() ?? "";
        final a = action.role.toLowerCase();

        if (r != a || !p.isAlive) return false;

        if (a == "somnifère") return p.somnifereUses > 0;
        if (a == "houston") return (globalTurnNumber % 2 != 0); // Impair
        if (a == "exorciste") return (globalTurnNumber == 2);

        return true;
      });
    }

    if (!shouldWakeUp) {
      debugPrint("⏭️ LOG [Skip] : Aucun acteur éligible pour ${action.role}.");
      Future.microtask(() => _nextAction());
    }
  }

  void _nextAction() {
    if (!mounted) return;
    for (var p in widget.players) {
      p.isSelected = false;
    }

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

    final result = NightActionsLogic.resolveNight(
      context,
      widget.players,
      pendingDeaths,
      somnifereActive: _somnifereUsed,
      exorcistSuccess: (_exorcismeResult == "success"),
    );

    // --- CORRECTION : DÉTECTION VICTOIRE EXORCISTE ---
    if (result.exorcistVictory) {
      debugPrint("🏆 LOG [NightScreen] : L'exorciste a réussi son mime !");
      exorcistWin = true; // Variable globale pour le succès
    }

    playSfx((result.deadPlayers.isEmpty && !result.villageIsNarcoleptic)
        ? "oiseau.mp3"
        : "cloche.mp3");

    _showMorningPopup(result);
  }

  // ==========================================================
  // CONSTRUCTION DE L'INTERFACE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (nightFinished) {
      return const Scaffold(backgroundColor: Color(0xFF0A0E21), body: SizedBox.shrink());
    }

    final action = nightActionsOrder[currentActionIndex];

    Player actor;
    try {
      actor = widget.players.firstWhere((p) =>
      p.role?.toLowerCase() == action.role.toLowerCase() && p.isAlive);
    } catch (_) {
      actor = widget.players.firstWhere((p) => p.isWolf && p.isAlive,
          orElse: () => Player(name: "Inconnu"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text("NUIT $globalTurnNumber - ${action.role.toUpperCase()}"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
              action.role == "Loups-garous évolués"
                  ? "⚖️ CONSEIL DES LOUPS"
                  : "🎭 AU TOUR DE : ${formatPlayerName(actor.name)}",
              style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(action.instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontStyle: FontStyle.italic))),
          const Divider(
              color: Colors.white10, thickness: 1, indent: 40, endIndent: 40),
          Expanded(
            child: RoleActionDispatcher(
              action: action,
              actor: actor,
              allPlayers: widget.players,
              pendingDeaths: pendingDeaths,
              onExorcisme: (res) {
                debugPrint("✝️ LOG [Action] : Callback Exorciste -> $res");
                _exorcismeResult = res;
                _nextAction();
              },
              onSomnifere: (used) {
                debugPrint("💤 LOG [Action] : Callback Somnifère -> $used");
                if (used) _somnifereUsed = true;
                _nextAction();
              },
              onNext: _nextAction,
              showPopUp: (title, msg) =>
                  _showPop(title, msg, onDismiss: _nextAction),
            ),
          ),
        ],
      ),
    );
  }

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
              child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))
        ],
      ),
    );
  }

  void _showMorningPopup(NightResult result) {
    // 1. DÉTECTION DES JOUEURS MUETS (ARCHIVISTE)
    List<String> mutedPlayers = widget.players
        .where((p) => p.isMutedDay && p.isAlive)
        .map((p) => p.name)
        .toList();

    // 2. DÉTECTION RETOUR FORCÉ VOYAGEUR
    bool voyageurIntercepte = widget.players.any((p) =>
    p.role?.toLowerCase() == "voyageur" &&
        p.isAlive &&
        !p.canTravelAgain &&
        !p.isInTravel
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Row(
          children: [
            Icon(Icons.wb_sunny, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Expanded(
              child: Text("LE VILLAGE SE RÉVEILLE", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              // VICTOIRE EXORCISTE
              if (result.exorcistVictory)
                const Column(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 50),
                    SizedBox(height: 10),
                    Text(
                        "L'EXORCISME A RÉUSSI !\nLe village est purifié et gagne immédiatement !",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ],
                ),

              // ANNONCES SPÉCIALES
              if (!result.exorcistVictory && result.announcements.isNotEmpty) ...[
                const Text("📢 ANNONCES SPÉCIALES :", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                ...result.announcements.map((msg) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                  ),
                  child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
                )),
                const Divider(color: Colors.white24, height: 20),
              ],

              // RETOUR FORCÉ VOYAGEUR (NOUVEAU)
              if (!result.exorcistVictory && voyageurIntercepte) ...[
                const Text("🛑 RETOUR FORCÉ :", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text(
                    "Le Voyageur a été attaqué durant son périple !\nIl a survécu mais a dû rentrer en urgence. Il ne pourra plus repartir.",
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
                const Divider(color: Colors.white24, height: 20),
              ],

              // SILENCE ARCHIVISTE (NOUVEAU)
              if (!result.exorcistVictory && mutedPlayers.isNotEmpty) ...[
                const Text("🤐 SILENCE IMPOSÉ :", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                ...mutedPlayers.map((name) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                      "- $name ne peut pas parler aujourd'hui.",
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
                )),
                const Divider(color: Colors.white24, height: 20),
              ],

              // MORTS ET NARCOLEPSIE
              if (!result.exorcistVictory && result.villageIsNarcoleptic)
                const Text("💤 Village KO (Somnifère) !\nPersonne n'est mort, mais personne ne pourra parler.",
                    style: TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold)),

              if (!result.exorcistVictory && !result.villageIsNarcoleptic) ...[
                if (result.deadPlayers.isEmpty)
                  const Text("🕊️ Personne n'est mort cette nuit.", style: TextStyle(color: Colors.greenAccent))
                else ...[
                  const Text("💀 DÉCÈS :", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...result.deadPlayers.map((p) {
                    // --- AJOUT INFO POKÉMON ---
                    String info = "- ${p.name} (${p.role})\n  ${result.deathReasons[p.name]}";

                    if ((p.role?.toLowerCase() == "pokémon" || p.role?.toLowerCase() == "pokemon") && p.pokemonRevengeTarget != null) {
                      var target = p.pokemonRevengeTarget!;
                      // Si la cible est aussi dans la liste des morts de cette nuit
                      if (result.deadPlayers.any((dead) => dead.name == target.name)) {
                        info += "\n  ⚡ A emporté ${target.name} !";
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(info, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              if (result.exorcistVictory) {
                exorcistWin = true;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: "VILLAGE", players: widget.players)),
                      (route) => false,
                );
                return;
              }

              if (result.revealedPlayerNames.isNotEmpty) {
                debugPrint("👁️ LOG [Devin] : Mise à jour des icônes pour ${result.revealedPlayerNames}");
                for (String name in result.revealedPlayerNames) {
                  try {
                    var p = widget.players.firstWhere((pl) => pl.name == name);
                    p.isRevealedByDevin = true;
                  } catch (_) {}
                }
              }

              setState(() {
                isDayTime = true;
              });
              await GameSaveService.saveGame();

              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text("VOIR LE VILLAGE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}