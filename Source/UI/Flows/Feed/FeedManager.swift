//
//  FeedCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 7/28/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedManager: NSObject {

    var didSetItems: CompletionOptional = nil
    var didComplete: (FeedType) -> Void = { _ in }
    var didFinish: CompletionOptional = nil
    var didShowViewAtIndex: ((Int) -> Void)?
    private var currentView: FeedView?
    private(set) var feedViews: [FeedView] = []
    private let containerView: UIView

    init(with container: UIView) {
        self.containerView = container
        super.init()
    }

    func set(items: [FeedType]) {
        self.feedViews = items.map({ (type) -> FeedView in
            let view = FeedView(with: type)
            view.didComplete = { [unowned self] in
                self.didComplete(type)
            }
            return view
        })
        
        self.didSetItems?()
        self.showFirst()
    }

    func showFirst() {
        if let first = self.feedViews.first {
            self.show(view: first, at: 0)
        }
    }

    func advanceToNextView(from index: Int) {
        if let nextView = self.feedViews[safe: index + 1]  {
            self.show(view: nextView, at: index + 1)
        } else {
            self.finishFeed()
        }
    }

    private func show(view: FeedView, at index: Int) {
        let duration: TimeInterval = self.currentView.isNil ? 0 : 0.2
        UIView.animate(withDuration: duration) {
            self.currentView?.alpha = 0
        } completion: { (completed) in
            self.currentView?.removeFromSuperview()
            self.currentView = view
            view.alpha = 0
            self.containerView.addSubview(view)
            view.expandToSuperviewSize()
            view.layoutNow()
            UIView.animate(withDuration: 0.2) {
                view.alpha = 1
            } completion: { (completed) in
                self.didShowViewAtIndex?(index)
            }
        }
    }

    private func finishFeed() {
        UIView.animate(withDuration: 0.2) {
            self.currentView?.alpha = 0
        } completion: { (completed) in
            self.didFinish?()
        }
    }
}
