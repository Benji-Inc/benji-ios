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

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}

struct newEmotionView: View {
    
    @State var emotion: Emotion?
        
    var body: some View {
        HStack {
            if let emotion = self.emotion {
                Spacer.length(.short)
                EmojiContainer(emoji: emotion.emoji)
                Spacer.length(.short)
                Text(emotion.rawValue.firstCapitalized)
                    .fontType(.small)
                Spacer.length(.short)
            }
        }.overlay {
            Picker("", selection: $emotion) {
                ForEach(Emotion.allCases, content: { e in
                    let text = "\(e.emoji) \(e.rawValue.firstCapitalized)"
                    Text(text)
                        .fontType(.small)
                })
            }.opacity(0.011)
                .onChange(of: emotion) { newValue in
                    if let e = newValue {
                        self.configure(for: e)
                    }
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
    }
}

struct newEmotionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            newEmotionView(emotion: .awkward)
        }
    }
}
