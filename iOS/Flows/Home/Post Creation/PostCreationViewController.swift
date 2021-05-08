//
//  PostCreationViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Parse

class PostCreationViewController: ImageCaptureViewController {

    let imageView = UIImageView()
    var didShowImage: CompletionOptional = nil
    var shouldHandlePan: ((UIPanGestureRecognizer) -> Void)? = nil

    let vibrancyView = PostVibrancyView()
    let exitButton = ImageViewButton()
    let cameraOptionsView = CameraOptionsView()
    let datePicker = UIDatePicker()

    let captionTextView = CaptionTextView()
    let gradientView = GradientView(with: [Color.background1.color.withAlphaComponent(0.5).cgColor, Color.clear.color.cgColor], startPoint: .bottomCenter, endPoint: .topCenter)

    var didTapExit: CompletionOptional = nil

    let swipeLabel = Label(font: .largeThin)
    let finishLabel = Label(font: .largeThin)

    private(set) var tabState: HomeTabView.State = .home

    var didSelectLibrary: CompletionOptional = nil

    var animator: UIViewPropertyAnimator?

    var canSwipeToPost: Bool = false
    var interactionInProgress = false // If we're currently progressing

    let threshold: CGFloat = 10 // Distance, in points, a pan must move vertically before a animation
    let distance: CGFloat = 250 // Distance that a pan must move to fully animate

    var panStartPoint = CGPoint() // Where the pan gesture began
    var startPoint = CGPoint() // Where the pan gesture was when animation was started

    var previewFile: PFFileObject?
    var file: PFFileObject?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.set(backgroundColor: .background1)
        self.view.addSubview(self.vibrancyView)
        
        self.imageView.isUserInteractionEnabled = true 
        self.imageView.layer.cornerRadius = 5
        self.imageView.clipsToBounds = true 
        self.imageView.contentMode = .scaleAspectFill
        self.didCapturePhoto = { [unowned self] image in
            self.show(image: image)
        }

        self.imageView.addSubview(self.gradientView)
        self.gradientView.alpha = 0

        self.imageView.addSubview(self.captionTextView)
        self.captionTextView.alpha = 0

        self.view.addSubview(self.exitButton)
        self.exitButton.imageView.image = UIImage(systemName: "xmark")!
        self.exitButton.alpha = 0
        self.exitButton.didSelect { [unowned self] in
            self.didTapExit?()
            self.reset()
        }

        self.view.addSubview(self.cameraOptionsView)
        self.cameraOptionsView.alpha = 0
        self.cameraOptionsView.backgroundColor = Color.white.color.withAlphaComponent(0.2)
        self.cameraOptionsView.roundCorners()

        self.flashMode = .off

        self.cameraOptionsView.didSelectOption = { [unowned self] type, isSelected in
            switch type {
            case .flip:
                self.flipCamera()
            case .library:
                self.didSelectLibrary?()
            case .flash:
                self.toggleFlash()
            }
        }

        self.view.addSubview(self.datePicker)
        self.datePicker.preferredDatePickerStyle = .compact
        self.datePicker.minimumDate = Date()
        self.datePicker.datePickerMode = .date
        self.datePicker.tintColor = .white
        self.datePicker.alpha = 0

        self.view.addSubview(self.swipeLabel)
        self.swipeLabel.setText("Swipe up to post")
        self.swipeLabel.textAlignment = .center
        self.swipeLabel.showShadow(withOffset: 5)
        self.swipeLabel.alpha = 0

        self.view.addSubview(self.finishLabel)
        self.finishLabel.setText("Posted 😎")
        self.finishLabel.textAlignment = .center
        self.finishLabel.alpha = 0.0

        self.vibrancyView.onPan { [unowned self] pan in
            if self.tabState == .home {
                self.shouldHandlePan?(pan)
            } else if self.canSwipeToPost {
                self.handle(pan: pan)
            }
        }

        KeyboardManger.shared.$cachedKeyboardFrame.removeDuplicates().mainSink { _ in
            if KeyboardManger.shared.isKeyboardShowing {
                UIView.animate(withDuration: 0.2) {
                    self.view.layoutNow()
                }
            }
        }.store(in: &self.cancellables)

