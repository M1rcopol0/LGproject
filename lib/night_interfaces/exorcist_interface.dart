import 'package:flutter/material.dart';

class ExorcistInterface extends StatelessWidget {
  final Function(String) onActionComplete;
  final Widget Function(String, Color, VoidCallback) circleBtnBuilder;

  const ExorcistInterface({
    super.key,
    required this.onActionComplete,
    required this.circleBtnBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Correction de l'icône : auto_fix_high (tout en minuscules)
        const Icon(Icons.auto_fix_high, size: 60, color: Colors.blueAccent),
        const SizedBox(height: 20),
        const Text(
          "L'exorcisme a-t-il été réussi ?",
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Text(
            "Répondez 'OUI' si le rituel a fonctionné, sinon 'NON'.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            circleBtnBuilder("OUI", Colors.green, () {
              // --- LOGS DE CONSOLE ---
              debugPrint("✝️ LOG [Exorciste] : Rituel réussi (Succès envoyé au Dispatcher).");
              onActionComplete("success");
            }),
            const SizedBox(width: 40),
            circleBtnBuilder("NON", Colors.redAccent, () {
              // --- LOGS DE CONSOLE ---
              debugPrint("✝️ LOG [Exorciste] : Rituel échoué (Échec envoyé au Dispatcher).");
              onActionComplete("failed");
            }),
          ],
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () {
            debugPrint("✝️ LOG [Exorciste] : Action passée (skipped).");
            onActionComplete("skipped");
          },
          child: const Text(
              "PASSER L'ACTION",
              style: TextStyle(color: Colors.white24, letterSpacing: 1.2)
          ),
        )
      ],
    );
  }
}