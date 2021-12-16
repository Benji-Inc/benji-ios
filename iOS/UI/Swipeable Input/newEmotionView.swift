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
        ZStack {
            Text("😋")
                .foregroundColor(.red)
        }
    }
}

struct newEmotionView: View {
    var body: some View {
        HStack {
            EmojiContainer()
            Spacer.length(.short)
            Text("Hello, World youd!")
                .fontType(.small)
        }
    }
}

struct newEmotionView_Previews: PreviewProvider {
    static var previews: some View {
        newEmotionView()
    }
}
