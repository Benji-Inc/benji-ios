//
//  newStatusView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import SwiftUI

/// A view that shows the read status and reply count of a message.
struct MessageStatusView: View {

    @ObservedObject var config: MessageDetailConfig

    var body: some View {
        HStack {
            MessageReadView(config: self.config)

            if self.config.replyCount > 0 {
                Spacer.length(.short)
                MessageReplyView(config: self.config)
            }
        }
    }
}

private struct MessageReadView: View {
    
    @ObservedObject var config: MessageDetailConfig
    
    var body: some View {
        HStack {
            Spacer.length(.standard)

            if let updateDate = self.config.updateDate {
                let dateString = Date.hourMinuteTimeOfDay.string(from: updateDate)
                Text(dateString)
                    .fontType(.small)
                    .color(.T1)

                Spacer.length(.standard)
            }


            if self.config.isRead {
                Image("checkmark-double")
                    .color(.T1)

                Spacer.length(.standard)
            }
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

private struct MessageReplyView: View {
    
    @ObservedObject var config: MessageDetailConfig
    
    var body: some View {
        HStack {
            Spacer.length(.standard)
            Text(self.config.replyCount.description)
                .fontType(.small)
                .color(.T1)
            Spacer.length(.standard)
        }
        .frame(minWidth: 25, minHeight: 15, idealHeight: 25, maxHeight: 25)
        .background(
            RoundedRectangle(cornerRadius: Theme.innerCornerRadius)
                .fill(color: .B1withAlpha,
                      strokeColor: .D6withAlpha,
                      lineWidth: 0.5)

        )
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        let config = MessageDetailConfig(message: nil)
        MessageStatusView(config: config).preferredColorScheme(.dark)
    }
}
