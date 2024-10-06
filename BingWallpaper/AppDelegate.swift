// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Cocoa
import Combine

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor private let wallpaperStatusBarManager = WallpaperStatusBarManager(
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
