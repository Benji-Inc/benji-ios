//
//  PostViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 2/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostViewController: ViewController {

    let post: Postable

    var type: PostType {
        return self.post.type
    }

    var attributes: [String: Any]? {
        return self.post.attributes
    }

    @Published var isPaused: Bool = false

    var didGoBack: CompletionOptional = nil
    var didFinish: CompletionOptional = nil
    var didPause: CompletionOptional = nil
    var didResume: CompletionOptional = nil
    var didSelectPost: CompletionOptional = nil
    var shouldHideTopView: CompletionOptional = nil
    var canMoveForwardOrBackward: Bool = true

    let gradientBlurView = GradientBlurView(with: [Color.background2.color.cgColor, Color.background3.color.cgColor], startPoint: .topCenter, endPoint: .bottomCenter)

    let leftView = AnimatingTapView()
    let rightView = AnimatingTapView()

    let container = PassThroughView()
    let bottomContainer = View()

    // Common items
    let textView = PostTextView()
    let button = Button()

    private let selectionImpact = UIImpactFeedbackGenerator()

    init(with post: Postable) {
        self.post = post
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.gradientBlurView)

        self.view.addSubview(self.rightView)
        self.view.addSubview(self.leftView)

        self.view.addSubview(self.container)

        self.$isPaused.mainSink { isPaused in
            if isPaused {
                self.didPause?()
            } else {
                self.didResume?()
            }
        }.store(in: &self.cancellables)

        self.rightView.didSelect { [unowned self] in
            guard self.canMoveForwardOrBackward else { return }
            self.selectionImpact.impactOccurred()
            self.didFinish?()
        }

        self.leftView.didSelect { [unowned self] in
            guard self.canMoveForwardOrBackward else { return }
            self.selectionImpact.impactOccurred()
            self.didGoBack?()
        }

        self.container.addSubview(self.getCenterContent())

        // Not in the container so it can handle touch events. 
        self.view.addSubview(self.bottomContainer)
        if let view = self.getBottomContent() {
            self.bottomContainer.addSubview(view)
        }

        self.button.didSelect { [unowned self] in
            self.didTapButton()
        }
    }

    func configurePost() {}
    func didTapButton() {}

    func getCenterContent() -> UIView {
        return self.textView
    }

    func getBottomContent() -> UIView? {
        return self.button
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.leftView.expandToSuperviewHeight()
        self.leftView.width = self.view.halfWidth
        self.leftView.pin(.left)

        self.rightView.expandToSuperviewHeight()
        self.rightView.width = self.view.halfWidth
        self.rightView.pin(.right)

        self.container.size = CGSize(width: self.view.width, height: self.view.safeAreaRect.height - Theme.buttonHeight - Theme.contentOffset)
        self.container.pinToSafeArea(.top, padding: 0)
        self.container.centerOnX()

        if let first = self.container.subviews.first {
            first.frame = self.container.bounds
        }

        self.bottomContainer.size = CGSize(width: self.container.width, height: Theme.buttonHeight)
        self.bottomContainer.pinToSafeArea(.bottom, padding: Theme.contentOffset)

        self.textView.setSize(withWidth: self.container.width * 0.9)
        self.textView.centerOnXAndY()

        self.button.setSize(with: self.bottomContainer.width)
        self.button.centerOnXAndY()

        self.gradientBlurView.expandToSuperviewSize()
        self.gradientBlurView.roundCorners()
    }
}
