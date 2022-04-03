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
}
