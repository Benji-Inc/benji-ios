//
//  newMessageDetailView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

struct newMessageDetailView: View {
    
    @State private var message: Messageable?
    
    var body: some View {
        HStack {
            Spacer().frame(width: Theme.ContentOffset.standard.value)

            newEmotionView(emotion: .bored)
                .background(.green)

            Spacer()

            newStatusView()
                .background(.indigo)

            Spacer()
                .frame(width: Theme.ContentOffset.standard.value)
        }.background(.red)
    }
    
    func configure(with message: Messageable) {
        self.message = message
    }

//    func configure(with message: Messageable) {
//        self.emotionView.configure(for: message)
//        self.statusView.configure(for: message)
//
//    }
//
//    func update(with message: Messageable) {
//        self.emotionView.configure(for: message)
//        self.statusView.configure(for: message)
//    }
}

struct newMessageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        newMessageDetailView().preferredColorScheme(.dark)
    }
}
