//
//  UserHeaderView.swift
//  Ours
//
//  Created by Benji Dodgson on 6/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class UserHeaderView: UICollectionReusableView {

    let imageView = AvatarView()

    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeSubviews()
    }

    deinit {
        self.cancellables.forEach({ cancellable in
            cancellable.cancel()
        })
    }

    func initializeSubviews() {
        self.addSubview(self.imageView)

        User.current()?.retrieveDataIfNeeded()
            .mainSink(receiveValue: { user in
                self.imageView.displayable = user 
            }).store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.setSize(for: self.height)
        self.imageView.pin(.left, padding: Theme.contentOffset)
        self.imageView.pin(.top)
    }
}
