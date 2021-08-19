//
//  ConnectionRequestCell.swift
//  Ours
//
//  Created by Benji Dodgson on 5/31/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConnectionRequestCell: NoticeCell {

    let content = ConnectionRequestView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.content)
    }

    override func canHandleStationaryPress() -> Bool {
        return false
    }

    override func configure(with item: SystemNotice) {
        super.configure(with: item)

        guard let connectionId = item.attributes?["connectionId"] as? String else { return }

        Task {
            do {
                let connection = try await Connection.getObject(with: connectionId)
                await self.content.configure(with: connection)
                self.setNeedsLayout()
            } catch {
                print(error)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
    }
}
