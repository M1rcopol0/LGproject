import 'dart:io'; // Pour File
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart'; // Pour le dossier temporaire
import 'package:share_plus/share_plus.dart'; // Pour envoyer le fichier
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart'; // Pour récupérer l'historique

import 'pick_ban_screen.dart';
import 'globals.dart';
import 'backup_service.dart';
import 'trophy_service.dart';
import 'models/player.dart';
import 'cloud_service.dart'; // AJOUT : Service Google Sheets

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _volume = 1.0;
  bool _autoCloudSync = false; // AJOUT : État du switch Cloud

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Modifié pour charger tout
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('app_volume') ?? 1.0;
      _autoCloudSync = prefs.getBool('auto_cloud_sync') ?? false; // AJOUT
    });
  }

  Future<void> _setVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_volume', value);
    setState(() {
      _volume = value;
      globalVolume = value; // Mise à jour globale
    });
  }

  Future<void> _setAutoCloud(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_cloud_sync', value);
    setState(() {
      _autoCloudSync = value;
    });
  }

  // ===========================================================================
  // 1. LOGIQUE D'EXPORTATION DES LOGS (Debug + Historique)
  // ===========================================================================
  Future<void> _generateAndSendLogs() async {
    try {
      // A. Création du contenu du log
      StringBuffer sb = StringBuffer();

      // --- HEADER ---
      sb.writeln("=== LOUP GAROU 3.0 - RAPPORT DE BUG ===");
      sb.writeln("Date: ${DateTime.now()}");
      sb.writeln("Version: $globalGameVersion");
      sb.writeln("Tour actuel: $globalTurnNumber");
      sb.writeln("Phase: ${isDayTime ? 'JOUR' : 'NUIT'}");
      sb.writeln("----------------------------------");

      // --- ÉTAT DES JOUEURS (SNAPSHOT) ---
      sb.writeln("--- ÉTAT DES JOUEURS ---");
      for (var p in globalPlayers) {
        sb.writeln("[${p.name}] Rôle: ${p.role ?? 'Aucun'} | Équipe: ${p.team}");
        sb.writeln("   Vie: ${p.isAlive} | Mort: ${!p.isAlive}");
        sb.writeln("   États: Sleep=${p.isEffectivelyAsleep}, Protected=${p.isVillageProtected}, Muted=${p.isMutedDay}");
        sb.writeln("   Votes: ${p.votes}");
      }
      sb.writeln("----------------------------------");

      // --- VARIABLES GLOBALES ---
      sb.writeln("--- VARIABLES GLOBALES ---");
      sb.writeln("FirstDead: $firstDeadPlayerName");
      sb.writeln("WolfVotedWolf: $wolfVotedWolf");
      sb.writeln("PantinClutch: $pantinClutchSave");
      sb.writeln("----------------------------------");

      // --- HISTORIQUE CONSOLE (TALKER) ---
      sb.writeln("\n=== HISTORIQUE DE LA CONSOLE ===");
      try {
        // On récupère l'historique des logs depuis le globalTalker
        final logs = globalTalker.history;
        for (var log in logs) {
          sb.writeln(log.generateTextMessage());
        }
      } catch (e) {
        sb.writeln("Erreur récupération historique Talker: $e");
      }
      sb.writeln("=== FIN DU RAPPORT ===");

      // B. Écriture dans un fichier temporaire
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/debug_logs_lg3.txt');
      await file.writeAsString(sb.toString());

      // C. Partage du fichier
      final xFile = XFile(file.path);
      // Le subject fonctionne surtout pour les mails
      await Share.shareXFiles([xFile], text: 'Rapport Bug Loup Garou 3.0', subject: 'Logs Debug LG3');

    } catch (e) {
      debugPrint("Erreur lors de l'envoi des logs : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur export logs : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ===========================================================================
  // 2. LOGIQUE DE RÉINITIALISATION GLOBALE (HARD RESET)
  // ===========================================================================
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Table rase ?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Cela supprimera TOUS les joueurs, leurs succès, les stats globales et remettra les réglages par défaut.\n\n(Vos préférences audio seront conservées).",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ANNULER", style: TextStyle(color: Colors.white54))
          ),
          TextButton(
            onPressed: () async {
              // --- CORRECTION : Nettoyage complet (Annuaire + Stats + Succès) ---
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('saved_players_list'); // Supprime l'annuaire

              await TrophyService.resetAllStats(); // Supprime les succès et stats (Appel TrophyService)

              // On nettoie aussi les logs visuels pour repartir propre
              globalTalker.cleanHistory();

              // Reset de la liste en mémoire
              setState(() {
                globalPlayers.clear();
              });

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Base de données et statistiques entièrement effacées."),
                      backgroundColor: Colors.redAccent
                  ),
                );
              }
            },
            child: const Text("TOUT EFFACER", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. LOGIQUE IMPORTATION
  // ===========================================================================
  void _confirmImport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Importer une sauvegarde", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Ceci fusionnera les joueurs et remplacera les trophées/stats par ceux du fichier.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              Navigator.pop(ctx);
              BackupService.importData(context).then((_) {
                setState(() {});
              });
            },
            child: const Text("CHOISIR FICHIER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. LOGIQUE SUPPRESSION INDIVIDUELLE
  // ===========================================================================
  void _showDeletePlayerDialog() async {
    if (globalPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucun joueur dans la liste actuelle."))
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Supprimer un joueur", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: globalPlayers.length,
            itemBuilder: (context, index) {
              final player = globalPlayers[index];
              return ListTile(
                title: Text(player.name, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onTap: () async {
                  await TrophyService.deletePlayerStats(player.name);
                  setState(() {
                    globalPlayers.removeAt(index);
                  });
                  final prefs = await SharedPreferences.getInstance();
                  List<String> names = globalPlayers.map((p) => p.name).toList();
                  await prefs.setStringList('saved_players_list', names);

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${player.name} retiré et stats réinitialisées."))
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("FERMER", style: TextStyle(color: Colors.white54))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("Paramètres"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- AUDIO ---
          ListTile(
            title: const Text("Musique de fond", style: TextStyle(color: Colors.white)),
            trailing: Switch(
              activeColor: Colors.orangeAccent,
              value: globalMusicEnabled,
              onChanged: (v) {
                setState(() => globalMusicEnabled = v);
                saveAudioSettings();
              },
            ),
          ),
          ListTile(
            title: const Text("Effets sonores (SFX)", style: TextStyle(color: Colors.white)),
            trailing: Switch(
              activeColor: Colors.orangeAccent,
              value: globalSfxEnabled,
              onChanged: (v) {
                setState(() => globalSfxEnabled = v);
                saveAudioSettings();
              },
            ),
          ),

          const Divider(color: Colors.white24),

          // --- TIMER ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              "Durée du Timer : ${globalTimerMinutes.toInt()} min",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Slider(
            value: globalTimerMinutes,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            activeColor: Colors.orangeAccent,
            onChanged: (v) => setState(() => globalTimerMinutes = v),
          ),

          const Divider(color: Colors.white24),

          // --- PICK & BAN ---
          ListTile(
            title: const Text("Choisir les rôles (Pick & Ban)", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.edit, color: Colors.orangeAccent),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const PickBanScreen())
            ),
          ),
          ListTile(
            title: const Text("Version du jeu", style: TextStyle(color: Colors.white)),
            subtitle: Text(globalGameVersion, style: const TextStyle(color: Colors.white38)),
            trailing: const Icon(Icons.info_outline, color: Colors.white24),
          ),

          const Divider(color: Colors.white24, height: 40),

          // --- AJOUT : SECTION CLOUD GOOGLE SHEETS ---
          const Text("CLOUD (GOOGLE SHEETS)", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

          SwitchListTile(
            title: const Text("Synchro Auto", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Mise à jour des stats après chaque partie", style: TextStyle(color: Colors.white38, fontSize: 12)),
            value: _autoCloudSync,
            activeColor: Colors.green,
            onChanged: (val) => _setAutoCloud(val),
          ),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.2),
              foregroundColor: Colors.greenAccent,
              side: const BorderSide(color: Colors.greenAccent),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => CloudService.uploadData(context),
            icon: const Icon(Icons.cloud_upload),
            label: const Text("FORCER LA SYNCHRO"),
          ),

          const SizedBox(height: 25),

          // --- GESTION MEMOIRE LOCALE ---
          const Text("GESTION LOCALE", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 15),

          // --- BOUTONS EXPORT / IMPORT ---
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    foregroundColor: Colors.blueAccent,
                    side: const BorderSide(color: Colors.blueAccent),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => BackupService.exportData(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("EXPORTER"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                    foregroundColor: Colors.purpleAccent,
                    side: const BorderSide(color: Colors.purpleAccent),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _confirmImport(context),
                  icon: const Icon(Icons.file_download),
                  label: const Text("IMPORTER"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- BOUTONS SUPPRESSION ---
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.withOpacity(0.1),
              foregroundColor: Colors.orangeAccent,
              side: const BorderSide(color: Colors.orangeAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showDeletePlayerDialog,
            icon: const Icon(Icons.person_remove),
            label: const Text("SUPPRIMER UN JOUEUR"),
          ),

          const SizedBox(height: 12),

          // --- BOUTON DE RESET TOTAL ---
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showResetDialog,
            icon: const Icon(Icons.delete_forever),
            label: const Text("RÉINITIALISER TOUT"),
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),

          // --- BOUTON ENVOYER LOGS (DEBUG) ---
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.withOpacity(0.2),
              foregroundColor: Colors.tealAccent,
              side: const BorderSide(color: Colors.tealAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _generateAndSendLogs,
            icon: const Icon(Icons.bug_report),
            label: const Text("ENVOYER LOGS (DEBUG)"),
          ),

          const SizedBox(height: 10),

          // --- BOUTON OUVRIR CONSOLE (LIVE) ---
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.withOpacity(0.2),
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => TalkerScreen(talker: globalTalker)),
            ),
            icon: const Icon(Icons.monitor_heart),
            label: const Text("OUVRIR CONSOLE LIVE"),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}