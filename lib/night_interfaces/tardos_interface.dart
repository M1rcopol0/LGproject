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
              onPressed: widget.onNext,
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
            "Choisissez une cible pour poser votre bombe.\nElle explosera dans 2 nuits.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: TargetSelectorInterface(
            players: widget.players,
            maxTargets: 1,
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
    // 1% de chance d'explosion immédiate sur soi-même (Règle Tardos)
    if (Random().nextInt(100) == 0) {
      _showPop("CRITIQUE !", "La bombe vous a explosé dans les mains ! Vous mourrez ce matin.", true);
      // On marque la mort (sera géré dans le Logic via un flag spécial ou direct death si possible,
      // mais ici on signale juste à l'UI, le Logic traitera la mort si on le set up bien).
      // Note: Pour simplifier, on set la bombe sur soi-même avec timer 0 pour explosion immédiate ce tour ci ?
      // Ou on gère ça via pendingDeaths dans le screen parent ?
      // Le plus propre ici est de simuler une pose réussie sur soi-même avec timer 0.
      setState(() {
        widget.actor.tardosTarget = widget.actor;
        widget.actor.bombTimer = 0; // Explosion immédiate
        widget.actor.hasPlacedBomb = true;
      });
    } else {
      setState(() {
        widget.actor.tardosTarget = target;
        widget.actor.bombTimer = 2; // Explose au bout de 2 nuits (résolution incluse)
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