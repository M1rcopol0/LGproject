/**
 * LOUP GAROU 3.0 - CLOUD SYNC SCRIPT V3 (DATABASE UNIQUE)
 *
 * Ce script Google Apps Script gère la synchronisation cloud
 * pour l'application Loup Garou 3.0 (Flutter).
 *
 * NOUVEAUTÉS V3:
 * - Cellule database unique (B1) = source de vérité
 * - Backups automatiques dans le même onglet (lignes 8, 10, 12...)
 * - Onglets visuels reconstruits automatiquement depuis B1
 * - Checksum MD5 pour validation d'intégrité
 *
 * INSTALLATION:
 * 1. Créer un nouveau Google Sheets (ou utiliser l'existant)
 * 2. Extensions > Apps Script
 * 3. Copier-coller ce code
 * 4. Déployer > Nouveau déploiement > Web app
 *    - Execute as: Moi
 *    - Who has access: Tout le monde
 * 5. Copier l'URL du déploiement dans lib/services/cloud_service.dart
 *
 * STRUCTURE:
 * - Onglet "Database" : Cellule B1 avec JSON complet (source unique)
 * - Onglet "Stats Globales" : Victoires par faction (reconstruit auto)
 * - Onglet "Annuaire" : Parties, victoires, téléphone (reconstruit auto)
 * - Onglet "Succès" : Grille visuelle avec couleurs (reconstruit auto)
 * - Onglet "Stats Détaillées" : Données brutes JSON (reconstruit auto)
 */

// ============================================================================
// CONFIGURATION
// ============================================================================

const SHEET_DATABASE = "Database";
const SHEET_GLOBAL = "Stats Globales";
const SHEET_DIRECTORY = "Annuaire";
const SHEET_ACHIEVEMENTS = "Succès";
const SHEET_DETAILS = "Stats Détaillées";

const DATABASE_CELL = "B1";
const VERSION_CELL = "B2";
const TIMESTAMP_CELL = "B3";
const CHECKSUM_CELL = "B4";

const MAX_BACKUPS = 10;
const BACKUP_START_ROW = 7; // Ligne 7 commence les backups

// Couleurs par rareté
const RARITY_COLORS = {
  1: "#42A5F5", // Bleu (Facile)
  2: "#66BB6A", // Vert (Intermédiaire)
  3: "#AB47BC", // Violet (Difficile)
  4: "#FFA726", // Orange/Or (Légendaire)
};

// ============================================================================
// GET - Récupération de la Database
// ============================================================================

