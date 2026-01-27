import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart';

class DevinInterface extends StatefulWidget {
  final Player devin;
  final List<Player> allPlayers;
  // Le callback renvoie le joueur choisi pour le focus.
  final Function(Player selected) onNext;

  const DevinInterface({
    super.key,
    required this.devin,
    required this.allPlayers,
    required this.onNext,
  });

  @override
  State<DevinInterface> createState() => _DevinInterfaceState();
}

class _DevinInterfaceState extends State<DevinInterface> {
  bool _isChangingTarget = false;

  @override
  Widget build(BuildContext context) {
    // 1. Vérifier si une cible est déjà en cours et vivante
    Player? currentTarget;
    try {
      if (widget.devin.concentrationTargetName != null) {
        currentTarget = widget.allPlayers.firstWhere(
              (p) => p.name == widget.devin.concentrationTargetName && p.isAlive,
        );
      }
    } catch (e) {
      currentTarget = null;
    }

    // =========================================================
    // CAS 1 : CIBLE DÉJÀ EN COURS (NUIT 2)
    // =========================================================
    if (currentTarget != null && !_isChangingTarget) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility, size: 80, color: Colors.purpleAccent),
            const SizedBox(height: 20),
            Text(
              "CONCENTRATION EN COURS",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              formatPlayerName(currentTarget.name),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Nuit ${widget.devin.concentrationNights + 1} / 2",
              style: const TextStyle(color: Colors.purpleAccent, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),

            // BOUTON VALIDATION (POUR LA 2ème NUIT)
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  // On passe le compteur à 2. NightActionsLogic détectera "compteur >= 2" et fera l'annonce au matin.
                  widget.devin.concentrationNights = 2;
                  debugPrint("👁️ LOG [Devin] : Validation Nuit 2 sur ${currentTarget!.name}. Révélation prévue au matin.");
                  widget.onNext(currentTarget!);
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("VALIDER (RÉVÉLATION AU MATIN)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),

            // BOUTON CHANGER (RESET)
            TextButton.icon(
              onPressed: () {
                debugPrint("👁️ LOG [Devin] : Abandon de l'observation sur ${currentTarget!.name}.");
                setState(() {
                  _isChangingTarget = true;
                });
              },
              icon: const Icon(Icons.refresh, color: Colors.white54),
              label: const Text("CHANGER DE CIBLE (RESET)", style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );
    }

    // =========================================================
    // CAS 2 : SÉLECTION D'UNE NOUVELLE CIBLE (NUIT 1)
    // =========================================================
    List<Player> targets = widget.allPlayers
        .where((p) => p.isAlive && p != widget.devin)
        .toList();

    // --- TRI ALPHABÉTIQUE ---
    targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Choisissez un joueur à observer.\n(Nécessite 2 nuits consécutives)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: targets.length,
            itemBuilder: (context, i) {
              final p = targets[i];
              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.person_search, color: Colors.purpleAccent),
                  title: Text(formatPlayerName(p.name), style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    debugPrint("👁️ LOG [Devin] : Nouvelle cible choisie : ${p.name} (Début Nuit 1)");

                    // On initialise le cycle
                    widget.devin.concentrationTargetName = p.name;
                    widget.devin.concentrationNights = 1; // On valide la fin de la nuit 1

                    widget.onNext(p);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}