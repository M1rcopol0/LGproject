import 'package:flutter/material.dart';
import 'models/player.dart';
import 'logic.dart';
import 'achievement_logic.dart';
import 'fin.dart';
import 'game_save_service.dart';
import 'globals.dart'; // Pour stopMusic() et globalGovernanceMode

class MJResultScreen extends StatefulWidget {
  final List<Player> allPlayers;

  const MJResultScreen({super.key, required this.allPlayers});

  @override
  State<MJResultScreen> createState() => _MJResultScreenState();
}

class _MJResultScreenState extends State<MJResultScreen> {
  // NOUVEAU : État pour masquer les résultats au début
  bool _resultsRevealed = false;

  @override
  Widget build(BuildContext context) {
    // Si les résultats ne sont pas encore révélés, on affiche l'écran de garde
    if (!_resultsRevealed) {
      return _buildRevealScreen();
    }

    // Sinon, on affiche l'écran de gestion des votes classique
    return _buildVoteManagementScreen();
  }

  // --- ÉCRAN 1 : AFFICHER LES RÉSULTATS ---
  Widget _buildRevealScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.white54),
            const SizedBox(height: 30),
            const Text(
              "LES VOTES SONT CLOS",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            const Text(
              "Le village a fait son choix...",
              style: TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: 280,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 10,
                ),
                onPressed: () {
                  setState(() {
                    _resultsRevealed = true;
                  });
                },
                child: const Text(
                  "AFFICHER LES RÉSULTATS",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ÉCRAN 2 : GESTION DES VOTES (Code existant) ---
  Widget _buildVoteManagementScreen() {
    // On filtre : Vivants + Joue cette partie + Pas absent (Archiviste)
    final sortedPlayers = widget.allPlayers.where((p) =>
    p.isAlive &&
        p.isPlaying &&
        !p.isAwayAsMJ
    ).toList();

    // Tri par votes décroissants
    sortedPlayers.sort((a, b) {
      int voteComp = b.votes.compareTo(a.votes);
      if (voteComp != 0) return voteComp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
          title: const Text("⚖️ DÉCISION DU MJ"),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Voici le récapitulatif des voix.\nMJ, désignez celui qui doit mourir.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sortedPlayers.length,
              itemBuilder: (context, i) {
                final p = sortedPlayers[i];
                bool isImmunized = p.isImmunizedFromVote || p.isInHouse;
                // Protection Ron-Aldo visuelle
                if (p.role?.toLowerCase() == "ron-aldo") {
                  if (widget.allPlayers.any((f) => f.isFanOfRonAldo && f.isAlive)) isImmunized = true;
                }

                return Card(
                  color: isImmunized ? Colors.cyan.withOpacity(0.1) : Colors.white10,
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    leading: isImmunized
                        ? const Icon(Icons.shield, color: Colors.cyanAccent, size: 28)
                        : const Icon(Icons.person_outline, color: Colors.white24),
                    title: Text(Player.formatName(p.name), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isImmunized ? Colors.cyanAccent : Colors.white)),
                    subtitle: Text(p.role?.toUpperCase() ?? "INCONNU", style: TextStyle(color: isImmunized ? Colors.cyanAccent.withOpacity(0.6) : Colors.orangeAccent, fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(color: isImmunized ? Colors.cyan[900] : Colors.red[900], borderRadius: BorderRadius.circular(20)),
                      child: Text("${p.votes} VOIX", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    onTap: () => _confirmDeath(context, p),
                  ),
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

    // ARRÊT IMMÉDIAT DE LA MUSIQUE DE VOTE
    try { globalAudioPlayer.stop(); } catch (e) {}

    if (target.isImmunizedFromVote) {
      _showSpecialPopUp(context, "🛡️ PROTECTION", "${Player.formatName(target.name)} est protégé(e) !");
      return;
    }

    playSfx("cloche.mp3");

    // 1. ÉLIMINATION LOGIQUE
    Player deceased = GameLogic.eliminatePlayer(context, widget.allPlayers, target, isVote: true);

    // 2. PRÉPARATION MESSAGE
    String roleReveal = deceased.role?.toUpperCase() ?? "INCONNU";
    String message = deceased.isAlive ? "La cible a survécu !" : "Le village a tranché ! ${Player.formatName(deceased.name)} est éliminé.";
    String title = deceased.isAlive ? "⚖️ Verdict : SURVIE" : "💀 Sentence : MORT";

    if (deceased.role?.toLowerCase() == "pantin" && deceased.isAlive) {
      message = "🃏 Le Pantin a survécu (Immunité unique).";
    }
    else if (deceased.role?.toLowerCase() == "voyageur" && deceased.isAlive) {
      message = "✈️ Le Voyageur revient au village (Survit).";
    }
    else if (!deceased.isAlive) {
      if (target.role?.toLowerCase() == "ron-aldo" && deceased.role?.toLowerCase() == "fan de ron-aldo") {
        message = "🛡️ SACRIFICE : ${Player.formatName(deceased.name)} s'est sacrifié !\nSon rôle était : FAN DE RON-ALDO";
      }
      else if (target.role?.toLowerCase() == "maison" && deceased != target) {
        message = "🏠 La Maison s'est effondrée sur ${Player.formatName(deceased.name)} !\nSon rôle était : ${deceased.role?.toUpperCase()}";
      }
      else {
        message = "${Player.formatName(deceased.name)} est éliminé.\n\nSon rôle était : $roleReveal";
        if ((deceased.role?.toLowerCase() == "pokémon" || deceased.role?.toLowerCase() == "pokemon") && deceased.pokemonRevengeTarget != null) {
          Player revengeTarget = deceased.pokemonRevengeTarget!;
          if (!revengeTarget.isAlive) {
            message += "\n\n⚡ VENGEANCE !\nLe Pokémon a foudroyé ${revengeTarget.name} (${revengeTarget.role?.toUpperCase()}) !";
          }
        }
      }
    }

    // 3. POP-UP DE MORT (BLOQUANT)
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );

    // 4. ROUTAGE (Après clic OK)
    if (context.mounted) {
      _routeAfterDecision(context);
    }
  }

  void _handleNoOneDies(BuildContext context) async {
    try { globalAudioPlayer.stop(); } catch (e) {}
    playSfx("cloche.mp3");

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("⚖️ Verdict : SURVIE", style: TextStyle(color: Colors.white)),
        content: const Text("Personne ne meurt ce soir.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
    if (context.mounted) _routeAfterDecision(context);
  }

  void _showSpecialPopUp(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(title, style: const TextStyle(color: Colors.orangeAccent)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () { Navigator.of(ctx).pop(); _routeAfterDecision(context); }, child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))],
      ),
    );
  }

  void _routeAfterDecision(BuildContext context) async {
    String? winner = GameLogic.checkWinner(widget.allPlayers);

    if (winner != null) {
      debugPrint("🏆 LOG [Vote] : Fin de partie détectée ! Vainqueur : $winner");
      List<Player> winnersList = widget.allPlayers.where((p) =>
      (winner == "VILLAGE" && p.team == "village") ||
          (winner == "LOUPS" && p.team == "loups") ||
          (winner == "SOLO" && p.team == "solo")
      ).toList();

      await AchievementLogic.checkEndGameAchievements(context, winnersList, widget.allPlayers);
      GameSaveService.clearSave();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: winner, players: widget.allPlayers)),
              (route) => false,
        );
      }
    } else {
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}