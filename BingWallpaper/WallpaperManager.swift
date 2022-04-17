import Cocoa

final class WallpaperManager {
    static let maximumNumberOfImages = 7

    private let imageService: ImageServiceType
    private var timer: Timer?
    private var lastRefresh = Date()

    private var screens: [NSScreen] = NSScreen.screens {
        didSet {
            guard oldValue != screens else { return }
            setDesktopImageURL()
        }
    }

    struct State {
        let index: Int
        let image: Image
        let fileURL: URL
    }

    @Published
    private(set) var state: State? {
        didSet {
            setDesktopImageURL()
        }
    }

    init(
        imageService: ImageServiceType,
        notificationCenter: NotificationCenter
    ) {
        self.imageService = imageService

        notificationCenter.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.screens = NSScreen.screens
        }
    }

    func start() async throws {
        await startTimer()

        try await refresh()
    }

    @MainActor
    private func startTimer() {
        let timer = Timer(timeInterval: .hours(1), repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if !Calendar.current.isDateInToday(self.lastRefresh) {
                Task {
                    try await self.refresh()
                }
            }
        }

        self.timer = timer

        RunLoop.main.add(timer, forMode: .common)
    }

    private func loadImage(at index: Int) async throws {
        guard let newImage = try await imageService.getTodayImage(at: index), state?.image != newImage else { return }

        state = State(
            index: index,
            image: newImage,
            fileURL: try await download(image: newImage)
        )
    }

    func nextImage() async throws {
        guard let imageIndex = state?.index, imageIndex > 0 else { return }
        try await loadImage(at: imageIndex - 1)
    }

    func previousImage() async throws {
        guard let imageIndex = state?.index, imageIndex < WallpaperManager.maximumNumberOfImages else { return }
        try await loadImage(at: imageIndex + 1)
    }

    func refresh() async throws {
        try await loadImage(at: 0)
        lastRefresh = Date()
    }

    private func setDesktopImageURL() {
        guard let fileURL = state?.fileURL else {
            return
        }

        do {
            try NSScreen.screens.forEach { screen in
                try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: [:])
            }
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    private enum ImageDownloadError: Error {
        case invalidURL
    }

    @discardableResult
    private func download(image: Image) async throws -> URL {
        let picturesDirectoryURL = try FileManager.default.url(
            for: .picturesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let bingURL = picturesDirectoryURL.appendingPathComponent("Bing")
        if !FileManager.default.fileExists(atPath: bingURL.path) {
            try FileManager.default.createDirectory(
                at: bingURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
        }

        let fileName = String(image.urlbase.dropFirst(7))
        let fileURL = bingURL.appendingPathComponent("\(fileName).jpg")

        guard !FileManager.default.fileExists(atPath: fileURL.path) else {
            return fileURL
        }

        guard let downloadURL = URL(string: "https://www.bing.com\(image.url)") else {
            throw ImageDownloadError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: downloadURL)
        try data.write(to: fileURL)

        return fileURL
    }
}
