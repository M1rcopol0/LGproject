import 'package:flutter/material.dart';
import '../models/player.dart';
import '../logic/logic.dart';
import '../logic/achievement_logic.dart';
import '../globals.dart';
import 'mj_result_screen.dart'; // Pour la redirection finale

// =============================================================================
// ORCHESTRATEUR DE VOTE (Gère la séquence sans casser la navigation)
// =============================================================================
class VotePlayerSelectionScreen extends StatefulWidget {
  final List<Player> allPlayers;
  final VoidCallback onComplete; // Ajout du callback de complétion

  const VotePlayerSelectionScreen({
    super.key,
    required this.allPlayers,
    required this.onComplete
  });

  @override
  State<VotePlayerSelectionScreen> createState() => _VotePlayerSelectionScreenState();
}

class _VotePlayerSelectionScreenState extends State<VotePlayerSelectionScreen> {
  late List<Player> voters;
  int currentIndex = 0;
  bool isPassingPhase = true; // true = Écran "Passez le téléphone", false = Écran de vote

  @override
  void initState() {
    super.initState();
    // On récupère la liste des votants (vivants, actifs, et non absents/archivistes)
    voters = widget.allPlayers.where((p) => p.isAlive && p.isPlaying && !p.isAwayAsMJ).toList();
    voters.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _nextStep() {
    if (isPassingPhase) {
      // Passage de "Passez le tel" -> "Vote"
      setState(() {
        isPassingPhase = false;
      });
    } else {
      // Le joueur a voté
      if (currentIndex < voters.length - 1) {
        // Il reste des joueurs : on passe au suivant (Phase "Passez le tel")
        setState(() {
          currentIndex++;
          isPassingPhase = true;
        });
      } else {
        // Tous les joueurs ont voté : Fin de la séquence anonyme
        _goToResults();
      }
    }
  }

  void _goToResults() async {
    debugPrint("🕵️ LOG [Vote] : Fin des votes individuels. Calcul des résultats...");
    GameLogic.processVillageVote(context, widget.allPlayers);

    if (!mounted) return;

    // On empile l'écran de résultat par-dessus l'orchestrateur.
    // On NE passe PAS widget.onComplete directement : MJResultScreen appelle son
    // onComplete AVANT que VotePlayerSelectionScreen se soit fermé, ce qui laisse
    // l'orchestrateur visible et crée le loop "dernier votant → résultats → dernier votant".
    // On lui passe un no-op et on gère l'appel à widget.onComplete nous-mêmes.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MJResultScreen(
          allPlayers: widget.allPlayers,
          onComplete: () {}, // géré ci-dessous après le pop de l'orchestrateur
        ),
      ),
    );

    // Quand on revient du MJResultScreen (partie continue),
    // on ferme d'abord l'orchestrateur, puis on notifie VillageScreen.
    // Si la partie est terminée, MJResultScreen a déjà vidé la pile via
    // pushAndRemoveUntil → mounted sera false → on ne fait rien.
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (voters.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: Center(child: Text("Personne ne peut voter.", style: TextStyle(color: Colors.white))),
      );
    }

    final currentPlayer = voters[currentIndex];

    // Affichage conditionnel selon la phase (Passez le tel VS Vote)
    if (isPassingPhase) {
      return _PassScreenContent(
        voter: currentPlayer,
        onNext: _nextStep,
      );
    } else {
      return _IndividualVoteScreenContent(
        voter: currentPlayer,
        allPlayers: widget.allPlayers,
        onVote: _nextStep,
      );
    }
  }
}

// =============================================================================
// WIDGET : ÉCRAN DE TRANSITION ("PASSEZ LE TÉLÉPHONE")
// =============================================================================
class _PassScreenContent extends StatelessWidget {
  final Player voter;
  final VoidCallback onNext;

  const _PassScreenContent({
    required this.voter,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "📲 PASSEZ LE TÉLÉPHONE À :",
              style: TextStyle(fontSize: 18, letterSpacing: 2, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Text(
              Player.formatName(voter.name),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black45)]
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                onPressed: onNext,
                child: const Text(
                  "JE SUIS PRÊT",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
// WIDGET : ÉCRAN DE VOTE INDIVIDUEL
// =============================================================================
class _IndividualVoteScreenContent extends StatefulWidget {
  final Player voter;
  final List<Player> allPlayers;
  final VoidCallback onVote;

  const _IndividualVoteScreenContent({
    required this.voter,
    required this.allPlayers,
    required this.onVote,
  });

  @override
  State<_IndividualVoteScreenContent> createState() => _IndividualVoteScreenContentState();
}

class _IndividualVoteScreenContentState extends State<_IndividualVoteScreenContent> {
  Player? selectedTarget;

  @override
  Widget build(BuildContext context) {
    bool voterIsTraveling = (widget.voter.role?.toLowerCase() == "voyageur" && widget.voter.isInTravel);
    bool ronAldoAlive = widget.allPlayers.any((p) => p.role?.toLowerCase() == "ron-aldo" && p.isAlive);
    bool isFanBlocked = widget.voter.isFanOfRonAldo && ronAldoAlive;

    if (voterIsTraveling) {
      debugPrint("🗳️ CAPTEUR [Vote] : ${widget.voter.name} skip vote (Voyageur absent).");
      return _buildSkippedScreen(
          "ABSENT DU VILLAGE",
          "Vous êtes en voyage. Vous ne pouvez pas voter ce soir.",
          Icons.flight_takeoff,
          Colors.purpleAccent
      );
    }

    if (isFanBlocked) {
      debugPrint("🗳️ CAPTEUR [Vote] : ${widget.voter.name} skip vote (Fan bloqué, Ron-Aldo vivant).");
      return _buildSkippedScreen(
          "DÉVOTION TOTALE",
          "Ron-Aldo décide pour vous.\nVotre voix compte automatiquement pour son choix.",
          Icons.star,
          Colors.amber
      );
    }

    final eligibleTargets = widget.allPlayers.where((p) =>
    p.isAlive &&
        p.isPlaying &&
        !p.isAwayAsMJ
    ).toList();

    eligibleTargets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text("VOTE : ${Player.formatName(widget.voter.name)}"),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
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
              itemCount: eligibleTargets.length,
              itemBuilder: (context, i) {
                final target = eligibleTargets[i];
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
      ),
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
                  widget.voter.targetVote = null;
                  widget.onVote();
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
      debugPrint("🗳️ LOG [Vote] : ${widget.voter.name} vote pour ${selectedTarget!.name}");
      AchievementLogic.trackVote(widget.voter, selectedTarget!); // Utilisation de trackVote pour les succès
      if (widget.voter.team == "loups" && selectedTarget!.team == "loups") {
        wolfVotedWolf = true;
      }
    }
    widget.onVote();
  }
}