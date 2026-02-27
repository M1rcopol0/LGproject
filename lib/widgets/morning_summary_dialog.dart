import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/player.dart';
import '../logic/night/night_actions_logic.dart'; // Pour NightResult

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

  Color _factionColor(String? team) {
    switch (team) {
      case "loups": return Colors.redAccent;
      case "village": return Colors.greenAccent;
      case "solo": return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }

  IconData _factionIcon(String? team) {
    switch (team) {
      case "loups": return Icons.whatshot;
      case "village": return Icons.shield;
      case "solo": return Icons.star;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Préparation des listes pour l'affichage
    List<String> mutedPlayers = players
        .where((p) => p.isMutedDay && p.isAlive)
        .map((p) => p.name)
        .toList();
    mutedPlayers.sort((a, b) => a.compareTo(b));

    Player? voyageurRetour = players.firstWhereOrNull((p) =>
        p.role?.toLowerCase() == "voyageur" &&
        p.isAlive &&
        !p.canTravelAgain &&
        !p.isInTravel &&
        p.hasReturnedThisTurn);

    Player? archivisteTranscende = players.firstWhereOrNull((p) =>
        p.role?.toLowerCase() == "archiviste" &&
        p.isAlive &&
        p.isAwayAsMJ &&
        !p.needsToChooseTeam &&
        p.mjNightsCount == 0);

    List<Player> sortedDeadPlayers = List.from(result.deadPlayers);
    sortedDeadPlayers.sort((a, b) => a.name.compareTo(b.name));

    final bool hasDeaths = sortedDeadPlayers.isNotEmpty;
    final String titleText = result.exorcistVictory
        ? "✝️ EXORCISME ACCOMPLI"
        : hasDeaths
            ? "☀️ L'AUBE SE LÈVE..."
            : "🌅 NUIT PAISIBLE";
    final Color titleColor = result.exorcistVictory
        ? Colors.amberAccent
        : hasDeaths
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: Row(
        children: [
          Icon(
            result.exorcistVictory ? Icons.auto_fix_high : Icons.wb_sunny,
            color: titleColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titleText,
              style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Victoire exorcisme
            if (result.exorcistVictory)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  border: Border.all(color: Colors.amberAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "L'EXORCISME A RÉUSSI !\nLe village est purifié et gagne immédiatement !",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.amberAccent, fontWeight: FontWeight.bold),
                ),
              ),

            // Annonces spéciales
            if (!result.exorcistVictory && result.announcements.isNotEmpty) ...[
              const Text("📢 ANNONCES SPÉCIALES :",
                  style: TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ...result.announcements.map((msg) => Text("- $msg",
                  style: const TextStyle(color: Colors.white70))),
              const Divider(color: Colors.white24),
            ],

            // Révélations (Devin)
            if (result.revealedPlayerNames.isNotEmpty) ...[
              const Text("🔍 RÉVÉLATIONS :",
                  style: TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...result.revealedPlayerNames.map((name) => Text(
                  "- $name a été identifié(e) par le Devin",
                  style: const TextStyle(color: Colors.white70))),
              const Divider(color: Colors.white24),
            ],

            // Retour forcé voyageur
            if (voyageurRetour != null) ...[
              const Text("🛑 RETOUR FORCÉ :",
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              Text(
                "Le Voyageur a dû rentrer. Il ne repartira plus.\n💊 Munitions restantes : ${voyageurRetour.travelerBullets}",
                style: const TextStyle(color: Colors.white70),
              ),
              const Divider(color: Colors.white24),
            ],

            // Silence
            if (mutedPlayers.isNotEmpty) ...[
              const Text("🤐 SILENCE :",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
              Text("${mutedPlayers.join(", ")} ne peut pas parler.",
                  style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24),
            ],

            // Transcendance archiviste
            if (archivisteTranscende != null) ...[
              const Text("🗂️ TRANSCENDANCE :",
                  style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
              Text(
                "${archivisteTranscende.name} a quitté le village pour devenir Maître du Jeu. Il ne jouera plus jusqu'à sa victoire.",
                style: const TextStyle(color: Colors.white70),
              ),
              const Divider(color: Colors.white24),
            ],

            // Somnifère
            if (result.villageIsNarcoleptic) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.15),
                  border: Border.all(color: Colors.purpleAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bedtime, color: Colors.purpleAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Le village est pris d'un profond sommeil...",
                        style: TextStyle(color: Colors.purpleAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Morts (affiché même si somnifère actif — d'autres actions nocturnes peuvent tuer)
            if (sortedDeadPlayers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.nightlight_round, color: Colors.greenAccent, size: 20),
                      SizedBox(width: 8),
                      Text("Personne n'est mort cette nuit.",
                          style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else ...[
                const Text("💀 DÉCÈS :",
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...sortedDeadPlayers.map((p) {
                  final String deathReason = result.deathReasons[p.name] ?? '';
                  final bool isHeartbreak = deathReason.contains("Chagrin d'amour");
                  final Color borderColor = isHeartbreak
                      ? Colors.pinkAccent.withOpacity(0.7)
                      : _factionColor(p.team).withOpacity(0.6);
                  final Color bgColor = isHeartbreak
                      ? Colors.pink.withOpacity(0.1)
                      : _factionColor(p.team).withOpacity(0.1);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: isHeartbreak ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isHeartbreak ? Icons.favorite_border : _factionIcon(p.team),
                          color: isHeartbreak ? Colors.pinkAccent : _factionColor(p.team),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                "${p.role}  •  $deathReason",
                                style: TextStyle(
                                    color: isHeartbreak ? Colors.pinkAccent : Colors.white70,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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
