import Cocoa

final class WallpaperManager {
    static let maximumNumberOfImages = 7

    private let imageService: ImageServiceType
    private var timer: Timer?
    private var lastRefresh = Date()

    private var fileURL: URL? {
        didSet {
            guard oldValue != fileURL else { return }
            setDesktopImageURL()
        }
    }

    private var screens: [NSScreen] = NSScreen.screens {
        didSet {
            guard oldValue != screens else { return }
            setDesktopImageURL()
        }
    }

    @Published
    private(set) var imageIndex = 0

    @Published
    private(set) var image: Image?

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
        try await refresh()
        startTimer()
    }

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

    private func loadImage() async throws {
        let image = try await imageService.getTodayImage(at: imageIndex)
        self.image = image

        if let image = image {
            self.fileURL = try await download(image: image)
        }
    }

    func nextImage() async throws {
        guard imageIndex > 0 else { return }
        imageIndex = imageIndex - 1
        try await loadImage()
    }

    func previousImage() async throws {
        guard imageIndex < WallpaperManager.maximumNumberOfImages else { return }
        imageIndex = imageIndex + 1
        try await loadImage()
    }

    func refresh() async throws {
        imageIndex = 0
        try await loadImage()
        lastRefresh = Date()
    }

    private func setDesktopImageURL() {
        guard let fileURL = fileURL else {
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
        guard let downloadURL = URL(string: "https://www.bing.com\(image.url)") else {
            throw ImageDownloadError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: downloadURL)

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

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try data.write(to: fileURL)
        }

        return fileURL
    }
}
