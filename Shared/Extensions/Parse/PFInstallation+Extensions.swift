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

    func saveToken() -> Future<Void, Error> {
        return Future { promise in
            if let current = User.current() {
                self["userId"] = current.objectId
                self.saveInBackground { (success, error) in
                    if success {
                        promise(.success(()))
                    } else if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.failure(ClientError.message(detail: "There was a problem saving your authorization credentials.")))
                    }
                }
            } else {
                promise(.failure(ClientError.message(detail: "You don't appear to be logged in.")))
            }
        }
    }
}
