import Cocoa
import Combine

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let wallpaperStatusBarManager = WallpaperStatusBarManager(
        wallpaperManager: WallpaperManager(
            imageService: ImageService(
                urlSession: .shared
            ),
            notificationCenter: .default
        ),
        workspace: .shared,
        application: .shared
    )

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Task {
            try await wallpaperStatusBarManager.start()
        }
    }
}