function doGet(e) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let dbSheet = ss.getSheetByName(SHEET_DATABASE);

    // Si l'onglet Database n'existe pas, le créer et migrer depuis V2
    if (!dbSheet) {
      Logger.log("⚠️ Onglet Database absent - Migration depuis V2");
      dbSheet = createDatabaseSheet(ss);
      migrateFromV2(ss, dbSheet);
    }

    // Lire la cellule database
    const databaseJSON = dbSheet.getRange(DATABASE_CELL).getValue();

    if (!databaseJSON || databaseJSON === "") {
      Logger.log("⚠️ Cellule B1 vide - Retour database vide");
      return ContentService.createTextOutput(JSON.stringify({
        version: "3.0",
        timestamp: new Date().toISOString(),
        global_stats: {},
        individual_stats: {},
        player_directory: {},
        metadata: {}
      })).setMimeType(ContentService.MimeType.JSON);
    }

    // Parser et retourner
    const database = JSON.parse(databaseJSON);

    // Vérifier checksum (optionnel - log warning si différent)
    const storedChecksum = dbSheet.getRange(CHECKSUM_CELL).getValue();
    const calculatedChecksum = calculateChecksum(databaseJSON);

    if (storedChecksum && storedChecksum !== calculatedChecksum) {
      Logger.log("⚠️ Checksum différent - Possible corruption");
    }

    Logger.log(`✅ GET réussi - Taille: ${databaseJSON.length} caractères`);
    return ContentService.createTextOutput(databaseJSON)
      .setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    Logger.log("❌ Erreur GET: " + error.toString());
    return ContentService.createTextOutput(JSON.stringify({
      error: error.toString(),
      version: "3.0",
      timestamp: new Date().toISOString(),
      global_stats: {},
      individual_stats: {},
      player_directory: {},
      metadata: {}
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

// ============================================================================
// POST - Sauvegarde et Actions
// ============================================================================

function doPost(e) {
  try {
    const payload = JSON.parse(e.postData.contents);
    const action = payload.action || "update_database";

    Logger.log(`📥 POST reçu - Action: ${action}`);

    const ss = SpreadsheetApp.getActiveSpreadsheet();

    // Router selon l'action
    if (action === "update_database") {
      return handleUpdateDatabase(ss, payload.database);
    } else if (action === "create_backup") {
      return handleCreateBackup(ss, payload.database, payload.label);
    } else if (action === "get_backup") {
      return handleGetBackup(ss, payload.backup_index);
    } else if (action === "list_backups") {
      return handleListBackups(ss);
    }

    throw new Error("Action inconnue: " + action);

  } catch (error) {
    Logger.log("❌ Erreur POST: " + error.toString());
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

// ============================================================================
// HANDLER: Mise à jour de la Database
// ============================================================================

function handleUpdateDatabase(ss, database) {
  if (!database) {
    throw new Error("Payload 'database' manquant");
  }

  // 1. Créer ou récupérer l'onglet Database
  let dbSheet = ss.getSheetByName(SHEET_DATABASE);
  if (!dbSheet) {
    dbSheet = createDatabaseSheet(ss);
  }

  // 2. Convertir en JSON string
  const databaseJSON = JSON.stringify(database);
  Logger.log(`📝 Écriture database - Taille: ${databaseJSON.length} caractères`);

  // Vérifier limite Google Sheets (50,000 caractères)
  if (databaseJSON.length > 50000) {
    Logger.log("⚠️ ATTENTION: Taille database > 50KB - Risque de dépassement");
  }

  // 3. Écrire dans les cellules
  dbSheet.getRange(DATABASE_CELL).setValue(databaseJSON);
  dbSheet.getRange(VERSION_CELL).setValue(database.version || "3.0");
  dbSheet.getRange(TIMESTAMP_CELL).setValue(database.timestamp || new Date().toISOString());

  // Calculer et stocker checksum
  const checksum = calculateChecksum(databaseJSON);
  dbSheet.getRange(CHECKSUM_CELL).setValue(checksum);

  Logger.log(`✅ Database écrite - Checksum: ${checksum.substring(0, 8)}...`);

  // 4. Reconstruire les onglets visuels
  try {
    updateVisualSheets(ss, database);
    Logger.log("✅ Onglets visuels reconstruits");
  } catch (error) {
    Logger.log("⚠️ Erreur reconstruction onglets: " + error.toString());
    // Continuer même si erreur (database sauvegardée)
  }

  return ContentService.createTextOutput(JSON.stringify({
    status: "success",
    timestamp: new Date().toISOString(),
    size_bytes: databaseJSON.length,
    checksum: checksum
  })).setMimeType(ContentService.MimeType.JSON);
}

// ============================================================================
// HANDLER: Créer une Backup
// ============================================================================

function handleCreateBackup(ss, database, label) {
  if (!database) {
    throw new Error("Payload 'database' manquant");
  }

  const dbSheet = ss.getSheetByName(SHEET_DATABASE);
  if (!dbSheet) {
    throw new Error("Onglet Database inexistant");
  }

  // Compter les backups existantes
  let backupCount = 0;
  let nextRow = BACKUP_START_ROW;

  for (let row = BACKUP_START_ROW; row <= dbSheet.getLastRow(); row += 2) {
    const cellValue = dbSheet.getRange(row, 1).getValue();
    if (cellValue && cellValue.toString().startsWith("BACKUP_")) {
      backupCount++;
      nextRow = row + 2;
    }
  }

  // Si MAX_BACKUPS atteint, supprimer la plus vieille (lignes 7-8)
  if (backupCount >= MAX_BACKUPS) {
    Logger.log("⚠️ MAX_BACKUPS atteint - Suppression de la plus vieille");
    dbSheet.deleteRows(BACKUP_START_ROW, 2);
    nextRow -= 2; // Ajuster la position
    backupCount--;
  }

  // Écrire la nouvelle backup
  const backupIndex = backupCount + 1;
  const timestamp = new Date().toLocaleString('fr-FR');
  const backupLabel = label ? `${label} - ${timestamp}` : `Backup ${backupIndex} - ${timestamp}`;

  dbSheet.getRange(nextRow, 1).setValue(`BACKUP_${backupIndex}`);
  dbSheet.getRange(nextRow, 2).setValue(backupLabel);
  dbSheet.getRange(nextRow + 1, 1).setValue(`DATA_${backupIndex}`);
  dbSheet.getRange(nextRow + 1, 2).setValue(JSON.stringify(database));

  // Style
  dbSheet.getRange(nextRow, 1, 1, 2).setBackground("#FFF3E0").setFontWeight("bold");
  dbSheet.getRange(nextRow + 1, 2).setWrap(true).setFontFamily("Courier New").setFontSize(8);

  Logger.log(`✅ Backup ${backupIndex} créée: ${backupLabel}`);

  return ContentService.createTextOutput(JSON.stringify({
    status: "success",
    backup_index: backupIndex,
    label: backupLabel
  })).setMimeType(ContentService.MimeType.JSON);
}

// ============================================================================
// HANDLER: Récupérer une Backup
// ============================================================================

function handleGetBackup(ss, backupIndex) {
  if (!backupIndex || backupIndex < 1) {
    throw new Error("backup_index invalide");
  }

  const dbSheet = ss.getSheetByName(SHEET_DATABASE);
  if (!dbSheet) {
    throw new Error("Onglet Database inexistant");
  }

  // Trouver la backup par son index
  for (let row = BACKUP_START_ROW; row <= dbSheet.getLastRow(); row += 2) {
    const labelCell = dbSheet.getRange(row, 1).getValue();
    if (labelCell && labelCell.toString() === `BACKUP_${backupIndex}`) {
      const dataCell = dbSheet.getRange(row + 1, 2).getValue();
      if (!dataCell) {
        throw new Error(`Backup ${backupIndex} - Données manquantes`);
      }

      const backupData = JSON.parse(dataCell);
      Logger.log(`✅ Backup ${backupIndex} récupérée`);

      return ContentService.createTextOutput(JSON.stringify(backupData))
        .setMimeType(ContentService.MimeType.JSON);
    }
  }

  throw new Error(`Backup ${backupIndex} introuvable`);
}

// ============================================================================
// HANDLER: Lister les Backups
// ============================================================================

function handleListBackups(ss) {
  const dbSheet = ss.getSheetByName(SHEET_DATABASE);
  if (!dbSheet) {
    return ContentService.createTextOutput(JSON.stringify({ backups: [] }))
      .setMimeType(ContentService.MimeType.JSON);
  }

  const backups = [];

  for (let row = BACKUP_START_ROW; row <= dbSheet.getLastRow(); row += 2) {
    const labelCellKey = dbSheet.getRange(row, 1).getValue();
    const labelCellValue = dbSheet.getRange(row, 2).getValue();

    if (labelCellKey && labelCellKey.toString().startsWith("BACKUP_")) {
      const index = parseInt(labelCellKey.toString().split("_")[1]);
      backups.push({
        index: index,
        label: labelCellValue || `Backup ${index}`
      });
    }
  }

  Logger.log(`✅ ${backups.length} backups listées`);

  return ContentService.createTextOutput(JSON.stringify({ backups: backups }))
    .setMimeType(ContentService.MimeType.JSON);
}

// ============================================================================
// CRÉATION: Onglet Database
// ============================================================================

function createDatabaseSheet(ss) {
  Logger.log("📝 Création onglet Database");

  const sheet = ss.insertSheet(SHEET_DATABASE, 0); // Position 0 (tout à gauche)

  // En-têtes
  sheet.getRange("A1").setValue("DATABASE");
  sheet.getRange("A2").setValue("VERSION");
  sheet.getRange("A3").setValue("TIMESTAMP");
  sheet.getRange("A4").setValue("CHECKSUM");
  sheet.getRange("A5").setValue("");
  sheet.getRange("A6").setValue("=== BACKUPS ===");

  // Style
  sheet.getRange("A1:A4").setFontWeight("bold");
  sheet.getRange("A1:B4").setBackground("#E3F2FD");
  sheet.getRange("A6:B6").setBackground("#FFEB3B").setFontWeight("bold").setHorizontalAlignment("center");

  // Largeur colonnes
  sheet.setColumnWidth(1, 150);
  sheet.setColumnWidth(2, 850);

  // Valeurs par défaut
  sheet.getRange("B2").setValue("3.0");
  sheet.getRange("B3").setValue(new Date().toISOString());

  Logger.log("✅ Onglet Database créé");

  return sheet;
}

// ============================================================================
// MIGRATION: Depuis V2 vers V3
// ============================================================================

function migrateFromV2(ss, dbSheet) {
  Logger.log("🔄 Migration V2 → V3...");

  try {
    // Lire les onglets existants (V2)
    const globalStats = readGlobalStatsFromSheet(ss);
    const playerDirectory = readPlayerDirectoryFromSheet(ss);
    const individualStats = readIndividualStatsFromSheet(ss);

    // Construire la database
    const database = {
      version: "3.0",
      timestamp: new Date().toISOString(),
      global_stats: globalStats,
      individual_stats: individualStats,
      player_directory: playerDirectory,
      metadata: {
        migrated_from: "v2",
        migration_date: new Date().toISOString()
      }
    };

    // Écrire dans B1
    const databaseJSON = JSON.stringify(database);
    dbSheet.getRange(DATABASE_CELL).setValue(databaseJSON);
    dbSheet.getRange(VERSION_CELL).setValue("3.0");
    dbSheet.getRange(TIMESTAMP_CELL).setValue(database.timestamp);
    dbSheet.getRange(CHECKSUM_CELL).setValue(calculateChecksum(databaseJSON));

    Logger.log("✅ Migration V2 → V3 terminée");
  } catch (error) {
    Logger.log("⚠️ Erreur migration: " + error.toString());
    // Créer database vide si migration échoue
    const emptyDb = {
      version: "3.0",
      timestamp: new Date().toISOString(),
      global_stats: {},
      individual_stats: {},
      player_directory: {},
      metadata: {}
    };
    dbSheet.getRange(DATABASE_CELL).setValue(JSON.stringify(emptyDb));
  }
}

// ============================================================================
// LECTURE: Stats depuis onglets V2 (pour migration)
// ============================================================================

function readGlobalStatsFromSheet(ss) {
  const sheet = ss.getSheetByName(SHEET_GLOBAL);
  if (!sheet) return {};

  const data = sheet.getDataRange().getValues();
  const stats = {};

  for (let i = 1; i < data.length; i++) {
    if (data[i][0]) {
      stats[data[i][0]] = data[i][1] || 0;
    }
  }

  return stats;
}

function readPlayerDirectoryFromSheet(ss) {
  const sheet = ss.getSheetByName(SHEET_DIRECTORY);
  if (!sheet) return {};

  const data = sheet.getDataRange().getValues();
  const directory = {};

  for (let i = 1; i < data.length; i++) {
    const name = data[i][0];
    if (!name) continue;

    directory[name] = {
      phoneNumber: data[i][1] || null
    };
  }

  return directory;
}

function readIndividualStatsFromSheet(ss) {
  const sheet = ss.getSheetByName(SHEET_DETAILS);
  if (!sheet) return {};

  const data = sheet.getDataRange().getValues();
  const stats = {};

  for (let i = 1; i < data.length; i++) {
    const name = data[i][0];
    if (!name) continue;

    stats[name] = {
      totalWins: data[i][1] || 0,
      roles: parseJSON(data[i][2]) || {},
      roleWins: parseJSON(data[i][3]) || {},
      achievements: parseJSON(data[i][4]) || {},
      counters: parseJSON(data[i][5]) || {}
    };
  }

  return stats;
}

// ============================================================================
// MISE À JOUR: Onglets Visuels
// ============================================================================

function updateVisualSheets(ss, database) {
  // 1. Stats Globales
  if (database.global_stats) {
    writeGlobalStats(ss, database.global_stats);
  }

  // 2. Annuaire
  if (database.player_directory) {
    writePlayerDirectory(ss, database.player_directory);
  }

  // 3. Succès et Stats Détaillées
  if (database.individual_stats) {
    writeAchievementsGrid(ss, database.individual_stats);
    writeDetailedStats(ss, database.individual_stats);
  }
}

// ============================================================================
// ÉCRITURE - Stats Globales
// ============================================================================

function writeGlobalStats(ss, globalStats) {
  let sheet = ss.getSheetByName(SHEET_GLOBAL);

  if (!sheet) {
    sheet = ss.insertSheet(SHEET_GLOBAL);
    sheet.appendRow(["Faction", "Victoires"]);
    sheet.getRange("A1:B1").setFontWeight("bold").setBackground("#4CAF50").setFontColor("#FFFFFF");
    sheet.setFrozenRows(1);
  } else {
    sheet.clear();
    sheet.appendRow(["Faction", "Victoires"]);
    sheet.getRange("A1:B1").setFontWeight("bold").setBackground("#4CAF50").setFontColor("#FFFFFF");
  }

  const factions = ["VILLAGE", "LOUPS-GAROUS", "SOLO"];
  factions.forEach(faction => {
    sheet.appendRow([faction, globalStats[faction] || 0]);
  });

  sheet.autoResizeColumns(1, 2);
}

// ============================================================================
// ÉCRITURE - Annuaire des Joueurs
// ============================================================================

function writePlayerDirectory(ss, playerDirectory) {
  let sheet = ss.getSheetByName(SHEET_DIRECTORY);

  if (!sheet) {
    sheet = ss.insertSheet(SHEET_DIRECTORY);
    sheet.appendRow(["Joueur", "Téléphone"]);
    sheet.getRange("A1:B1").setFontWeight("bold").setBackground("#FF9800").setFontColor("#FFFFFF");
    sheet.setFrozenRows(1);
  } else {
    sheet.clear();
    sheet.appendRow(["Joueur", "Téléphone"]);
    sheet.getRange("A1:B1").setFontWeight("bold").setBackground("#FF9800").setFontColor("#FFFFFF");
  }

  // Trier les joueurs par ordre alphabétique
  const sortedPlayers = Object.keys(playerDirectory).sort((a, b) => {
    return a.localeCompare(b);
  });

  sortedPlayers.forEach(name => {
    const player = playerDirectory[name];
    sheet.appendRow([name, player.phoneNumber || ""]);
  });

  sheet.autoResizeColumns(1, 2);
}

// ============================================================================
// ÉCRITURE - Grille des Succès (VISUEL - NOUVELLE STRUCTURE)
// ============================================================================

function writeAchievementsGrid(ss, individualStats) {
  let sheet = ss.getSheetByName(SHEET_ACHIEVEMENTS);

  // Créer ou nettoyer la feuille
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_ACHIEVEMENTS, 2); // Position 2
  } else {
    sheet.clear();
  }

  // Trier les joueurs par ordre alphabétique
  const sortedPlayers = Object.keys(individualStats).sort((a, b) => {
    return a.localeCompare(b, 'fr', { sensitivity: 'base' });
  });

  // === EN-TÊTE ===
  const headerRow = ["Joueur", "Victoires", "Victoires par Rôle"];
  sheet.appendRow(headerRow);
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(3);

  // Style de l'en-tête
  const headerRange = sheet.getRange(1, 1, 1, 3);
  headerRange.setFontWeight("bold")
    .setBackground("#37474F")
    .setFontColor("#FFFFFF")
    .setWrap(true)
    .setVerticalAlignment("middle")
    .setHorizontalAlignment("center");

  // Largeur des colonnes fixes
  sheet.setColumnWidth(1, 150); // Joueur
  sheet.setColumnWidth(2, 80);  // Victoires
  sheet.setColumnWidth(3, 250); // Victoires par Rôle
  sheet.setRowHeight(1, 40);    // Hauteur de l'en-tête

  // === DONNÉES - CHAQUE JOUEUR ===
  let currentRow = 2;

  sortedPlayers.forEach((playerName) => {
    const player = individualStats[playerName];

    // Colonne A : Nom du joueur
    sheet.getRange(currentRow, 1).setValue(playerName)
      .setFontWeight("bold")
      .setVerticalAlignment("middle");

    // Colonne B : Victoires totales
    sheet.getRange(currentRow, 2).setValue(player.totalWins || 0)
      .setHorizontalAlignment("center")
      .setVerticalAlignment("middle");

    // Colonne C : Victoires par rôle (formaté)
    const roleWins = player.roleWins || {};
    const roleWinsFormatted = Object.entries(roleWins)
      .sort((a, b) => b[1] - a[1]) // Trier par nombre décroissant
      .map(([role, wins]) => `${role}: ${wins}`)
      .join('\n');

    sheet.getRange(currentRow, 3).setValue(roleWinsFormatted || "Aucun")
      .setWrap(true)
      .setVerticalAlignment("top")
      .setFontSize(9);

    // Colonnes D+ : Succès individuels (seulement ceux débloqués)
    if (player.rich_achievements && player.rich_achievements.length > 0) {
      // Trier les succès par rareté décroissante
      const sortedAchievements = player.rich_achievements.sort((a, b) => {
        return (b.rarity || 1) - (a.rarity || 1);
      });

      let currentCol = 4; // Commence à la colonne D

      sortedAchievements.forEach(ach => {
        // Formater la date
        let dateStr = "";
        if (ach.date) {
          try {
            // Parser la date (format: "DD/MM/YYYY à HH:MM")
            const dateParts = ach.date.split(' à ');
            if (dateParts.length >= 1) {
              dateStr = dateParts[0]; // Garder juste DD/MM/YYYY
              if (dateParts.length >= 2) {
                dateStr += `\n${dateParts[1]}`; // Ajouter HH:MM en dessous
              }
            }
          } catch (e) {
            dateStr = ach.date;
          }
        }

        // Contenu de la cellule : Icône + Titre + Description + Date
        const cellContent = `${ach.icon || '🏆'} ${ach.title || 'Succès'}\n\n${ach.description || ''}\n\n📅 ${dateStr}`;

        // Couleur selon rareté
        const color = RARITY_COLORS[ach.rarity || 1] || "#CCCCCC";

        // Écrire la cellule
        sheet.getRange(currentRow, currentCol)
          .setValue(cellContent)
          .setBackground(color)
          .setFontColor("#FFFFFF")
          .setFontWeight("bold")
          .setWrap(true)
          .setVerticalAlignment("top")
          .setHorizontalAlignment("left")
          .setFontSize(9);

        // Définir largeur de colonne (si pas déjà fait)
        if (sheet.getColumnWidth(currentCol) < 200) {
          sheet.setColumnWidth(currentCol, 200);
        }

        currentCol++;
      });
    }

    // Hauteur de ligne adaptative (minimum 80)
    const numAchievements = (player.rich_achievements || []).length;
    const rowHeight = Math.max(80, Math.min(150, 80 + numAchievements * 5));
    sheet.setRowHeight(currentRow, rowHeight);

    currentRow++;
  });

  // Légende en bas
  const noteRow = currentRow + 1;
  sheet.getRange(noteRow, 1, 1, 4).merge()
    .setValue("🎨 Légende des couleurs : 🔵 Facile • 🟢 Intermédiaire • 🟣 Difficile • 🟠 Légendaire")
    .setFontStyle("italic")
    .setFontColor("#757575")
    .setHorizontalAlignment("center")
    .setBackground("#F5F5F5");
}

// ============================================================================
// ÉCRITURE - Stats Détaillées (JSON)
// ============================================================================

function writeDetailedStats(ss, individualStats) {
  let sheet = ss.getSheetByName(SHEET_DETAILS);

  if (!sheet) {
    sheet = ss.insertSheet(SHEET_DETAILS);
    sheet.appendRow([
      "Joueur",
      "Victoires Totales",
      "Victoires par Faction (JSON)",
      "Victoires par Rôle (JSON)",
      "Succès (JSON)",
      "Compteurs (JSON)"
    ]);
    sheet.getRange("A1:F1").setFontWeight("bold").setBackground("#607D8B").setFontColor("#FFFFFF");
    sheet.setFrozenRows(1);
  } else {
    sheet.clear();
    sheet.appendRow([
      "Joueur",
      "Victoires Totales",
      "Victoires par Faction (JSON)",
      "Victoires par Rôle (JSON)",
      "Succès (JSON)",
      "Compteurs (JSON)"
    ]);
    sheet.getRange("A1:F1").setFontWeight("bold").setBackground("#607D8B").setFontColor("#FFFFFF");
  }

  // Trier par victoires
  const sortedPlayers = Object.keys(individualStats).sort((a, b) => {
    return (individualStats[b].totalWins || 0) - (individualStats[a].totalWins || 0);
  });

  sortedPlayers.forEach(name => {
    const player = individualStats[name];

    sheet.appendRow([
      name,
      player.totalWins || 0,
      JSON.stringify(player.roles || {}, null, 2),
      JSON.stringify(player.roleWins || {}, null, 2),
      JSON.stringify(player.achievements || {}, null, 2),
      JSON.stringify(player.counters || {}, null, 2)
    ]);
  });

  sheet.autoResizeColumns(1, 2);
  sheet.setColumnWidth(3, 200);
  sheet.setColumnWidth(4, 200);
  sheet.setColumnWidth(5, 200);
  sheet.setColumnWidth(6, 200);

  // Style JSON
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    sheet.getRange(2, 3, lastRow - 1, 4).setWrap(true).setVerticalAlignment("top").setFontFamily("Courier New");
  }
}

// ============================================================================
// UTILITAIRES
// ============================================================================

function parseJSON(str) {
  try {
    if (!str || str === "") return null;
    return JSON.parse(str);
  } catch (e) {
    return null;
  }
}

function calculateChecksum(jsonString) {
  // Calculer MD5 hash
  const digest = Utilities.computeDigest(
    Utilities.DigestAlgorithm.MD5,
    jsonString,
    Utilities.Charset.UTF_8
  );

  // Convertir en hex
  return digest.map(byte => {
    const v = (byte < 0) ? 256 + byte : byte;
    return ('0' + v.toString(16)).slice(-2);
  }).join('');
}
