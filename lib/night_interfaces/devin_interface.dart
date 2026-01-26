import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class DevinInterface extends StatefulWidget {
  final Player devin;
  final List<Player> allPlayers;
  // Le callback renvoie le joueur choisi pour le focus.
  // Si c'est le même qu'avant -> increment. Si c'est un autre -> reset à 1.
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
    // Vérifier si une cible est déjà en cours et vivante
    Player? currentTarget;
    try {
      if (widget.devin.concentrationTargetName != null) {
        currentTarget = widget.allPlayers.firstWhere(
              (p) => p.name == widget.devin.concentrationTargetName && p.isAlive,
        );
      }
    } catch (e) {
      // Si la cible est morte, on reset le focus
      currentTarget = null;
    }

    // CAS 1 : Déjà focus sur quelqu'un vivant, et pas en train de changer
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
            const Text(
              "(1 nuit passée)",
              style: TextStyle(color: Colors.purpleAccent, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),

            // BOUTON CONTINUER
            SizedBox(
              width: 280,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  // On renvoie la MEME cible => Le Logic passera à 2 nuits => Révélation
                  widget.onNext(currentTarget!);
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("CONTINUER (RÉVÉLER RÔLE)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),

            // BOUTON CHANGER
            TextButton.icon(
              onPressed: () {
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

    // CAS 2 : Pas de cible ou choix de changer -> Liste des joueurs
    List<Player> targets = widget.allPlayers
        .where((p) => p.isAlive && p != widget.devin)
        .toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Choisissez un joueur à observer. (Nécessite 2 nuits consécutives)",
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
                    // Nouvelle cible => Le Logic mettra le compteur à 1
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