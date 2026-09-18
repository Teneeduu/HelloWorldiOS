import SwiftUI

struct ContentView: View {
    @State private var animate = false
    @State private var showSettings = false
    @StateObject private var library = MusicLibrary()
    @StateObject private var slideshow = PhotoSlideshow()
    @StateObject private var quotes = QuoteLibrary()
    @StateObject private var reminders = QuoteReminders()

    private let rainbow: [Color] = [.pink, .purple, .indigo, .blue, .cyan, .green, .yellow, .orange, .red, .pink]

    var body: some View {
        ZStack {
            background

            VStack {
                Spacer()
                greeting
                quoteLine
                Spacer()
                playButton
            }

            settingsButton
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                animate = true
            }
            reminders.reschedule(using: quotes)
        }
        .onChange(of: slideshow.generation) { _ in
            quotes.shuffle()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(library: library, slideshow: slideshow, quotes: quotes, reminders: reminders)
        }
    }

    @ViewBuilder
    private var background: some View {
        Color.black.ignoresSafeArea()

        if slideshow.isEnabled, let photo = slideshow.image {
            GeometryReader { geo in
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            .id(slideshow.generation)
            .transition(.opacity)

            LinearGradient(
                colors: [.black.opacity(0.55), .black.opacity(0.1), .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        } else {
            AngularGradient(colors: rainbow, center: .center)
                .hueRotation(.degrees(animate ? 360 : 0))
                .blur(radius: 70)
                .opacity(0.6)
                .ignoresSafeArea()
        }
    }

    private var greeting: some View {
        Text("Hello,\nworld!")
            .font(.system(size: 64, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundStyle(
                LinearGradient(colors: rainbow, startPoint: .leading, endPoint: .trailing)
            )
            .hueRotation(.degrees(animate ? 360 : 0))
            .scaleEffect(animate ? 1.08 : 0.94)
            .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
            .shadow(color: .white.opacity(0.4), radius: animate ? 28 : 10)
            .padding()
    }

    @ViewBuilder
    private var quoteLine: some View {
        if let quote = quotes.current {
            VStack(spacing: 6) {
                Text(quote.text)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)

                if !quote.source.isEmpty {
                    Text("—— " + quote.source)
                        .font(.system(size: 13, design: .rounded))
                        .opacity(0.75)
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.7), radius: 8, y: 2)
            .padding(.horizontal, 36)
            .padding(.top, 10)
            .id(quote.id)
            .transition(.opacity)
        }
    }

    private var playButton: some View {
        Button {
            library.toggle()
        } label: {
            Label(library.isPlaying ? "正在播放" : "播放音乐", systemImage: library.isPlaying ? "waveform" : "music.note")
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .foregroundStyle(.white)
        .disabled(library.tracks.isEmpty)
        .padding(.bottom, 48)
    }

    private var settingsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .foregroundStyle(.white)
                .padding(.trailing, 16)
            }
            Spacer()
        }
        .padding(.top, 8)
    }
}

#Preview {
    ContentView()
}
