import Cocoa
import Combine

final class WallpaperStatusBarManager {
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

        wallpaperManager.$imageIndex.sink { [weak self] imageIndex in
            self?.updateImageMenuActions(index: imageIndex)
        }.store(in: &cancellables)

        wallpaperManager.$image.sink { [weak self] image in
            self?.updateTitleAndCopyright(image: image)
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
