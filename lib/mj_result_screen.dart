import 'package:flutter/material.dart';
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
    debugPrint("⚖️ LOG [Sentence] : Le MJ a choisi d'éliminer ${target.name}.");
    try { globalAudioPlayer.stop(); } catch (e) {}

    if (target.isImmunizedFromVote) {
      _showSpecialPopUp(context, "🛡️ PROTECTION", "${Player.formatName(target.name)} est protégé(e) !");
      return;
    }

    playSfx("cloche.mp3");
    Player? lover = target.isLinkedByCupidon ? target.lover : null;
    bool loverWasAlive = lover?.isAlive ?? false;
    Player deceased = GameLogic.eliminatePlayer(context, widget.allPlayers, target, isVote: true);

    String message = _buildDeathMessage(target, deceased, lover, loverWasAlive);
    String title = deceased.isAlive ? "⚖️ Verdict : SURVIE" : "💀 Sentence : MORT";

    await showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))]
    ));

    if (!deceased.isAlive && deceased.role?.toLowerCase() == "chasseur") {
      await _handleChasseurAction(context, deceased);
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
      if (deceased.role?.toLowerCase().contains("pokemon") == true && deceased.pokemonRevengeTarget != null && !deceased.pokemonRevengeTarget!.isAlive) {
        msg += "\n\n⚡ VENGEANCE !\nLe Pokémon a foudroyé ${deceased.pokemonRevengeTarget!.name} !";
      }
      return msg;
    }
    return "La cible a survécu !";
  }

  Future<void> _handleChasseurAction(BuildContext context, Player hunter) async {
    await showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(backgroundColor: Colors.red[900], title: const Text("🔫 DERNIER SOUFFLE", style: TextStyle(color: Colors.white)), content: Text("${hunter.name} est le Chasseur !\nIl doit éliminer quelqu'un immédiatement.", style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CHOISIR LA CIBLE", style: TextStyle(color: Colors.white)))]),
    );
    if (!context.mounted) return;
    await showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) {
        final targets = widget.allPlayers.where((p) => p.isAlive).toList();
        targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return AlertDialog(backgroundColor: const Color(0xFF1D1E33), title: const Text("Tir du Chasseur", style: TextStyle(color: Colors.white)), content: SizedBox(width: double.maxFinite, height: 300, child: ListView.builder(itemCount: targets.length, itemBuilder: (c, i) => ListTile(title: Text(targets[i].name, style: const TextStyle(color: Colors.white)), trailing: const Icon(Icons.gps_fixed, color: Colors.redAccent), onTap: () { Navigator.pop(ctx); _confirmChasseurKill(context, targets[i]); }))));
      },
    );
  }

  void _confirmChasseurKill(BuildContext context, Player target) {
    playSfx("gunshot.mp3");
    Player dead = GameLogic.eliminatePlayer(context, widget.allPlayers, target, isVote: false, reason: "Tir du Chasseur");
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1D1E33), title: const Text("CIBLE ABATTUE", style: TextStyle(color: Colors.white)), content: Text("${dead.name} a été tué par le Chasseur.\nSon rôle était : ${dead.role?.toUpperCase()}", style: const TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))]));
  }

  void _handleNoOneDies(BuildContext context) async {
    try { globalAudioPlayer.stop(); } catch (e) {}
    playSfx("cloche.mp3");
    await showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1D1E33), title: const Text("⚖️ Verdict : SURVIE", style: TextStyle(color: Colors.white)), content: const Text("Personne ne meurt ce soir.", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)))]));
    if (context.mounted) _routeAfterDecision(context);
  }

  void _showSpecialPopUp(BuildContext context, String title, String content) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1D1E33), title: Text(title, style: const TextStyle(color: Colors.orangeAccent)), content: Text(content, style: const TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () { Navigator.of(ctx).pop(); _routeAfterDecision(context); }, child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))]));
  }

  void _routeAfterDecision(BuildContext context) async {
    // 1. Check victoire Exorciste (Prioritaire)
    if (exorcistWin) {
      debugPrint("🏆 LOG [MJ] : Victoire Exorciste détectée !");
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: "VILLAGE", players: widget.allPlayers)),
              (route) => false
      );
      return;
    }

    // 2. Check victoire normale
    String? winner = GameLogic.checkWinner(widget.allPlayers);

    if (winner == null) {
      // PARTIE CONTINUE -> RETOUR MENU
      if (context.mounted) {
        widget.onComplete(); // Signale au menu de passer au state suivant (Election Chef ou Nuit)
        Navigator.pop(context); // Ferme MJResultScreen (IMPORTANT)
      }
    } else {
      // PARTIE TERMINÉE -> ÉCRAN FIN
      List<Player> winnersList = widget.allPlayers.where((p) => (winner == "VILLAGE" && p.team == "village") || (winner == "LOUPS" && p.team == "loups") || (winner == "SOLO" && p.team == "solo")).toList();
      await AchievementLogic.checkEndGameAchievements(context, winnersList, widget.allPlayers);
      GameSaveService.clearSave();
      if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: winner, players: widget.allPlayers)), (route) => false);
    }
  }
}