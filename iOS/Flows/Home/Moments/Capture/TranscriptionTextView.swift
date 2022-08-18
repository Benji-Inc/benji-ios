//
//  TranscriptTextView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/17/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization
import Speech

class TranscriptionTextView: TextView {

    override func initializeViews() {
        super.initializeViews()
        
        self.setFont(.regular)
        self.textColor = ThemeColor.white.color.withAlphaComponent(0.8)
        
        self.isEditable = true
        self.isScrollEnabled = false
        self.isSelectable = true
        self.textAlignment = .left
        self.alpha = 0
        self.tintColor = ThemeColor.D6.color
        self.returnKeyType = .done
        
        let offset = Theme.ContentOffset.standard.value

        self.textContainerInset.left = offset
        self.textContainerInset.right = offset
        self.textContainerInset.top = offset
        self.textContainerInset.bottom = offset
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Theme.innerCornerRadius
        
        self.backgroundColor = ThemeColor.B0.color.withAlphaComponent(0.4)
    }
    
    func animateSpeech(result: SFSpeechRecognitionResult?) {

        if let result = result {
            self.animationTask?.cancel()
            self.setTextColor(.clear)
            self.alpha = 0
            
            self.setText(result.bestTranscription.formattedString)
            self.textAlignment = .left
                    
            Task {
                async let fadeIn: () = UIView.awaitAnimation(with: .fast, animations: {
                    self.alpha = 1.0
                })
                async let textAnimation: () = self.startAnimation(with: result.bestTranscription.segments)
                let _: [()] = await [fadeIn, textAnimation]
            }
        } else {
            self.setText("No caption")
            UIView.animate(withDuration: Theme.animationDurationFast) {
                self.alpha = 1
            }
        }
        
    }

    var animationTask: Task<Void, Never>?
    
    func startAnimation(with segments: [SFTranscriptionSegment]) async {
        self.animationTask?.cancel()

        self.animationTask = Task {

            let keyPoints: [CGFloat] = [0.8, 0.7, 0.6, 0.35, 0]

            for index in -keyPoints.count..<segments.count {
                guard !Task.isCancelled else { return }

                let updatedText = self.attributedText.mutableCopy() as! NSMutableAttributedString

                for i in 0...keyPoints.count {
                    guard let nextSegment = segments[safe: index + i] else { continue }

                    let alpha = lerp(CGFloat(i)/CGFloat(keyPoints.count), keyPoints: keyPoints)
                    updatedText.addAttribute(.foregroundColor,
                                             value: ThemeColor.white.color.withAlphaComponent(alpha),
                                             range: nextSegment.substringRange)

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

            self.textColor = ThemeColor.white.color.withAlphaComponent(0.8)
        }

        await self.animationTask?.value
    }
}

