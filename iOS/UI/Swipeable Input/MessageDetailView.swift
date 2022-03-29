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

    var emotion: Emotion? {
        return self.message?.emotions.first
    }

    init(message: Messageable?) {
        self.message = message
    }
}

struct MessageDetailView: View {

    @ObservedObject var config: MessageDetailViewState
    
    var body: some View {
        HStack {
            if let _ = self.config.emotion {
                Spacer().frame(width: Theme.ContentOffset.long.value)
                EmotionView(config: self.config)
            }
            
            Spacer()
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
