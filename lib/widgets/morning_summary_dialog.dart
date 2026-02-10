import 'package:flutter/material.dart';
import '../models/player.dart';
import '../night_actions_logic.dart'; // Pour NightResult

class MorningSummaryDialog extends StatelessWidget {
  final NightResult result;
  final List<Player> players;
  final VoidCallback onConfirm;

  const MorningSummaryDialog({
    super.key,
    required this.result,
    required this.players,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Préparation des listes pour l'affichage
    List<String> mutedPlayers = players
        .where((p) => p.isMutedDay && p.isAlive)
        .map((p) => p.name)
        .toList();
    mutedPlayers.sort((a, b) => a.compareTo(b));

    bool voyageurIntercepte = players.any((p) =>
    p.role?.toLowerCase() == "voyageur" &&
        p.isAlive &&
        !p.canTravelAgain &&
        !p.isInTravel &&
        p.hasReturnedThisTurn);

    List<String> screamers = players
        .where((p) => p.mustScreamKungFu && p.isAlive)
        .map((p) => p.name)
        .toList();
    screamers.sort((a, b) => a.compareTo(b));

    List<Player> sortedDeadPlayers = List.from(result.deadPlayers);
    sortedDeadPlayers.sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: const Row(
        children: [
          Icon(Icons.wb_sunny, color: Colors.orangeAccent),
          SizedBox(width: 10),
          Expanded(
              child: Text("LE VILLAGE SE RÉVEILLE",
                  style: TextStyle(color: Colors.white))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.exorcistVictory)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                    "L'EXORCISME A RÉUSSI !\nLe village est purifié et gagne immédiatement !",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.amberAccent, fontWeight: FontWeight.bold)),
              ),
            if (!result.exorcistVictory && result.announcements.isNotEmpty) ...[
              const Text("📢 ANNONCES SPÉCIALES :",
                  style: TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ...result.announcements.map((msg) => Text("- $msg",
                  style: const TextStyle(color: Colors.white70))),
              const Divider(color: Colors.white24),
            ],
            if (screamers.isNotEmpty) ...[
              const Text("🐼 DÉFI DU PANDA :",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                    "${screamers.join(", ")} doit crier :\n\"KUNG-FU PANDA !\"",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
              ),
              const Divider(color: Colors.white24, height: 20),
            ],
            if (voyageurIntercepte) ...[
              const Text("🛑 RETOUR FORCÉ :",
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const Text("Le Voyageur a dû rentrer. Il ne repartira plus.",
                  style: TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24),
            ],
            if (mutedPlayers.isNotEmpty) ...[
              const Text("🤐 SILENCE :",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
              Text("${mutedPlayers.join(", ")} ne peut pas parler.",
                  style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24),
            ],
            if (result.villageIsNarcoleptic)
              const Text(
                  "💤 Village KO (Somnifère) !\nPersonne ne meurt, personne ne parle.",
                  style: TextStyle(color: Colors.purpleAccent)),
            if (!result.villageIsNarcoleptic) ...[
              if (sortedDeadPlayers.isEmpty)
                const Text("🕊️ Personne n'est mort cette nuit.",
                    style: TextStyle(color: Colors.greenAccent))
              else ...[
                const Text("💀 DÉCÈS :",
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ...sortedDeadPlayers.map((p) => Text(
                    "- ${p.name} (${p.role})\n  ${result.deathReasons[p.name]}",
                    style: const TextStyle(color: Colors.white70))),
              ],
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
          onPressed: onConfirm,
          child: const Text("VOIR LE VILLAGE",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}