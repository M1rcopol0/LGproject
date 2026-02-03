import 'package:flutter/material.dart';
import 'models/player.dart';
import 'globals.dart';
import 'logic.dart';
import 'achievement_logic.dart'; // IMPORT AJOUTÉ
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'night_interfaces/target_selector_interface.dart';

// =============================================================================
// 1. ÉCRAN DE TRANSITION (PASSE LE TÉLÉPHONE)
// =============================================================================
class PassScreen extends StatefulWidget {
  final List<Player> voters;
  final List<Player> allPlayers;
  final int index;
  final VoidCallback onComplete;

  const PassScreen({
    super.key,
    required this.voters,
    required this.allPlayers,
    required this.index,
    required this.onComplete,
  });

  @override
  State<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen> {
  // SÉCURITÉ : On copie et on trie la liste une seule fois pour éviter le re-build instable
  late List<Player> sortedVoters;

  @override
  void initState() {
    super.initState();
    sortedVoters = List.from(widget.voters);
    sortedVoters.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    bool isLastVoter = widget.index >= sortedVoters.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastVoter ? "🗳️ VOTE TERMINÉ !" : "📲 PASSEZ LE TÉLÉPHONE À :",
              style: const TextStyle(fontSize: 18, letterSpacing: 2, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Text(
              isLastVoter ? "MAÎTRE DU JEU" : Player.formatName(sortedVoters[widget.index].name),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: isLastVoter ? Colors.redAccent : Colors.orangeAccent,
                  shadows: const [Shadow(blurRadius: 10, color: Colors.black45)]
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: isLastVoter ? Colors.red[900] : Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                onPressed: () {
                  if (isLastVoter) {
                    debugPrint("🕵️ LOG [Vote] : Fin des votes individuels. Passage au MJ.");

                    // CORRECTION : Passage du context pour les Pop-ups de succès immédiats (Traître, etc.)
                    GameLogic.processVillageVote(context, widget.allPlayers);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MJResultScreen(
                          allPlayers: widget.allPlayers,
                          onComplete: widget.onComplete,
                        ),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IndividualVoteScreen(
                          voter: sortedVoters[widget.index],
                          voters: sortedVoters,
                          allPlayers: widget.allPlayers,
                          index: widget.index,
                          onComplete: widget.onComplete,
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  isLastVoter ? "VOIR LES RÉSULTATS" : "JE SUIS PRÊT",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2. ÉCRAN DE VOTE INDIVIDUEL (Avec Blocage Voyageur/Fan)
// =============================================================================
class IndividualVoteScreen extends StatefulWidget {
  final Player voter;
  final List<Player> voters;
  final List<Player> allPlayers;
  final int index;
  final VoidCallback onComplete;

  const IndividualVoteScreen({
    super.key,
    required this.voter,
    required this.voters,
    required this.allPlayers,
    required this.index,
    required this.onComplete,
  });

  @override
  State<IndividualVoteScreen> createState() => _IndividualVoteScreenState();
}

class _IndividualVoteScreenState extends State<IndividualVoteScreen> {
  Player? selectedTarget;

  @override
  Widget build(BuildContext context) {
    bool voterIsTraveling = (widget.voter.role?.toLowerCase() == "voyageur" && widget.voter.isInTravel);

    // --- DICTATURE RON-ALDO ---
    // Si le joueur est fan et que Ron-Aldo est vivant, il ne vote pas.
    bool ronAldoAlive = widget.allPlayers.any((p) => p.role?.toLowerCase() == "ron-aldo" && p.isAlive);
    bool isFanBlocked = widget.voter.isFanOfRonAldo && ronAldoAlive;

    if (voterIsTraveling) {
      return _buildSkippedScreen(
          "ABSENT DU VILLAGE",
          "Vous êtes en voyage. Vous ne pouvez pas voter ce soir.",
          Icons.flight_takeoff,
          Colors.purpleAccent
      );
    }

    if (isFanBlocked) {
      return _buildSkippedScreen(
          "DÉVOTION TOTALE",
          "Ron-Aldo décide pour vous.\nVotre voix compte automatiquement pour son choix.",
          Icons.star, // Étoile de fan
          Colors.amber
      );
    }

    // TRI ALPHABÉTIQUE DES CIBLES
    final eligibleTargets = widget.allPlayers.where((p) => p.isAlive).toList();
    eligibleTargets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text("VOTE : ${Player.formatName(widget.voter.name)}"),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: _buildVoteList(eligibleTargets),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
          ),
          onPressed: (selectedTarget != null) ? _submitVote : null,
          child: const Text(
              "VALIDER MON VOTE",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
          ),
        ),
      ),
    );
  }

  // --- ÉCRANS BLOQUANTS (Voyageur / Fan) ---
  Widget _buildSkippedScreen(String title, String desc, IconData icon, Color color) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: () {
                  widget.voter.targetVote = null; // Vote nul forcé
                  _goToNext();
                },
                child: const Text("SUIVANT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitVote() {
    if (selectedTarget != null) {
      widget.voter.targetVote = selectedTarget;

      // Note: Le calcul du poids se fait dans GameLogic.processVillageVote
      debugPrint("🗳️ LOG [Vote] : ${widget.voter.name} vote pour ${selectedTarget!.name}");

      // Check Succès "Fan Traître"
      AchievementLogic.checkTraitorFan(context, widget.voter, selectedTarget!);

      if (widget.voter.team == "loups" && selectedTarget!.team == "loups") {
        wolfVotedWolf = true;
      }
    }
    _goToNext();
  }

  void _goToNext() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PassScreen(
          voters: widget.voters,
          allPlayers: widget.allPlayers,
          index: widget.index + 1,
          onComplete: widget.onComplete,
        ),
      ),
    );
  }

  Widget _buildVoteList(List<Player> targets) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Qui souhaitez-vous éliminer ?",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: targets.length,
            itemBuilder: (context, i) {
              final target = targets[i];
              bool isSelected = selectedTarget == target;

              return Card(
                color: isSelected ? Colors.orangeAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? Colors.orangeAccent : Colors.transparent),
                ),
                child: ListTile(
                  onTap: () => setState(() => selectedTarget = target),
                  leading: Icon(Icons.person, color: isSelected ? Colors.orangeAccent : Colors.white24),
                  title: Text(
                      Player.formatName(target.name),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                  ),
                  trailing: Radio<Player>(
                    activeColor: Colors.orangeAccent,
                    value: target,
                    groupValue: selectedTarget,
                    onChanged: (val) => setState(() => selectedTarget = val),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 3. ÉCRAN DE RÉSULTAT POUR LE MJ (VERDICT)
// =============================================================================
class MJResultScreen extends StatelessWidget {
  final List<Player> allPlayers;
  final VoidCallback onComplete;

  const MJResultScreen({super.key, required this.allPlayers, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = allPlayers.where((p) => p.isAlive).toList();

    // TRI : Par votes décroissant, puis Alphabétique
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
                // Immunité Ron-Aldo (si fans vivants)
                if (p.role?.toLowerCase() == "ron-aldo") {
                  if (allPlayers.any((f) => f.isFanOfRonAldo && f.isAlive)) isImmunized = true;
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

  void _confirmDeath(BuildContext context, Player target) {
    debugPrint("⚖️ LOG [Sentence] : Le MJ a choisi d'éliminer ${target.name}.");
    playSfx("cloche.mp3");

    if (target.isImmunizedFromVote) {
      _showSpecialPopUp(context, "🛡️ PROTECTION", "${Player.formatName(target.name)} est protégé(e) !");
      return;
    }

    String roleReveal = target.role?.toUpperCase() ?? "INCONNU";

    // Élimination principale (Gère aussi la cascade de morts : Pokémon, Maison, etc.)
    Player deceased = GameLogic.eliminatePlayer(context, allPlayers, target, isVote: true);

    String message = deceased.isAlive ? "La cible a survécu !" : "Le village a tranché ! ${Player.formatName(deceased.name)} est éliminé.";

    // --- GESTION DES MESSAGES CONTEXTUELS ---

    if (deceased.role?.toLowerCase() == "pantin" && deceased.isAlive) {
      message = "🃏 Le Pantin a survécu (Immunité unique).";
    }
    else if (deceased.role?.toLowerCase() == "voyageur" && deceased.isAlive) {
      message = "✈️ Le Voyageur revient au village (Survit).";
    }
    else if (!deceased.isAlive) {
      // 1. Cas Sacrifice Ron-Aldo
      if (target.role?.toLowerCase() == "ron-aldo" && deceased.role?.toLowerCase() == "fan de ron-aldo") {
        message = "🛡️ SACRIFICE : ${Player.formatName(deceased.name)} s'est sacrifié !\nSon rôle était : FAN DE RON-ALDO";
      }
      // 2. Cas Maison Effondrée
      else if (target.role?.toLowerCase() == "maison" && deceased != target) {
        message = "🏠 La Maison s'est effondrée sur ${Player.formatName(deceased.name)} !\nSon rôle était : ${deceased.role?.toUpperCase()}";
      }
      // 3. Cas Standard
      else {
        message = "${Player.formatName(deceased.name)} est éliminé.\n\nSon rôle était : $roleReveal";

        // --- AJOUT INFO POKÉMON ---
        if ((deceased.role?.toLowerCase() == "pokémon" || deceased.role?.toLowerCase() == "pokemon") && deceased.pokemonRevengeTarget != null) {
          Player revengeTarget = deceased.pokemonRevengeTarget!;
          // On vérifie qu'elle est bien morte (GameLogic l'a tuée juste avant)
          if (!revengeTarget.isAlive) {
            message += "\n\n⚡ VENGEANCE !\nLe Pokémon a foudroyé ${revengeTarget.name} (${revengeTarget.role?.toUpperCase()}) !";
          }
        }
      }
    }

    _finalize(context, message, deceased.isAlive);
  }

  void _showSpecialPopUp(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(title, style: const TextStyle(color: Colors.orangeAccent)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () { Navigator.of(ctx).pop(); _finalize(context, "Annulé par protection.", true); }, child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))],
      ),
    );
  }

  void _handleNoOneDies(BuildContext context) {
    playSfx("cloche.mp3");
    _finalize(context, "Personne ne meurt ce soir.", true);
  }

  void _finalize(BuildContext context, String message, bool noOne) async {
    // --- AJOUT : Vérification des succès AVANT le reset du tour ---
    await AchievementLogic.checkMidGameAchievements(context, allPlayers);

    GameLogic.nextTurn(allPlayers);

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(noOne ? "⚖️ Verdict : SURVIE" : "💀 Sentence : MORT", style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pop(context);
                onComplete();
              },
              child: const Text("OK", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }
}