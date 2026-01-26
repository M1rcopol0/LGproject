import 'package:flutter/material.dart';
import '../models/player.dart';

class SomnifereInterface extends StatelessWidget {
  final Player actor;
  final Function(bool) onActionComplete;

  const SomnifereInterface({super.key, required this.actor, required this.onActionComplete});

  @override
  Widget build(BuildContext context) {
    bool canUse = actor.somnifereUses > 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Charges restantes : ${actor.somnifereUses}",
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _btn("NON", Colors.grey, () => onActionComplete(false)),
              if (canUse)
                _btn("OUI", Colors.purpleAccent, () {
                  actor.somnifereUses--;
                  onActionComplete(true);
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}