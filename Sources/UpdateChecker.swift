import Foundation

/// Asks GitHub whether a newer build was released. Installing it is AltStore's
/// job — iOS never lets an app install anything, including itself.
final class UpdateChecker: ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case available(build: Int)
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    static let sourceURL = "https://github.com/Teneeduu/HelloWorldiOS/releases/latest/download/source.json"
    private static let latestReleaseAPI = "https://api.github.com/repos/Teneeduu/HelloWorldiOS/releases/latest"

    var currentBuild: Int {
        Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") ?? 0
    }

    func check() {
        guard let url = URL(string: Self.latestReleaseAPI) else { return }
        state = .checking

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    self.state = .failed(error.localizedDescription)
                    return
                }
                guard let data,
                      let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tag = payload["tag_name"] as? String
                else {
                    self.state = .failed("看不懂 GitHub 的回复")
                    return
                }

                let latest = Int(tag.replacingOccurrences(of: "build-", with: "")) ?? 0
                self.state = latest > self.currentBuild ? .available(build: latest) : .upToDate
            }
        }
        .resume()
    }
}
