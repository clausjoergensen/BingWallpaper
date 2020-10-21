import Cocoa
import Combine

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let maximumNumberOfImages = 7
    private let statusBar = NSStatusBar.system
    private let statusBarMenu = NSMenu(title: "Bing Wallpaper")
    private var statusBarItem: NSStatusItem!
    private let imageService = ImageService()
    private var cancellable: AnyCancellable?
    private var timer: Timer?
    private var lastRefresh = Date()

    private var imageIndex = 0 {
        didSet {
            previousImageMenuItem.action = imageIndex >= 0 && imageIndex < maximumNumberOfImages ? #selector(previousImage) : nil
            nextImageMenuItem.action = imageIndex > 0 ? #selector(nextImage) : nil
        }
    }

    private lazy var titleMenuItem: NSMenuItem = {
        NSMenuItem(title: "", action: #selector(openImage), keyEquivalent: "")
    }()

    private lazy var copyrightMenuItem: NSMenuItem = {
        NSMenuItem(title: "", action: nil, keyEquivalent: "")
    }()

    private lazy var nextImageMenuItem: NSMenuItem = {
        NSMenuItem(title: "Next Wallpaper", action: nil, keyEquivalent: "")
    }()

    private lazy var previousImageMenuItem: NSMenuItem = {
        NSMenuItem(title: "Previous Wallpaper", action: #selector(previousImage), keyEquivalent: "")
    }()

    private lazy var refreshMenuItem: NSMenuItem = {
        NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "")
    }()

    private lazy var quitMenuItem: NSMenuItem = {
        NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
    }()

    private var image: Image? {
        didSet {
            guard let split = image?.copyright.components(separatedBy: " (©"), split.count == 2 else { return }
            titleMenuItem.title = split[0]
            copyrightMenuItem.title = "©\(split[1].dropLast())"
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarMenu.addItem(titleMenuItem)
        statusBarMenu.addItem(copyrightMenuItem)
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(nextImageMenuItem)
        statusBarMenu.addItem(previousImageMenuItem)
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(refreshMenuItem)
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(quitMenuItem)

        nextImageMenuItem.isEnabled = false
        previousImageMenuItem.isEnabled = false

        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "Bing Wallpaper"
        statusBarItem.button?.image = NSImage(named: "Icon")
        statusBarItem.button?.action = #selector(openImage)
        statusBarItem.menu = statusBarMenu

        refresh()
        startTimer()
    }

    private func startTimer() {
        let timer = Timer(timeInterval: .hours(1), repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if !Calendar.current.isDateInToday(self.lastRefresh) {
                self.refresh()
            }
        }

        self.timer = timer

        RunLoop.main.add(timer, forMode: .common)
    }

    private func loadImage() {
        cancellable = imageService.getTodayImage(at: imageIndex)
            .sink { [weak self] image in
                self?.image = image

                if let image = image {
                    self?.downloadAndSetWallpaper(image: image)
                }
            }
    }

    @objc
    private func loadNewestImage() {
        imageIndex = 0
        loadImage()
    }

    @objc
    private func openImage() {
        guard let url = image?.copyrightlink else { return }
        NSWorkspace.shared.open(url)
    }

    @objc
    private func nextImage() {
        guard imageIndex > 0 else { return }
        imageIndex = imageIndex - 1
        loadImage()
    }

    @objc
    private func previousImage() {
        guard imageIndex < maximumNumberOfImages else { return }
        imageIndex = imageIndex + 1
        loadImage()
    }

    @objc
    private func refresh() {
        imageIndex = 0
        loadImage()
        lastRefresh = Date()
    }

    @objc
    private func quit() {
        NSApplication.shared.terminate(self)
    }

    private func downloadAndSetWallpaper(image: Image) {
        let url = URL(string: "https://www.bing.com\(image.url)")!
        let fileName = String(image.urlbase.dropFirst(7))

        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .replaceError(with: nil)
            .sink { data in
                guard let data = data else { return }
                do {
                    let url = try FileManager.default.url(for: .picturesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

                    let bingURL = url.appendingPathComponent("Bing")
                    if !FileManager.default.fileExists(atPath: bingURL.path) {
                        try FileManager.default.createDirectory(at: bingURL, withIntermediateDirectories: false, attributes: nil)
                    }

                    let fileURL = bingURL.appendingPathComponent("\(fileName).jpg")
                    if !FileManager.default.fileExists(atPath: fileURL.path) {
                        try data.write(to: fileURL)
                    }

                    try NSScreen.screens.forEach { screen in
                        try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: [:])
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
    }
}
