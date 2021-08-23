//
//  UserHeaderView.swift
//  Ours
//
//  Created by Benji Dodgson on 6/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserHeaderView: UICollectionReusableView {

    let imageView = AvatarView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeSubviews()
    }

    func initializeSubviews() {
        self.addSubview(self.imageView)

        Task {
            guard let user = try? await User.current()?.retrieveDataIfNeeded() else { return }
            self.imageView.displayable = user
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.setSize(for: self.height)
        self.imageView.pin(.left, padding: Theme.contentOffset)
        self.imageView.pin(.top)
    }
}
