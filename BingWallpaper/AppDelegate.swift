import Cocoa
import Combine

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarMenu = NSMenu(title: "Bing Wallpaper")
    private var statusBarItem: NSStatusItem!
    private let wallpaperManager = WallpaperManager()
    private var cancellables = Set<AnyCancellable>()

    private lazy var copyrightMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private lazy var nextImageMenuItem = NSMenuItem(title: "Next Wallpaper", action: nil, keyEquivalent: "")

    private lazy var titleMenuItem: NSMenuItem = {
        NSMenuItem(title: "", action: #selector(openImage), keyEquivalent: "")
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

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "Bing Wallpaper"
        statusBarItem.button?.image = NSImage(named: "Icon")
        statusBarItem.button?.action = #selector(openImage)
        statusBarItem.menu = statusBarMenu

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

        Task {
            try await wallpaperManager.start()
        }
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
