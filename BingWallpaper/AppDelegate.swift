import Cocoa
import Combine

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let wallpaperStatusBarManager = WallpaperStatusBarManager()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Task {
            try await wallpaperStatusBarManager.start()
        }
    }
}
