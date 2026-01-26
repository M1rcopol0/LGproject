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
            "Désignez 2 joueurs pour comparer leurs camps.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        Expanded(
          child: TargetSelectorInterface(
            players: eligibleTargets,
            maxTargets: 2,
            onTargetsSelected: (selected) {
              if (selected.length == 2) {
                onComplete(selected);
              }
            },
          ),
        ),
      ],
    );
  }
}