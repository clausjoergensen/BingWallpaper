// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Foundation

public extension TimeInterval {
    static func seconds(_ seconds: Double) -> TimeInterval {
        return seconds
    }

    static func minutes(_ minutes: Double) -> TimeInterval {
        return minutes * 60
    }

    static func hours(_ hours: Double) -> TimeInterval {
        return hours * 3600
    }

    static func days(_ days: Double) -> TimeInterval {
        return days * 3600 * 24
    }
}
