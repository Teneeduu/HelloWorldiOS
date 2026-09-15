import SwiftUI

struct ContentView: View {
    @State private var animate = false
    @State private var showPlayer = false
    @StateObject private var library = MusicLibrary()

    private let rainbow: [Color] = [.pink, .purple, .indigo, .blue, .cyan, .green, .yellow, .orange, .red, .pink]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AngularGradient(colors: rainbow, center: .center)
                .hueRotation(.degrees(animate ? 360 : 0))
                .blur(radius: 70)
                .opacity(0.6)
                .ignoresSafeArea()

            VStack {
                Spacer()

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

                Spacer()

                Button {
                    showPlayer = true
                } label: {
                    Label(library.isPlaying ? "正在播放" : "播放音乐", systemImage: library.isPlaying ? "waveform" : "music.note")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .foregroundStyle(.white)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
        .sheet(isPresented: $showPlayer) {
            PlayerView(library: library)
        }
    }
}

#Preview {
    ContentView()
}
