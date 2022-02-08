//
//  newMessageDetailView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

class MessageDetailConfig: ObservableObject {

    @Published var message: Messageable? = nil

    var emotion: Emotion? {
        return self.message?.emotion
    }
    var isRead: Bool {
        return self.message?.isConsumed ?? false
    }
    var updateDate: Date? {
        return self.message?.lastUpdatedAt
    }
    var replyCount: Int {
        return self.message?.totalReplyCount ?? 0
    }

    init(message: Messageable?) {
        self.message = message
    }
}

struct MessageDetailView: View {

    @ObservedObject var config: MessageDetailConfig
    
    var body: some View {
        HStack {
            if let emotion = self.config.emotion {
                Spacer().frame(width: Theme.ContentOffset.standard.value)
                EmotionView(emotion: emotion)
            }

            Spacer()

            MessageStatusView(config: self.config)
                .padding(.vertical, 0.0)

            Spacer()
                .frame(width: Theme.ContentOffset.standard.value)
        }
        .frame(height: 50)
        .background(.red)
    }
}

struct MessageDetailView_Previews: PreviewProvider {

    static var previews: some View {
        let config = MessageDetailConfig(message: MockMessage())

        MessageDetailView(config: config).preferredColorScheme(.dark)
    }
}
