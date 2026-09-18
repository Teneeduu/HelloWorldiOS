import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var library: MusicLibrary
    @ObservedObject var slideshow: PhotoSlideshow
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    photoSection
                    trackSection
                    helpSection
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
                        slideshow.refresh()
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

    private var photoSection: some View {
        Section("背景照片") {
            Toggle("用照片当背景", isOn: $slideshow.isEnabled)

            Picker("多久换一张", selection: $slideshow.interval) {
                Text("15 秒").tag(15.0)
                Text("30 秒").tag(30.0)
                Text("1 分钟").tag(60.0)
                Text("5 分钟").tag(300.0)
            }

            LabeledContent("相册里的照片", value: slideshow.hasAccess ? "\(slideshow.libraryCount) 张" : "未授权")
            LabeledContent("Jo 文件夹里的照片", value: "\(slideshow.folderCount) 张")

            if !slideshow.hasAccess {
                if slideshow.status == .denied || slideshow.status == .restricted {
                    Text("相册权限被拒绝了。去「设置 → 隐私与安全性 → 照片 → Jo」重新允许。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Button("允许访问相册") {
                        slideshow.requestAccess()
                    }
                }
            } else if slideshow.status == .limited {
                Text("现在只授权了部分照片。想让它从整个相册抽，去「设置 → 隐私与安全性 → 照片 → Jo」改成完全访问。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("不想给相册权限也行：打开「文件」App → 我的 iPhone/iPad → Jo → Photos，把图片放进去，点右上角 ↻ 刷新即可。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var trackSection: some View {
        Section("歌曲") {
            if library.tracks.isEmpty {
                Text("还没有歌，点左上角 ＋ 从「文件」里选")
                    .foregroundStyle(.secondary)
            } else {
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
        }
    }

    private var helpSection: some View {
        Section("还能怎么加歌") {
            VStack(alignment: .leading, spacing: 8) {
                Text("用「文件」App 直接放进来")
                    .font(.footnote.weight(.semibold))
                Text("打开系统的「文件」App → 我的 iPhone/iPad → Jo，把 mp3 粘贴进这个文件夹，回来点右上角 ↻ 刷新。歌可以先用网盘、微信、隔空投送从电脑传到手机。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("从电脑直接拖（需要装 iMazing）")
                    .font(.footnote.weight(.semibold))
                    .padding(.top, 4)
                Text("Windows 版 iTunes 从 12.7 起就没有文件共享了。要从电脑直连拖文件，装 iMazing，连上设备找到 Jo 的文件夹拖进去。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
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
