//
//  ArchiveHeaderView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchiveHeaderView: UICollectionReusableView {

    let lineView = View()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeSubviews() {
        self.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .background3)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.lineView.height = 2
        self.lineView.expandToSuperviewWidth()
        self.lineView.pin(.bottom, padding: Theme.contentOffset.half)
    }
}
