//
//  SplashViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/20/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import StoreKit
import Localization

class SplashViewController: FullScreenViewController, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .fade
    }
    
    /// A view to blur out the emotions collection view.
    let blurView = BlurView()
    private lazy var emotionCollectionView = EmotionCircleCollectionView(cellDiameter: 80)

    let loadingView = AnimationView.with(animation: .loading)
    
    private let emotionNameLabel = ThemeLabel(font: .smallBold)
    private let label = ThemeLabel(font: .small)

    #warning("Remove test")
    let textView = TextView(font: .regular, textColor: .T1)
    
    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.emotionCollectionView)
        self.view.addSubview(self.blurView)
        
        self.view.addSubview(self.emotionNameLabel)
        self.view.addSubview(self.label)

        self.view.addSubview(self.loadingView)
        self.loadingView.contentMode = .scaleAspectFit
        self.loadingView.loopMode = .loop

        self.view.addSubview(self.textView)
        self.textView.textContainer.lineBreakMode = .byTruncatingTail
        self.textView.textAlignment = .left
        self.textView.text = Lorem.paragraphs(nbParagraphs: 5) + "😀😢👨‍👨‍👧‍👧" + "END!"
        self.textView.setTextColor(.clear)

        logDebug(self.textView.text)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.emotionCollectionView.expandToSuperviewSize()
        self.blurView.expandToSuperviewSize()
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.label.pinToSafeAreaLeft()
        self.label.pinToSafeArea(.bottom, offset: .noOffset)
        
        self.emotionNameLabel.setSize(withWidth: self.view.width)
        self.emotionNameLabel.pinToSafeAreaLeft()
        self.emotionNameLabel.match(.bottom, to: .top, of: self.label, offset: .negative(.short))

        self.loadingView.size = CGSize(width: 18, height: 18)
        self.loadingView.pinToSafeAreaRight()
        self.loadingView.pinToSafeArea(.bottom, offset: .noOffset)

        self.textView.setSize(withMaxWidth: self.view.width - 40)
        self.textView.centerOnXAndY()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.stopLoadAnimation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.animateInWords()
    }

    var animationTask: Task<Void, Never>?
    func animateInWords() {
        self.animationTask?.cancel()

        self.animationTask = Task {
            await Task.sleep(seconds: 1)

            let nsString = self.textView.attributedText.string as NSString
            var substringRanges: [NSRange] = []
            nsString.enumerateSubstrings(in: NSRange(location: 0, length: nsString.length),
                                         options: .byComposedCharacterSequences) { (substring, substringRange, _, _) in

                // There's no need to animate spaces.
                guard substring != " " else { return }
                substringRanges.append(substringRange)
            }

            let lookAheadCount = 5
            for index in -lookAheadCount..<substringRanges.count {
                guard !Task.isCancelled else { return }

                let updatedText = self.textView.attributedText.mutableCopy() as! NSMutableAttributedString

                let keyPoints: [CGFloat] = [1, 0.9, 0.7, 0.35, 0]

                for i in 0...lookAheadCount {
                    guard let nextRange = substringRanges[safe: index + i] else { continue }

                    let alpha = lerp(CGFloat(i)/CGFloat(lookAheadCount), keyPoints: keyPoints)
                    updatedText.addAttribute(.foregroundColor,
                                             value: ThemeColor.T1.color.withAlphaComponent(alpha),
                                             range: nextRange)

                }

                await withCheckedContinuation { continuation in
                    UIView.transition(with: self.textView,
                                      duration: 0.01,
                                      options: [.transitionCrossDissolve, .curveLinear]) {
                        self.textView.attributedText = updatedText
                    } completion: { completed in
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }

    #warning("remove this")
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        self.textView.setTextColor(.clear)
        self.animateInWords()
    }

    func startLoadAnimation() {
        self.loadingView.play()

        Task { [weak self] in
            guard let `self` = self else { return }
            await Task.sleep(seconds: 0.25)
            
            guard !Task.isCancelled else { return }
            
            await self.animateEmotions()
        }.add(to: self.autocancelTaskPool)
    }

    private func animateEmotions() async {
        guard !Task.isCancelled else { return }
        
        guard let emotion = Emotion.allCases.randomElement() else { return }

        await UIView.awaitAnimation(with: .fast, animations: {
            self.label.alpha = 0
            self.emotionNameLabel.alpha = 0
        })
        
        self.label.setText(emotion.definition)
        self.label.textColor = emotion.color
        
        self.emotionNameLabel.setText(emotion.description.capitalized)
        self.emotionNameLabel.textColor = emotion.color
    
        self.view.setNeedsLayout()
        
        await UIView.awaitAnimation(with: .fast, delay: 0.1, animations: {
            self.emotionNameLabel.alpha = 0.8
            self.label.alpha = 0.6
        })

        let emotionsCounts = [emotion : 4]
        self.emotionCollectionView.setEmotionsCounts(emotionsCounts, animated: true)

        await Task.sleep(seconds: 5)

        Task { [weak self] in
            await self?.animateEmotions()
        }.add(to: self.autocancelTaskPool)
    }

    func stopLoadAnimation() {
        self.loadingView.stop()
        self.autocancelTaskPool.cancelAndRemoveAll()
    }
}
