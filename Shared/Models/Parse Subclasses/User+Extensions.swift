//
//  User+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 11/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

extension User: Avatar {

    var userObjectID: String? {
        self.objectId
    }

    var image: UIImage? {
        return nil
    }

    var isOnboarded: Bool {

        if self.fullName.isEmpty {
            return false
        } else if self.smallImage == nil {
            return false
        }

        return true 
    }

    var isCurrentUser: Bool {
        return self.objectId == User.current()?.objectId
    }
}

#if !APPCLIP
// Code you don't want to use in your App Clip.
extension User {

    func getRitual() -> Future<Ritual> {
        let promise = Promise<Ritual>()

        if let ritual = self.ritual {
            if ritual.isDataAvailable {
                promise.resolve(with: ritual)
            } else {
                self.ritual?.retrieveDataIfNeeded()
                    .observe(with: { (result) in
                        switch result {
                        case .success(let ritual):
                            runMain {
                                promise.resolve(with: ritual)
                            }
                        case .failure(let error):
                            promise.reject(with: error)
                        }
                    })
                self.ritual?.fetchInBackground(block: { (object, error) in

                })
            }
        } else {
            promise.reject(with: ClientError.message(detail: "Failed to retrieve your routine."))
        }

        return promise
    }
}

extension User: ManageableCellItem {
    var id: String {
        return self.objectId!
    }
}
#endif

extension User {
    
    func formatName(from text: String) {
        let components = text.components(separatedBy: " ").filter { (component) -> Bool in
            return !component.isEmpty
        }
        if let first = components.first {
            self.givenName = first
        }
        if let last = components.last {
            self.familyName = last
        }
    }
}
