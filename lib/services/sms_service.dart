import 'package:telephony/telephony.dart';
import 'package:flutter/material.dart';
import '../models/player.dart';

class SmsService {
  static final Telephony _telephony = Telephony.instance;

  // Nettoyage du numéro (ex: "06 12 34 56 78" -> "+33612345678")
  static String? _cleanPhoneNumber(String raw) {
    if (raw.isEmpty) return null;

    // 1. Enlever tout ce qui n'est pas chiffre ou '+'
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');

    // 2. Gestion basique du format français (Optionnel)
    if (clean.startsWith('06') || clean.startsWith('07')) {
      clean = '+33${clean.substring(1)}';
    }

    // 3. Vérification longueur minimale (ex: +33 + 9 chiffres = 12 chars)
    if (clean.length < 4) return null;

    return clean;
  }

  static Future<bool> sendRoleToPlayer(Player player) async {
    String? phone = _cleanPhoneNumber(player.phoneNumber ?? "");

    if (phone == null) {
      debugPrint("❌ SMS Ignoré : Pas de numéro valide pour ${player.name}");
      return false;
    }

    String message = "🐺 [LOUP-GAROU] 🐺\n\nBonjour ${player.name},\nTon rôle est : ${player.role?.toUpperCase()}.\nTon équipe : ${player.team.toUpperCase()}\n\nBonne chance !";

    try {
      debugPrint("📤 Envoi SMS à ${player.name} ($phone)...");

      // Envoi direct en arrière-plan
      await _telephony.sendSms(
        to: phone,
        message: message,
        isMultipart: true, // Pour les longs messages
      );

      // Note : Sur Android, l'envoi à soi-même ne sonne souvent pas (regardez dans "Envoyés")
      return true;

    } catch (e) {
      debugPrint("❌ Erreur SMS vers ${player.name}: $e");
      return false;
    }
  }

  static Future<void> sendRolesToAll(BuildContext context, List<Player> players) async {
    debugPrint("📱 Démarrage de la campagne SMS...");

    // Demande de permissions native via Telephony
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted != true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Permission SMS refusée !"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    int count = 0;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Envoi des rôles par SMS... 📨"), duration: Duration(seconds: 2)),
      );
    }

    for (var p in players) {
      if (!p.isPlaying || !p.isAlive) continue;

      // Petit délai pour ne pas être bloqué par l'opérateur comme spam
      await Future.delayed(const Duration(milliseconds: 500));

      bool success = await sendRoleToPlayer(p);
      if (success) count++;
    }

    debugPrint("✅ Campagne SMS terminée. $count messages traités.");
  }
}