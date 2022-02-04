//
//  newStatusView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

struct newReadView: View {
    
    @State var message: Messageable?
    
    var body: some View {
        HStack {
            Spacer.length(.short)

            Text("12:34 PM")
                .fontType(.small)
                .color(.T1)

            Spacer.length(.short)

            Image("checkmark-double")
                .color(.T1)

            Spacer.length(.short)
        }
        .frame(minHeight: 15, idealHeight: 25, maxHeight: 25)
        .background(
            RoundedRectangle(cornerRadius: Theme.innerCornerRadius)
                .fill(color: .B1withAlpha,
                      strokeColor: .D6withAlpha,
                      lineWidth: 0.5)

        )
    }
}

struct newReplyView: View {
    
    @State var message: Messageable?
    
    var body: some View {
        HStack {
            Spacer.length(.short)
            Text("2")
                .fontType(.small)
                .color(.T1)
            Spacer.length(.short)
        }
        .frame(minHeight: 15, idealHeight: 25, maxHeight: 25)
        .background(
            RoundedRectangle(cornerRadius: Theme.innerCornerRadius)
                .fill(color: .B1withAlpha,
                      strokeColor: .D6withAlpha,
                      lineWidth: 0.5)

        )
    }
}

struct newStatusView: View {
    
    @State var message: Messageable?
    
    var body: some View {
        HStack {
            newReadView()
            Spacer.length(.short)
            newReplyView()
        }
//        .background(.orange)
    }
}

struct newStatusView_Previews: PreviewProvider {
    static var previews: some View {
        newStatusView(message: nil).preferredColorScheme(.dark)
    }
}
