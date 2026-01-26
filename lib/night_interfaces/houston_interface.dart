import 'package:flutter/material.dart';
import '../models/player.dart';
import 'target_selector_interface.dart';

class HoustonInterface extends StatelessWidget {
  final Player actor;
  final List<Player> players;
  final Function(List<Player>) onComplete;

  const HoustonInterface({
    super.key,
    required this.actor,
    required this.players,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    // On filtre les joueurs vivants et on exclut Houston lui-même
    final eligibleTargets = players.where((p) => p.isAlive && p != actor).toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "HOUSTON\nDésignez 2 joueurs pour comparer leurs camps.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Si les deux joueurs sont dans le même camp, le voyant restera vert au matin. S'ils sont de camps différents, il passera au rouge.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TargetSelectorInterface(
            players: eligibleTargets,
            maxTargets: 2,
            onTargetsSelected: (selected) {
              if (selected.length == 2) {
                // --- LOGS DE CONSOLE ---
                debugPrint("🛰️ LOG [Houston] : ${actor.name} surveille ${selected[0].name} (Camp: ${selected[0].team}) et ${selected[1].name} (Camp: ${selected[1].team}).");

                onComplete(selected);
              } else {
                debugPrint("🛰️ LOG [Houston] : Action passée sans sélectionner 2 cibles.");
                onComplete([]);
              }
            },
          ),
        ),
      ],
    );
  }
}