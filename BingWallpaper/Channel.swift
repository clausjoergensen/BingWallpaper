// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Combine

public final class Channel<Output>: AsyncSequence, @unchecked Sendable where Output: Sendable {
    public typealias AsyncIterator = AsyncStream<Output>.Iterator
    public typealias Element = Output

    private let continuation: AsyncStream<Output>.Continuation
    private let stream: AsyncStream<Output>
    private var cancellables = Set<AnyCancellable>()

    public init(publisher: any Publisher<Output, Never>) {
        (stream, continuation) = AsyncStream.makeStream(bufferingPolicy: .unbounded)

        publisher
            .sink { [weak self] value in
                self?.send(value)
            }
            .store(in: &cancellables)
    }

    deinit {
        continuation.finish()
    }

    public func send(_ value: Output) {
        continuation.yield(value)
    }

    public func makeAsyncIterator() -> AsyncStream<Output>.Iterator {
        stream.makeAsyncIterator()
    }
}
