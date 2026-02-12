import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/player_status_icons.dart';

class PlayerListCard extends StatelessWidget {
  final Player player;
  final bool isGameStarted;
  final VoidCallback onTap;
  final Function(bool?)? onCheckChanged;

  const PlayerListCard({
    super.key,
    required this.player,
    required this.isGameStarted,
    required this.onTap,
    this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isDead = isGameStarted && !player.isAlive;

    return Card(
      color: isDead ? Colors.red.withOpacity(0.1) : Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isDead ? Icons.dangerous : Icons.person,
          color: isDead ? Colors.red : Colors.greenAccent,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                player.name,
                style: TextStyle(
                  color: Colors.white,
                  decoration: isDead ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            player.buildStatusIcons(),
          ],
        ),
        subtitle: isGameStarted
            ? Text(
          player.role?.toUpperCase() ?? "INCONNU",
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        )
            : (player.isRoleLocked
            ? Text("🔒 ${player.role?.toUpperCase()}",
            style: const TextStyle(color: Colors.amberAccent, fontSize: 10))
            : null),
        trailing: !isGameStarted
            ? Checkbox(
          value: player.isPlaying,
          activeColor: Colors.orangeAccent,
          onChanged: onCheckChanged,
        )
            : null,
      ),
    );
  }
}