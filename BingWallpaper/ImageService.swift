import Foundation
import Combine

struct ImageService {
    func getTodayImage(at index: Int = 0) -> AnyPublisher<Image?, Never> {
        let url = URL(string: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=\(index)&n=1&mkt=en-US")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: ImagesResult.self, decoder: JSONDecoder())
            .map { $0.images.first }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
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
