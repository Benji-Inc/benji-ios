//
//  ConnectionCell.swift
//  Ours
//
//  Created by Benji Dodgson on 1/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Combine

class ConnectionCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Connection

    private let vibrancyView = VibrancyView()
    private let connectionRequestView = ConnectionRequestView()

    var currentItem: Connection?

    var didUpdateConnection: ((Connection) -> Void)? = nil

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.vibrancyView)
        self.vibrancyView.roundCorners()
        self.contentView.addSubview(self.connectionRequestView)
        self.connectionRequestView.didUpdateConnection = { [unowned self] connection in
            self.didUpdateConnection?(connection)
        }
    }

    func configure(with item: Connection) {
        self.connectionRequestView.configure(with: item)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.connectionRequestView.width = self.contentView.width * 0.95
        self.connectionRequestView.expandToSuperviewHeight()
        self.connectionRequestView.centerOnX()

        self.vibrancyView.frame = self.connectionRequestView.frame
    }
}
