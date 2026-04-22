import SwiftUI

struct ContentView: View {

    @EnvironmentObject var gameScore: GameScore
    @EnvironmentObject var achievements: AchievementManager
    @EnvironmentObject var practiceHistory: PracticeHistory
    @State private var selectedTab = 0
    @State private var showProfile = false

    var body: some View {
        TabView(selection: $selectedTab) {

            TunerView()
                .tabItem {
                    Label("Afinador", systemImage: "tuningfork")
                }
                .tag(0)

            ChordsView()
                .tabItem {
                    Label("Acordes", systemImage: "music.note.list")
                }
                .tag(1)

            MetronomeView()
                .tabItem {
                    Label("Metrónomo", systemImage: "metronome")
                }
                .tag(2)

            LessonsView()
                .tabItem {
                    Label("Aprender", systemImage: "book.fill")
                }
                .tag(3)

            ScalePracticeView()
                .tabItem {
                    Label("Escalas", systemImage: "waveform.path")
                }
                .tag(4)
        }
        .tint(.orange)
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { HapticManager.selection() }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(gameScore)
                .environmentObject(achievements)
                .environmentObject(practiceHistory)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showProfile = true
                HapticManager.tap()
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(.trailing, 16)
            .padding(.top, 4)
        }
    }
}
