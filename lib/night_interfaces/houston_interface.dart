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
    // 1. Filtrage : Vivants et pas soi-même
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
            "Le résultat de l'analyse (Même camp ou non) sera annoncé au réveil du village.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TargetSelectorInterface(
            players: eligibleTargets,
            maxTargets: 2,
            isProtective: false, // Thème neutre
            onTargetsSelected: (selected) {
              if (selected.length == 2) {
                // --- LOGS DE CONSOLE ---
                debugPrint("🛰️ LOG [Houston] : ${actor.name} surveille ${selected[0].name} (Camp: ${selected[0].team}) et ${selected[1].name} (Camp: ${selected[1].team}).");

                // On envoie la sélection au Dispatcher qui la stockera dans actor.houstonTargets
                // Le résultat sera généré dans NightActionsLogic au matin.
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