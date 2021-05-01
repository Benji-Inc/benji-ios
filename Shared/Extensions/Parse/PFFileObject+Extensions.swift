//
//  PFFileObject+Extensions.swift
//  Ours
//
//  Created by Benji Dodgson on 5/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

extension PFFileObject: ImageDisplayable {

    var userObjectID: String? {
        return nil
    }

    var image: UIImage? {
        return nil
    }

    func retrieveDataInBackground(progressHandler: ((Int) -> Void)? = nil) -> Future<Data, Error> {
        return Future { promise in

            self.getDataInBackground { data, error in
                if let e = error {
                    promise(.failure(e))
                } else if let data = data {
                    promise(.success(data))
                } else {
                    promise(.failure(ClientError.apiError(detail: "No error or data returned for file.")))
                }
            } progressBlock: { progress in
                progressHandler?(Int(progress))
            }
        }
    }
}
