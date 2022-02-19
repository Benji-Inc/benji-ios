//
//  newMessageDetailView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

/// ViewModel for the MessageDetailView.
class MessageDetailViewState: ObservableObject {

    @Published var message: Messageable?
    @Published var deliveryStatus: DeliveryStatus

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
        self.deliveryStatus = .sent
    }
}

struct MessageDetailView: View {

    @ObservedObject var config: MessageDetailViewState
    
    var body: some View {
        HStack {
            if let _ = self.config.emotion {
                Spacer().frame(width: Theme.ContentOffset.standard.value)
                EmotionView(config: self.config)
            }
            
            Spacer()

            MessageStatusView(config: self.config)
                .padding(.vertical, 0.0)

            Spacer()
                .frame(width: Theme.ContentOffset.standard.value)
        }
        .frame(height: 50)
    }
}

struct MessageDetailView_Previews: PreviewProvider {

    static var previews: some View {
        let config = MessageDetailViewState(message: MockMessage())

        MessageDetailView(config: config).preferredColorScheme(.dark)
    }
}
