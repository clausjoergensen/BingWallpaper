// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Combine

extension Task: @retroactive Cancellable {
    func store(in set: inout Set<AnyCancellable>) {
        set.insert(AnyCancellable(self))
    }
}
