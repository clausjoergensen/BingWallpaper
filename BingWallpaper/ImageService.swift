// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Foundation

protocol ImageServiceType: Sendable {
    func getTodayImage(at index: Int) async throws -> Image?
}

struct ImageService: ImageServiceType {
    let urlSession: URLSession

    func getTodayImage(at index: Int) async throws -> Image? {
        let url = URL(string: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=\(index)&n=1&mkt=sv-SE")!
        let (data, _) = try await urlSession.data(from: url)

        struct ImagesResult: Decodable {
            var images: [Image]
        }

        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        let result = try decoder.decode(ImagesResult.self, from: data)

        return result.images.first
    }
}

struct Image: Decodable, Equatable {
    var copyright: String
    var title: String
    var url: String
    var urlbase: String
    var copyrightlink: URL
    let startDate: Date
    let endDate: Date

    enum CodingKeys: String, CodingKey {
        case copyright
        case title
        case url
        case urlbase
        case copyrightlink
        case startDate = "startdate"
        case endDate = "enddate"
    }
}
