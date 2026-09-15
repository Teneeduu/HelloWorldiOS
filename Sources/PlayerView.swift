import SwiftUI
import UniformTypeIdentifiers

struct PlayerView: View {
    @ObservedObject var library: MusicLibrary
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if library.tracks.isEmpty {
                    Spacer()
                    Text("还没有歌曲，点右上角 + 添加")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(library.tracks) { track in
                            HStack {
                                Image(systemName: track.id == library.currentTrackID && library.isPlaying ? "waveform" : "music.note")
                                    .foregroundStyle(track.id == library.currentTrackID ? .pink : .secondary)
                                Text(track.title)
                                    .lineLimit(1)
                                Spacer()
                                if track.isBundled {
                                    Text("内置")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                library.play(track)
                            }
                        }
                        .onMove { library.move(fromOffsets: $0, toOffset: $1) }
                        .onDelete { offsets in
                            for index in offsets {
                                library.removeTrack(library.tracks[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                controls
            }
            .navigationTitle("播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isImporting = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        library.addFile(from: url)
                    }
                case .failure(let error):
                    print("Import failed: \(error)")
                }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Text(library.currentTrack?.title ?? "未播放")
                .font(.headline)
                .lineLimit(1)
                .padding(.top, 12)

            HStack(spacing: 36) {
                Button {
                    library.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .disabled(library.currentTrackID == nil)

                Button {
                    library.toggle()
                } label: {
                    Image(systemName: library.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                }
                .disabled(library.tracks.isEmpty)
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}
