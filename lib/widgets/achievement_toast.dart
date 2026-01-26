// lib/widgets/achievement_toast.dart

import 'package:flutter/material.dart';

class AchievementToast extends StatelessWidget {
  final String title;
  final String icon;
  final String playerName;

  const AchievementToast({
    super.key,
    required this.title,
    required this.icon,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orangeAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Accompli par $playerName",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}