//
//  EmojiServiceManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct Emoji: Decodable, Hashable {
    var id: Int
    var emoji: String
    var isSelected: Bool = false 

    private enum CodingKeys: String, CodingKey {
        case emoji
        case id
    }
}

struct Response: Decodable {
    var results: [Emoji]
}

class EmojiServiceManager {

    enum NetworkMethods: String {
        case GET = "GET"
        case POST = "POST"
    }
    
    static func fetchEmojis(for category: EmojiCategorySegmentControl.EmojiCategory) async throws -> Response {
        let url = "https://api.emojisworld.fr/v1/popular?categories=\(category.rawValue)"
        return try await self.fetchEmojis(withURL: url)
    }
    
    static func fetchAllEmojis() async throws -> Response {
        let url = "https://api.emojisworld.fr/v1/random"
        return try await self.fetchEmojis(withURL: url)
    }
    
    private static func fetchEmojis(withURL url: String) async throws -> Response {
        return try await withCheckedThrowingContinuation({ continuation in
            
            guard let safeURL = URL(string: "\(url)") else {
                continuation.resume(throwing: ClientError.apiError(detail: "Wrong URL"))
                return
            }

            var request = URLRequest(url: safeURL)
            request.httpMethod = NetworkMethods.GET.rawValue

            let session = URLSession(configuration: .default)

            session.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    continuation.resume(throwing: ClientError.apiError(detail: "Network Timed Out"))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let decodedData = try decoder.decode(Response.self, from: data)
                    continuation.resume(returning: decodedData)
                } catch {
                    continuation.resume(throwing: ClientError.apiError(detail: "Emoji Not Found"))
                }
            }.resume()
        })
    }
}
