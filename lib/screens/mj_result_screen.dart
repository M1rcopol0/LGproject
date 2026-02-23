import 'package:flutter/material.dart';
import '../models/player.dart';
import '../logic/elimination_logic.dart';
import '../logic/win_condition_logic.dart';
import 'fin_screen.dart';
import '../services/game_save_service.dart';
import '../services/audio_service.dart';
import '../globals.dart';
import '../widgets/mj_vote_card.dart';

class MJResultScreen extends StatefulWidget {
  final List<Player> allPlayers;
  final VoidCallback onComplete;

  const MJResultScreen({super.key, required this.allPlayers, required this.onComplete});

  @override
  State<MJResultScreen> createState() => _MJResultScreenState();
}

class _MJResultScreenState extends State<MJResultScreen> {
  bool _resultsRevealed = false;
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    if (!_resultsRevealed) return _buildRevealScreen();
    return _buildVoteManagementScreen();
  }

  // ---------------------------------------------------------------------------
  // 1. ÉCRAN DE RÉVÉLATION (Suspens)
  // ---------------------------------------------------------------------------
  Widget _buildRevealScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.white54),
            const SizedBox(height: 30),
            const Text("LES VOTES SONT CLOS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
            const SizedBox(height: 10),
            const Text("Le village a fait son choix...", style: TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic)),
            const SizedBox(height: 60),
            SizedBox(width: 280, height: 60, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 10),
                onPressed: () => setState(() => _resultsRevealed = true),
                child: const Text("AFFICHER LES RÉSULTATS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))
            )),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. ÉCRAN DE GESTION (Choix du MJ)
  // ---------------------------------------------------------------------------
  Widget _buildVoteManagementScreen() {
    final sortedPlayers = widget.allPlayers.where((p) => p.isAlive && p.isPlaying && !p.isAwayAsMJ).toList();

    // Tri par nombre de votes (décroissant) puis alphabétique
    sortedPlayers.sort((a, b) {
      int voteComp = b.votes.compareTo(a.votes);
      if (voteComp != 0) return voteComp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    bool scapegoatActive = widget.allPlayers.any((p) => p.isAlive && p.hasScapegoatPower);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(title: const Text("⚖️ DÉCISION DU MJ"), automaticallyImplyLeading: false, backgroundColor: Colors.transparent),
      body: Column(
        children: [
          if (scapegoatActive) Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.brown[700], child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.pets, color: Colors.white, size: 20), SizedBox(width: 10), Text("POUVOIR DU BOUC ÉMISSAIRE ACTIF !", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0))])),
          const Padding(padding: EdgeInsets.all(20.0), child: Text("Voici le récapitulatif des voix.\nMJ, désignez celui qui doit mourir.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16))),
          Expanded(
            child: ListView.builder(
              itemCount: sortedPlayers.length,
              itemBuilder: (context, i) {
                return MJVoteCard(
                  player: sortedPlayers[i],
                  allPlayers: widget.allPlayers,
                  onTap: () => _confirmDeath(context, sortedPlayers[i]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () => _handleNoOneDies(context),
              child: const Text("🕊️ GRÂCE DU VILLAGE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. LOGIQUE D'ÉLIMINATION
  // ---------------------------------------------------------------------------
  void _confirmDeath(BuildContext context, Player target) async {
    if (_isNavigating) return;

    debugPrint("⚖️ LOG [Sentence] : Le MJ a choisi d'éliminer ${target.name}.");
    try { stopMusic(); } catch (e) {}

    // Vérification immunité Bled
    if (target.isImmunizedFromVote) {
      debugPrint("🛡️ CAPTEUR [Vote] : ${target.name} immunisé contre le vote (Bled).");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🛡️ ${Player.formatName(target.name)} est protégé(e) contre le vote !"), backgroundColor: Colors.blueGrey, duration: const Duration(seconds: 2)));
      return;
    }

    playSfx("cloche.mp3");

    // --- ÉLIMINATION VIA LA NOUVELLE LOGIQUE (Retourne une LISTE) ---
    List<Player> victims = EliminationLogic.eliminatePlayer(
        context,
        widget.allPlayers,
        target,
        isVote: true,
        reason: "Vote du Village"
    );

    // Si la liste est vide (Pantin survit, Voyageur survit, etc.)
    if (victims.isEmpty) {
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1D1E33),
              title: const Text("⚖️ Verdict : SURVIE", style: TextStyle(color: Colors.white)),
              content: Text("${target.name} a survécu au vote !", style: const TextStyle(color: Colors.white70)),
              actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))]
          )
      );
      if (mounted) _routeAfterDecision(context);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!context.mounted) return;

    // --- AFFICHAGE DES MORTS ---
    String message = "Les joueurs suivants sont éliminés :\n\n";
    for (var p in victims) {
      message += "- ${p.name} (${p.role})\n";
    }

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            title: const Text("💀 Sentence : MORT", style: TextStyle(color: Colors.white)),
            content: Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))]
        )
    );

    // --- GESTION RÉCURSIVE DES POUVOIRS DE MORT (Chasseur, Pokémon) ---
    List<Player> playersToProcess = List.from(victims);
    List<String> processedNames = [];

    while (playersToProcess.isNotEmpty) {
      Player currentDead = playersToProcess.removeAt(0);

      if (processedNames.contains(currentDead.name)) continue;
      processedNames.add(currentDead.name);

      List<Player> newVictims = [];
      String? role = currentDead.role?.toLowerCase();

      // A. CAS CHASSEUR
      if (role == "chasseur") {
        debugPrint("💀 CAPTEUR [Mort] : Vengeance Chasseur pour ${currentDead.name}.");
        newVictims = await _handleRetaliationAction(context, currentDead, "Tir du Chasseur", "🔫 DERNIER SOUFFLE", "Il doit éliminer quelqu'un immédiatement.");
      }
      // B. CAS POKÉMON
      else if (role == "pokémon" || role == "pokemon") {
        debugPrint("💀 CAPTEUR [Mort] : Vengeance Pokémon pour ${currentDead.name}.");
        newVictims = await _handleRetaliationAction(context, currentDead, "Attaque Tonnerre", "⚡ VENGEANCE ÉLECTRIQUE", "Le Pokémon lance une dernière attaque !");
      }

      if (newVictims.isNotEmpty) {
        playersToProcess.addAll(newVictims);
      }
    }

    if (context.mounted) _routeAfterDecision(context);
  }

  Future<List<Player>> _handleRetaliationAction(BuildContext context, Player source, String reason, String title, String desc) async {
    await showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
          backgroundColor: Colors.red[900],
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text("${source.name} (${source.role}) est mort.\n$desc", style: const TextStyle(color: Colors.white)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CHOISIR LA CIBLE", style: TextStyle(color: Colors.white)))]
      ),
    );

    if (!mounted) return [];

    Player? selectedTarget = await showDialog<Player>(
      context: context, barrierDismissible: false,
      builder: (ctx) {
        final targets = widget.allPlayers.where((p) => p.isAlive).toList();
        targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            title: Text("CIBLE DE ${source.name.toUpperCase()}", style: const TextStyle(color: Colors.white)),
            content: SizedBox(width: double.maxFinite, height: 300, child: ListView.builder(
                itemCount: targets.length,
                itemBuilder: (c, i) => ListTile(
                    title: Text(targets[i].name, style: const TextStyle(color: Colors.white)),
                    leading: const Icon(Icons.gps_fixed, color: Colors.redAccent),
                    onTap: () { Navigator.pop(ctx, targets[i]); }
                )
            )),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("PASSER", style: TextStyle(color: Colors.white54)))]
        );
      },
    );

    if (selectedTarget != null && mounted) {
      debugPrint("💀 CAPTEUR [Mort] : ${source.name} tire sur ${selectedTarget.name}.");
      playSfx("gunshot.mp3");

      List<Player> shotVictims = EliminationLogic.eliminatePlayer(
          context,
          widget.allPlayers,
          selectedTarget,
          isVote: false,
          reason: reason
      );

      String msg = "Victime(s) du tir :\n";
      for (var p in shotVictims) {
        msg += "- ${p.name} (${p.role})\n";
      }

      await showDialog(
          context: context, barrierDismissible: false,
          builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1D1E33),
              title: const Text("CIBLE ABATTUE", style: TextStyle(color: Colors.white)),
              content: Text(msg, style: const TextStyle(color: Colors.white70)),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))]
          )
      );

      return shotVictims;
    }
    return [];
  }

  void _handleNoOneDies(BuildContext context) async {
    try { stopMusic(); } catch (e) {}
    playSfx("cloche.mp3");
    await showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1D1E33), title: const Text("⚖️ Verdict : SURVIE", style: TextStyle(color: Colors.white)), content: const Text("Personne ne meurt ce soir.", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)))]));
    if (mounted) _routeAfterDecision(context);
  }

  void _routeAfterDecision(BuildContext context) async {
    if (_isNavigating) return;
    _isNavigating = true;

    String? winner = WinConditionLogic.checkWinner(widget.allPlayers);

    if (winner == null) {
      debugPrint("🚀 CAPTEUR [Navigation] : Partie continue, retour au village.");
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
      }
    } else {
      debugPrint("🏁 LOG [Route] : Fin détectée ($winner).");

      await GameSaveService.clearSave();

      if (mounted) {
        _navigateToGameOver(winner);
      }
    }
  }

  void _navigateToGameOver(String winner) {
    debugPrint("🚀 LOG [Route] : Navigation SAFE vers GameOverScreen.");

    try {
      stopMusic();
    } catch (e) {
      debugPrint("⚠️ Erreur arrêt audio: $e");
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => GameOverScreen(
            winnerType: winner,
            players: widget.allPlayers,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
            (Route<dynamic> route) => false
    );
  }
}