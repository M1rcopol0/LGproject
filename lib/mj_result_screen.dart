import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'models/player.dart';
import 'logic.dart';
import 'achievement_logic.dart';
import 'fin.dart';
import 'game_save_service.dart';
import 'globals.dart';
import 'widgets/mj_vote_card.dart';

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

  Widget _buildVoteManagementScreen() {
    final sortedPlayers = widget.allPlayers.where((p) => p.isAlive && p.isPlaying && !p.isAwayAsMJ).toList();
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

  void _confirmDeath(BuildContext context, Player target) async {
    if (_isNavigating) return;

    debugPrint("⚖️ LOG [Sentence] : Le MJ a choisi d'éliminer ${target.name}.");
    try { globalAudioPlayer.stop(); } catch (e) {}

    if (target.isImmunizedFromVote) {
      debugPrint("🛡️ CAPTEUR [Vote] : ${target.name} immunisé contre le vote (Bled).");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🛡️ ${Player.formatName(target.name)} est protégé(e) contre le vote !"), backgroundColor: Colors.blueGrey, duration: const Duration(seconds: 2)));
      return;
    }

    playSfx("cloche.mp3");
    Player? lover = target.isLinkedByCupidon ? target.lover : null;
    bool loverWasAlive = lover?.isAlive ?? false;

    // 1. MORT PRINCIPALE
    Player deceased = GameLogic.eliminatePlayer(context, widget.allPlayers, target, isVote: true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    // 2. DIALOGUE MORT PRINCIPALE
    String message = _buildDeathMessage(target, deceased, lover, loverWasAlive);
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            title: Text(deceased.isAlive ? "⚖️ Verdict : SURVIE" : "💀 Sentence : MORT", style: const TextStyle(color: Colors.white)),
            content: Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))]
        )
    );

    if (!deceased.isAlive) {
      // --- SUPPRESSION TOTALE DE LA LOGIQUE DE MORT LIÉE (DRESSEUR/POKEMON) ---
      // Si c'est le Dresseur : il meurt, point barre. Le Pokémon reste en vie.
      // Si c'est le Pokémon : il a sa vengeance, puis il meurt. Le Dresseur reste en vie.

      // CAS POKÉMON : VENGEANCE
      if (deceased.role?.toLowerCase() == "pokémon" || deceased.role?.toLowerCase() == "pokemon") {
        debugPrint("💀 CAPTEUR [Mort] : Vengeance Pokémon déclenchée pour ${deceased.name}.");
        await _handleRetaliationAction(context, deceased, "Attaque Tonnerre", "⚡ VENGEANCE ÉLECTRIQUE", "Le Pokémon lance une dernière attaque foudroyante !");
      }

      // CAS CHASSEUR : VENGEANCE
      else if (deceased.role?.toLowerCase() == "chasseur") {
        debugPrint("💀 CAPTEUR [Mort] : Vengeance Chasseur déclenchée pour ${deceased.name}.");
        await _handleRetaliationAction(context, deceased, "Tir du Chasseur", "🔫 DERNIER SOUFFLE", "Il doit éliminer quelqu'un immédiatement.");
      }
    }

    if (context.mounted) _routeAfterDecision(context);
  }

  String _buildDeathMessage(Player target, Player deceased, Player? lover, bool loverWasAlive) {
    if (deceased.role?.toLowerCase() == "pantin" && deceased.isAlive) return "🃏 Le Pantin a survécu (Immunité unique au premier vote).";
    if (deceased.role?.toLowerCase() == "voyageur" && deceased.isAlive) return "✈️ Le Voyageur revient au village (Survit au vote pendant le voyage).";
    if (!deceased.isAlive) {
      if (target.role?.toLowerCase() == "ron-aldo" && deceased.role?.toLowerCase() == "fan de ron-aldo") return "🛡️ SACRIFICE : ${Player.formatName(deceased.name)} s'est sacrifié pour Ron-Aldo !";
      if (target.role?.toLowerCase() == "maison" && deceased != target) return "🏠 La Maison s'est effondrée sur ${Player.formatName(deceased.name)} !";

      String msg = "${Player.formatName(deceased.name)} est éliminé.\n\nSon rôle était : ${deceased.role?.toUpperCase()}";
      if (lover != null && loverWasAlive && !lover.isAlive) msg += "\n\n💔 DRAME !\nSon amant(e) ${lover.name} meurt de chagrin instantanément !";
      return msg;
    }
    return "La cible a survécu !";
  }

  Future<void> _handleRetaliationAction(BuildContext context, Player source, String reason, String title, String desc) async {
    // 1. Info
    await showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
          backgroundColor: Colors.red[900],
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text("${source.name} (${source.role}) est mort.\n$desc", style: const TextStyle(color: Colors.white)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CHOISIR LA CIBLE", style: TextStyle(color: Colors.white)))]
      ),
    );

    if (!mounted) return;

    // 2. Sélection
    Player? selectedTarget = await showDialog<Player>(
      context: context, barrierDismissible: false,
      builder: (ctx) {
        // CORRECTION : On retire le Dresseur de la liste des cibles possibles si c'est le Pokémon qui tire
        final targets = widget.allPlayers.where((p) =>
        p.isAlive &&
            !(source.role?.toLowerCase().contains("pok") == true && p.role?.toLowerCase() == "dresseur")
        ).toList();

        targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: SizedBox(width: double.maxFinite, height: 300, child: ListView.builder(
                itemCount: targets.length,
                itemBuilder: (c, i) => ListTile(
                    title: Text(targets[i].name, style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.gps_fixed, color: Colors.redAccent),
                    onTap: () { Navigator.pop(ctx, targets[i]); }
                )
            ))
        );
      },
    );

    if (selectedTarget != null && mounted) {
      await _confirmRetaliationKill(context, selectedTarget, reason);
    }
  }

  Future<void> _confirmRetaliationKill(BuildContext context, Player target, String reason) async {
    debugPrint("💀 CAPTEUR [Mort] : Vengeance tir sur ${target.name} (${target.role}), raison: $reason.");
    playSfx("gunshot.mp3");
    Player dead = GameLogic.eliminatePlayer(context, widget.allPlayers, target, isVote: false, reason: reason);

    await showDialog(
        context: context, barrierDismissible: false,
        builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            title: const Text("CIBLE ABATTUE", style: TextStyle(color: Colors.white)),
            content: Text("${dead.name} a été tué.\nSon rôle était : ${dead.role?.toUpperCase()}", style: const TextStyle(color: Colors.white70)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))]
        )
    );
  }

  void _handleNoOneDies(BuildContext context) async {
    try { globalAudioPlayer.stop(); } catch (e) {}
    playSfx("cloche.mp3");
    await showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1D1E33), title: const Text("⚖️ Verdict : SURVIE", style: TextStyle(color: Colors.white)), content: const Text("Personne ne meurt ce soir.", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)))]));
    if (mounted) _routeAfterDecision(context);
  }

  void _routeAfterDecision(BuildContext context) async {
    if (_isNavigating) return;
    _isNavigating = true;

    // 1. Victoire Exorciste
    if (exorcistWin) {
      _navigateToGameOver("VILLAGE");
      return;
    }

    // 2. Victoire Classique
    String? winner = GameLogic.checkWinner(widget.allPlayers);

    if (winner == null) {
      // PARTIE CONTINUE
      debugPrint("🚀 CAPTEUR [Navigation] : Partie continue, retour au village.");
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
      }
    } else {
      // FIN DE PARTIE
      debugPrint("🏁 LOG [Route] : Fin détectée ($winner).");

      try {
        List<Player> winnersList = widget.allPlayers.where((p) => (winner == "VILLAGE" && p.team == "village") || (winner == "LOUPS" && p.team == "loups") || (winner == "SOLO" && p.team == "solo")).toList();
        await AchievementLogic.checkEndGameAchievements(context, winnersList, widget.allPlayers);
      } catch (e) {
        debugPrint("⚠️ Erreur succès : $e");
      }

      await GameSaveService.clearSave();

      if (mounted) {
        _navigateToGameOver(winner);
      }
    }
  }

  void _navigateToGameOver(String winner) {
    debugPrint("🚀 LOG [Route] : Navigation SAFE vers GameOverScreen.");
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => GameOverScreen(
                    winnerType: winner,
                    players: List.from(widget.allPlayers)
                )
            ),
                (Route<dynamic> route) => false
        );
      }
    });
  }
}