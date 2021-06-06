//
//  FeedIndicatorView.swift
//  Benji
//
//  Created by Benji Dodgson on 2/19/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol FeedIndicatorViewDelegate: AnyObject {
    func feedIndicator(_ view: FeedIndicatorView, didFinishProgressFor index: Int)
}

class FeedIndicatorView: View {

    private let offset: CGFloat = 10
    private var elements: [IndicatorView] = []
    var delegate: FeedIndicatorViewDelegate?

    deinit {
        self.elements.forEach { element in
            element.stopCurrent()
        }
    }

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

    func update(to index: Int, with duration: TimeInterval) {

        guard let element = self.elements[safe: index] else {
            self.delegate?.feedIndicator(self, didFinishProgressFor: index)
            return
        }

        element.animateProgress(with: duration) { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.feedIndicator(self, didFinishProgressFor: index)
        }
    }

    func resetAllIndicators() {
        for (index, view) in self.elements.enumerated() {
            self.finishAnimator(at: index, shouldFinish: true)
            view.progressWidth = 0
            view.layoutNow()
        }
    }

    func goBack(to previousIndex: Int, with duration: TimeInterval) {
        for (index, view) in self.elements.enumerated() {
            // reset the current and the previous
            if index >= previousIndex {
                self.finishAnimator(at: index, shouldFinish: false)
                view.progressWidth = 0
                view.layoutNow()
            }
        }

        self.update(to: previousIndex, with: duration)
    }

    func pauseProgress(at index: Int) {
        guard let element = self.elements[safe: index] else { return }
        element.animator?.pauseAnimation()
    }

    func resumeProgress(at index: Int) {
        guard let element = self.elements[safe: index] else { return }
        element.animator?.continueAnimation(withTimingParameters: nil, durationFactor: 1.0)
    }

    func finishProgress(at index: Int, finishAnimator: Bool = false) {
        self.finishAnimator(at: index, shouldFinish: finishAnimator)
        self.delegate?.feedIndicator(self, didFinishProgressFor: index)
    }

    private func finishAnimator(at index: Int, shouldFinish: Bool) {
        guard let element = self.elements[safe: index],
              let animator = element.animator,
              animator.state == .active else { return }

        animator.stopAnimation(false)
        if shouldFinish {
            animator.finishAnimation(at: .end)
        } else {
            animator.finishAnimation(at: .start)
        }
    }
}

private class IndicatorView: View {

    let progressView = View()
    var progressWidth: CGFloat = 0
    private(set) var animator: UIViewPropertyAnimator?

    deinit {
        if self.animator?.state == .active {
            self.animator?.stopAnimation(false)
        }
        if self.animator?.state == .stopped {
            // This call is the one that can assert and crash the app
            self.animator?.finishAnimation(at: .start)
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .background3)
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

        if self.animator.isNil {
            self.animator = self.createAnimator(with: duration)
        }

        self.animator?.addAnimations { [weak self] in
            guard let `self` = self else { return }
            self.progressWidth = self.width
            self.layoutNow()
        }

        self.animator?.addCompletion({ (position) in
            guard position == .end else { return }
            completion?()
        })

        self.animator?.startAnimation()
    }

    private func createAnimator(with duration: TimeInterval) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: duration,
                                              curve: .linear,
                                              animations: nil)
        self.animator?.isInterruptible = true
        self.animator?.scrubsLinearly = true
        self.animator?.pauseAnimation()
        return animator
    }

    func stopCurrent() {
        if let current = self.animator {
            if current.state == .active {
                current.stopAnimation(true)
                current.finishAnimation(at: .end)
            } else if current.state == .stopped {
                current.finishAnimation(at: .current)
            } else if current.isRunning {
                current.stopAnimation(true)
                current.finishAnimation(at: .end)
            }
        }
    }
}
