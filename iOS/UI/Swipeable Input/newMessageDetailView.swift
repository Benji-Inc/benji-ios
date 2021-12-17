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
            newEmotionView(emotion: .bored)
                .frame(alignment: .leading)
            Spacer()
            newStatusView()
                .frame(alignment: .trailing)
        }
    }
    
    func configure(with message: Messageable) {
        self.message = message
    }
}

struct newMessageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        newMessageDetailView().preferredColorScheme(.light)
    }
}
