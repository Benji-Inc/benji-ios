//
//  File.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ToastStatusView: ToastView {

    private let label = ThemeLabel(font: .smallBold, textColor: .red)
    private let blurView = BlurView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.addSubview(self.label)
        self.backgroundColor = ThemeColor.red.color.withAlphaComponent(0.2)

        self.label.setText(toast.description)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        #if !NOTIFICATION && !APPCLIP
        guard let superview = UIWindow.topWindow() else { return }
        self.label.setSize(withWidth: superview.width - Theme.contentOffset.doubled)

        self.size = CGSize(width: self.label.width + Theme.contentOffset, height: self.label.height + Theme.contentOffset)

        self.label.centerOnXAndY()
        self.centerOnX()

        self.blurView.expandToSuperviewSize()
        #endif
    }
}
