import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';
import 'target_selector_interface.dart';

class TardosInterface extends StatefulWidget {
  final Player actor;
  final List<Player> players;
  final VoidCallback onNext;

  const TardosInterface({
    super.key,
    required this.actor,
    required this.players,
    required this.onNext,
  });

  @override
  State<TardosInterface> createState() => _TardosInterfaceState();
}

class _TardosInterfaceState extends State<TardosInterface> {

  @override
  Widget build(BuildContext context) {
    debugPrint("🧨 LOG [Tardos] : ${widget.actor.name} - Active: ${widget.actor.hasPlacedBomb} | Used: ${widget.actor.hasUsedBombPower}");

    // =========================================================
    // ÉTAT 1 : BOMBE EN COURS (Tic-Tac)
    // =========================================================
    // Prioritaire : Si la bombe est posée, on affiche le timer, même si hasUsedBombPower est true.
    if (widget.actor.hasPlacedBomb) {
      String status = (widget.actor.bombTimer > 0)
          ? "La bombe explosera dans ${widget.actor.bombTimer} nuit(s)."
          : "La bombe va exploser ce matin !";

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 20),
            const Text(
              "BOMBE ACTIVÉE",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () {
                debugPrint("🧨 LOG [Tardos] : Action passée (Bombe déjà active).");
                widget.onNext();
              },
              child: const Text("PASSER", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // =========================================================
    // ÉTAT 2 : POUVOIR DÉJÀ CONSOMMÉ (Plus de bombe)
    // =========================================================
    // Si hasPlacedBomb est false (elle a explosé) MAIS que hasUsedBombPower est true.
    if (widget.actor.hasUsedBombPower) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "STOCK ÉPUISÉ",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Vous avez déjà utilisé votre unique bombe.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () {
                debugPrint("🧨 LOG [Tardos] : Action passée (Stock épuisé).");
                widget.onNext();
              },
              child: const Text("CONTINUER", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // =========================================================
    // ÉTAT 3 : PRÊT À POSER (Sélecteur)
    // =========================================================
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "TARDOS\nChoisissez une cible pour poser votre bombe.\nElle explosera dans 2 nuits.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        Expanded(
          child: TargetSelectorInterface(
            players: widget.players.where((p) => p.isAlive && p != widget.actor).toList(),
            maxTargets: 1,
            isProtective: false,
            onTargetsSelected: (selected) {
              if (selected.isNotEmpty) {
                _placeBomb(selected.first);
              } else {
                widget.onNext();
              }
            },
          ),
        ),
      ],
    );
  }

  void _placeBomb(Player target) {
    // --- MARQUAGE DÉFINITIF ---
    // On marque que le pouvoir est consommé pour empêcher une seconde pose plus tard
    widget.actor.hasUsedBombPower = true;

    int roll = Random().nextInt(100);
    debugPrint("🎲 LOG [Tardos] : Jet de dé pour la pose : $roll (Seuil critique : 0)");

    if (roll == 0) {
      // ÉCHEC CRITIQUE (1%)
      debugPrint("💥 LOG [Tardos] : ÉCHEC CRITIQUE ! La bombe explose sur Tardos.");
      setState(() {
        widget.actor.tardosTarget = widget.actor;
        widget.actor.bombTimer = 0; // Explosion immédiate
        widget.actor.hasPlacedBomb = true; // Active l'état "Bombe en cours" pour ce tour
      });
      _showPop("CRITIQUE !", "La bombe vous a explosé dans les mains !\nVous mourrez ce matin.", true);
    } else {
      // SUCCÈS STANDARD
      debugPrint("🧨 LOG [Tardos] : Bombe posée sur ${target.name}.");
      setState(() {
        widget.actor.tardosTarget = target;
        widget.actor.bombTimer = 2; // Timer standard
        widget.actor.hasPlacedBomb = true;
      });
      _showPop("BOMBE POSÉE", "La bombe est armée sur ${target.name}.\nExplosion dans 2 nuits.", false);
    }
  }

  void _showPop(String title, String msg, bool isSelfKill) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(title, style: TextStyle(color: isSelfKill ? Colors.red : Colors.orangeAccent)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onNext();
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}