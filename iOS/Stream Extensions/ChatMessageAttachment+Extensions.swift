//
//  Attachment+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension AnyChatMessageAttachment {

    var isExpression: Bool {
        guard let imageAttachment = self.attachment(payloadType: ImageAttachmentPayload.self) else {
            return false
        }

        guard let isExpressionData = imageAttachment.extraData?["isExpression"],
              case RawJSON.bool(let isExpression) = isExpressionData else { return false }

        return isExpression
    }
}

extension ChatMessageAttachment where Payload: AttachmentPayload {

    var isExpression: Bool {
        return self.asAnyAttachment.isExpression
    }
}
