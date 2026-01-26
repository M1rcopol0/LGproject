import 'package:flutter/material.dart';
import '../../models/player.dart';

class VoyageurInterface extends StatelessWidget {
  final Player actor;
  final VoidCallback onStayAtVillage; // Rester au village
  final VoidCallback onDepart;        // Partir en voyage
  final VoidCallback onReturn;        // Rentrer du voyage
  final VoidCallback onStayTraveling; // Rester en voyage

  const VoyageurInterface({
    super.key,
    required this.actor,
    required this.onStayAtVillage,
    required this.onDepart,
    required this.onReturn,
    required this.onStayTraveling,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            actor.isInTravel ? Icons.flight_takeoff : Icons.home,
            size: 80,
            color: actor.isInTravel ? Colors.cyanAccent : Colors.greenAccent,
          ),
          const SizedBox(height: 20),
          Text(
            actor.isInTravel
                ? "VOUS ÊTES EN VOYAGE"
                : "VOUS ÊTES AU VILLAGE",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            actor.isInTravel
                ? "Voulez-vous rentrer ce soir ?"
                : "Voulez-vous partir en voyage ?",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 40),

          if (!actor.isInTravel) ...[
            // CAS 1 : AU VILLAGE
            _buildChoiceBtn("PARTIR EN VOYAGE", Colors.deepPurple, onDepart),
            const SizedBox(height: 20),
            _buildChoiceBtn("RESTER AU VILLAGE", Colors.blueGrey, onStayAtVillage),
          ] else ...[
            // CAS 2 : EN VOYAGE
            _buildChoiceBtn("RENTRER AU VILLAGE", Colors.green, onReturn),
            const SizedBox(height: 20),
            _buildChoiceBtn("RESTER EN VOYAGE", Colors.cyan.withOpacity(0.5), onStayTraveling),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}