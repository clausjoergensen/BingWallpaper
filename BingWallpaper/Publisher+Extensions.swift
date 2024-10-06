// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Combine

public extension Publisher where Output: Sendable, Failure == Never {
    func task(_ operation: sending @escaping (Output) async -> Void) -> Task<Void, Never> {
        let values = Channel(publisher: self)
        return Task.detached {
            for await value in values {
                guard !Task.isCancelled else { return }
                await operation(value)
            }
        }
    }
}
