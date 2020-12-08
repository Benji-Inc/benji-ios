//
//  NavigationBarView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NavigationBarView: View {

    static let margin: CGFloat = 14

    private(set) var titleLabel = DisplayThinLabel()

    let leftButton = Button()
    private(set) var leftItem: UIView?
    private var leftTapHandler: (() -> Void)?

    let rightButton = Button()
    private(set) var rightItem: UIView?
    private var rightTapHandler: (() -> Void)?

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .clear)

        self.addSubview(self.titleLabel)

        self.addSubview(self.leftButton)
        self.leftButton.didSelect { [unowned self] in
            self.leftTapHandler?()
        }

        self.addSubview(self.rightButton)
        self.rightButton.didSelect { [unowned self] in
            self.rightTapHandler?()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.leftButton.left = NavigationBarView.margin
        self.leftButton.size = CGSize(width: 30, height: 30)
        self.leftButton.centerOnY()

        self.leftItem?.frame = self.leftButton.bounds
        self.leftItem?.contentMode = .center

        self.rightButton.size = CGSize(width: 30, height: 30)
        self.rightButton.right = self.width - NavigationBarView.margin
        self.rightButton.centerOnY()

        self.rightItem?.frame = self.rightButton.bounds
        self.rightItem?.contentMode = .center

        if self.leftItem == nil && self.rightItem == nil {
            // If there are no left or right items, give more space for the title
            self.titleLabel.width = self.width - 2 * NavigationBarView.margin
        } else {
            // Otherwise, fill the space between the item containers with the title label
            self.titleLabel.width = self.rightButton.left - self.leftButton.right
        }
        self.titleLabel.height = self.height
        self.titleLabel.centerOnXAndY()
    }


    func setLeft(_ item: UIView?, tapHandler: @escaping () -> Void) {
        self.leftItem?.removeFromSuperview()

        self.leftItem = item
        if let leftItem = self.leftItem {
            self.leftButton.addSubview(leftItem)
        }

        self.leftTapHandler = tapHandler

        self.setNeedsLayout()
    }

    func setRight(_ item: UIView, tapHandler: @escaping () -> Void) {
        self.rightItem?.removeFromSuperview()

        self.rightItem = item
        if let rightItem = self.rightItem {
            self.rightButton.addSubview(rightItem)
        }

        self.rightTapHandler = tapHandler

        self.setNeedsLayout()
    }
}

