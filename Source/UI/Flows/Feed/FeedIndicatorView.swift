//
//  FeedIndicatorView.swift
//  Benji
//
//  Created by Benji Dodgson on 2/19/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedIndicatorView: View {

    private let offset: CGFloat = 10
    private var elements: [IndicatorView] = []

    override func initializeSubviews() {
        super.initializeSubviews()

        self.clipsToBounds = false
    }

    func configure(with count: Int) {

        self.removeAllSubviews()
        self.elements = []

        guard count > 0 else { return }
        
        for _ in 1...count {
            let element = IndicatorView()
            self.elements.append(element)
            self.addSubview(element)
        }

        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard self.elements.count > 0 else { return }

        var totalOffsets = self.offset * CGFloat(self.elements.count - 1)
        totalOffsets = clamp(totalOffsets, min: self.offset)
        var itemWidth = (self.width - totalOffsets) / CGFloat(self.elements.count)
        itemWidth = clamp(itemWidth, min: 1)
        
        let itemSize = CGSize(width: itemWidth, height: self.height)

        for (index, element) in self.elements.enumerated() {
            let offset = CGFloat(index) * (itemSize.width + self.offset)
            element.size = itemSize
            element.left =  offset
            element.centerOnY()
            element.makeRound()
        }
    }

    func update(to index: Int, completion: CompletionOptional) {
        guard let element = self.elements[safe: index] else {
            completion?()
            return
        }

        element.animateProgress(with: 5.0, completion: completion)
    }
}

private class IndicatorView: View {

    let progressView = View()
    private var progressWidth: CGFloat = 0

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .background2)
        self.addSubview(self.progressView)
        self.progressView.set(backgroundColor: .teal)
        self.progressView.showShadow(withOffset: 2, color: Color.teal.color)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.progressView.expandToSuperviewHeight()
        self.progressView.pin(.left)
        self.progressView.width = self.progressWidth
    }

    func animateProgress(with duration: TimeInterval, completion: CompletionOptional) {
        UIView.animate(withDuration: duration) {
            self.progressWidth = self.width
            self.layoutNow()
        } completion: { (completed) in
            completion?()
        }
    }
}
