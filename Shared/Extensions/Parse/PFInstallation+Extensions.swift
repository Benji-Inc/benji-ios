//
//  PFInstallation+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 1/26/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

extension PFInstallation {

    static func getCurrent() -> Future<PFInstallation, Error> {
        return Future { promise in
            self.getCurrentInstallationInBackground().continueWith { task in
                if let installation = task.result {
                    return promise(.success(installation))
                } else {
                    return promise(.failure(ClientError.apiError(detail: "No installation was returned")))
                }
            }
        }
    }
}
