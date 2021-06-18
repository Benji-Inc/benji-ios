//
//  User+INPerson.swift
//  Ours
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents

extension User {

    var inPerson: INPerson? {
        return INPerson(personHandle: self.inHandle,
                        nameComponents: self.nameComponents,
                        displayName: self.fullName,
                        image: self.inImage,
                        contactIdentifier: nil,
                        customIdentifier: self.objectId,
                        aliases: nil,
                        suggestionType: self.inSuggestionType)
    }

    private var inImage: INImage? {
        guard let urlString = self.smallImage?.url, let url = URL(string: urlString) else { return nil }
        return INImage(url: url)
    }

    private var inHandle: INPersonHandle {
        return INPersonHandle(value: self.handle, type: .unknown, label: .main)
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

