import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/globals.dart';

class GrandMereInterface extends StatelessWidget {
  final Player actor;
  final Function(bool) onBakeComplete;
  final VoidCallback onSkip;
  final Widget Function(String, Color, VoidCallback) circleBtnBuilder;

  const GrandMereInterface({
    super.key,
    required this.actor,
    required this.onBakeComplete,
    required this.onSkip,
    required this.circleBtnBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Log de statut au chargement
    debugPrint("🥧 LOG [Grand-mère] : Check Cooldown - isProtected: ${actor.isVillageProtected}, hasBaked: ${actor.hasBakedQuiche}");

    // Nouvelle logique de Cooldown simplifiée et robuste :
    // On ne peut pas cuisiner si une quiche est DÉJÀ EN FOUR (hasBakedQuiche)
    // OU si le village bénéficie déjà d'une quiche (isVillageProtected).
    bool inCooldown = actor.hasBakedQuiche || actor.isVillageProtected;

    if (inCooldown) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 20),
            const Text(
              "FOUR EN REFROIDISSEMENT",
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "La pâte doit reposer.\nVous cuisinez déjà pour le village.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () {
                debugPrint("🥧 LOG [Grand-mère] : Cooldown actif, passage automatique.");
                onSkip();
              },
              child: const Text("CONTINUER LA NUIT", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.soup_kitchen, size: 80, color: Colors.orangeAccent),
        const SizedBox(height: 20),
        const Text(
          "LA QUICHE DE MAMIE",
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2
          ),
        ),
        const SizedBox(height: 15),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            "Voulez-vous cuisiner cette nuit ?\n\n(La quiche sera prête pour protéger\ntout le village la NUIT PROCHAINE)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.amberAccent, fontSize: 16),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouton de préparation (Effet différé)
            circleBtnBuilder("CUISINER", Colors.green, () {
              debugPrint("🥧 LOG [Grand-mère] : Mise au four confirmée (Nuit $globalTurnNumber).");

              // Action : On met la quiche au four pour la nuit suivante
              actor.hasBakedQuiche = true;
              actor.lastQuicheTurn = globalTurnNumber;

              // On informe le dispatcher et le système de sauvegarde
              onBakeComplete(true);
            }),
            const SizedBox(width: 40),
            circleBtnBuilder("REPOS", Colors.redAccent, () {
              debugPrint("🥧 LOG [Grand-mère] : Mamie a choisi de se reposer.");
              onSkip();
            }),
          ],
        ),
        const SizedBox(height: 40),
        const Text(
          "⚠️ La protection dure 1 cycle complet (Nuit + Jour).",
          style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}