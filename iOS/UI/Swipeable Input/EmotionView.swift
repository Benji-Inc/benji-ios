//
//  SwiftUIView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI
import StreamChat

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

struct EmotionView: View {
    
    @ObservedObject var config: MessageDetailViewState
        
    var body: some View {
        HStack {
            if let emotion = self.config.emotion {
                Spacer.length(.standard)
                Text(emotion.emoji)
                    .fontType(.reactionEmoji)
                Spacer.length(.standard)
                Text(emotion.rawValue.firstCapitalized)
                    .fontType(.small)
                Spacer.length(.standard)
            }
        }
        .frame(minHeight: 25, idealHeight: 25, maxHeight: 25)
        .background(
            RoundedRectangle(cornerRadius: Theme.innerCornerRadius)
                .fill(color: .B1withAlpha,
                      strokeColor: .BORDER,
                      lineWidth: 0.5)

        )
    }
}

struct EmotionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let config = MessageDetailViewState(message: MockMessage())

            EmotionView(config: config)
        }.preferredColorScheme(.dark)
    }
}
