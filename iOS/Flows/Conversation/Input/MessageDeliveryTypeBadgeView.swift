//
//  DeliveryTypeBadgeView.swift
//  Jibber
//
//  Created by Martin Young on 3/31/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class MessageDeliveryTypeBadgeView: BaseView {

    @Published var deliveryType: MessageDeliveryType?
    private var cancellables = Set<AnyCancellable>()

    private let imageView = UIImageView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)

        self.squaredSize = 25

        let configuration = UIImage.SymbolConfiguration(pointSize: 15)
        self.imageView.preferredSymbolConfiguration = configuration
        self.imageView.set(backgroundColor: .badgeHighlightTop)
        self.imageView.tintColor = ThemeColor.L1.color
        self.imageView.contentMode = .center

        self.$deliveryType
            .removeDuplicates()
            .mainSink { [unowned self] deliveryType in
                self.imageView.isVisible = deliveryType.exists
                self.imageView.image = deliveryType?.image
            }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.roundCorners()
        self.imageView.expandToSuperviewSize()
    }
}
