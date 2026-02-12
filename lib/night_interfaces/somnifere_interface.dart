import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';

class SomnifereInterface extends StatelessWidget {
  final Player actor;
  final Function(bool) onActionComplete;

  const SomnifereInterface({super.key, required this.actor, required this.onActionComplete});

  @override
  Widget build(BuildContext context) {
    bool canUse = actor.somnifereUses > 0;

    // LOG de statut au chargement
    debugPrint("💤 LOG [Somnifère] : ${actor.name} accède à l'interface. Charges restantes: ${actor.somnifereUses}");

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nights_stay, size: 80, color: Colors.purpleAccent),
          const SizedBox(height: 20),
          const Text(
            "UTILISER LE SOMNIFÈRE ?",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Charges restantes : ${actor.somnifereUses}",
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _btn("NON", Colors.grey, () {
                debugPrint("💤 LOG [Somnifère] : Action refusée. Le village restera éveillé.");
                onActionComplete(false);
              }),
              if (canUse)
                _btn("OUI", Colors.purpleAccent, () {
                  actor.somnifereUses--;
                  debugPrint("💤 LOG [Somnifère] : ACTIVÉ ! Charges restantes : ${actor.somnifereUses}");
                  debugPrint("⚠️ LOG [Somnifère] : Le village sera narcoleptique au réveil.");
                  onActionComplete(true);
                }),
            ],
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Effet : Annule toutes les morts de la nuit et réduit le village au silence demain.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 10,
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}