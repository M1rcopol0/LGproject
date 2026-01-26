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
        const Text("L'exorcisme a-t-il été réussi ?",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            circleBtnBuilder("OUI", Colors.green, () => onActionComplete("success")),
            const SizedBox(width: 40),
            circleBtnBuilder("NON", Colors.redAccent, () => onActionComplete("failed")),
          ],
        ),
      ],
    );
  }
}