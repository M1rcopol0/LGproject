import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

// Import de toutes les interfaces spécifiques
import 'exorcist_interface.dart';
import 'grand_mere_interface.dart';
import 'devin_interface.dart';
import 'ron_aldo_interface.dart';
import 'target_selector_interface.dart';
import 'dresseur_interface.dart';
import 'maison_interface.dart';
import 'archiviste_interface.dart';
import 'somnifere_interface.dart';
import 'voyageur_interface.dart';
import 'chaman_interface.dart';
import 'bled_interface.dart';
import 'lg_evolue_interface.dart';
import 'dingo_interface.dart';
import 'zookeeper_interface.dart';
import 'phyl_interface.dart';
import 'tardos_interface.dart';
import 'houston_interface.dart';

class RoleActionDispatcher extends StatelessWidget {
  final NightAction action;
  final Player actor;
  final List<Player> allPlayers;
  final Map<Player, String> pendingDeaths;
  final Function(String? result) onExorcisme;
  final Function(bool used) onSomnifere;
  final VoidCallback onNext;
  final Function(String title, String msg) showPopUp;

  const RoleActionDispatcher({
    super.key,
    required this.action,
    required this.actor,
    required this.allPlayers,
    required this.pendingDeaths,
    required this.onExorcisme,
    required this.onSomnifere,
    required this.onNext,
    required this.showPopUp,
  });

