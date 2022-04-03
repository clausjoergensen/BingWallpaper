import Cocoa
import Combine

final class WallpaperStatusBarManager {
    private let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var cancellables = Set<AnyCancellable>()
    private let wallpaperManager = WallpaperManager()

    private lazy var copyrightMenuItem = NSMenuItem(title: "")

    private lazy var titleMenuItem = NSMenuItem(
        title: "",
        action: #selector(openImage),
        target: self
    )

    private lazy var nextImageMenuItem = NSMenuItem(
        title: Strings.Menu.next,
        action: nil,
        target: self
    )

    private lazy var previousImageMenuItem = NSMenuItem(
        title: Strings.Menu.previous,
        action: #selector(previousImage),
        target: self
    )

    private lazy var refreshMenuItem = NSMenuItem(
        title: Strings.Menu.refresh,
        action: #selector(refresh),
        target: self
    )

    private lazy var quitMenuItem = NSMenuItem(
        title: Strings.Menu.quit,
        action: #selector(quit),
        target: self
    )

    private lazy var statusBarMenu: NSMenu = {
        let menu = NSMenu(title: Strings.title)
        menu.addItem(titleMenuItem)
        menu.addItem(copyrightMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(nextImageMenuItem)
        menu.addItem(previousImageMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(refreshMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitMenuItem)
        return menu
    }()

    init() {
        statusBarItem.button?.title = Strings.title
        statusBarItem.button?.image = .icon
        statusBarItem.button?.action = #selector(openImage)
        statusBarItem.menu = statusBarMenu

        nextImageMenuItem.isEnabled = false
        previousImageMenuItem.isEnabled = false

        wallpaperManager.$imageIndex.sink { [weak self] imageIndex in
            guard let self = self else { return }
            self.previousImageMenuItem.action = imageIndex >= 0 && imageIndex < WallpaperManager.maximumNumberOfImages
                ? #selector(self.previousImage)
                : nil
            self.nextImageMenuItem.action = imageIndex > 0
                ? #selector(self.nextImage)
                : nil
        }.store(in: &cancellables)

        wallpaperManager.$image.sink { [weak self] image in
            guard let self = self else { return }
            guard let split = image?.copyright.components(separatedBy: " (©"), split.count == 2 else { return }
            self.titleMenuItem.title = split[0]
            self.copyrightMenuItem.title = "©\(split[1].dropLast())"
        }.store(in: &cancellables)
    }

    @MainActor
    func start() async throws {
        try await wallpaperManager.start()
    }

    @objc
    private func nextImage() {
        Task {
            try await wallpaperManager.nextImage()
        }
    }

    @objc
    private func previousImage() {
        Task {
            try await wallpaperManager.previousImage()
        }
    }

    @objc
    private func refresh() {
        Task {
            try await wallpaperManager.refresh()
        }
    }

    @objc
    private func openImage() {
        guard let url = wallpaperManager.image?.copyrightlink else { return }
        NSWorkspace.shared.open(url)
    }

    @objc
    private func quit() {
        NSApplication.shared.terminate(self)
    }
}

private extension NSMenuItem {
    convenience init(title: String, action: Selector? = nil, target: AnyObject? = nil) {
        self.init(title: title, action: action, keyEquivalent: "")
        self.target = target
    }
}
