//
//  newStatusView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

struct newStatusView: View {

    @ObservedObject var config: MessageDetailConfig

    var body: some View {
        HStack {
            newReadView(config: self.config)

            if self.config.replyCount > 0 {
                Spacer.length(.short)
                newReplyView(config: self.config)
            }
        }
    }
}

struct newReadView: View {
    
    @ObservedObject var config: MessageDetailConfig
    
    var body: some View {
        HStack {
            Spacer.length(.short)


            if let updateDate = self.config.updateDate {
                let dateString = Date.hourMinuteTimeOfDay.string(from: updateDate)
                Text(dateString)
                    .fontType(.small)
                    .color(.T1)

                Spacer.length(.short)
            }

            if self.config.isRead {
                Image("checkmark-double")
                    .color(.T1)

                Spacer.length(.short)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.innerCornerRadius)
                .fill(color: .B1withAlpha,
                      strokeColor: .D6withAlpha,
                      lineWidth: 0.5)

        )
    }
}

struct newReplyView: View {
    
    @ObservedObject var config: MessageDetailConfig
    
    var body: some View {
        HStack {
            Spacer.length(.short)
            Text(self.config.replyCount.description)
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

struct newStatusView_Previews: PreviewProvider {
    static var previews: some View {
        let config = MessageDetailConfig(emotion: .calm, isRead: true, updateDate: nil, replyCount: 3)
        newStatusView(config: config).preferredColorScheme(.dark)
    }
}
