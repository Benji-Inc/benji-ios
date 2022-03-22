//
//  URLSession+Extension.swift
//  Jibber
//
//  Created by Martin Young on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension URLSession {

    func dataTask(with url: URL) async throws -> (Data, URLResponse) {
        let result: (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
            let dataTask = self.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                    return
                }

                continuation.resume(throwing: ClientError.apiError(detail: "Unable to load data."))
            }

            dataTask.resume()
        }

        return result
    }
}
