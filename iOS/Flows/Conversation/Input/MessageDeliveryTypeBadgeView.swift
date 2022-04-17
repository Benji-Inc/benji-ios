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
                self.setNeedsLayout()
            }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let type = self.deliveryType {
            switch type {
            case .timeSensitive:
                let configuration = UIImage.SymbolConfiguration(pointSize: 20)
                self.imageView.preferredSymbolConfiguration = configuration
                self.squaredSize = 30
            case .conversational:
                let configuration = UIImage.SymbolConfiguration(pointSize: 17.5)
                self.imageView.preferredSymbolConfiguration = configuration
                self.squaredSize = 27.5
            case .respectful:
                let configuration = UIImage.SymbolConfiguration(pointSize: 15)
                self.imageView.preferredSymbolConfiguration = configuration
                self.squaredSize = 25
            }
        } else {
            let configuration = UIImage.SymbolConfiguration(pointSize: 15)
            self.imageView.preferredSymbolConfiguration = configuration
            self.squaredSize = 25
        }

        self.imageView.roundCorners()
        self.imageView.expandToSuperviewSize()
    }
}
