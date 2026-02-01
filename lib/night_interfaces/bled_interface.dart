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
    // AJOUT : Récupération de la dernière cible protégée
    final String? forbiddenTargetName = actor.lastBledTarget;

    // Filtrage des cibles éligibles
    final eligiblePlayers = players.where((p) =>
    p.isAlive &&
        p != actor &&
        p.name != forbiddenTargetName // Ne peut pas cibler la personne protégée la veille
    ).toList();

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
        if (forbiddenTargetName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "🚫 ${Player.formatName(forbiddenTargetName)} ne peut pas être protégé(e) deux fois de suite.",
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 10),
        Expanded(
          child: TargetSelectorInterface(
            players: eligiblePlayers, // Liste filtrée
            maxTargets: 1,
            isProtective: true, // Thème vert pour la protection
            onTargetsSelected: (selected) {
              if (selected.isNotEmpty) {
                final target = selected.first;

                // --- LOGS DE CONSOLE ---
                debugPrint("🤫 LOG [Bled] : ${actor.name} protège et fait taire ${target.name}.");

                // 1. Application de l'immunité immédiate pour le vote de demain
                target.isImmunizedFromVote = true;

                // 2. Mise à jour de la dernière cible pour interdire au prochain tour
                actor.lastBledTarget = target.name;

                // 3. TRACKING SUCCÈS (Sortez Couvert)
                actor.protectedPlayersHistory.add(target.name);
                debugPrint("📊 LOG [Bled] : Historique protections uniques: ${actor.protectedPlayersHistory.length}");

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