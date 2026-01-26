import 'dart:async';
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
      debugPrint("🏁 LOG [NightScreen] : Toutes les actions ont été passées en revue.");
      _finishNight();
      return;
    }

    final action = nightActionsOrder[currentActionIndex];
    debugPrint("🔍 LOG [Flux] : Examen de l'action : ${action.role}");

    // Phyl n'agit qu'à la Nuit 1
    if (action.role == "Phyl" && globalTurnNumber > 1) {
      debugPrint("⏭️ LOG [Skip] : Phyl (Action réservée à la Nuit 1).");
      _nextAction();
      return;
    }

    bool shouldWakeUp = false;

    // --- LOGIQUE DE RÉVEIL INTELLIGENTE ---
    if (action.role == "Loups-garous évolués") {
      shouldWakeUp = widget.players.any((p) => p.isAlive && p.isWolf);
      if (!shouldWakeUp) debugPrint("⏭️ LOG [Skip] : Meute de loups entièrement décimée.");
    }
    else if (action.role == "Dresseur") {
      shouldWakeUp = widget.players.any((p) =>
      (p.role?.toLowerCase() == "dresseur" || p.role?.toLowerCase() == "pokémon") && p.isAlive);
      if (!shouldWakeUp) debugPrint("⏭️ LOG [Skip] : Duo Dresseur/Pokémon mort.");
    }
    else {
      // Rôles solo et villageois actifs
      shouldWakeUp = widget.players.any((p) {
        final r = p.role?.toLowerCase() ?? "";
        final a = action.role.toLowerCase();

        if (r != a || !p.isAlive) return false;

        // Cas particuliers de réveil
        if (a == "somnifère") {
          bool hasCharges = p.somnifereUses > 0;
          if (!hasCharges) debugPrint("⏭️ LOG [Skip] : Somnifère n'a plus de charges.");
          return hasCharges;
        }
        if (a == "houston") {
          bool isOddTurn = (globalTurnNumber % 2 != 0);
          if (!isOddTurn) debugPrint("⏭️ LOG [Skip] : Houston ne capte rien les nuits paires.");
          return isOddTurn;
        }
        if (a == "exorciste") {
          bool isNightTwo = (globalTurnNumber == 2);
          if (!isNightTwo) debugPrint("⏭️ LOG [Skip] : L'Exorciste n'agit qu'en Nuit 2.");
          return isNightTwo;
        }

        return true;
      });
    }

    if (!shouldWakeUp) {
      debugPrint("⏭️ LOG [Skip] : Aucun acteur vivant ou éligible pour ${action.role}.");
      Future.microtask(() => _nextAction());
    } else {
      debugPrint("👁️ LOG [Réveil] : L'interface pour ${action.role} va s'afficher.");
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

    debugPrint("--------------------------------------------------");
    debugPrint("🧪 LOG [Résolution] : Lancement du calcul final de la nuit.");
    debugPrint("💀 LOG [Pending] : ${pendingDeaths.length} morts en attente de validation.");

    // RÉSOLUTION FINALE DES ACTIONS ET DES MORTS
    final result = NightActionsLogic.resolveNight(
      context,
      widget.players,
      pendingDeaths,
      somnifereActive: _somnifereUsed,
      exorcistSuccess: (_exorcismeResult == "success"),
    );

    // Bruitage du matin
    playSfx((result.deadPlayers.isEmpty && !result.villageIsNarcoleptic) ? "oiseau.mp3" : "cloche.mp3");

    debugPrint("🌅 LOG [Matin] : Affichage du résumé au MJ.");
    _showMorningPopup(result);
  }

  // ==========================================================
  // CONSTRUCTION DE L'INTERFACE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (nightFinished) return const Scaffold(backgroundColor: Color(0xFF0A0E21), body: SizedBox.shrink());

    final action = nightActionsOrder[currentActionIndex];

    Player actor;
    try {
      actor = widget.players.firstWhere(
              (p) => p.role?.toLowerCase() == action.role.toLowerCase() && p.isAlive
      );
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
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
              action.role == "Loups-garous évolués"
                  ? "⚖️ CONSEIL DES LOUPS"
                  : "🎭 AU TOUR DE : ${formatPlayerName(actor.name)}",
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
                debugPrint("✝️ LOG [Action] : Résultat Exorciste reçu -> $res");
                _exorcismeResult = res;
                _nextAction();
              },
              onSomnifere: (used) {
                debugPrint("💤 LOG [Action] : Résultat Somnifère reçu -> $used");
                if (used) _somnifereUsed = true;
                _nextAction();
              },
              onNext: () {
                debugPrint("➡️ LOG [Navigation] : Action terminée pour ${action.role}.");
                _nextAction();
              },
              showPopUp: (title, msg) => _showPop(title, msg, onDismiss: _nextAction),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // POPUPS DE RÉSULTATS
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
        title: const Text("🌅 RÉVEIL DU VILLAGE",
            style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.exorcistVictory)
                const Column(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 50),
                    SizedBox(height: 10),
                    Text("L'EXORCISME A RÉUSSI !\nLe village est purifié et gagne immédiatement !",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),

              if (!result.exorcistVictory && result.villageIsNarcoleptic)
                const Text("💤 Village KO (Somnifère) !\n",
                    style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),

              if (!result.exorcistVictory) ...[
                if (result.deadPlayers.isEmpty)
                  const Text("🕊️ Personne n'est mort cette nuit.",
                      style: TextStyle(color: Colors.greenAccent))
                else ...[
                  const Text("💀 DÉCÈS :",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...result.deadPlayers.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text("- ${p.name} (${p.role})\n  ${result.deathReasons[p.name]}",
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  )),
                ],
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              setState(() { isDayTime = true; });
              await GameSaveService.saveGame();
              debugPrint("💾 LOG [Save] : Partie sauvegardée au matin.");
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("VOIR LE VILLAGE",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}