import 'package:telephony/telephony.dart';
import 'package:flutter/material.dart';
import '../models/player.dart';

class SmsService {
  static final Telephony _telephony = Telephony.instance;

  static String? _cleanPhoneNumber(String raw) {
    if (raw.isEmpty) return null;
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('06') || clean.startsWith('07')) {
      clean = '+33${clean.substring(1)}';
    }
    if (clean.length < 4) return null;
    return clean;
  }

  // On prend 'allPlayers' en argument pour scanner les alliés
  static Future<bool> sendRoleToPlayer(Player player, List<Player> allPlayers) async {
    String? phone = _cleanPhoneNumber(player.phoneNumber ?? "");

    if (phone == null) {
      debugPrint("❌ SMS Ignoré : Pas de numéro valide pour ${player.name}");
      return false;
    }

    // --- CONSTRUCTION DU MESSAGE ---
    String message = "🐺 [LOUP-GAROU] 🐺\n\nBonjour ${player.name},\nTon rôle est : ${player.role?.toUpperCase()}.\nTon équipe : ${player.team.toUpperCase()}";

    // 1. INFO POUR LES LOUPS (Modification ici)
    if (player.team == 'loups') {
      // On cherche les autres loups vivants (sauf moi)
      List<String> allies = allPlayers
          .where((p) => p.team == 'loups' && p.name != player.name && p.isAlive)
          .map((p) => p.name) // ON NE MET QUE LE NOM ICI
          .toList();

      if (allies.isNotEmpty) {
        message += "\n\n🌑 LA MEUTE :\n${allies.join("\n")}";
      } else {
        message += "\n\n🌑 Tu es le seul loup pour l'instant.";
      }
    }

    // 2. INFO POUR DRESSEUR / POKÉMON
    String myRole = player.role?.toLowerCase() ?? "";

    if (myRole == 'dresseur') {
      var pokemon = allPlayers.where((p) => p.role?.toLowerCase() == 'pokemon' || p.role?.toLowerCase() == 'pokémon').toList();
      if (pokemon.isNotEmpty) {
        message += "\n\n⚡ TON POKÉMON :\n${pokemon.first.name}";
      }
    }
    else if (myRole == 'pokemon' || myRole == 'pokémon') {
      var dresseur = allPlayers.where((p) => p.role?.toLowerCase() == 'dresseur').toList();
      if (dresseur.isNotEmpty) {
        message += "\n\n🧢 TON DRESSEUR :\n${dresseur.first.name}";
      }
    }

    message += "\n\nBonne chance !";
    // -------------------------------------------

    try {
      debugPrint("📤 Envoi SMS à ${player.name} ($phone)...");
      await _telephony.sendSms(
        to: phone,
        message: message,
        isMultipart: true,
      );
      return true;
    } catch (e) {
      debugPrint("❌ Erreur SMS vers ${player.name}: $e");
      return false;
    }
  }

  static Future<void> sendRolesToAll(BuildContext context, List<Player> players) async {
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) return;

    int count = 0;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Envoi des SMS de rôles... 📨"), duration: Duration(seconds: 2)),
      );
    }

    for (var p in players) {
      if (!p.isPlaying || !p.isAlive) continue;

      await Future.delayed(const Duration(milliseconds: 400));

      bool success = await sendRoleToPlayer(p, players);
      if (success) count++;
    }

    debugPrint("✅ Campagne SMS terminée. $count messages envoyés.");
  }
}