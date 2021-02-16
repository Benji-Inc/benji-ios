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

    func searchForContact(with predicateType: ContactPredicateType) -> [CNContact] {
        var contacts: [CNContact] = [CNContact]()
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
            contacts = try self.store.unifiedContacts(matching: predicate, keysToFetch: keys)
            return contacts
        } catch {
            return []
        }
    }

    func fetchContacts() {
        // 1.
        self.store.requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                print("failed to request access", error)
                return
            }
            if granted {
                // 2.
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactIdentifierKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                do {
                    // 3.
                    try self.store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        if contact.fullName == "benjamin dodgson" {
                            print(contact.identifier)
                        }

//                        if contact.identifier == "448C2146-D60F-4991-BB59-173261FA25E6:ABPerson" {
//                            print("Found contact")
//                        }
//                        print(contact.fullName)
                    })
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
            } else {
                print("access denied")
            }
        }
    }
}
