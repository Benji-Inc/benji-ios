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
                        .stroke(.D6withAlpha, alpha: 0.3, width: 0.25)
                    Text(self.emoji).fontType(.small)
                }
            ).frame(width: 20, height: 20, alignment: .center)
            .color(.T1, alpha: 0.1)
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
    
    let emotion: Emotion
        
    var body: some View {
        HStack {
            Spacer.length(.short)
            EmojiContainer(emoji: self.emotion.emoji)
            Spacer.length(.short)
            Text(self.emotion.rawValue.firstCapitalized)
                .fontType(.small)
            Spacer.length(.short)
        }
    }
}

struct newEmotionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            newEmotionView(emotion: .awkward)
        }
    }
}
