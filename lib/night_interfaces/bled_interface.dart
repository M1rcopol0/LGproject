import 'package:flutter/material.dart';
import '../../models/player.dart';
import 'target_selector_interface.dart';

class BledInterface extends StatelessWidget {
  final List<Player> players;
  final Function(List<Player>) onComplete; // Signature attendue par NightActionsScreen

  const BledInterface({
    super.key,
    required this.players,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Text(
            "Qui protéger du vote du village demain ?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: TargetSelectorInterface(
            players: players,
            maxTargets: 1, // 1 seule protection
            isProtective: true, // Affichage vert
            onTargetsSelected: (selected) {
              if (selected.isNotEmpty) {
                // Application de l'immunité
                selected.first.isImmunizedFromVote = true;
              }
              onComplete(selected);
            },
          ),
        ),
      ],
    );
  }
}