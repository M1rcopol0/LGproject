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
    // LOG de statut au chargement
    debugPrint("🧨 LOG [Tardos] : ${widget.actor.name} accède à l'interface. Bombe déjà posée : ${widget.actor.hasPlacedBomb}");

    // Si la bombe est déjà posée (explosée ou en attente)
    if (widget.actor.hasPlacedBomb) {
      String status = (widget.actor.bombTimer > 0)
          ? "La bombe explosera dans ${widget.actor.bombTimer} nuit(s)."
          : "La bombe a déjà explosé.";

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

    // Sinon, on propose de poser la bombe
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "TARDOS\nChoisissez une cible pour poser votre bombe.\nElle explosera dans 2 nuits.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: TargetSelectorInterface(
            players: widget.players.where((p) => p.isAlive && p != widget.actor).toList(),
            maxTargets: 1,
            onTargetsSelected: (selected) {
              if (selected.isNotEmpty) {
                _placeBomb(selected.first);
              } else {
                debugPrint("🧨 LOG [Tardos] : Aucune cible choisie.");
                widget.onNext();
              }
            },
          ),
        ),
      ],
    );
  }

  void _placeBomb(Player target) {
    // 1% de chance d'explosion immédiate sur soi-même (Règle Tardos)
    int roll = Random().nextInt(100);
    debugPrint("🎲 LOG [Tardos] : Jet de dé pour la pose : $roll (Seuil critique : 0)");

    if (roll == 0) {
      debugPrint("💥 LOG [Tardos] : ÉCHEC CRITIQUE ! La bombe explose sur Tardos (${widget.actor.name}).");
      _showPop("CRITIQUE !", "La bombe vous a explosé dans les mains ! Vous mourrez ce matin.", true);

      setState(() {
        widget.actor.tardosTarget = widget.actor;
        widget.actor.bombTimer = 0; // Explosion immédiate lors de la résolution
        widget.actor.hasPlacedBomb = true;
      });
    } else {
      debugPrint("🧨 LOG [Tardos] : Bombe posée sur ${target.name}. Timer réglé sur 2.");
      setState(() {
        widget.actor.tardosTarget = target;
        widget.actor.bombTimer = 2; // Explose au bout de 2 nuits
        widget.actor.hasPlacedBomb = true;
      });
      _showPop("BOMBE POSÉE", "La bombe explosera sur ${target.name} dans 2 nuits.", false);
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