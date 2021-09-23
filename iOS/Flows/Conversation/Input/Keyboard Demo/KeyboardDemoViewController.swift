//
//  MessagingDemoViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Lottie

class KeyboardDemoViewController: ViewController {

    let scrollView = UIScrollView()
    let pagingIndicator = UIPageControl()
    let exitButton = ImageViewButton()

    private var demoViews: [DemoView] {
        return self.scrollView.subviews.compactMap { view in
            return view as? DemoView
        }
    }

    private var didFinishDemos: CompletionOptional = nil
    @Published var currentIndex: Int = 0

    enum DemoType {

        case send
        case sendAlert
        case cursor

        var instruction: Localized {
            switch self {
            case .send:
                return "Swipe up to send"
            case .sendAlert:
                return "Hold down to send something important"
            case .cursor:
                return "Use the space bar to move the cursor"
            }
        }

        var animation: MicroAnimation {
            switch self {
            case .send:
                return .send
            case .sendAlert:
                return .sendAlert
            case .cursor:
                return .cursor
            }
        }
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background2)

        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.view.addSubview(self.scrollView)
        self.scrollView.delegate = self
        self.view.addSubview(self.pagingIndicator)

        self.view.addSubview(self.exitButton)
        self.exitButton.imageView.image = UIImage(systemName: "xmark")!

        self.pagingIndicator.hidesForSinglePage = true
        self.pagingIndicator.backgroundStyle = .prominent

        self.scrollView.isPagingEnabled = true

        self.$currentIndex
            .removeDuplicates()
            .mainSink { index in
                for (viewIndex, view) in self.demoViews.enumerated() {
                    if viewIndex == index {
                        view.animationView.play()
                    } else {
                        view.animationView.stop()
                    }
                }
                if let view = self.demoViews[safe: index] {
                    view.animationView.play()
                }
                self.pagingIndicator.currentPage = index
            }.store(in: &self.cancellables)
    }

    func load(demos: [DemoType]) {

        self.scrollView.removeAllSubviews()

        demos.forEach { demo in
            let view = DemoView(with: demo)
            self.scrollView.addSubview(view)
        }

        self.pagingIndicator.numberOfPages = demos.count
        self.pagingIndicator.currentPage = 0

        if let view = self.demoViews[safe: 0] {
            view.animationView.play()
        }
        
        self.view.layoutNow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.scrollView.expandToSuperviewSize()

        for (index, view) in self.demoViews.enumerated() {
            let xOffset: CGFloat = self.scrollView.width * CGFloat(index)
            view.frame = CGRect(x: xOffset,
                                y: 0, width: self.view.width,
                                height: self.view.height)
        }

        self.scrollView.contentSize = CGSize(width: self.view.width * CGFloat((self.demoViews.count)), height: self.view.height)

        self.pagingIndicator.sizeToFit()
        self.pagingIndicator.centerOnX()
        self.pagingIndicator.pinToSafeArea(.bottom, padding: 0)

        self.exitButton.squaredSize = 50
        self.exitButton.pin(.top, padding: Theme.contentOffset.half)
        self.exitButton.pin(.right, padding: Theme.contentOffset.half)
    }
}

extension KeyboardDemoViewController: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentIndex = scrollView.currentXIndex
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.currentIndex = scrollView.currentXIndex
    }
}
