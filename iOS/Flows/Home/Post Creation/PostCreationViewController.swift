//
//  PostCreationViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class PostCreationViewController: ImageCaptureViewController {

    private var cancellables = Set<AnyCancellable>()

    private let imageView = UIImageView()
    var didShowImage: CompletionOptional = nil
    var shouldHandlePan: ((UIPanGestureRecognizer) -> Void)? = nil

    let vibrancyView = PostVibrancyView()
    let exitButton = ImageViewButton()

    var didTapExit: CompletionOptional = nil

    let swipeLabel = Label(font: .largeThin)

    private var tabState: HomeTabView.State = .home

    private(set) var animator: UIViewPropertyAnimator?

    var interactionInProgress = false // If we're currently progressing

    let threshold: CGFloat = 10 // Distance, in points, a pan must move vertically before a animation
    let distance: CGFloat = 250 // Distance that a pan must move to fully animate

    var panStartPoint = CGPoint() // Where the pan gesture began
    var startPoint = CGPoint() // Where the pan gesture was when animation was started

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.set(backgroundColor: .background1)

        self.view.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill
        self.didCapturePhoto = { [unowned self] image in
            self.show(image: image)
        }

        self.view.addSubview(self.vibrancyView)
        self.view.addSubview(self.exitButton)

        self.exitButton.imageView.image = UIImage(systemName: "xmark")!
        self.exitButton.alpha = 0
        self.exitButton.didSelect { [unowned self] in
            self.didTapExit?()
            self.reset()
        }

        self.view.addSubview(self.swipeLabel)
        self.swipeLabel.setText("Swipe up to post")
        self.swipeLabel.textAlignment = .center
        self.swipeLabel.showShadow(withOffset: 5)
        self.swipeLabel.alpha = 0

        self.vibrancyView.onPan { [unowned self] pan in
            if self.tabState == .home {
                self.shouldHandlePan?(pan)
            } else {
                self.handle(pan: pan)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.vibrancyView.animateScroll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.height = self.view.height * 0.5
        self.imageView.width = self.view.width * 0.5
        self.imageView.centerOnX()
        self.imageView.centerY = self.view.halfHeight * 0.8

        self.vibrancyView.expandToSuperviewSize()

        self.exitButton.squaredSize = 50
        self.exitButton.match(.top, to: .top, of: self.vibrancyView, offset: Theme.contentOffset)
        self.exitButton.pin(.right, padding: Theme.contentOffset)

        self.swipeLabel.setSize(withWidth: self.view.width)
        self.swipeLabel.centerOnX()
        self.swipeLabel.pinToSafeArea(.bottom, padding: Theme.contentOffset.doubled)
    }

    func handle(state: HomeTabView.State) {
        self.tabState = state
        UIView.animate(withDuration: Theme.animationDuration) {
            self.swipeLabel.alpha = state == .review ? 1.0 : 0.0
            self.exitButton.alpha = state == .home ? 0.0 : 1.0
            self.vibrancyView.show(blur: state == .home)
        }
    }

    func show(image: UIImage) {
        self.stop()
        self.imageView.image = image
        self.didShowImage?()
    }

    func reset() {
        self.currentPosition = .front
        self.imageView.image = nil
        self.begin()
    }

    func createPost(progressHandler: @escaping (Int) -> Void) -> Future<Void, Error> {
        return Future { promise in
            if let image = self.imageView.image, let data = image.data, let preview = image.previewData {
                FeedManager.shared.createPost(with: data,
                                              previewData: preview,
                                              caption: nil,
                                              progressHandler: progressHandler)
                    .mainSink { post in
                        self.reset()
                        promise(.success(()))
                    }.store(in: &self.cancellables)
            } else {
                promise(.failure(ClientError.apiError(detail: "No image for post")))
            }
        }
    }

    func createAnimator() {
        guard self.animator.isNil else { return }

        self.animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear, animations: { [weak self] in
            guard let `self` = self else { return }
            let layer = self.imageView.layer
            var transform = CATransform3DIdentity
            transform.m34 = 1.0 / -500
            transform = CATransform3DRotate(transform, 85.0 * .pi / 180.0, 1.0, 0.0, 0.0)

            let move = CATransform3DMakeTranslation(0, -(self.view.height * 0.3), 0)
            let new = CATransform3DConcat(transform, move)
            let scale = CATransform3DScale(new, 1.0, 1.0, 0.5)
            //let newer = CATransform3DConcat(new, scale)

            UIView.animateKeyframes(withDuration: 0.0, delay: 0.0, options: .allowUserInteraction) {

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
                    layer.transform = scale
                }

                UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.5) {
                    self.imageView.alpha = 0.2
                }

            } completion: { _ in

            }
        })

        self.animator?.addCompletion({ [weak self] (position) in
            guard let `self` = self else { return }
            // Animator completes initially on pause, so we also need to check progress
            if position == .end {//, let progress = self.animator?.fractionComplete, progress == 1.0 {
                print("CREATE POST")
            }
            self.animator = nil
        })

        self.animator?.scrubsLinearly = true
        self.animator?.isInterruptible = true
        self.animator?.pauseAnimation()
        self.prepareInitialAnimation()
    }

    //reset the animation
    private func prepareInitialAnimation() {
        //self.isAnimatingFinal = false
        self.imageView.alpha = 1.0
        //self.label.transform = CGAffineTransform.init(scaleX: self.minScale, y: self.minScale)
    }
}

extension PostCreationViewController: UIGestureRecognizerDelegate {

    func handle(pan: UIPanGestureRecognizer) {
        guard self.tabState == .review else { return }

        let currentPoint = pan.location(in: nil)

        switch pan.state {
        case .began:
            self.createAnimator()
            self.panStartPoint = currentPoint
        case .changed:
            if self.interactionInProgress {
                let progress = self.progress(currentPoint: currentPoint)
                self.animator?.fractionComplete = progress
            } else if currentPoint.y + self.panStartPoint.y > self.threshold {
                self.interactionInProgress = true
                self.startPoint = currentPoint
            }

        case .ended, .cancelled, .failed:
            self.interactionInProgress = false

            print(self.progress(currentPoint: currentPoint))
            self.animator?.isReversed = self.progress(currentPoint: currentPoint) < 1.0
            self.animator?.continueAnimation(withTimingParameters: nil, durationFactor: 0.0)

        case .possible:
            break
        @unknown default:
            break
        }
    }

    private func progress(currentPoint: CGPoint) -> CGFloat {
        let progress = (self.startPoint.y - currentPoint.y) / self.distance
        return clamp(progress, 0.0, 1.0)
    }
}