        KeyboardManger.shared.$isKeyboardShowing.removeDuplicates().mainSink { isShowing in
            UIView.animate(withDuration: 0.2) {
                self.captionTextView.countView.alpha = isShowing ? 1.0 : 0.0
                self.view.layoutNow()
            }
        }.store(in: &self.cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.vibrancyView.animateScroll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.exitButton.squaredSize = 50
        self.exitButton.match(.top, to: .top, of: self.vibrancyView, offset: Theme.contentOffset)
        self.exitButton.pin(.right, padding: Theme.contentOffset)

        self.cameraOptionsView.width = 50
        self.cameraOptionsView.height = 200
        self.cameraOptionsView.centerOnY()
        self.cameraOptionsView.pin(.right, padding: Theme.contentOffset)

        self.datePicker.match(.top, to: .top, of: self.exitButton, offset: 8)
        self.datePicker.pin(.left, padding: Theme.contentOffset)

        self.vibrancyView.expandToSuperviewSize()

        self.swipeLabel.setSize(withWidth: self.view.width)
        self.swipeLabel.centerOnX()
        self.swipeLabel.pinToSafeArea(.bottom, padding: Theme.contentOffset.doubled)

        let height = self.view.height - self.exitButton.bottom - Theme.contentOffset.doubled - self.swipeLabel.height - self.view.safeAreaInsets.bottom - Theme.contentOffset
        self.imageView.height = height
        self.imageView.width = self.view.width - Theme.contentOffset.doubled
        self.imageView.centerOnX()

        if KeyboardManger.shared.isKeyboardShowing {
            self.imageView.pin(.bottom, padding: KeyboardManger.shared.cachedKeyboardFrame.height + 10)
        } else {
            self.imageView.match(.top, to: .bottom, of: self.exitButton)
        }

        self.captionTextView.size = CGSize(width: self.imageView.width - Theme.contentOffset, height: 94)
        self.captionTextView.pin(.bottom, padding: Theme.contentOffset.half)
        self.captionTextView.centerOnX()

        self.gradientView.expandToSuperviewWidth()
        self.gradientView.height = self.imageView.height * 0.35
        self.gradientView.pin(.bottom, padding: 0.0)

        self.finishLabel.setSize(withWidth: self.view.width)
        self.finishLabel.centerOnXAndY()
    }

    func handle(state: HomeTabView.State) {
        self.tabState = state
        UIView.animate(withDuration: Theme.animationDuration) {
            self.captionTextView.alpha = state == .review ? 1.0 : 0.0
            self.exitButton.alpha = state == .home ? 0.0 : 1.0
            self.cameraOptionsView.alpha = state == .capture ? 1.0 : 0.0
            self.datePicker.alpha = state == .capture ? 1.0 : 0.0
            self.swipeLabel.alpha = state == .review ? 1.0 : 0.0
            self.gradientView.alpha = state == .review ? 1.0 : 0.0
            self.vibrancyView.show(blur: state == .home)
        }
    }

    func show(image: UIImage) {
        self.stop()
        if self.imageView.superview.isNil {
            self.view.addSubview(self.imageView)
        }

        self.imageView.image = image
        self.imageView.alpha = 1.0

        self.didShowImage?()
        self.preloadData { progress in
            print(progress)
            if progress < 100 {
                self.swipeLabel.setText("Uploading: %\(progress)")
            } else {
                self.hideSwipeLabel()
            }
            self.view.layoutNow()
        }.mainSink().store(in: &self.cancellables)
    }

    func reset() {
        self.currentPosition = .front
        self.imageView.image = nil
        self.imageView.transform = .identity

        self.imageView.removeFromSuperview()
        self.begin()

        self.previewFile?.cancel()
        self.previewFile?.clearCachedDataInBackground()

        self.canSwipeToPost = false

        self.file?.cancel()
        self.previewFile?.clearCachedDataInBackground()

        self.swipeLabel.alpha = 0.0
        self.swipeLabel.transform = CGAffineTransform(translationX: 0.0, y: 200)

        self.captionTextView.text = nil
        self.captionTextView.resignFirstResponder()

        self.finishLabel.alpha = 0

        self.datePicker.date = Date()

        self.datePicker.publisher(for: \.date).mainSink { _ in
            self.view.layoutNow()
        }.store(in: &self.cancellables)

        self.view.layoutNow()
    }

    func finishSaving() {
        self.imageView.alpha = 0

        self.finishLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        self.finishLabel.alpha = 0.0
        self.view.layoutNow()
        
        UIView.animate(withDuration: 2.5, delay: 0.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: .curveEaseIn, animations: {
            self.finishLabel.transform = .identity
            self.finishLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: Theme.animationDuration, delay: 0.0, options: []) {
                self.finishLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.finishLabel.alpha = 0.0
            } completion: { _ in
                self.didTapExit?()
                self.reset()
            }
        }
    }

    func hideSwipeLabel() {
        self.swipeLabel.setText("Uploading: %100")
        self.view.layoutNow()
        UIView.animate(withDuration: Theme.animationDuration, delay: 1.0, options: []) {
            self.swipeLabel.alpha = 0
        } completion: { _ in
            self.showSwipeLabel()
        }
    }

    func showSwipeLabel() {
        self.swipeLabel.setText("Swipe up to post")
        self.swipeLabel.transform = CGAffineTransform(translationX: 0.0, y: 50)

        self.view.layoutNow()
        UIView.animate(withDuration: 1, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: .curveEaseIn, animations: {
            self.swipeLabel.transform = .identity
            self.swipeLabel.alpha = 1.0
        }) { _ in
            self.canSwipeToPost = true
        }
    }
}

extension PostCreationViewController: UITextViewDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
