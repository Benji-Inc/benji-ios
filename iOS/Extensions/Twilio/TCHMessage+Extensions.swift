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
        if let updateId = self.attributes?["updateId"] as? Int {
            return String(updateId)
        }
        return self.attributes?["updateId"] as? String
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

    var isLink: Bool {
        guard let value = self.attributes?["isLink"] as? Bool else { return false }
        return value
    }

    var kind: MessageKind {
        switch self.messageType {
        case .text:
            guard let text = self.body else { return .text("")}
            if self.isLink, let url = URL(string: text) {
                return .link(url)
            } else {
                return .text(text)
            }
        case .media:
            guard let type = self.mediaType, let mediaType = MediaType(rawValue: type) else {
                return .text(String(optional: self.body))
            }

            switch mediaType {
            case .photo:
                let body = self.attributes?["body"] as? String
                return .photo(photo: EmptyMediaItem(mediaType: mediaType), body: String(optional: body))
            case .video:
                fatalError()
            }
        default:
            return .text(String(optional: self.body))
        }
    }

    var context: MessageContext {
        if let statusString = self.attributes?["context"] as? String, let type = MessageContext(rawValue: statusString) {
            return type
        }

        return .passive
    }

    var hasBeenConsumedBy: [String] {
        return self.attributes?["consumers"] as? [String] ?? []
    }

    @discardableResult
    func updateConsumers(with consumer: Avatar) async throws -> Messageable {
        var consumers = self.hasBeenConsumedBy
        consumers.append(consumer.userObjectID!)
        return try await self.appendAttributes(with: ["consumers": consumers])
    }

    func appendAttributes(with attributes: [String: Any]) async throws -> Messageable {
        let messageable: Messageable = try await withCheckedThrowingContinuation { continuation in
            let current: [String: Any] = self.attributes()?.dictionary as? [String: Any] ?? [:]
            let updated = current.merging(attributes, uniquingKeysWith: { (first, _) in first })

            if let newAttributes = TCHJsonAttributes.init(dictionary: updated) {
                self.setAttributes(newAttributes) { (result) in
                    if let error = result.error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: self)
                    }
                }
            } else {
                continuation.resume(throwing: ClientError.generic)
            }
        }

        return messageable
    }

    func getMediaContentURL() async throws -> String {
        let url: String = try await withCheckedThrowingContinuation { continuation in
            self.getMediaContentTemporaryUrl { (result, url) in
                if let mediaURL = url {
                    continuation.resume(returning: mediaURL)
                } else if let e = result.error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(throwing: ClientError.apiError(detail: "Error retrieving media content URL."))
                }
            }
        }
        return url
    }
}

extension TCHMessage {

    func getAuthorAsUser() async throws -> User {
        return try await User.localThenNetworkQuery(for: self.authorID)
    }
}
