//
//  EmojiServiceManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct Emoji: Decodable, Hashable {
    var id = UUID()
    var emoji: String

    private enum CodingKeys: String, CodingKey {
        case emoji
    }
}

struct Response: Decodable {
    var results: [Emoji]
}

class EmojiServiceManager {

    enum NetworkError: Error {
        case emojiNotFound
        case timeOut
        case wrongURL
    }

    enum NetworkMethods: String {
        case GET = "GET"
        case POST = "POST"
    }

    static func makeEmojiApiCall (
        for query: String,
        limit: Int,
        completionHandler: @escaping (Result<Response, NetworkError>) -> ()
    ) {
        let url = "https://api.emojisworld.fr/v1/search?q=\(query)&limit=\(limit)"
        guard let safeURL = URL(string: "\(url)") else {
            completionHandler(.failure(NetworkError.wrongURL))
            return
        }

        var request = URLRequest(url: safeURL)
        request.httpMethod = NetworkMethods.GET.rawValue

        let session = URLSession(configuration: .default)

        session.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completionHandler(.failure(NetworkError.timeOut))
                return
            }

            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(Response.self, from: data)
                completionHandler(.success(decodedData))
            } catch {
                completionHandler(.failure(NetworkError.emojiNotFound))
            }
        }.resume()
    }

}
