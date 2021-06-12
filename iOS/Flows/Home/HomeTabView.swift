//
//  HomeTabView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/17/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class HomeTabView: View {

    private var leftButton = ImageViewButton()
    private var cancellables = Set<AnyCancellable>()

    var didSelectProfile: CompletionOptional = nil

    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)

        self.addSubview(self.leftButton)

        self.leftButton.imageView.image = UIImage(systemName: "person.crop.circle")
        self.leftButton.alpha = 1

        self.leftButton.didSelect { [unowned self] in
            self.didSelectProfile?()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let itemWidth = self.width * 0.33
        let itemSize = CGSize(width: itemWidth, height: 60)
        self.leftButton.size = itemSize
        if self.safeAreaInsets.bottom == 0 {
            self.leftButton.pin(.bottom, padding: 0)
        } else  {
            self.leftButton.pinToSafeArea(.bottom, padding: 0)
        }
        self.leftButton.left = 0
    }
}
