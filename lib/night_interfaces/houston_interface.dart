import 'package:flutter/material.dart';
import '../models/player.dart';
import '../achievement_logic.dart'; // Import nécessaire pour le succès
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
    // 1. Filtrage et Tri Alphabétique
    final eligibleTargets = players.where((p) => p.isAlive && p != actor).toList();
    eligibleTargets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
            // On force la sélection de 2 cibles pour valider
            minTargets: 2,
            isProtective: false, // Thème neutre/action
            onTargetsSelected: (selected) {
              if (selected.length == 2) {
                // --- 1. TRIGGER SUCCÈS APOLLO 13 ---
                // CORRECTION : Ajout du context pour afficher le Toast immédiatement
                AchievementLogic.checkApollo13(context, actor, selected[0], selected[1]);

                // --- 2. LOGS DE CONSOLE ---
                debugPrint("🛰️ LOG [Houston] : ${actor.name} surveille ${selected[0].name} (Camp: ${selected[0].team}) et ${selected[1].name} (Camp: ${selected[1].team}).");

                // --- 3. SAUVEGARDE POUR RÉSOLUTION ---
                // Important pour que NightActionsLogic puisse générer l'annonce au matin
                actor.houstonTargets = selected;

                // --- 4. NAVIGATION ---
                onComplete(selected);
              } else {
                // Cas où l'utilisateur passe son tour (normalement bloqué par minTargets, mais sécurité)
                debugPrint("🛰️ LOG [Houston] : Action passée sans sélectionner 2 cibles complètes.");
                onComplete([]);
              }
            },
          ),
        ),
      ],
    );
  }
}