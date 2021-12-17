//
//  SwiftUIView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI
import StreamChat

struct EmojiContainer: View {
    @State var emoji: String = ""
    
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.innerCornerRadius)
            .overlay (
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.innerCornerRadius)
                        .stroke(.border, alpha: 0.3, width: 0.25)
                    Text(self.emoji).fontType(.small)
                }
            ).frame(width: 20, height: 20, alignment: .center)
            .color(.white, alpha: 0.1)
    }
}

struct newEmotionView: View {
    
    @State var emotion: Emotion?
    //private let button = Button()
    
    var body: some View {
        HStack {
            if let emotion = emotion {
                Spacer.length(.short)
                EmojiContainer(emoji: emotion.emoji)
                Spacer.length(.short)
                Text(emotion.rawValue.firstCapitalized)
                        .fontType(.small)
                Spacer.length(.short)
            }
        }
    }
    
    func configure(for message: Messageable) {
        let controller = ChatClient.shared.messageController(for: message)
        if let msg = controller?.message, let reaction = msg.latestReactions.first(where: { reaction in
            return reaction.author.userObjectId == msg.authorId
        }), let emotion = Emotion(rawValue: reaction.type.rawValue) {
            self.configure(for: emotion)
        }
    }
    
    func configure(for emotion: Emotion) {
        self.emotion = emotion
//        self.button.menu = self.createMenu(for: emotion)
    }
}

struct newEmotionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            newEmotionView(emotion: .awkward)
        }
    }
}
