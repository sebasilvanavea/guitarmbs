import SwiftUI

@main
struct GuitarAPPApp: App {

    @StateObject private var gameScore = GameScore()
    @StateObject private var achievements = AchievementManager()
    @StateObject private var practiceHistory = PracticeHistory()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
            }
            .environmentObject(gameScore)
            .environmentObject(achievements)
            .environmentObject(practiceHistory)
            .overlay(alignment: .top) {
                if let achievement = achievements.newlyUnlocked {
                    AchievementToast(
                        achievement: achievement,
                        isPresented: Binding(
                            get: { achievements.newlyUnlocked != nil },
                            set: { if !$0 { achievements.newlyUnlocked = nil } }
                        )
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onAppear {
                NotificationManager.requestPermission()
                NotificationManager.scheduleDailyReminder()
            }
            .onChange(of: gameScore.totalXP) {
                achievements.check(gameScore: gameScore)
            }
            .onChange(of: gameScore.completedLessonIDs) {
                achievements.check(gameScore: gameScore)
            }
        }
    }
}
