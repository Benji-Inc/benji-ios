//
//  Avatar.swift
//  Benji
//
//  Created by Benji Dodgson on 6/23/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol PersonType: ImageDisplayable {
    var initials: String { get }
    var givenName: String { get }
    var familyName: String { get }
    var fullName: String { get }
    var firstAndLastInitial: String? { get }
    var handle: String { get }
}

extension PersonType {
    
    var fullName: String {
        if self.givenName.isEmpty && self.familyName.isEmpty {
            return "Unknown"
        }
        return self.givenName + " " + self.familyName
    }

    var initials: String {
        let firstInitial = String(optional: self.givenName.first?.uppercased())
        let lastInitial = String(optional: self.familyName.first?.uppercased())
        return firstInitial + lastInitial
    }

    var firstAndLastInitial: String? {
        let lastInitial = String(optional: self.familyName.first?.lowercased())
        return self.givenName.lowercased() + " " + lastInitial
    }
}
