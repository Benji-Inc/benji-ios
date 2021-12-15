//
//  PFFileObject+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

extension PFFileObject: ImageDisplayable {

    var userObjectId: String? {
        return nil
    }

    var image: UIImage? {
        return nil
    }

    func retrieveDataInBackground(progressHandler: ((Int) -> Void)? = nil) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in

            self.getDataInBackground { data, error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: ClientError.apiError(detail: "No error or data returned for file."))
                }
            } progressBlock: { progress in
                progressHandler?(Int(progress))
            }
        }
    }
}
