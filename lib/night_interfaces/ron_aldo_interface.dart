import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class RonAldoInterface extends StatelessWidget {
  final Player actor;
  final List<Player> allPlayers;
  final VoidCallback onNext;

  const RonAldoInterface({
    super.key,
    required this.actor,
    required this.allPlayers,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    // Liste des fans actuels vivants
    final currentFans = allPlayers.where((p) => p.isFanOfRonAldo && p.isAlive).toList();

    // Cas où le club est déjà plein (limite de 3 fans)
    if (currentFans.length >= 3) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, size: 64, color: Colors.orangeAccent),
            const SizedBox(height: 10),
            const Text("VOTRE CLUB EST COMPLET",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("(3 Fans vivants)", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 30),
            ElevatedButton(
                onPressed: onNext,
                child: const Text("PASSER")
            ),
          ],
        ),
      );
    }

    // Liste des cibles potentielles : Vivants, pas Ron-Aldo lui-même, pas encore Fan
    final potentialTargets = allPlayers.where((p) =>
    p.isAlive &&
        p.role != "Ron-Aldo" &&
        !p.isFanOfRonAldo
    ).toList();

    // Tri de la liste par ordre alphabétique
    potentialTargets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
              "FANS ACTUELS : ${currentFans.length} / 3",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
        ),
        const Divider(color: Colors.white10),
        Expanded(
          child: ListView.builder(
            itemCount: potentialTargets.length,
            itemBuilder: (context, i) {
              final p = potentialTargets[i];
              return ListTile(
                title: Text(formatPlayerName(p.name),
                    style: const TextStyle(color: Colors.white)),
                subtitle: const Text("Convertir en Fan",
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                trailing: const Icon(Icons.person_add_alt_1, color: Colors.orangeAccent),
                onTap: () {
                  // Logique de conversion : l'ancien rôle est écrasé
                  p.isFanOfRonAldo = true;
                  p.role = "Fan de Ron-Aldo";

                  // Calcul de l'ordre d'arrivée pour la gestion du sacrifice (le plus ancien meurt en premier)
                  int maxOrder = allPlayers
                      .map((pl) => pl.fanJoinOrder)
                      .fold(0, (prev, e) => e > prev ? e : prev);
                  p.fanJoinOrder = maxOrder + 1;

                  onNext();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}