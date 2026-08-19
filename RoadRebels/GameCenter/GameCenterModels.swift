import Foundation

/// Leaderboard/achievement IDs. These strings must match whatever is
/// configured in App Store Connect for this app's real bundle ID/Team —
/// until that's set up, submissions simply no-op (GameCenterService guards
/// every call on `isAuthenticated`).
enum LeaderboardID: String {
    case endlessDistance = "endless_distance"
    case fastestRace = "fastest_race"
    case mostTakedowns = "most_takedowns"
    case bestCombo = "best_combo"
}

enum AchievementID: String, CaseIterable {
    case firstRide = "first_ride"
    case firstWin = "first_win"
    case tenWins = "ten_wins"
    case hundredWins = "hundred_wins"
    case firstBoss = "first_boss"
    case masterRider = "master_rider"
    case hundredNearMisses = "hundred_near_misses"
    case roadLegend = "road_legend"
    case noCrashRun = "no_crash_run"
    case perfectRace = "perfect_race"
}
