import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart';
import '../../achievement_logic.dart'; // <--- IMPORT OBLIGATOIRE POUR LE SUCCÈS
import 'target_selector_interface.dart';

class DingoInterface extends StatelessWidget {
  final Player actor; // Le joueur qui agit (Dingo)
  final VoidCallback onHit; // Callback de navigation (Succès entraînement)
  final VoidCallback onMiss; // Callback de navigation (Échec entraînement)
  final List<Player> players;
  final Function(Player) onKillTargetSelected; // Callback pour tuer (Série terminée)

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

    // =========================================================
    // CAS 1 : TIR MORTEL (Série complétée : 4/4)
    // =========================================================
    if (actor.dingoStrikeCount >= 4) {
      // 1. Filtrage et Tri Alphabétique des cibles potentielles
      final eligibleTargets = players.where((p) => p.isAlive && p != actor).toList();
      eligibleTargets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
              players: eligibleTargets,
              maxTargets: 1,
              isProtective: false, // C'est un tir offensif (Rouge)
              onTargetsSelected: (selected) {
                if (selected.isNotEmpty) {
                  Player victim = selected.first;

                  // --- 1. TRIGGER SUCCÈS "UN TIR DU PARKING" ---
                  // On vérifie si ce tir est légendaire (dernier ennemi tué)
                  AchievementLogic.checkParkingShotCondition(actor, victim, players);

                  // --- 2. MISE À JOUR DES STATS ---
                  actor.dingoShotsFired++;
                  actor.dingoShotsHit++; // Un tir mortel compte comme un tir réussi

                  // --- 3. LOGS ---
                  debugPrint("💥 LOG [Dingo] : Tir mortel exécuté sur ${victim.name}.");
                  debugPrint("📊 STATS [Dingo] : Tirs totaux: ${actor.dingoShotsFired} | Touchés: ${actor.dingoShotsHit}");

                  // --- 4. ACTION (Tuer) ---
                  onKillTargetSelected(victim);
                }
              },
            ),
          ),
        ],
      );
    }

    // =========================================================
    // CAS 2 : ENTRAÎNEMENT (Série < 4)
    // =========================================================
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
              // BOUTON ÉCHEC
              _buildBigButton(
                context,
                "TIR RATÉ",
                Icons.close,
                Colors.red.withOpacity(0.8),
                    () {
                  // MISE À JOUR ÉTAT
                  actor.dingoShotsFired++;
                  actor.dingoStrikeCount = 0; // RESET DE LA SÉRIE

                  // LOGS
                  debugPrint("💨 LOG [Dingo] : Tir raté. Série réinitialisée à 0.");
                  debugPrint("📊 STATS [Dingo] : Tirs totaux: ${actor.dingoShotsFired}");

                  // NAVIGATION
                  onMiss();
                },
              ),
              // BOUTON SUCCÈS
              _buildBigButton(
                context,
                "TIR RÉUSSI",
                Icons.check,
                Colors.green.withOpacity(0.8),
                    () {
                  // MISE À JOUR ÉTAT
                  actor.dingoShotsFired++;
                  actor.dingoShotsHit++;
                  actor.dingoStrikeCount++; // INCRÉMENTATION DE LA SÉRIE

                  // LOGS
                  debugPrint("🎯 LOG [Dingo] : Tir réussi ! Progression : ${actor.dingoStrikeCount}/4");
                  debugPrint("📊 STATS [Dingo] : Tirs totaux: ${actor.dingoShotsFired} | Touchés: ${actor.dingoShotsHit}");

                  // NAVIGATION
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