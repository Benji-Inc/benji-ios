//
//  ExpressionAttachment.swift
//  Jibber
//
//  Created by Martin Young on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

struct ExpressionAttachmentPayload: AttachmentPayload {

    public static let type: AttachmentType = AttachmentType(rawValue: "expression")

    var expressionURL: URL
}

// MARK: - Codable

extension ExpressionAttachmentPayload: Codable {

    func encode(to encoder: Encoder) throws {
        var values: [String : RawJSON] = [:]
        values[JibberAttachmentCodingKeys.expressionURL.rawValue] = .string(self.expressionURL.absoluteString)
        try values.encode(to: encoder)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JibberAttachmentCodingKeys.self)
        let expressionURL = try container.decode(URL.self, forKey: .expressionURL)

        self.init(expressionURL: expressionURL)
    }
}
