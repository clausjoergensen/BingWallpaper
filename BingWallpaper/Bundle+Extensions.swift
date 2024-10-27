// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Foundation

extension Bundle {
    var shortVersionString: String {
        guard let string = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return "1.0"
        }

        return string
    }
}
