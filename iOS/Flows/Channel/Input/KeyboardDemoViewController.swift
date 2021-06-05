//
//  MessagingDemoViewController.swift
//  Ours
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

    private var demoViews: [DemoView] {
        return self.scrollView.subviews.compactMap { view in
            return view as? DemoView
        }
    }

    private var didFinishDemos: CompletionOptional = nil

    enum DemoType {

        case send
        case sendAlert
        case cursor

        var instruction: Localized {
            switch self {
            case .send:
                return "Send"
            case .sendAlert:
                return "Alert"
            case .cursor:
                return "Cursor"
            }
        }

        var animation: MicroAnimation {
            switch self {
            case .send:
                return .checkbox
            case .sendAlert:
                return .checkbox
            case .cursor:
                return .checkbox
            }
        }
    }

    override func loadView() {
        self.view = self.scrollView
    }

    override func initializeViews() {
        super.initializeViews()

        self.scrollView.isPagingEnabled = true
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func load(demos: [DemoType]) {

        self.scrollView.removeAllSubviews()

        demos.forEach { demo in
            let view = DemoView(with: demo)
            self.scrollView.addSubview(view)
        }

        self.view.layoutNow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        for (index, view) in self.demoViews.enumerated() {
            let xOffset: CGFloat = self.scrollView.width * CGFloat(index)
            view.frame = CGRect(x: xOffset,
                                y: 0, width: self.view.width,
                                height: self.view.height)
        }

        self.scrollView.contentSize = CGSize(width: self.view.width * CGFloat((self.demoViews.count)), height: self.view.height)
    }
}

class DemoView: View {

    let animationView = AnimationView()
    let label = Label(font: .regular)
    private let demo: KeyboardDemoViewController.DemoType

    init(with demo: KeyboardDemoViewController.DemoType) {
        self.demo = demo
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .red)
        self.addSubview(self.label)
        self.addSubview(self.animationView)

        self.label.setText(self.demo.instruction)
        self.animationView.load(animation: self.demo.animation)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.animationView.squaredSize = 100
        self.animationView.centerOnX()
        self.animationView.centerY = self.height * 0.4

        self.label.setSize(withWidth: self.width - Theme.contentOffset)
        self.label.centerOnX()
        self.label.match(.top, to: .bottom, of: self.animationView, offset: Theme.contentOffset.half)
    }
}
