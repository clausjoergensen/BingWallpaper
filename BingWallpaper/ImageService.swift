import Foundation
import Combine

protocol ImageServiceType {
    func getTodayImage(at index: Int) async throws -> Image?
}

struct ImageService: ImageServiceType {
    func getTodayImage(at index: Int) async throws -> Image? {
        let url = URL(string: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=\(index)&n=1&mkt=sv-SE")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(ImagesResult.self, from: data)
        return result.images.first
    }
}

struct ImagesResult: Decodable {
    var images: [Image]
}

struct Image: Decodable {
    var copyright: String
    var title: String
    var url: String
    var urlbase: String
    var copyrightlink: URL
}
