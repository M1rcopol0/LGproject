import 'package:flutter/material.dart';
import '../../models/player.dart'; // Remonte de 2 niveaux si dans lib/night_interfaces
import '../../globals.dart';      // Idem
import 'target_selector_interface.dart'; // Même dossier

class TimeMasterInterface extends StatefulWidget {
  // On garde le nom "onTimerAdjust" pour matcher l'appel dans NightActionsScreen
  // même si fonctionnellement c'est une sélection de cibles.
  final Function(dynamic) onTimerAdjust;

  const TimeMasterInterface({super.key, required this.onTimerAdjust});

  @override
  State<TimeMasterInterface> createState() => _TimeMasterInterfaceState();
}

class _TimeMasterInterfaceState extends State<TimeMasterInterface> {
  @override
  Widget build(BuildContext context) {
    // On récupère la liste globale des joueurs via globals.dart puisque non passée en paramètre
    // (Dans votre NightActionsScreen, vous ne passiez pas 'players' au constructeur TimeMaster)

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Text(
            "Maître du Temps : Choisissez 2 joueurs à éliminer du flux temporel.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.cyanAccent),
          ),
        ),
        Expanded(
          child: TargetSelectorInterface(
            players: globalPlayers, // Utilise la variable globale
            maxTargets: 2,
            isProtective: false,
            onTargetsSelected: (selected) {
              if (selected.length == 2) {
                // On tue directement ici ou on renvoie la liste
                for (var p in selected) {
                  p.isAlive = false; // Mort immédiate (ou différée selon logique)
                }
                // On appelle le callback pour finir
                widget.onTimerAdjust(null);
              }
            },
          ),
        ),
      ],
    );
  }
}