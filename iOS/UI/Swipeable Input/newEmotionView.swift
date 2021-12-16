//
//  SwiftUIView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

extension Text {
    func fontType(_ type: FontType) -> some View {
        self.font(Font(type.font as CTFont))
    }
}

struct newEmotionView: View {
    var body: some View {
        Text("Hello, World youd!")
            .fontType(.display)
    }
}

struct newEmotionView_Previews: PreviewProvider {
    static var previews: some View {
        newEmotionView()
    }
}
