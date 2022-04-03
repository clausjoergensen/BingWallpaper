import Foundation

protocol ImageServiceType {
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

        let result = try JSONDecoder().decode(ImagesResult.self, from: data)

        return result.images.first
    }
}

struct Image: Decodable, Equatable {
    var copyright: String
    var title: String
    var url: String
    var urlbase: String
    var copyrightlink: URL
}