  @override
  Widget build(BuildContext context) {
    // --- LOGIQUE D'ANONYMAT ET SOMMEIL ---
    bool isImmuneToSleep = (action.role == "Archiviste" && actor.isAwayAsMJ);

    // CONDITION SPÉCIALE : On ne bloque pas l'écran pour les Loups-Garous Évolués
    // car c'est une action de groupe (le groupe doit pouvoir voter même si l'un d'eux dort).
    // On ne bloque pas non plus le Zookeeper (attaquant).
    bool isGroupAction = (action.role == "Loups-garous évolués");

    if (!isGroupAction &&
        action.role != "Zookeeper" &&
        actor.isEffectivelyAsleep &&
        !isImmuneToSleep) {
      return _buildAsleepScreen();
    }

    // --- DISPATCHER DES RÔLES ACTIFS ---
    switch (action.role) {
      case "Zookeeper":
        return ZookeeperInterface(
            players: allPlayers,
            onTargetSelected: (t) => onNext()
        );

      case "Phyl":
        return PhylInterface(actor: actor, players: allPlayers, onComplete: onNext);

      case "Grand-mère":
        return GrandMereInterface(
            actor: actor,
            onBakeComplete: (success) => onNext(),
            onSkip: onNext,
            circleBtnBuilder: _circleBtn
        );

      case "Dresseur":
        return DresseurInterface(
            actor: actor,
            allPlayers: allPlayers,
            onComplete: (target) {
              if (target != null) pendingDeaths[target] = "Rage du Pokémon";
              onNext();
            }
        );

      case "Voyageur":
        return VoyageurInterface(
          actor: actor,
          onDepart: () { actor.isInTravel = true; onNext(); },
          onStayAtVillage: () {
            if (actor.travelerBullets > 0) {
              _showKillSelector(context, actor, "Balle du Voyageur", (t) {
                actor.travelerBullets--;
                pendingDeaths[t] = "Abattu par le Voyageur";
                onNext();
              });
            } else { onNext(); }
          },
          onReturn: () { actor.isInTravel = false; onNext(); },
          onStayTraveling: () { onNext(); },
        );

      case "Pantin":
        return TargetSelectorInterface(
          players: allPlayers.where((p) => p.isAlive && p != actor).toList(),
          maxTargets: 2,
          onTargetsSelected: (selected) {
            for (var p in selected) { p.pantinCurseTimer = 2; }
            onNext();
          },
        );

      case "Loups-garous évolués":
      // L'interface gérera elle-même l'affichage d'un bandeau "Immobilisé" si besoin
        return LGEvolueInterface(
          players: allPlayers,
          onVictimChosen: (p) {
            pendingDeaths[p] = "Morsure de Loup";
            nightWolvesTarget = p;
            onNext();
          },
        );

      case "Somnifère":
        return SomnifereInterface(actor: actor, onActionComplete: onSomnifere);

      case "Devin":
        return DevinInterface(
          devin: actor,
          allPlayers: allPlayers,
          onNext: (selected) {
            if (actor.concentrationTargetName == selected.name) {
              actor.concentrationNights++;
            } else {
              actor.concentrationTargetName = selected.name;
              actor.concentrationNights = 1;
            }
            onNext();
          },
        );

      case "Houston":
        return HoustonInterface(
          actor: actor,
          players: allPlayers,
          onComplete: (selected) {
            actor.houstonTargets = selected;
            onNext();
          },
        );

      case "Archiviste":
        return ArchivisteInterface(
          players: allPlayers,
          actor: actor,
          onComplete: (msg) {
            if (msg != null) showPopUp("ARCHIVISTE", msg);
            else onNext();
          },
        );

      case "Maison":
        return MaisonInterface(
          actor: actor,
          players: allPlayers,
          onComplete: (selectedList) {
            for (var p in selectedList) { p.isInHouse = true; }
            onNext();
          },
        );

      case "Chuchoteur":
        int maxMutes = (globalTurnNumber >= 5) ? 3 : (globalTurnNumber >= 3 ? 2 : 1);
        return TargetSelectorInterface(
          players: allPlayers.where((p) => p.isAlive).toList(),
          maxTargets: maxMutes,
          onTargetsSelected: (selected) {
            for (var p in selected) p.isMutedDay = true;
            showPopUp("CHUCHOTEUR", "Cibles réduites au silence.");
          },
        );

      case "Maître du temps":
        return TargetSelectorInterface(
          players: allPlayers.where((p) => p.isAlive).toList(),
          maxTargets: 2,
          onTargetsSelected: (selected) {
            for (var p in selected) pendingDeaths[p] = "Effacé par le Temps";
            onNext();
          },
        );

      case "Tardos":
        return TardosInterface(actor: actor, players: allPlayers, onNext: onNext);

      case "Dingo":
        return DingoInterface(
          actor: actor,
          players: allPlayers,
          onHit: onNext,
          onMiss: onNext,
          onKillTargetSelected: (target) {
            pendingDeaths[target] = "Tir du Dingo";
            onNext();
          },
        );

      case "Ron-Aldo":
        return RonAldoInterface(actor: actor, allPlayers: allPlayers, onNext: onNext);

      case "Loup-garou chaman":
        return ChamanInterface(players: allPlayers, onTargetSelected: (p) => onNext());

      case "Exorciste":
        return ExorcistInterface(
          onActionComplete: onExorcisme,
          circleBtnBuilder: _circleBtn,
        );

      default:
        return Center(
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text("PASSER L'ACTION"),
          ),
        );
    }
  }

  // --- ÉCRAN DE SOMMEIL (STRICTE CONFIDENTIALITÉ) ---

  Widget _buildAsleepScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bedtime, size: 100, color: Colors.blueAccent),
          const SizedBox(height: 30),
          const Text(
            "VOUS DORMEZ PROFONDÉMENT",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Un événement (Somnifère ou Zookeeper) vous empêche d'agir cette nuit.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
            ),
            onPressed: onNext,
            child: const Text("CONTINUER LA NUIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- HELPERS D'INTERFACE ---

  Widget _circleBtn(String text, Color col, VoidCallback fn) {
    return InkWell(
      onTap: fn,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: col, shape: BoxShape.circle, boxShadow: [
          BoxShadow(color: col.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
        ]),
        alignment: Alignment.center,
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  void _showKillSelector(BuildContext context, Player killer, String reason, Function(Player) onKill) {
    final targets = allPlayers.where((p) => p.isAlive && p != killer).toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("CIBLE DE L'ATTAQUE", style: TextStyle(color: Colors.redAccent)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (c, i) => ListTile(
              leading: const Icon(Icons.gps_fixed, color: Colors.red),
              title: Text(targets[i].name, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                onKill(targets[i]);
              },
            ),
          ),
        ),
      ),
    );
  }
}