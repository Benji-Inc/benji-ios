//
//  newMessageDetailView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

class MessageDetailConfig: ObservableObject {

    @Published var emotion: Emotion?
    @Published var isRead: Bool
    @Published var updateDate: Date?
    @Published var replyCount: Int

    convenience init() {
        self.init(emotion: nil, isRead: false, updateDate: nil, replyCount: 0)
    }

    init(emotion: Emotion?, isRead: Bool, updateDate: Date?, replyCount: Int) {
        self.emotion = emotion
        self.isRead = isRead
        self.updateDate = updateDate
        self.replyCount = replyCount
    }
}

struct MessageDetailView: View {

    @ObservedObject var config: MessageDetailConfig
    
    var body: some View {
        HStack {
            if let emotion = self.config.emotion {
                Spacer().frame(width: Theme.ContentOffset.standard.value)
                EmotionView(emotion: emotion)
                    .background(.green)
            }

            Spacer()

            StatusView(config: self.config)
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
        let config = MessageDetailConfig(emotion: .calm,
                                         isRead: false,
                                         updateDate: nil,
                                         replyCount: 2)

        MessageDetailView(config: config).preferredColorScheme(.dark)
    }
}
