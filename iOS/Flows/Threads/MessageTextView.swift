//
//  MessageTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 7/1/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization

class MessageTextView: TextView {

    override func initializeViews() {
        super.initializeViews()
        
        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = true

        self.textContainerInset.left = 0
        self.textContainerInset.right = 0
        self.textContainerInset.top = 0
        self.textContainerInset.bottom = 0
    }

    func setText(with message: Messageable) {
        self.animationTask?.cancel()

        self.setText(message.kind.text)
    }

    // Allows us to interact with links if they exist or pass the touch to the next receiver if they do not
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Location of the tap
        var location = point
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top

        // Find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location,
                                                               in: self.textContainer,
                                                               fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < self.textStorage.length {
            // Check if character is a link and handle normally
            if self.textStorage.attribute(NSAttributedString.Key.link,
                                          at: characterIndex,
                                          effectiveRange: nil) != nil {
                return self
            }
        }

        // Return nil to pass touch to next receiver
        return nil
    }

    var animationTask: Task<Void, Never>?

    func startReadAnimation() async {
        self.animationTask?.cancel()

        self.animationTask = Task {
            let nsString = self.attributedText.string as NSString
            let substringRanges: [NSRange] = nsString.getRangesOfSubstringsSeparatedBySpaces()

            let lookAheadCount = 5
            for index in -lookAheadCount..<substringRanges.count {
                guard !Task.isCancelled else { return }

                let updatedText = self.attributedText.mutableCopy() as! NSMutableAttributedString

                let keyPoints: [CGFloat] = [1, 0.9, 0.7, 0.35, 0]

                for i in 0...lookAheadCount {
                    guard let nextRange = substringRanges[safe: index + i] else { continue }

                    let alpha = lerp(CGFloat(i)/CGFloat(lookAheadCount), keyPoints: keyPoints)
                    updatedText.addAttribute(.foregroundColor,
                                             value: ThemeColor.white.color.withAlphaComponent(alpha),
                                             range: nextRange)

                }

                await withCheckedContinuation { continuation in
                    UIView.transition(with: self,
                                      duration: 0.1,
                                      options: [.transitionCrossDissolve, .curveLinear]) {
                        self.attributedText = updatedText
                    } completion: { completed in
                        continuation.resume(returning: ())
                    }
                }
            }

            self.textColor = ThemeColor.white.color
        }

        await self.animationTask?.value
    }
}
