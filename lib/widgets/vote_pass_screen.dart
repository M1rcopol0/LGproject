import 'package:flutter/material.dart';
import '../models/player.dart';

class VotePassScreen extends StatelessWidget {
  final Player voter;
  final VoidCallback onNext;

  const VotePassScreen({
    super.key,
    required this.voter,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "📲 PASSEZ LE TÉLÉPHONE À :",
              style: TextStyle(fontSize: 18, letterSpacing: 2, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Text(
              Player.formatName(voter.name),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black45)]),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                onPressed: onNext,
                child: const Text(
                  "JE SUIS PRÊT",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}