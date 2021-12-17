//
//  SwiftUIView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

struct EmojiContainer: View {
    @State var emoji: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .overlay (
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(.border, width: 0.25)
                    Text(self.emoji).fontType(.small)
                }
            ).frame(width: 20, height: 20, alignment: .center)
            .color(.white, alpha: 0.1)
    }
}

struct newEmotionView: View {
    
    @State var emotion: Emotion
    
    var body: some View {
        HStack {
            Spacer.length(.short)
            EmojiContainer(emoji: self.emotion.emoji)
            Spacer.length(.short)
            Text(self.emotion.rawValue)
                .fontType(.small)
            Spacer.length(.short)
        }
    }
}

struct newEmotionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            newEmotionView(emotion: .awe)
        }
    }
}
