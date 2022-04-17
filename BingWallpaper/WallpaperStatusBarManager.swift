import Cocoa
import Combine
import os

final class WallpaperStatusBarManager {
    private static let log = OSLog(subsystem: "com.clajun.BingWallpaper", category: "Logging")

    private let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var cancellables = Set<AnyCancellable>()
    private let wallpaperManager: WallpaperManager
    private let workspace: NSWorkspace
    private let application: NSApplication

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

    init(
        wallpaperManager: WallpaperManager,
        workspace: NSWorkspace,
        application: NSApplication
    ) {
        self.wallpaperManager = wallpaperManager
        self.workspace = workspace
        self.application = application

        setupStatusBarAndMenuItems()

        Task {
            do {
                try await wallpaperManager.start()
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

    @objc
    private func nextImage() {
        Task {
            do {
                try await wallpaperManager.nextImage()
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

    @objc
    private func previousImage() {
        Task {
            do {
                try await wallpaperManager.previousImage()
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

    @objc
    private func refresh() {
        Task {
            do {
                try await wallpaperManager.refresh()
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

    @objc
    private func openImage() {
        guard let url = wallpaperManager.state?.image.copyrightlink else { return }
        workspace.open(url)
    }

    @objc
    private func quit() {
        application.terminate(self)
    }

    private func setupStatusBarAndMenuItems() {
        statusBarItem.button?.title = Strings.title
        statusBarItem.button?.image = .icon
        statusBarItem.button?.action = #selector(openImage)
        statusBarItem.menu = statusBarMenu

        nextImageMenuItem.isEnabled = false
        previousImageMenuItem.isEnabled = false

        wallpaperManager.$state.sink { [weak self] state in
            guard let self = self, let state = state else { return }
            self.updateImageMenuActions(index: state.index)
            self.updateTitleAndCopyright(image: state.image)
        }.store(in: &cancellables)
    }

    private func updateImageMenuActions(index: Int) {
        if index >= 0 && index < WallpaperManager.maximumNumberOfImages {
            previousImageMenuItem.action = #selector(previousImage)
        } else {
            previousImageMenuItem.action = nil
        }

        if index > 0 {
            nextImageMenuItem.action = #selector(nextImage)
        } else {
            nextImageMenuItem.action = nil
        }
    }

    private func updateTitleAndCopyright(image: Image?) {
        guard let split = image?.copyright.components(separatedBy: " (©"), split.count == 2 else {
            return
        }

        titleMenuItem.title = split[0]
        copyrightMenuItem.title = "©\(split[1].dropLast())"
    }
}

private extension NSMenuItem {
    convenience init(title: String, action: Selector? = nil, target: AnyObject? = nil) {
        self.init(title: title, action: action, keyEquivalent: "")
        self.target = target
    }
}
