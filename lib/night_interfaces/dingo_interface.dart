import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart';
import 'target_selector_interface.dart';

class DingoInterface extends StatelessWidget {
  final Player actor; // Le joueur qui agit (Dingo)
  final VoidCallback onHit;
  final VoidCallback onMiss;
  final List<Player> players;
  final Function(Player) onKillTargetSelected;

  const DingoInterface({
    super.key,
    required this.actor,
    required this.onHit,
    required this.onMiss,
    required this.players,
    required this.onKillTargetSelected,
  });

  @override
  Widget build(BuildContext context) {
    // --- LOGS DE CONSOLE ---
    debugPrint("🎯 LOG [Dingo] : ${actor.name} accède à son arme. Série actuelle : ${actor.dingoStrikeCount}/4");

    // CAS 1 : TIR MORTEL (Après 4 réussites)
    if (actor.dingoStrikeCount >= 4) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "🎯 CONCENTRATION MAXIMALE\nVous pouvez abattre un joueur ce soir.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TargetSelectorInterface(
              players: players.where((p) => p.isAlive && p != actor).toList(),
              maxTargets: 1,
              isProtective: false,
              onTargetsSelected: (selected) {
                if (selected.isNotEmpty) {
                  debugPrint("💥 LOG [Dingo] : Tir mortel exécuté sur ${selected.first.name}.");
                  // On enregistre le tir mortel pour les stats
                  actor.dingoShotsFired++;
                  actor.dingoShotsHit++;
                  onKillTargetSelected(selected.first);
                }
              },
            ),
          ),
        ],
      );
    }

    // CAS 2 : ENTRAÎNEMENT
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Série actuelle : ${actor.dingoStrikeCount} / 4",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Entraînez-vous pour charger votre arme.",
            style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBigButton(
                context,
                "TIR RATÉ",
                Icons.close,
                Colors.red.withOpacity(0.8),
                    () {
                  debugPrint("💨 LOG [Dingo] : Tir raté. Série réinitialisée.");
                  actor.dingoShotsFired++; // Stats pour succès "Mauvais tireur"
                  onMiss();
                },
              ),
              _buildBigButton(
                context,
                "TIR RÉUSSI",
                Icons.check,
                Colors.green.withOpacity(0.8),
                    () {
                  debugPrint("🎯 LOG [Dingo] : Tir réussi ! Progression : ${actor.dingoStrikeCount + 1}/4");
                  actor.dingoShotsFired++;
                  actor.dingoShotsHit++;
                  onHit();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5)
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}