import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/globals.dart';

class PhylInterface extends StatefulWidget {
  final Player actor;
  final List<Player> players;
  final VoidCallback onComplete;

  const PhylInterface({
    super.key,
    required this.actor,
    required this.players,
    required this.onComplete,
  });

  @override
  State<PhylInterface> createState() => _PhylInterfaceState();
}

class _PhylInterfaceState extends State<PhylInterface> {
  List<Player> _assignedTargets = [];

  @override
  void initState() {
    super.initState();
    _assignRandomTargets();
  }

  void _assignRandomTargets() {
    // Si des cibles sont déjà assignées (cas de re-render ou retour sur l'écran), on récupère l'existant
    if (widget.actor.phylTargets.isNotEmpty) {
      _assignedTargets = widget.actor.phylTargets;
      debugPrint("🎰 LOG [Phyl] : Récupération des cibles existantes : ${_assignedTargets.map((p) => p.name).join(', ')}");
      return;
    }

    // 1. Filtrer les cibles valides (Tout le monde sauf Phyl et les morts)
    List<Player> potentialTargets = widget.players.where((p) =>
    p.name != widget.actor.name && p.isAlive
    ).toList();

    // 2. Mélanger et prendre 2
    potentialTargets.shuffle();
    if (potentialTargets.length >= 2) {
      _assignedTargets = potentialTargets.sublist(0, 2);
    } else {
      // Cas extrême (ex: test à très peu de joueurs)
      _assignedTargets = potentialTargets;
    }

    // 3. Sauvegarder dans le joueur
    widget.actor.phylTargets = _assignedTargets;

    // --- LOGS DE CONSOLE ---
    debugPrint("🎰 LOG [Phyl] : Initialisation des cibles pour ${widget.actor.name}");
    debugPrint("🎯 Cibles assignées : ${_assignedTargets.map((p) => p.name).join(' et ')}");
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.casino, size: 80, color: Colors.deepPurpleAccent),
          const SizedBox(height: 20),
          const Text(
            "VOS CIBLES SONT DÉSIGNÉES",
            style: TextStyle(
              color: Colors.deepPurpleAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            child: Text(
              "Pour gagner, vous devez devenir Chef du Village ET ces deux joueurs doivent mourir :",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 40),

          // AFFICHAGE DES CARTES DES CIBLES
          if (_assignedTargets.isEmpty)
            const Text("Pas assez de joueurs pour assigner des cibles.", style: TextStyle(color: Colors.red))
          else
            Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: _assignedTargets.map((target) {
                return Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_remove, color: Colors.redAccent, size: 30),
                      const SizedBox(height: 10),
                      Text(
                        formatPlayerName(target.name),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 50),

          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
              onPressed: () {
                debugPrint("🎰 LOG [Phyl] : ${widget.actor.name} a validé ses cibles.");
                widget.onComplete();
              },
              child: const Text("J'AI RETENU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}