import 'dart:async';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'globals.dart';
import 'logic.dart';
import 'night_actions_logic.dart';
import 'game_save_service.dart';
import 'night_interfaces/role_action_dispatcher.dart';
import 'achievement_logic.dart';
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

    // PHASE 0 : PRÉ-RÉSOLUTION (Bombes, poisons...)
    NightActionsLogic.prepareNightStates(widget.players);

    // Reset visuel des sélections
    for (var p in widget.players) {
      p.isSelected = false;
    }

    _checkSkipAction();
  }

  // ==========================================================
  // LOGIQUE DE NAVIGATION ET FILTRAGE DES RÔLES
  // ==========================================================

  void _checkSkipAction() {
    if (currentActionIndex >= nightActionsOrder.length) {
      _finishNight();
      return;
    }

    final action = nightActionsOrder[currentActionIndex];
    final roleName = action.role;

    // --- RÈGLES DE SKIP SPÉCIALES ---

    // 1. Phyl : Nuit 1 seulement
    if (roleName == "Phyl" && globalTurnNumber > 1) {
      debugPrint("⏭️ LOG [Skip] : Phyl (Action réservée à la Nuit 1).");
      _nextAction();
      return;
    }

    // 2. Cupidon : Nuit 1 seulement
    if (roleName == "Cupidon" && globalTurnNumber > 1) {
      debugPrint("⏭️ LOG [Skip] : Cupidon (Action réservée à la Nuit 1).");
      _nextAction();
      return;
    }

    bool shouldWakeUp = false;

    // 3. Gestion des groupes (Loups)
    if (roleName == "Loups-garous évolués") {
      // Les loups se réveillent s'il y a au moins un loup vivant
      shouldWakeUp = widget.players.any((p) => p.isAlive && p.isWolf);
    }
    // 4. Gestion Dresseur / Pokémon
    else if (roleName == "Dresseur") {
      shouldWakeUp = widget.players.any((p) =>
      (p.role?.toLowerCase() == "dresseur" ||
          p.role?.toLowerCase() == "pokémon") &&
          p.isAlive);
    }
    // 5. Gestion Générique (Optimisation ici : remplace les multiples if/else)
    else {
      shouldWakeUp = widget.players.any((p) {
        final r = p.role?.toLowerCase() ?? "";
        final a = roleName.toLowerCase();

        if (r != a || !p.isAlive) return false;

        // Conditions spécifiques aux rôles à charges ou tours
        if (a == "somnifère") return p.somnifereUses > 0;
        if (a == "houston") return (globalTurnNumber % 2 != 0); // Impair
        if (a == "exorciste") return (globalTurnNumber == 2);

        // Pour tous les autres (Sorcière, Voyante, etc.), ils se réveillent s'ils sont vivants
        return true;
      });
    }

    if (!shouldWakeUp) {
      debugPrint("⏭️ LOG [Skip] : Aucun acteur éligible pour $roleName.");
      Future.microtask(() => _nextAction());
    }
  }

  void _nextAction() {
    if (!mounted) return;

    // Vérification Mid-Game après chaque rôle (débloque certains succès immédiatement)
    AchievementLogic.checkMidGameAchievements(context, widget.players);

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

    // Résolution logique des morts (Loups, Sorcière, etc.)
    final result = NightActionsLogic.resolveNight(
      context,
      widget.players,
      pendingDeaths,
      somnifereActive: _somnifereUsed,
      exorcistSuccess: (_exorcismeResult == "success"),
    );

    if (result.exorcistVictory) {
      debugPrint("🏆 LOG [NightScreen] : L'exorciste a réussi son mime !");
      exorcistWin = true;
    }

    // Son de réveil (Oiseau si calme, Cloche si morts)
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
      // Fallback pour les groupes (Loups) ou si erreur
      actor = widget.players.firstWhere((p) => p.isWolf && p.isAlive,
          orElse: () => Player(name: "Inconnu"));
    }

    String title = "NUIT $globalTurnNumber - ${action.role.toUpperCase()}";
    if (action.role.contains("Loup")) title = "NUIT $globalTurnNumber - LOUPS-GAROUS";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
              action.role.contains("Loup")
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
              showPopUp: (title, msg) => _showPop(title, msg, onDismiss: _nextAction),

              // --- CORRECTION CRITIQUE SORCIÈRE ---
              // Permet à la potion de mort d'être enregistrée dans la liste globale des morts
              onDirectKill: (target, reason) {
                setState(() {
                  pendingDeaths[target] = reason;
                });
                debugPrint("🩸 LOG [Action] : Mort directe enregistrée pour ${target.name} ($reason)");
              },
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
    // 1. Joueurs muets (Tri Alphabétique)
    List<String> mutedPlayers = widget.players
        .where((p) => p.isMutedDay && p.isAlive)
        .map((p) => p.name)
        .toList();
    mutedPlayers.sort((a, b) => a.compareTo(b));

    // 2. Retour Voyageur
    bool voyageurIntercepte = widget.players.any((p) =>
    p.role?.toLowerCase() == "voyageur" &&
        p.isAlive &&
        !p.canTravelAgain &&
        !p.isInTravel &&
        p.hasReturnedThisTurn
    );

    // 3. Kung-Fu Panda (Tri Alphabétique)
    List<String> screamers = widget.players
        .where((p) => p.mustScreamKungFu && p.isAlive)
        .map((p) => p.name)
        .toList();
    screamers.sort((a, b) => a.compareTo(b));

    // 4. Liste des morts (Tri Alphabétique pour l'affichage)
    List<Player> sortedDeadPlayers = List.from(result.deadPlayers);
    sortedDeadPlayers.sort((a, b) => a.name.compareTo(b.name));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Row(
          children: [
            Icon(Icons.wb_sunny, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Expanded(child: Text("LE VILLAGE SE RÉVEILLE", style: TextStyle(color: Colors.white))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              if (result.exorcistVictory)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                      "L'EXORCISME A RÉUSSI !\nLe village est purifié et gagne immédiatement !",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                ),

              if (!result.exorcistVictory && result.announcements.isNotEmpty) ...[
                const Text("📢 ANNONCES SPÉCIALES :", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ...result.announcements.map((msg) => Text("- $msg", style: const TextStyle(color: Colors.white70))),
                const Divider(color: Colors.white24),
              ],

              if (screamers.isNotEmpty) ...[
                const Text("🐼 DÉFI DU PANDA :", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                      "${screamers.join(", ")} doit crier :\n\"KUNG-FU PANDA !\"",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)
                  ),
                ),
                const Divider(color: Colors.white24, height: 20),
              ],

              if (voyageurIntercepte) ...[
                const Text("🛑 RETOUR FORCÉ :", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                const Text("Le Voyageur a dû rentrer. Il ne repartira plus.", style: TextStyle(color: Colors.white70)),
                const Divider(color: Colors.white24),
              ],

              if (mutedPlayers.isNotEmpty) ...[
                const Text("🤐 SILENCE :", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("${mutedPlayers.join(", ")} ne peut pas parler.", style: const TextStyle(color: Colors.white70)),
                const Divider(color: Colors.white24),
              ],

              if (result.villageIsNarcoleptic)
                const Text("💤 Village KO (Somnifère) !\nPersonne ne meurt, personne ne parle.", style: TextStyle(color: Colors.purpleAccent)),

              if (!result.villageIsNarcoleptic) ...[
                if (sortedDeadPlayers.isEmpty)
                  const Text("🕊️ Personne n'est mort cette nuit.", style: TextStyle(color: Colors.greenAccent))
                else ...[
                  const Text("💀 DÉCÈS :", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ...sortedDeadPlayers.map((p) => Text("- ${p.name} (${p.role})\n  ${result.deathReasons[p.name]}", style: const TextStyle(color: Colors.white70))),
                ],
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              // Fin du jeu immédiate si exorciste
              if (result.exorcistVictory) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: "VILLAGE", players: widget.players)), (route) => false);
                return;
              }

              // Application des révélations Devin
              for (String name in result.revealedPlayerNames) {
                try {
                  widget.players.firstWhere((pl) => pl.name == name).isRevealedByDevin = true;
                } catch (_) {}
              }

              await AchievementLogic.checkMidGameAchievements(context, widget.players);
              setState(() => isDayTime = true);
              await GameSaveService.saveGame();

              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context); // Retour au GameMenu
              }
            },
            child: const Text("VOIR LE VILLAGE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}