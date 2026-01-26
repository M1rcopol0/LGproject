import 'package:flutter/material.dart';
import '../../models/player.dart';
import 'target_selector_interface.dart';

class LGEvolueInterface extends StatelessWidget {
  final List<Player> players;
  final Function(Player) onVictimChosen;

  const LGEvolueInterface({
    super.key,
    required this.players,
    required this.onVictimChosen,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Identifier les loups vivants
    final aliveWolves = players.where((p) => p.isAlive && p.team == "loups").toList();

    // 2. Identifier les loups capables de voter
    // Un loup vote s'il ne dort pas (Zookeeper/Somnifère/Pokémon)
    // Le Chaman ne vote que s'il est le SEUL survivant de la meute
    final votingWolves = aliveWolves.where((p) {
      if (p.isEffectivelyAsleep) return false;

      if (p.role?.toLowerCase() == "loup-garou chaman") {
        bool hasOtherLoup = aliveWolves.any((other) => other != p);
        return !hasOtherLoup;
      }
      return true;
    }).toList();

    // 3. Déterminer si le groupe est totalement immobilisé
    // Si des loups sont vivants mais qu'aucun ne peut voter
    bool isEntirelyBlocked = aliveWolves.isNotEmpty && votingWolves.isEmpty;

    // 4. Filtrer les victimes potentielles (Vivant et pas loup)
    final potentialVictims = players.where((p) =>
    p.isAlive && p.team != "loups"
    ).toList();

    return Stack(
      children: [
        // COUCHE 1 : L'interface de vote
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const Text(
                    "CONSEIL DES LOUPS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Puissance de vote : ${votingWolves.length} / ${aliveWolves.length}",
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  if (votingWolves.any((w) => w.role?.toLowerCase() == "loup-garou chaman"))
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "⚠️ Chaman seul : Vote activé.",
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    isEntirelyBlocked
                        ? "La meute est paralysée..."
                        : "Désignez la victime de cette nuit :",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.redAccent, thickness: 0.5, indent: 50, endIndent: 50),

            Expanded(
              child: IgnorePointer(
                ignoring: isEntirelyBlocked,
                child: Opacity(
                  opacity: isEntirelyBlocked ? 0.3 : 1.0,
                  child: TargetSelectorInterface(
                    players: potentialVictims.isNotEmpty ? potentialVictims : players.where((p) => p.isAlive).toList(),
                    maxTargets: 1,
                    isProtective: false, // Thème rouge pour attaque
                    onTargetsSelected: (selected) {
                      if (selected.isNotEmpty) {
                        onVictimChosen(selected.first);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),

        // COUCHE 2 : Le bandeau d'immobilisation (sécurité visuelle)
        if (isEntirelyBlocked)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block, color: Colors.red, size: 80),
                    const SizedBox(height: 20),
                    const Text(
                      "MEUTE BLOQUÉE",
                      style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Tous les loups capables de chasser ont été endormis ou neutralisés.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
                      ),
                      onPressed: () => onVictimChosen(Player(name: "Personne")),
                      child: const Text("PASSER LA NUIT", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}