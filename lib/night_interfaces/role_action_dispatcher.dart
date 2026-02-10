import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

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
import 'chuchoteur_interface.dart';
import 'pantin_interface.dart';
import 'sorciere_interface.dart';
import 'cupidon_interface.dart';
import 'voyante_interface.dart';
import 'saltimbanque_interface.dart';
import 'kung_fu_panda_interface.dart';

class RoleActionDispatcher extends StatefulWidget {
  final NightAction action;
  final Player actor;
  final List<Player> allPlayers;
  final Map<Player, String> pendingDeaths;
  final Function(String? result) onExorcisme;
  final Function(bool used) onSomnifere;
  final VoidCallback onNext;
  final Function(String title, String msg) showPopUp;
  final Function(Player target, String reason)? onDirectKill; // Callback Sorcière

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
    this.onDirectKill,
  });

  @override
  State<RoleActionDispatcher> createState() => _RoleActionDispatcherState();
}

class _RoleActionDispatcherState extends State<RoleActionDispatcher> {
  bool _pokemonVengeanceDone = false;

  @override
  Widget build(BuildContext context) {
    bool isImmuneToSleep = (widget.action.role == "Archiviste" && widget.actor.isAwayAsMJ);
    if (widget.actor.isEffectivelyAsleep && !isImmuneToSleep && widget.action.role != "Zookeeper") {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bedtime, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text("VOUS DORMEZ", style: TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: widget.onNext, child: const Text("CONTINUER"))
          ],
        ),
      );
    }

    switch (widget.action.role) {
      case "Sorcière":
        return SorciereInterface(
          player: widget.actor,
          allPlayers: widget.allPlayers,
          onActionComplete: widget.onNext,
          onKill: (target) {
            if (widget.onDirectKill != null) {
              widget.onDirectKill!(target, "Potion de Mort");
            }
          },
        );

      case "Cupidon": return CupidonInterface(player: widget.actor, allPlayers: widget.allPlayers, onActionComplete: widget.onNext);
      case "Voyante": return VoyanteInterface(player: widget.actor, allPlayers: widget.allPlayers, onActionComplete: widget.onNext);
      case "Saltimbanque": return SaltimbanqueInterface(player: widget.actor, allPlayers: widget.allPlayers, onActionComplete: widget.onNext);
      case "Kung-Fu Panda": return KungFuPandaInterface(player: widget.actor, allPlayers: widget.allPlayers, onActionComplete: widget.onNext);

      case "Loups-garous évolués":
        return LGEvolueInterface(
          players: widget.allPlayers,
          onVictimChosen: (p) {
            if (p.name != "Personne") {
              nightWolvesTarget = p;
              widget.pendingDeaths[p] = "Morsure de Loup";
            }
            widget.onNext();
          },
        );

      case "Pokémon":
      case "Pokemon":
        if (!_pokemonVengeanceDone) {
          return PokemonInterface(
            actor: widget.actor,
            players: widget.allPlayers,
            onTargetSelected: (target) {
              widget.actor.pokemonRevengeTarget = target;
              Player? dresseur;
              try { dresseur = widget.allPlayers.firstWhere((p) => p.role?.toLowerCase() == "dresseur"); } catch (e) {}
              if (dresseur != null && !dresseur.isAlive) setState(() => _pokemonVengeanceDone = true);
              else widget.onNext();
            },
          );
        }
        return DresseurInterface(actor: widget.actor, allPlayers: widget.allPlayers, onComplete: (target) { if(target!=null) widget.pendingDeaths[target] = "Attaque du Pokémon (Rage)"; widget.onNext(); });

      case "Voyageur": return VoyageurInterface(actor: widget.actor, allPlayers: widget.allPlayers, onDepart: () { widget.actor.isInTravel = true; widget.onNext(); }, onReturnWithoutShooting: () { widget.actor.isInTravel = false; widget.actor.canTravelAgain = false; widget.actor.hasReturnedThisTurn = true; widget.onNext(); }, onStayTraveling: widget.onNext, onStayAtVillage: widget.onNext, onShoot: (t) { widget.actor.isInTravel = false; widget.actor.canTravelAgain = false; widget.actor.hasReturnedThisTurn = true; widget.actor.travelerBullets--; widget.pendingDeaths[t] = "Tir du Voyageur"; widget.onNext(); });
      case "Zookeeper": return ZookeeperInterface(players: widget.allPlayers, onTargetSelected: (t) => widget.onNext());
      case "Phyl": return PhylInterface(actor: widget.actor, players: widget.allPlayers, onComplete: widget.onNext);
      case "Grand-mère": return GrandMereInterface(actor: widget.actor, onBakeComplete: (s) => widget.onNext(), onSkip: widget.onNext, circleBtnBuilder: (t, c, f) => InkWell(onTap: f, child: Container(width: 80, height: 80, color: c, child: Center(child: Text(t)))));
      case "Dresseur": if (!widget.actor.isAlive) { WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNext()); return const SizedBox(); } return DresseurInterface(actor: widget.actor, allPlayers: widget.allPlayers, onComplete: (t) => widget.onNext());
      case "Pantin": return PantinInterface(players: widget.allPlayers, onTargetsSelected: (l) { for(var p in l) p.pantinCurseTimer=2; widget.onNext(); });
      case "Somnifère": return SomnifereInterface(actor: widget.actor, onActionComplete: widget.onSomnifere);
      case "Devin": return DevinInterface(devin: widget.actor, allPlayers: widget.allPlayers, onNext: (s) => widget.onNext());
      case "Houston": return HoustonInterface(actor: widget.actor, players: widget.allPlayers, onComplete: (l) { widget.actor.houstonTargets = l; widget.onNext(); });
      case "Enculateur du bled": return BledInterface(actor: widget.actor, players: widget.allPlayers, onComplete: (l) { for(var p in l) { p.isMutedDay = true; p.isImmunizedFromVote = true; } widget.onNext(); });
      case "Archiviste": return ArchivisteInterface(players: widget.allPlayers, actor: widget.actor, onComplete: (m) { if(m!=null) widget.showPopUp("Info", m); else widget.onNext(); });
      case "Maison": return MaisonInterface(actor: widget.actor, players: widget.allPlayers, onComplete: (l) { for(var p in l) p.isInHouse = true; widget.onNext(); });
      case "Chuchoteur": return ChuchoteurInterface(players: widget.allPlayers, onTargetsSelected: (l) { for(var p in l) p.isMutedDay = true; widget.onNext(); });
      case "Maître du temps": return TimeMasterInterface(player: widget.actor, allPlayers: widget.allPlayers, onAction: (t, p) { if(t=="REWIND" && p is Player) p.isSavedByTimeMaster = true; widget.onNext(); });
      case "Tardos": return TardosInterface(actor: widget.actor, players: widget.allPlayers, onNext: widget.onNext);
      case "Dingo": return DingoInterface(actor: widget.actor, players: widget.allPlayers, onHit: widget.onNext, onMiss: widget.onNext, onKillTargetSelected: (t) { widget.pendingDeaths[t] = "Tir du Dingo"; widget.onNext(); });
      case "Ron-Aldo": return RonAldoInterface(actor: widget.actor, allPlayers: widget.allPlayers, onNext: widget.onNext);
      case "Loup-garou chaman": return ChamanInterface(players: widget.allPlayers, onTargetSelected: (p) => widget.onNext());

    // --- CORRECTION MAJEURE ICI ---
    // On accepte soit "SUCCESS" soit "EXORCISM_SUCCESS" pour être sûr
      case "Exorciste":
        return ExorcistInterface(
            player: widget.actor,
            allPlayers: widget.allPlayers,
            onAction: (t, d) {
              if(t == "SUCCESS" || t == "EXORCISM_SUCCESS") {
                widget.onExorcisme("SUCCESS");
              } else {
                widget.onExorcisme(null);
              }
            }
        );

      default: return Center(child: ElevatedButton(onPressed: widget.onNext, child: const Text("PASSER L'ACTION")));
    }
  }
}