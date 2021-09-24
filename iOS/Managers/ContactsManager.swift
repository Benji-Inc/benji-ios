//
//  ContactsManager.swift
//  Jibber
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

    func searchForContact(with predicateType: ContactPredicateType) -> [CNContact] {
        let predicate: NSPredicate

        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactIdentifierKey, CNContactThumbnailImageDataKey] as [CNKeyDescriptor]

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
            return try self.store.unifiedContacts(matching: predicate, keysToFetch: keys)
        } catch {
            return []
        }
    }

    func fetchContacts() async -> [CNContact] {
            // 1.
        do {
            if try await self.store.requestAccess(for: .contacts) {
                // 2.
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactIdentifierKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                
                do {
                    // 3.
                    var contacts: [CNContact] = []
                    try self.store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        contacts.append(contact)
                    })
                    return contacts
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
            } else {
                print("access denied")
            }
        } catch {
            print(error)
        }

        return []
    }
}
