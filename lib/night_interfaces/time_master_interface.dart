import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart';
import 'target_selector_interface.dart';

class TimeMasterInterface extends StatefulWidget {
  final Function(dynamic) onTimerAdjust;

  const TimeMasterInterface({super.key, required this.onTimerAdjust});

  @override
  State<TimeMasterInterface> createState() => _TimeMasterInterfaceState();
}

class _TimeMasterInterfaceState extends State<TimeMasterInterface> {
  @override
  Widget build(BuildContext context) {
    // LOG de statut au chargement
    debugPrint("⏳ LOG [Maître du Temps] : Accès à l'interface du flux temporel.");

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(15.0),
          child: Column(
            children: [
              Text(
                "MAÎTRE DU TEMPS",
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Choisissez 2 joueurs à éliminer du flux temporel.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.cyanAccent, thickness: 0.5, indent: 40, endIndent: 40),
        Expanded(
          child: TargetSelectorInterface(
            players: globalPlayers.where((p) => p.isAlive).toList(),
            maxTargets: 2,
            isProtective: false, // Thème rouge/attaque
            onTargetsSelected: (selected) {
              if (selected.length == 2) {
                debugPrint("⏳ LOG [Maître du Temps] : EFFACEMENT TEMPOREL lancé.");

                // On boucle pour appliquer la mort et loguer chaque victime
                for (var p in selected) {
                  debugPrint("💀 LOG [Maître du Temps] : ${p.name} est effacé du flux.");
                  p.isAlive = false;
                }

                // Finalisation de l'action
                widget.onTimerAdjust(null);
              } else if (selected.isEmpty) {
                debugPrint("⏳ LOG [Maître du Temps] : Le flux temporel reste inchangé (Action passée).");
                widget.onTimerAdjust(null);
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            "⚠️ Attention : Ces joueurs ne se réveilleront pas demain.",
            style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}