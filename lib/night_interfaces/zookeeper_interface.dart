import 'package:flutter/material.dart';
import '../../models/player.dart';
import 'target_selector_interface.dart';

class ZookeeperInterface extends StatelessWidget {
  final List<Player> players;
  final Function(Player) onTargetSelected;

  const ZookeeperInterface({
    super.key,
    required this.players,
    required this.onTargetSelected,
  });

  @override
  Widget build(BuildContext context) {
    // On filtre les joueurs vivants
    final alivePlayers = players.where((p) => p.isAlive).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.colorize, color: Colors.cyanAccent, size: 40),
              const SizedBox(height: 10),
              const Text(
                "FLÉCHETTE NARCOLEPTIQUE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Désignez une cible. Elle s'endormira\nautomatiquement la nuit prochaine.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.cyanAccent, thickness: 0.5, indent: 40, endIndent: 40),
        Expanded(
          child: TargetSelectorInterface(
            players: alivePlayers,
            maxTargets: 1,
            isProtective: false, // Affichage "attaque" (rouge/orange) car c'est un malus pour la cible
            onTargetsSelected: (selectedList) {
              if (selectedList.isNotEmpty) {
                final target = selectedList.first;

                // LOGIQUE ZOOKEEPER :
                // On ne met PAS 'isEffectivelyAsleep' à true maintenant.
                // resolveNight s'en chargera au début de la nuit suivante.
                target.hasBeenHitByDart = true;

                onTargetSelected(target);
              }
            },
          ),
        ),
      ],
    );
  }
}