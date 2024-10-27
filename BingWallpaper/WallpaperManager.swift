// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Cocoa
import Combine

final class WallpaperManager: @unchecked Sendable {
    static let maximumNumberOfImages = 7

    private let imageService: ImageServiceType
    private var cancellables = Set<AnyCancellable>()
    private var lastRefresh: Date?

    private var screens: [NSScreen] = NSScreen.screens {
        didSet {
            guard oldValue != screens else { return }
            setDesktopImageURL(screens: screens)
        }
    }

    struct State {
        let index: Int
        let image: Image
        let fileURL: URL
    }

    @Published private(set) var state: State? {
        didSet {
            setDesktopImageURL(screens: screens)
        }
    }

    init(
        imageService: ImageServiceType,
        notificationCenter: NotificationCenter
    ) {
        self.imageService = imageService

        notificationCenter
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.screens = NSScreen.screens
            }
            .store(in: &cancellables)
    }

    func start() async throws {
        Logger.info("Started Bing Wallpaper")
        startTimer()
        try await refresh()
    }

    private func startTimer() {
        Timer
            .publish(every: .hours(1), on: .main, in: .common)
            .autoconnect()
            .task { [weak self] _ in
                guard let self else { return }
                try? await refresh()
            }
            .store(in: &cancellables)
    }

    private func loadImage(at index: Int) async throws {
        guard let newImage = try await imageService.getTodayImage(at: index) else {
            Logger.info("Image at index \(index) is the same as the current image.")
            return
        }

        state = State(
            index: index,
            image: newImage,
            fileURL: try await download(image: newImage)
        )
    }

    func nextImage() async throws {
        guard let imageIndex = state?.index else { return }
        try await loadImage(at: max(0, imageIndex - 1))
    }

    func previousImage() async throws {
        guard let imageIndex = state?.index else { return }
        try await loadImage(at: min(WallpaperManager.maximumNumberOfImages, imageIndex + 1))
    }

    func refresh(force: Bool = false) async throws {
        if force {
            Logger.info("Refreshing image (forced)")
            try await loadImage(at: 0)
        } else if let image = state?.image, let lastRefresh {
            let imageExpiration = image.endDate.addingTimeInterval(.hours(7))
            if lastRefresh > imageExpiration {
                Logger.info("Refreshing image. Last refresh was at \(lastRefresh), image expires at \(imageExpiration)")
                try await loadImage(at: 0)
            }
        } else {
            Logger.info("Refreshing image (initial)")
            try await loadImage(at: 0)
        }

        lastRefresh = Date()
    }

    private func setDesktopImageURL(screens: [NSScreen]) {
        guard let fileURL = state?.fileURL else {
            return
        }

        do {
            try screens.forEach { screen in
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
