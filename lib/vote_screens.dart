import 'package:flutter/material.dart';
import 'models/player.dart';
import 'globals.dart';
import 'logic.dart';
import 'achievement_logic.dart';
import 'trophy_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// =============================================================================
// 1. ÉCRAN DE TRANSITION (PASSE LE TÉLÉPHONE)
// =============================================================================
class PassScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    bool isLastVoter = index >= voters.length;

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
              isLastVoter ? "MAÎTRE DU JEU" : formatPlayerName(voters[index].name),
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MJResultScreen(
                          allPlayers: allPlayers,
                          onComplete: onComplete,
                        ),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IndividualVoteScreen(
                          voter: voters[index],
                          voters: voters,
                          allPlayers: allPlayers,
                          index: index,
                          onComplete: onComplete,
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
// 2. ÉCRAN DE VOTE INDIVIDUEL
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

    final eligibleTargets = widget.allPlayers.where((p) => p.isAlive).toList();
    eligibleTargets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text("VOTE : ${formatPlayerName(widget.voter.name)}"),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: voterIsTraveling
          ? _buildTravelingView()
          : _buildVoteList(eligibleTargets),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: voterIsTraveling ? Colors.blueGrey : Colors.green[700],
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
          ),
          onPressed: (voterIsTraveling || selectedTarget != null) ? _submitVote : null,
          child: Text(
              voterIsTraveling ? "PASSER (EN VOYAGE)" : "VALIDER MON VOTE",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
          ),
        ),
      ),
    );
  }

  void _submitVote() {
    if (selectedTarget != null) {
      widget.voter.targetVote = selectedTarget;

      // LOG DE VOTE INDIVIDUEL
      int weight = (widget.voter.role?.toLowerCase() == "pantin") ? 2 : 1;
      debugPrint("🗳️ LOG [Vote] : ${widget.voter.name} (${widget.voter.role}) vote pour ${selectedTarget!.name} (Poids: $weight)");

      AchievementLogic.checkTraitorFan(widget.voter, selectedTarget!);

      if (!widget.voter.isVoteCancelled) {
        selectedTarget!.votes += weight;
        if (widget.voter.team == "loups" && selectedTarget!.team == "loups") {
          debugPrint("🐺 LOG [Trahison] : Un Loup vote contre un autre Loup !");
          wolfVotedWolf = true;
        }
      } else {
        debugPrint("🔇 LOG [Vote] : Le vote de ${widget.voter.name} est annulé (Mute/Effet).");
      }
    } else {
      debugPrint("✈️ LOG [Vote] : ${widget.voter.name} ne vote pas (En voyage).");
    }

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

  Widget _buildTravelingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: 80, color: Colors.purpleAccent),
          SizedBox(height: 20),
          Text("ABSENT DU VILLAGE", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Padding(
            padding: EdgeInsets.all(30.0),
            child: Text(
              "Vous êtes actuellement en voyage. Vous ne pouvez pas voter ce soir.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteList(List<Player> targets) {
    return ListView.builder(
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
                formatPlayerName(target.name),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white
                )
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
    sortedPlayers.sort((a, b) {
      if (b.votes != a.votes) {
        return b.votes.compareTo(a.votes);
      }
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
                if (p.role?.toLowerCase() == "ron-aldo") {
                  bool hasFans = allPlayers.any((f) => f.isFanOfRonAldo && f.isAlive);
                  if (hasFans) isImmunized = true;
                }

                return Card(
                  color: isImmunized ? Colors.cyan.withOpacity(0.1) : Colors.white10,
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    leading: isImmunized
                        ? const Icon(Icons.shield, color: Colors.cyanAccent, size: 28)
                        : const Icon(Icons.person_outline, color: Colors.white24),
                    title: Text(
                        formatPlayerName(p.name),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isImmunized ? Colors.cyanAccent : Colors.white
                        )
                    ),
                    subtitle: Text(
                        p.role?.toUpperCase() ?? "INCONNU",
                        style: TextStyle(color: isImmunized ? Colors.cyanAccent.withOpacity(0.6) : Colors.orangeAccent, fontSize: 12)
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                          color: isImmunized ? Colors.cyan[900] : Colors.red[900],
                          borderRadius: BorderRadius.circular(20)
                      ),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
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

    if (target.role?.toLowerCase() == "voyageur" && target.isInTravel) {
      debugPrint("✈️ LOG [Sentence] : Cible invulnérable (Voyageur en vol).");
      target.isInTravel = false;
      _showSpecialPopUp(context, "✈️ RETOUR FORCÉ", "${formatPlayerName(target.name)} était en voyage ! Il survit mais rentre au village.");
      return;
    }

    if (target.isImmunizedFromVote) {
      debugPrint("🛡️ LOG [Sentence] : Cible protégée par le Bouc Émissaire.");
      _showSpecialPopUp(context, "🛡️ PROTECTION DU BLED", "${formatPlayerName(target.name)} est protégé(e) ! Personne ne meurt.");
      return;
    }

    Player deceased = GameLogic.eliminatePlayer(context, allPlayers, target, isVote: true);
    debugPrint("💀 LOG [Mort] : Confirmation du décès de ${deceased.name}.");

    String message;
    if (target.role?.toLowerCase() == "ron-aldo" && deceased.role?.toLowerCase() == "fan de ron-aldo") {
      message = "🛡️ SACRIFICE : ${formatPlayerName(deceased.name)} s'est sacrifié pour Ron-Aldo !";
    }
    else if (deceased.role?.toLowerCase() == "pantin" && deceased.isAlive) {
      message = "Le Pantin est maudit ! Il mourra dans 2 jours.";
    }
    else if (target.role?.toLowerCase() == "maison" || target.isInHouse) {
      message = "La Maison s'effondre ! ${formatPlayerName(deceased.name)} est éliminé.";
    }
    else {
      message = "Le village a tranché ! ${formatPlayerName(deceased.name)} est éliminé.";
    }

    _finalize(context, message, false);
  }

  void _showSpecialPopUp(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(title, style: const TextStyle(color: Colors.orangeAccent)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finalize(context, "L'exécution a été annulée par protection.", true);
            },
            child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  void _handleNoOneDies(BuildContext context) {
    debugPrint("⚖️ LOG [Sentence] : Le MJ a gracié le village.");
    playSfx("cloche.mp3");
    _finalize(context, "Personne ne meurt ce soir.", true);
  }

  void _finalize(BuildContext context, String message, bool noOne) {
    GameLogic.nextTurn(allPlayers);
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(noOne ? "⚖️ Verdict" : "💀 Sentence", style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pop(context);
              onComplete();
            },
            child: const Text("OK", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}