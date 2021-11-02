//
//  User+INPerson.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents
import UIKit

extension User {

    func getINPerson() async -> INPerson? {

        var inImage: INImage? = nil
        if let data = try? await self.smallImage?.retrieveDataInBackground() {
            if let image = UIImage(data: data),
               let cgImage = image.cgImage {

                let orientedImage = UIImage.init(cgImage: cgImage,
                                                 scale: image.scale,
                                                 orientation: .down)

                if let previewData = orientedImage.previewData {
                    inImage = INImage(imageData: previewData)
                }
            }
        }
        return INPerson(personHandle: self.inHandle,
                        nameComponents: self.nameComponents,
                        displayName: self.fullName,
                        image: inImage,
                        contactIdentifier: nil,
                        customIdentifier: self.objectId,
                        isMe: User.current()?.objectId == self.objectId,
                        suggestionType: .instantMessageAddress)
    }

    private var inHandle: INPersonHandle {
        return INPersonHandle(value: self.phoneNumber, type: .phoneNumber, label: .iPhone)
    }

    private var nameComponents: PersonNameComponents? {
        var components = PersonNameComponents()
        components.givenName = self.givenName
        components.familyName = self.familyName
        return components
    }

    private var inSuggestionType: INPersonSuggestionType {
        return INPersonSuggestionType.instantMessageAddress
    }
}

