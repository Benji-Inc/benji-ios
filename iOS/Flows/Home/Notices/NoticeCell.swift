//
//  NoticeCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeCell: CollectionViewManagerCell, ManageableCell, UIGestureRecognizerDelegate {
    typealias ItemType = SystemNotice

    // Touch Handlers
    private lazy var stationaryPressRecognizer
         = StationaryPressGestureRecognizer(cancelsTouchesInView: false,
                                            target: self,
                                            action: #selector(self.handleStationaryPress))

    var currentItem: SystemNotice?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addGestureRecognizer(self.stationaryPressRecognizer)
        self.stationaryPressRecognizer.delegate = self

        self.contentView.layer.cornerRadius = Theme.cornerRadius
    }

    func configure(with item: SystemNotice) {}

    func canHandleStationaryPress() -> Bool {
        return true
    }

    // MARK: Touch Handling

    @objc private func handleStationaryPress(_ gestureRecognizer: StationaryPressGestureRecognizer) {
        
        guard self.canHandleStationaryPress() else { return }
        // Scale down the cell when pressed, and scale back up on release.
        switch gestureRecognizer.state {
        case .possible, .changed:
            break
        case .began:
            self.scaleDown()
        case .ended, .cancelled, .failed:
            self.scaleUp()
        @unknown default:
            break
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if gestureRecognizer === self.stationaryPressRecognizer {
            if otherGestureRecognizer.view?.isDescendant(of: self) == true {
                return false
            }
        }
        return true
    }
}
