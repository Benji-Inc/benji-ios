//
//  TCHMessages+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Parse
import TMROLocalization
import Combine

extension TCHMessage: Avatar {

    var handle: String {
        return String()
    }

    var givenName: String {
        return String()
    }

    var familyName: String {
        return String()
    }

    var image: UIImage? {
        return nil
    }

    var userObjectID: String? {
        return self.author
    }
}

extension TCHMessage: Messageable {

    var updateId: String? {
        return self.attributes()?.dictionary?["updateId"] as? String
    }

    var id: String {
        return self.sid!
    }

    var isFromCurrentUser: Bool {
        guard let author = self.author,
            let identity = PFUser.current()?.objectId else { return false }
        return author == identity
    }

    var createdAt: Date {
        return self.dateCreatedAsDate ?? Date()
    }

    var text: Localized {
        return String(optional: self.body)
    }

    var authorID: String {
        return String(optional: self.author)
    }

    var messageIndex: NSNumber? {
        return self.index
    }

    var attributes: [String : Any]? {
        return self.attributes()?.dictionary as? [String: Any]
    }

    var avatar: Avatar {
        return self
    }

    var status: MessageStatus {
        return .delivered
    }

    var kind: MessageKind {
        switch self.messageType {
        case .text:
            return .text(String(optional: self.body))
        case .media:
            guard let type = self.mediaType, let mediaType = MediaType(rawValue: type) else {
                return .text(String(optional: self.body))
            }

            switch mediaType {
            case .photo:
                return .photo(photo: EmptyMediaItem(mediaType: mediaType), body: String(optional: self.body))
            case .video:
                fatalError()
            }
        default:
            return .text(String(optional: self.body))
        }
    }

    var context: MessageContext {
        if let statusString = self.attributes()?.dictionary?["context"] as? String, let type = MessageContext(rawValue: statusString) {
            return type
        }

        return .casual
    }

    var hasBeenConsumedBy: [String] {
        return self.attributes()?.dictionary?["consumers"] as? [String] ?? []
    }

    @discardableResult
    func udpateConsumers(with consumer: Avatar) -> Future<Void, Error> {
        var consumers = self.hasBeenConsumedBy
        consumers.append(consumer.userObjectID!)
        return self.appendAttributes(with: ["consumers": consumers])
    }

    func appendAttributes(with attributes: [String: Any]) -> Future<Void, Error> {
        return Future { promise in
            let current: [String: Any] = self.attributes()?.dictionary as? [String: Any] ?? [:]
            let updated = current.merging(attributes, uniquingKeysWith: { (first, _) in first })

            if let newAttributes = TCHJsonAttributes.init(dictionary: updated) {
                self.setAttributes(newAttributes) { (result) in
                    if let error = result.error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            } else {
                promise(.failure(ClientError.generic))
            }
        }
    }

    func getMediaContentURL() -> Future<String, Error> {
        return Future { promise in 
            self.getMediaContentTemporaryUrl { (result, url) in
                if let mediaURL = url {
                    promise(.success(mediaURL))
                } else if let e = result.error {
                    promise(.failure(e))
                } else {
                    promise(.failure(ClientError.apiError(detail: "Error retrieving media content URL.")))
                }
            }
        }
    }
}

extension TCHMessage {

    func getAuthorAsUser() -> Future<User, Error> {
        return User.localThenNetworkQuery(for: self.authorID)
    }
}
