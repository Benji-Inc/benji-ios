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

        Connection.getObject(with: connectionId).mainSink { result in
            switch result {
            case .success(let connection):
                self.content.configure(with: connection)
                self.content.layoutNow()
            case .error(_):
                break
            }
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
    }
}
