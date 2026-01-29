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
import 'time_master_interface.dart';
import 'pokemon_interface.dart';

class RoleActionDispatcher extends StatefulWidget {
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
  State<RoleActionDispatcher> createState() => _RoleActionDispatcherState();
}

class _RoleActionDispatcherState extends State<RoleActionDispatcher> {
  // Flag pour l'enchainement Pokémon (Vengeance -> Rage) si Dresseur mort
  bool _pokemonVengeanceDone = false;

  @override
  Widget build(BuildContext context) {
    debugPrint("🎬 LOG : Action en cours : ${widget.action.role} (Joueur : ${widget.actor.name})");

    // L'Archiviste en exil est immunisé au sommeil
    bool isImmuneToSleep = (widget.action.role == "Archiviste" && widget.actor.isAwayAsMJ);

    // Si le joueur est endormi (Zookeeper ou Pokémon)
    // Note : Si le Pokémon est enragé (Dresseur mort), est-il immunisé au sommeil ? Par défaut non.
    if (widget.actor.isEffectivelyAsleep && !isImmuneToSleep && widget.action.role != "Zookeeper") {
      debugPrint("💤 LOG : ${widget.actor.name} est endormi.");
      return _buildAsleepScreen();
    }

    switch (widget.action.role) {

    // --- LOGIQUE POKÉMON (Vengeance + Rage si Dresseur mort) ---
      case "Pokémon":
      case "Pokemon":
      // 1. D'abord, on choisit la Vengeance (Toujours)
        if (!_pokemonVengeanceDone) {
          return PokemonInterface(
            actor: widget.actor,
            players: widget.allPlayers,
            onRevengeTargetSelected: (target) {
              widget.actor.pokemonRevengeTarget = target;
              if (target != null) {
                debugPrint("⚡ LOG : Pokémon lie son destin à ${target.name} (Vengeance)");
              }

              // Si Dresseur est mort, on enchaine sur la Rage
              Player? dresseur;
              try {
                dresseur = widget.allPlayers.firstWhere((p) => p.role?.toLowerCase() == "dresseur");
              } catch (e) { dresseur = null; }

              if (dresseur != null && !dresseur.isAlive) {
                debugPrint("🔥 LOG [Pokémon] : Dresseur mort -> Passage en mode RAGE.");
                setState(() => _pokemonVengeanceDone = true);
              } else {
                widget.onNext(); // Dresseur vivant, fin du tour Pokémon
              }
            },
          );
        }

        // 2. Si Vengeance faite et Dresseur mort -> Mode RAGE (Interface Dresseur mode attaque)
        return DresseurInterface(
            actor: widget.actor,
            allPlayers: widget.allPlayers,
            onComplete: (target) {
              // Target est la victime du meurtre (Rage)
              if (target != null) {
                debugPrint("⚡ LOG : Le Pokémon enragé attaque ${target.name}");
                widget.pendingDeaths[target] = "Attaque du Pokémon (Rage)";
              }
              widget.onNext();
            }
        );

      case "Voyageur":
        return VoyageurInterface(
          actor: widget.actor,
          allPlayers: widget.allPlayers,
          onDepart: () {
            widget.actor.isInTravel = true;
            widget.onNext();
          },
          onReturnWithoutShooting: () {
            widget.actor.isInTravel = false;
            widget.actor.canTravelAgain = false;
            debugPrint("🏠 LOG : Retour simple du Voyageur (Vulnérable ce soir).");
            widget.onNext();
          },
          onStayTraveling: () {
            widget.onNext();
          },
          onStayAtVillage: widget.onNext,
          onShoot: (target) {
            widget.actor.isInTravel = false;
            widget.actor.canTravelAgain = false;
            widget.actor.travelerBullets--;
            widget.pendingDeaths[target] = "Tir du Voyageur (${widget.actor.name})";
            debugPrint("🔫 LOG : Retour agressif du Voyageur sur ${target.name}.");
            widget.onNext();
          },
        );

      case "Zookeeper":
        return ZookeeperInterface(
            players: widget.allPlayers,
            onTargetSelected: (t) {
              debugPrint("💉 LOG : Zookeeper vise ${t.name}");
              widget.onNext();
            }
        );

      case "Phyl":
        return PhylInterface(actor: widget.actor, players: widget.allPlayers, onComplete: widget.onNext);

      case "Grand-mère":
        return GrandMereInterface(
            actor: widget.actor,
            onBakeComplete: (success) {
              if (success) debugPrint("🥧 LOG : La Grand-mère cuisine.");
              widget.onNext();
            },
            onSkip: widget.onNext,
            circleBtnBuilder: _circleBtn
        );

      case "Dresseur":
      // Si Dresseur mort, on saute (car géré par le tour Pokémon ci-dessus, ou juste sauté par la boucle)
        if (!widget.actor.isAlive) {
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNext());
          return const SizedBox();
        }
        return DresseurInterface(
          actor: widget.actor,
          allPlayers: widget.allPlayers,
          onComplete: (target) {
            if (target != null) {
              // Note: Avec la nouvelle interface, lastDresseurAction est déjà set dans l'interface
              debugPrint("🦅 LOG : Dresseur action terminée.");
            }
            widget.onNext();
          },
        );

      case "Pantin":
        return TargetSelectorInterface(
          players: widget.allPlayers.where((p) => p.isAlive && p != widget.actor).toList(),
          maxTargets: 2,
          onTargetsSelected: (selected) {
            for (var p in selected) {
              debugPrint("🎭 LOG : Le Pantin maudit ${p.name}");
              p.pantinCurseTimer = 2;
            }
            widget.onNext();
          },
        );

      case "Loups-garous évolués":
        return LGEvolueInterface(
          players: widget.allPlayers,
          onVictimChosen: (p) {
            if (p.name != "Personne") {
              debugPrint("🐺 LOG : Les Loups mordent ${p.name}");
              widget.pendingDeaths[p] = "Morsure de Loup";
              nightWolvesTarget = p;
            }
            widget.onNext();
          },
        );

      case "Somnifère":
        return SomnifereInterface(actor: widget.actor, onActionComplete: widget.onSomnifere);

      case "Devin":
        return DevinInterface(
          devin: widget.actor,
          allPlayers: widget.allPlayers,
          onNext: (selected) => widget.onNext(),
        );

      case "Houston":
        return HoustonInterface(
          actor: widget.actor,
          players: widget.allPlayers,
          onComplete: (selected) {
            widget.actor.houstonTargets = selected;
            widget.onNext();
          },
        );

      case "Enculateur du bled":
        return BledInterface(
          actor: widget.actor,
          players: widget.allPlayers,
          onComplete: (targets) {
            for (var t in targets) {
              t.isMutedDay = true;
              t.isImmunizedFromVote = true;
            }
            widget.onNext();
          },
        );

      case "Archiviste":
        return ArchivisteInterface(
          players: widget.allPlayers,
          actor: widget.actor,
          onComplete: (msg) {
            if (msg != null) widget.showPopUp("ARCHIVISTE", msg);
            else widget.onNext();
          },
        );

      case "Maison":
        return MaisonInterface(
          actor: widget.actor,
          players: widget.allPlayers,
          onComplete: (selectedList) {
            for (var p in selectedList) {
              p.isInHouse = true;
            }
            widget.onNext();
          },
        );

      case "Chuchoteur":
        int maxMutes = (globalTurnNumber >= 5) ? 3 : (globalTurnNumber >= 3 ? 2 : 1);
        return TargetSelectorInterface(
          players: widget.allPlayers.where((p) => p.isAlive).toList(),
          maxTargets: maxMutes,
          onTargetsSelected: (selected) {
            for (var p in selected) {
              p.isMutedDay = true;
            }
            widget.showPopUp("CHUCHOTEUR", "Cibles réduites au silence.");
          },
        );

      case "Maître du temps":
        return TimeMasterInterface(
          player: widget.actor,
          allPlayers: widget.allPlayers,
          onAction: (type, target) {
            if (type == "REWIND" && target is Player) {
              debugPrint("⏳ LOG : Le Maître du Temps protège ${target.name}");
              target.isSavedByTimeMaster = true;
            }
            widget.onNext();
          },
        );

      case "Tardos":
        return TardosInterface(actor: widget.actor, players: widget.allPlayers, onNext: widget.onNext);

      case "Dingo":
        return DingoInterface(
          actor: widget.actor,
          players: widget.allPlayers,
          onHit: () {
            debugPrint("🎯 LOG : Le Dingo a réussi son tir.");
            widget.onNext();
          },
          onMiss: () {
            debugPrint("❌ LOG : Le Dingo a raté son tir.");
            widget.onNext();
          },
          onKillTargetSelected: (target) {
            debugPrint("💀 LOG : Tir MORTEL du Dingo sur ${target.name}");
            widget.pendingDeaths[target] = "Tir du Dingo";
            widget.onNext();
          },
        );

      case "Ron-Aldo":
        return RonAldoInterface(actor: widget.actor, allPlayers: widget.allPlayers, onNext: widget.onNext);

      case "Loup-garou chaman":
        return ChamanInterface(players: widget.allPlayers, onTargetSelected: (p) => widget.onNext());

      case "Exorciste":
        return ExorcistInterface(
          player: widget.actor,
          allPlayers: widget.allPlayers,
          onAction: (actionType, data) {
            if (actionType == "EXORCISM_SUCCESS") {
              widget.onExorcisme("SUCCESS");
            } else {
              widget.onExorcisme(null);
            }
          },
        );

      default:
        debugPrint("⚠️ LOG : Action non gérée pour ${widget.action.role}");
        return Center(
          child: ElevatedButton(
            onPressed: widget.onNext,
            child: const Text("PASSER L'ACTION"),
          ),
        );
    }
  }

  Widget _buildAsleepScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bedtime, size: 100, color: Colors.blueAccent),
          const SizedBox(height: 30),
          const Text("VOUS DORMEZ", style: TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: widget.onNext,
            child: const Text("CONTINUER"),
          )
        ],
      ),
    );
  }

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