import 'package:flutter/material.dart';

class GameInfoHeader extends StatelessWidget {
  final bool isGameStarted;
  final int playerCount;
  final String timeString;
  final bool isTimerRunning;
  final VoidCallback onToggleTimer;
  final VoidCallback onResetTimer;

  const GameInfoHeader({
    super.key,
    required this.isGameStarted,
    required this.playerCount,
    required this.timeString,
    required this.isTimerRunning,
    required this.onToggleTimer,
    required this.onResetTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isGameStarted) ...[
            const Icon(Icons.groups, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Text(
              "$playerCount Participants",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ] else ...[
            const Icon(Icons.timer, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(
              timeString,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                isTimerRunning ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: onToggleTimer,
            ),
            IconButton(
              icon: const Icon(Icons.replay, color: Colors.white54),
              onPressed: onResetTimer,
            ),
          ]
        ],
      ),
    );
  }
}