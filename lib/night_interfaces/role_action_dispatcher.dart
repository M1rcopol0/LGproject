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
    // --- LOGS DE CONSOLE ---
    debugPrint("🎬 LOG : Action en cours : ${action.role} (Joueur : ${actor.name})");

    // --- LOGIQUE D'ANONYMAT ET SOMMEIL ---
    // L'Archiviste en exil est immunisé au sommeil car il n'est pas "physiquement" là
    bool isImmuneToSleep = (action.role == "Archiviste" && actor.isAwayAsMJ);

    // Si le joueur est endormi (Zookeeper ou Pokémon)
    if (actor.isEffectivelyAsleep && !isImmuneToSleep && action.role != "Zookeeper") {
      debugPrint("💤 LOG : ${actor.name} est endormi (Zookeeper/Pokémon). Affichage écran sommeil.");
      return _buildAsleepScreen();
    }

    // --- DISPATCHER DES RÔLES ACTIFS ---
    switch (action.role) {
      case "Zookeeper":
        return ZookeeperInterface(
            players: allPlayers,
            onTargetSelected: (t) {
              debugPrint("💉 LOG : Zookeeper (${actor.name}) a visé ${t.name}");
              onNext();
            }
        );

      case "Phyl":
        return PhylInterface(actor: actor, players: allPlayers, onComplete: onNext);

      case "Grand-mère":
        return GrandMereInterface(
            actor: actor,
            onBakeComplete: (success) {
              if (success) debugPrint("🥧 LOG : La Grand-mère a mis une quiche au four.");
              onNext();
            },
            onSkip: onNext,
            circleBtnBuilder: _circleBtn
        );

      case "Dresseur":
        return DresseurInterface(
            actor: actor,
            allPlayers: allPlayers,
            onComplete: (target) {
              if (target != null) {
                debugPrint("⚡ LOG : Pokémon Rage sur ${target.name}");
                pendingDeaths[target] = "Rage du Pokémon";
              }
              onNext();
            }
        );

      case "Voyageur":
        return VoyageurInterface(
          actor: actor,
          allPlayers: allPlayers,
          onDepart: () {
            actor.isInTravel = true;
            onNext();
          },
          onReturnWithoutShooting: () {
            actor.isInTravel = false;
            // Si la règle est qu'il doit attendre avant de repartir, mettre : actor.canTravelAgain = false;
            onNext();
          },
          onStayTraveling: () {
            // Logique de stats gérée par NightActionsLogic
            onNext();
          },
          onStayAtVillage: onNext,
          onShoot: (target) {
            actor.isInTravel = false;
            actor.travelerBullets--;
            pendingDeaths[target] = "Tir du Voyageur (${actor.name})";
            onNext();
          },
        );

      case "Pantin":
        return TargetSelectorInterface(
          players: allPlayers.where((p) => p.isAlive && p != actor).toList(),
          maxTargets: 2,
          onTargetsSelected: (selected) {
            for (var p in selected) {
              debugPrint("🎭 LOG : Le Pantin maudit ${p.name}");
              p.pantinCurseTimer = 2;
            }
            onNext();
          },
        );

      case "Loups-garous évolués":
        return LGEvolueInterface(
          players: allPlayers,
          onVictimChosen: (p) {
            if (p.name != "Personne") {
              debugPrint("🐺 LOG : Les Loups ont choisi de mordre ${p.name}");
              pendingDeaths[p] = "Morsure de Loup";
              nightWolvesTarget = p;
            } else {
              debugPrint("🐺 LOG : Les Loups ne mangent personne (Meute bloquée).");
            }
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
            debugPrint("👁️ LOG : La Devin se concentre sur ${selected.name}");
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
            // CORRECTIF : APPEL DE LA LOGIQUE DE COMPARAISON
            _handleHoustonAction(selected);
          },
        );

      case "Enculateur du bled":
        return BledInterface(
          actor: actor,
          players: allPlayers,
          onComplete: (targets) {
            for (var t in targets) {
              debugPrint("🤫 LOG : Le Bled a immunisé ${t.name} (et le fait taire)");
              t.isMutedDay = true;
              t.isImmunizedFromVote = true;
            }
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
            for (var p in selectedList) {
              debugPrint("🏠 LOG : La Maison accueille ${p.name}");
              p.isInHouse = true;
            }
            onNext();
          },
        );

      case "Chuchoteur":
        int maxMutes = (globalTurnNumber >= 5) ? 3 : (globalTurnNumber >= 3 ? 2 : 1);
        return TargetSelectorInterface(
          players: allPlayers.where((p) => p.isAlive).toList(),
          maxTargets: maxMutes,
          onTargetsSelected: (selected) {
            for (var p in selected) {
              debugPrint("🔇 LOG : Le Chuchoteur fait taire ${p.name}");
              p.isMutedDay = true;
            }
            showPopUp("CHUCHOTEUR", "Cibles réduites au silence.");
          },
        );

      case "Maître du temps":
        return TargetSelectorInterface(
          players: allPlayers.where((p) => p.isAlive).toList(),
          maxTargets: 2,
          onTargetsSelected: (selected) {
            for (var p in selected) {
              debugPrint("⏳ LOG : Le Maître du Temps efface ${p.name}");
              pendingDeaths[p] = "Effacé par le Temps";
            }
            onNext();
          },
        );

      case "Tardos":
        return TardosInterface(actor: actor, players: allPlayers, onNext: onNext);

      case "Dingo":
        return DingoInterface(
          actor: actor,
          players: allPlayers,
          onHit: () {
            debugPrint("🎯 LOG : Le Dingo a réussi son tir.");
            onNext();
          },
          onMiss: () {
            debugPrint("❌ LOG : Le Dingo a raté son tir.");
            onNext();
          },
          onKillTargetSelected: (target) {
            debugPrint("💀 LOG : Tir MORTEL du Dingo sur ${target.name}");
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
          onActionComplete: (res) {
            debugPrint("✝️ LOG : L'Exorciste a agi. Résultat : $res");
            onExorcisme(res);
          },
          circleBtnBuilder: _circleBtn,
        );

      default:
        debugPrint("⚠️ LOG : Action non gérée pour ${action.role}");
        return Center(
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text("PASSER L'ACTION"),
          ),
        );
    }
  }

  // --- LOGIQUE HOUSTON (CORRIGÉE) ---
  void _handleHoustonAction(List<Player> targets) {
    if (targets.length != 2) {
      onNext();
      return;
    }

    Player p1 = targets[0];
    Player p2 = targets[1];
    bool sameTeam = (p1.team == p2.team);

    // Message selon les règles : "Qui voilà-je" vs "Houston, on a un problème"
    String phraseMJ = sameTeam ? "QUI VOILÀ-JE !" : "HOUSTON, ON A UN PROBLÈME !";
    String details = sameTeam
        ? "✅ Ils sont dans la MÊME équipe."
        : "⚠️ Ils sont dans des équipes DIFFÉRENTES.";

    String fullMessage = "Analyse terminée pour ${p1.name} et ${p2.name}.\n\n"
        "Annoncez à voix haute :\n"
        "📢 \"$phraseMJ\"\n\n"
        "($details)";

    // On utilise showPopUp qui doit être géré par NightActionsScreen pour passer au suivant à la fermeture
    showPopUp("RAPPORT HOUSTON", fullMessage);
  }

  // --- ÉCRAN DE SOMMEIL ---
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
              "Un événement (Zookeeper ou Pokémon) vous empêche d'agir cette nuit.",
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
}