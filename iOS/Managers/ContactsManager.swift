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

class ContactsManager {

    static let shared = ContactsManager()
    private let store = CNContactStore()
    
    private var fetchedContacts: [CNContact] = []
    
    init() {
        if self.hasPermissions {
            Task {
                self.fetchedContacts = await self.fetchContacts()
            }
        }
    }
    
    var hasPermissions: Bool {
        return CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }

    enum ContactPredicateType {
        case name(String)
        case phone(String)
        case email(String)
        case identifier(String)
    }
    
    func searchForContact(with predicateType: ContactPredicateType) -> [CNContact] {
        
        let predicate: NSPredicate

        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey,
                    CNContactIdentifierKey] as [CNKeyDescriptor]

        switch predicateType {
        case .name(let name):
            predicate = CNContact.predicateForContacts(matchingName: name)
        case .email(let email):
            predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
        case .phone(let phone):
            let cnNumber = CNPhoneNumber(stringValue: phone)
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
        guard self.fetchedContacts.isEmpty else {
            return self.fetchedContacts
        }
        // 1.
        do {
            if try await self.store.requestAccess(for: .contacts) {
                // 2.
                let keys = [CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey,
                            CNContactPhoneNumbersKey]

                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                request.sortOrder = .familyName
                
                do {
                    // 3.
                    var contacts: [CNContact] = []
                    try self.store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        if contact.phoneNumbers.count > 0 {
                            contacts.append(contact)
                        }
                    })
                    
                    self.fetchedContacts = contacts
                    
                    return contacts
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
            } else {
                print("access denied")
            }
        } catch {
            logError(error)
        }

        return []
    }
}
