import SwiftUI

@main
struct GuitarAPPApp: App {

    @StateObject private var gameScore = GameScore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameScore)
        }
    }
}
