//
//  ContactsManager.swift
//  Ours
//
//  Created by Benji Dodgson on 2/2/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts
import Combine

class ContactsManger {

    static let shared = ContactsManger()
    private let store = CNContactStore()

    enum ContactPredicateType {
        case name(String)
        case phone(String)
        case email(String)
        case identifier(String)
    }

    func searchForContact(with predicateType: ContactPredicateType) -> Future<[CNContact], Error> {
        return Future { promise in
            var contacts: [CNContact] = [CNContact]()
            let predicate: NSPredicate
            switch predicateType {
            case .name(let name):
                predicate = CNContact.predicateForContacts(matchingName: name)
            case .email(let email):
                predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
            case .phone(let phone):
                let cnNumber = CNPhoneNumber.init(stringValue: phone)
                predicate = CNContact.predicateForContacts(matching: cnNumber)
            case .identifier(let identifier):
                predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])
            }

            do {
                contacts = try self.store.unifiedContacts(matching: predicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
                promise(.success(contacts))
            } catch {
                promise(.failure(error))
            }
        }
    }
}
