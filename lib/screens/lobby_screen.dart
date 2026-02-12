import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/player.dart';
import '../logic.dart';
import '../globals.dart';
import '../game_save_service.dart';
import '../player_storage.dart';
import '../roulette_screen.dart';
import '../settings_screen.dart';
import '../wiki_page.dart';
import '../achievements_page.dart';
import '../widgets/game_info_header.dart';
import '../widgets/player_list_card.dart';
import '../widgets/game_action_buttons.dart';
import 'village_screen.dart';
// IMPORT DU SERVICE SMS
import '../services/sms_service.dart';

class LobbyScreen extends StatefulWidget {
  final List<Player> players;
  const LobbyScreen({super.key, required this.players});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {

  @override
  void initState() {
    super.initState();
    // Redirection automatique si une partie est déjà en cours (Load Game)
    if (globalRolesDistributed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VillageScreen(players: widget.players.where((p) => p.isPlaying).toList())),
        );
      });
    }
  }

  void _toggleSelection(Player p) {
    setState(() => p.isPlaying = !p.isPlaying);
  }

  void _startGame() async {
    List<Player> activePlayers = widget.players.where((p) => p.isPlaying).toList();
    if (activePlayers.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Il faut au moins 3 joueurs !"), backgroundColor: Colors.red)
      );
      return;
    }

    // --- CORRECTION IMPORTANTE : RAFRAÎCHISSEMENT DES NUMÉROS ---
    // On s'assure que les joueurs sélectionnés ont bien le dernier numéro connu dans l'annuaire.
    // Cela règle le problème où le Lobby garde une vieille version du joueur en mémoire.
    for (var p in activePlayers) {
      String? freshPhone = await PlayerDirectory.getPhoneNumber(p.name);
      // On met à jour l'objet joueur courant avec le numéro frais
      p.phoneNumber = freshPhone;
    }
    // -----------------------------------------------------------

    // 1. Animation de la Roulette
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RouletteScreen()));

    // 2. Distribution des rôles
    setState(() {
      GameLogic.assignRoles(activePlayers);
      globalRolesDistributed = true;
      globalTurnNumber = 1;
      isDayTime = true;
      nightOnePassed = false;
    });

    // 3. ENVOI AUTOMATIQUE DES SMS
    // On lance l'envoi. Grâce à la boucle ci-dessus, les numéros sont à jour.
    if (mounted) {
      SmsService.sendRolesToAll(context, activePlayers);
    }

    // 4. Sauvegarde
    await GameSaveService.saveGame();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => VillageScreen(players: activePlayers)),
    );
  }

  // --- DIALOGUES ---
  void _addPlayerDialog() {
    String name = "";
    String phone = "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Nouveau Joueur", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: "Nom"), style: const TextStyle(color: Colors.white), onChanged: (v) => name = v),
            TextField(decoration: const InputDecoration(labelText: "Téléphone"), style: const TextStyle(color: Colors.white), keyboardType: TextInputType.phone, onChanged: (v) => phone = v),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (name.isNotEmpty) {
                await PlayerDirectory.registerPlayer(name, phoneNumber: phone.isEmpty ? null : phone);
                setState(() {
                  widget.players.add(Player(name: name, isPlaying: true, phoneNumber: phone.isEmpty ? null : phone));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Ajouter"),
          )
        ],
      ),
    );
  }

  void _editPlayerDialog(Player p) {
    TextEditingController nameCtrl = TextEditingController(text: p.name);
    TextEditingController phoneCtrl = TextEditingController(text: p.phoneNumber ?? "");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Éditer Joueur", style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nom")),
          TextField(controller: phoneCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Téléphone"), keyboardType: TextInputType.phone),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isNotEmpty) {
              await PlayerDirectory.updatePlayerProfile(p.name, nameCtrl.text, phoneCtrl.text.isEmpty ? null : phoneCtrl.text);
              setState(() {
                p.name = Player.formatName(nameCtrl.text);
                p.phoneNumber = phoneCtrl.text.isEmpty ? null : phoneCtrl.text;
              });
              Navigator.pop(ctx);
            }
          }, child: const Text("Sauvegarder"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Player> displayList = List.from(widget.players);
    displayList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("PRÉPARATION", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D1E33),
        actions: [
          IconButton(icon: const Icon(FontAwesomeIcons.trophy, color: Colors.amber, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsPage()))),
          IconButton(icon: const Icon(Icons.menu_book), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WikiPage()))),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Column(
        children: [
          GameInfoHeader(
            isGameStarted: false,
            playerCount: widget.players.where((p) => p.isPlaying).length,
            timeString: "00:00",
            isTimerRunning: false,
            onToggleTimer: () {},
            onResetTimer: () {},
          ),
          Expanded(
            child: ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final p = displayList[index];
                return GestureDetector(
                  onLongPress: () => _editPlayerDialog(p),
                  child: PlayerListCard(
                    player: p,
                    isGameStarted: false,
                    onTap: () => _toggleSelection(p),
                    onCheckChanged: (v) => _toggleSelection(p),
                  ),
                );
              },
            ),
          ),
          GameActionButtons(
            isGameStarted: false,
            onStartGame: _startGame,
            onAddPlayer: _addPlayerDialog,
          ),
        ],
      ),
    );
  }
}