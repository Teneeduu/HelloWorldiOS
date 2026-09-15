import SwiftUI

struct ContentView: View {
    @State private var animate = false
    @StateObject private var audio = AudioLoopPlayer(resourceName: "theme", fileExtension: "mp3")

    private let rainbow: [Color] = [.pink, .purple, .indigo, .blue, .cyan, .green, .yellow, .orange, .red, .pink]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AngularGradient(colors: rainbow, center: .center)
                .hueRotation(.degrees(animate ? 360 : 0))
                .blur(radius: 70)
                .opacity(0.6)
                .ignoresSafeArea()

            Text("Hello,\nworld!")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(colors: rainbow, startPoint: .leading, endPoint: .trailing)
                )
                .hueRotation(.degrees(animate ? 360 : 0))
                .scaleEffect(animate ? 1.08 : 0.94)
                .shadow(color: .white.opacity(0.5), radius: animate ? 30 : 10)
                .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                animate = true
            }
            audio.play()
        }
    }
}

#Preview {
    ContentView()
}
