import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/globals.dart';
import 'package:fluffer/services/trophy_service.dart';
import 'target_selector_interface.dart';

class MaisonInterface extends StatelessWidget {
  final Player actor;
  final List<Player> players;
  final Function(List<Player>) onComplete;

  const MaisonInterface({
    super.key,
    required this.actor,
    required this.players,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Identifier les occupants actuels (Vivants)
    final residents = players.where((p) => p.isInHouse && p.isAlive).toList();

    // 2. Vérifier si la maison est pleine (Max 2)
    bool isFull = residents.length >= 2;

    // --- LOGS DE CONSOLE ---
    debugPrint("🏠 LOG [Maison] : Statut actuel - Occupants: ${residents.length}/2 (${residents.map((p) => p.name).join(', ')})");

    return Column(
      children: [
        // --- HEADER D'INFO ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "OCCUPANTS : ${residents.length}/2",
                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (residents.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  residents.map((p) => formatPlayerName(p.name)).join(", "),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ] else
                const Text("(Maison vide)", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),

        // --- INTERFACE PRINCIPALE ---
        if (isFull) ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  const Text("MAISON COMPLÈTE", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Vous ne pouvez plus accueillir personne tant qu'un occupant est en vie.",
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  debugPrint("🏠 LOG [Maison] : Maison complète, passage de l'action.");
                  onComplete([]);
                },
                child: const Text("PASSER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ] else ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
            child: Text(
              "Choisissez un nouveau locataire.\n(Il restera chez vous définitivement)",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: TargetSelectorInterface(
              players: players.where((p) => !p.isInHouse && p != actor && p.isAlive).toList(),
              maxTargets: 1,
              isProtective: true,
              onTargetsSelected: (selectedList) {
                if (selectedList.isNotEmpty) {
                  final target = selectedList.first;

                  // --- LOGS DE CONSOLE ---
                  debugPrint("🏠 LOG [Maison] : ${actor.name} accueille ${target.name} (Équipe: ${target.team})");

                  // --- TRACKING SUCCÈS CORRIGÉ ---
                  // On utilise le bon compteur pour "Formation Hôtelière"
                  actor.hostedCountThisGame++;

                  // Vérification immédiate pour "Bienvenue Loup"
                  if (target.team == "loups") {
                    debugPrint("🏠 LOG [Maison] : ALERTE ! Un loup vient d'entrer dans la maison.");
                    TrophyService.checkAndUnlockImmediate(
                      context: context,
                      playerName: actor.name,
                      achievementId: "welcome_wolf",
                      checkData: {'maison_hosted_wolf': true},
                    );
                  }

                  onComplete(selectedList);
                } else {
                  debugPrint("🏠 LOG [Maison] : Aucune nouvelle personne accueillie ce soir.");
                  onComplete([]);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}