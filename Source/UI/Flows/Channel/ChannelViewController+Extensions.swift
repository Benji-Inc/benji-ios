//
//  ChannelViewController+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 7/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension ChannelViewController: KeyboardObservable, UIGestureRecognizerDelegate {

    func handleKeyboard(frame: CGRect, with animationDuration: TimeInterval, timingCurve: UIView.AnimationCurve) {
        guard !self.maintainPositionOnKeyboardFrameChanged else { return }

        if let indexPath = self.indexPathForEditing {
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        } else {
            self.collectionView.scrollToEnd()
        }
    }
    
    func handle(pan: UIPanGestureRecognizer) {
        guard let text = self.messageInputAccessoryView.expandingTextView.text, !text.isEmpty else { return }

        let currentLocation = pan.location(in: self.view)
        let startingPoint: CGPoint

        if let point = self.interactiveStartingPoint {
            startingPoint = point
        } else {
            // Initial location
            startingPoint = pan.location(in: nil)
            self.interactiveStartingPoint = startingPoint
        }
        let totalOffset = self.messageInputAccessoryView.height + 10
        var diff = (startingPoint.y - currentLocation.y)
        diff -= totalOffset
        var progress = diff / 100
        progress = clamp(progress, 0.0, 1.0)

        switch pan.state {
        case .possible:
            break
        case .began:
            self.previewView = PreviewMessageView()
            self.previewView?.set(backgroundColor: self.messageInputAccessoryView.messageContext.color)
            self.previewView?.textView.text = text
            self.previewView?.backgroundView.alpha = 0.0
            self.messageInputAccessoryView.addSubview(self.previewView!)
            self.previewView?.frame = self.messageInputAccessoryView.inputContainerView.frame
            self.previewView?.layoutNow()
            let top = self.messageInputAccessoryView.top - totalOffset

            self.previewAnimator = UIViewPropertyAnimator(duration: Theme.animationDuration,
                                                          curve: .easeInOut,
                                                          animations: nil)
            self.previewAnimator?.addAnimations {
                UIView.animateKeyframes(withDuration: 0,
                                        delay: 0,
                                        animations: {
                                            UIView.addKeyframe(withRelativeStartTime: 0,
                                                               relativeDuration: 0.3,
                                                               animations: {
                                                                self.messageInputAccessoryView.expandingTextView.alpha = 0
                                                                self.previewView?.backgroundView.alpha = 1
                                            })

                                            UIView.addKeyframe(withRelativeStartTime: 0,
                                                               relativeDuration: 1,
                                                               animations: {
                                                                self.previewView?.top = top
                                                                self.view.setNeedsLayout()
                                            })

                }) { (completed) in }
            }

            self.previewAnimator?.addCompletion({ (position) in
                if position == .end {
                    if let updatedMessage = self.messageInputAccessoryView.editableMessage {
                        self.update(message: updatedMessage, text: text)
                    } else {
                        self.send(message: text,
                                  context: self.messageInputAccessoryView.messageContext,
                                  attributes: ["status": MessageStatus.sent.rawValue])
                    }
                    self.messageInputAccessoryView.editableMessage = nil
                    self.previewView?.removeFromSuperview()
                }
                if position == .start {
                    self.previewView?.removeFromSuperview()
                }
            })

            self.previewAnimator?.pauseAnimation()

        case .changed:
            if let preview = self.previewView {
                let translation = pan.translation(in: preview)
                preview.x = self.messageInputAccessoryView.x + translation.x
                self.previewAnimator?.fractionComplete = (translation.y * -1) / 100
            }
        case .ended:
            self.previewAnimator?.isReversed = progress <= 0.5
            self.previewAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        case .cancelled:
            self.previewAnimator?.finishAnimation(at: .end)
        case .failed:
            self.previewAnimator?.finishAnimation(at: .end)
        @unknown default:
            break
        }
    }
}
