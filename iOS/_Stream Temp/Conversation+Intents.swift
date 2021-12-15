//
//  ChatChannel+Intents.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents
import StreamChat

typealias Conversation = ChatChannel
typealias ConversationId = ChannelId

extension Conversation {
    
    var speakableGroupName: INSpeakableString? {
        guard let name = self.name else { return nil }

        return INSpeakableString.init(vocabularyIdentifier: String(),
                                      spokenPhrase: name,
                                      pronunciationHint: nil)
    }
}
