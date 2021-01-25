//
//  MesasgeInputAccessoryView+Panning.swift
//  Benji
//
//  Created by Benji Dodgson on 6/6/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension InputAccessoryView: UIGestureRecognizerDelegate {

    func handle(pan: UIPanGestureRecognizer) {

        let object = SendableObject(kind: self.currentMessageKind, context: self.currentContext, previousMessage: self.editableMessage)

        guard object.isSendable else { return }

        let currentLocation = pan.location(in: nil)
        let startingPoint: CGPoint

        if let point = self.interactiveStartingPoint {
            startingPoint = point
        } else {
            // Initial location
            startingPoint = pan.location(in: nil)
            self.interactiveStartingPoint = startingPoint
        }
        let totalOffset: CGFloat = self.height
        var diff = (startingPoint.y - currentLocation.y)
        diff -= totalOffset
        var progress = diff / 100
        progress = clamp(progress, 0.0, 1.0)

        switch pan.state {
        case .possible:
            break
        case .began:
            self.previewView = PreviewMessageView()
            self.previewView?.set(backgroundColor: self.currentContext.color)
            self.previewView?.messageKind = self.currentMessageKind
            self.previewView?.backgroundView.alpha = 0.0
            self.addSubview(self.previewView!)
            self.previewView?.frame = self.inputContainerView.frame
            self.previewView?.layoutNow()
            let top = self.top - totalOffset

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
                                                                self.attachmentView.alpha = 0 
                                                                self.expandingTextView.alpha = 0
                                                                self.previewView?.backgroundView.alpha = 1
                                            })

                                            UIView.addKeyframe(withRelativeStartTime: 0,
                                                               relativeDuration: 1,
                                                               animations: {
                                                                self.previewView?.top = top
                                                                self.setNeedsLayout()
                                            })

                }) { (completed) in }
            }

            self.previewAnimator?.addCompletion({ (position) in
                if position == .end {
                    self.delegate.inputAccessory(self, didConfirm: object)
                    self.reset()
                    self.previewView?.removeFromSuperview()
                }
                if position == .start {
                    self.previewView?.removeFromSuperview()
                }

                self.selectionFeedback.impactOccurred()
                self.interactiveStartingPoint = nil
            })

            self.previewAnimator?.pauseAnimation()

        case .changed:
            if let preview = self.previewView {
                let translation = pan.translation(in: preview)
                preview.x = self.x + translation.x
                self.previewAnimator?.fractionComplete = (translation.y * -1) / 100
            }
        case .ended:
            self.previewAnimator?.isReversed = progress <= 0.02
            self.previewAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        case .cancelled:
            self.previewAnimator?.finishAnimation(at: .end)
        case .failed:
            self.previewAnimator?.finishAnimation(at: .end)
        @unknown default:
            break
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer {
            return self.expandingTextView.isFirstResponder
        }

        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if gestureRecognizer is UIPanGestureRecognizer {
            return false
        }

        return true
    }
}

