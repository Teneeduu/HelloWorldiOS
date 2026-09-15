import SwiftUI
import UniformTypeIdentifiers

struct PlayerView: View {
    @ObservedObject var library: MusicLibrary
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                computerUploadHint

                if library.tracks.isEmpty {
                    Spacer()
                    Text("还没有歌曲，点右上角 + 从手机添加，或看上面的说明从电脑添加")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
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
            .navigationTitle("设置")
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
                    Button {
                        library.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
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

    private var computerUploadHint: some View {
        DisclosureGroup("从电脑上传歌曲") {
            VStack(alignment: .leading, spacing: 6) {
                Text("1. 手机连电脑（数据线，或配好 AltServer 后同一 WiFi）")
                Text("2. 电脑上打开 Finder / iTunes / “Apple 设备”App，找到 HelloWorld 这个 App 的文件共享")
                Text("3. 把 mp3 / m4a / wav 文件直接拖进去")
                Text("4. 回到这里点右上角 ↻ 刷新，新歌就会出现在下面的列表里")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 4)
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
