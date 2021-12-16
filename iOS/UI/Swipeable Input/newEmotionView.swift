//
//  SwiftUIView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

struct EmojiContainer: View {
    
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .overlay (
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(.border, width: 0.25)
                    Text("😔").fontType(.small)
                }
            ).frame(width: 20, height: 20, alignment: .center)
            .color(.white, alpha: 0.1)
    }
}

struct newEmotionView: View {
    var body: some View {
        HStack {
            EmojiContainer()
            Spacer.length(.short)
            Text("Hello, World!")
                .fontType(.small)
        }
    }
}

struct newEmotionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            newEmotionView().preferredColorScheme(.light)
        }
    }
}
