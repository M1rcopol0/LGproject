import '../models/player.dart';

// --- TRACKING ACTIONS NOCTURNES ---
Player? nightChamanTarget;
Player? nightWolvesTarget;
bool nightWolvesTargetSurvived = false;
int wolvesNightKills = 0;
int quicheSavedThisNight = 0;

void resetNightState() {
  nightChamanTarget = null;
  nightWolvesTarget = null;
  nightWolvesTargetSurvived = false;
  wolvesNightKills = 0;
  quicheSavedThisNight = 0;
}
