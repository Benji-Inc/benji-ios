//
//  Messageable+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 2/7/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension Messageable {

    var emotion: Emotion? {
        let controller = ChatClient.shared.messageController(for: self)

        guard let data = controller?.message?.extraData["emotions"] else {
            return nil
        }

        guard case .array(let JSONObjects) = data, let emotionJSON = JSONObjects.first else {
            return nil
        }

        guard case .string(let emotionString) = emotionJSON,
              let emotion = Emotion(rawValue: emotionString) else {
                  return nil
              }

        return emotion
    }
}
