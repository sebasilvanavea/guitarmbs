import SwiftUI

struct AchievementToast: View {
    let achievement: Achievement
    @Binding var isPresented: Bool

    @State private var offset: CGFloat = -120
    @State private var opacity: Double = 0

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(.orange)
                    .frame(width: 44, height: 44)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("🏆 ¡Logro desbloqueado!")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                    Text(achievement.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(achievement.description)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.12))
                    .shadow(color: .orange.opacity(0.3), radius: 12)
            )
            .padding(.horizontal, 20)
            .offset(y: offset)
            .opacity(opacity)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    offset = -120
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isPresented = false
                }
            }
        }
    }
}
