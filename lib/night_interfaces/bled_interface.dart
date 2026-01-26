import 'package:flutter/material.dart';
import '../../models/player.dart';
import 'target_selector_interface.dart';

class BledInterface extends StatelessWidget {
  final Player actor; // Paramètre indispensable pour le Dispatcher
  final List<Player> players;
  final Function(List<Player>) onComplete;

  const BledInterface({
    super.key,
    required this.actor,
    required this.players,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(15.0),
          child: Text(
            "ENCULATEUR DU BLED\nQui protéger du vote du village demain ?",
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
            "Le joueur sélectionné sera immunisé contre les votes lors du prochain conseil.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TargetSelectorInterface(
            // On exclut l'acteur de la liste des cibles
            players: players.where((p) => p.isAlive && p != actor).toList(),
            maxTargets: 1,
            isProtective: true, // Thème vert pour la protection
            onTargetsSelected: (selected) {
              if (selected.isNotEmpty) {
                final target = selected.first;

                // --- LOGS DE CONSOLE ---
                debugPrint("🤫 LOG [Bled] : ${actor.name} protège et fait taire ${target.name}.");

                // Application de l'immunité immédiate pour le vote de demain
                target.isImmunizedFromVote = true;
                // Note: La censure (isMutedDay) est appliquée dans le dispatcher
                // via le retour du onComplete, mais on pourrait aussi le faire ici.
              } else {
                debugPrint("🤫 LOG [Bled] : ${actor.name} n'a choisi personne.");
              }
              onComplete(selected);
            },
          ),
        ),
      ],
    );
  }
}