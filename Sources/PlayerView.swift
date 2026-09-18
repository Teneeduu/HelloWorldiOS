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
        DisclosureGroup("还能怎么加歌") {
            VStack(alignment: .leading, spacing: 8) {
                Text("用「文件」App 直接放进来")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("打开系统的「文件」App → 我的 iPhone/iPad → HelloWorld，把 mp3 粘贴进这个文件夹，回来点右上角 ↻ 刷新即可。歌可以先用网盘、微信、隔空投送从电脑传到手机。")

                Text("从电脑直接拖（需要装 iMazing）")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("电脑装 iMazing，用数据线连手机，找到 HelloWorld 的文件夹把歌拖进去。Windows 版 iTunes 从 12.7 起已经没有「文件共享」功能了，用不了。")
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

            HStack(spacing: 28) {
                Button {
                    library.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                }
                .disabled(library.currentTrackID == nil)

                Button {
                    library.previous()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }
                .disabled(library.tracks.isEmpty)

                Button {
                    library.toggle()
                } label: {
                    Image(systemName: library.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                }
                .disabled(library.tracks.isEmpty)

                Button {
                    library.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .disabled(library.tracks.isEmpty)
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}
