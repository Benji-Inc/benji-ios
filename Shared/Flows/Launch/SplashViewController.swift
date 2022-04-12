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
    private var emotions: Set<Emotion> = []
    
    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.emotionCollectionView)
//        self.view.addSubview(self.blurView)
        #warning("undo")
        self.emotionCollectionView.backgroundColor = .gray
        
        self.view.addSubview(self.emotionNameLabel)
        self.view.addSubview(self.label)

        self.view.addSubview(self.loadingView)
        self.loadingView.contentMode = .scaleAspectFit
        self.loadingView.loopMode = .loop
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.emotionCollectionView.expandToSuperviewSize()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        

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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.stopLoadAnimation()
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
        
        self.emotionNameLabel.setText(emotion.rawValue.capitalized)
        self.emotionNameLabel.textColor = emotion.color
    
        self.view.setNeedsLayout()
        
        await UIView.awaitAnimation(with: .fast, delay: 0.1, animations: {
            self.emotionNameLabel.alpha = 0.8
            self.label.alpha = 0.6
        })
        
        self.emotions.insert(emotion)
        
//        let items = self.emotions.compactMap { emotion in
//            return EmotionCircleItem(emotion: emotion)
//        }

        var emotionsCounts: [Emotion : Int]
        = [.surprised : 1]

        self.emotionCollectionView.setEmotionsCounts(emotionsCounts)

        await Task.sleep(seconds: 1)

        emotionsCounts
        = [.surprised : 1,
           .avoidance : 1]

        self.emotionCollectionView.setEmotionsCounts(emotionsCounts)

        await Task.sleep(seconds: 1)

        emotionsCounts
        = [.avoidance : 2,
           .surprised : 2,
           .heartbroken : 3]

        self.emotionCollectionView.setEmotionsCounts(emotionsCounts)

        await Task.sleep(seconds: 1)

        emotionsCounts
        = [.surprised : 3,
           .avoidance : 3]

        self.emotionCollectionView.setEmotionsCounts(emotionsCounts)

        await Task.sleep(seconds: 1)

        Task {
            await self.animateEmotions()
        }.add(to: self.autocancelTaskPool)
    }

    func stopLoadAnimation() {
        self.loadingView.stop()
        self.autocancelTaskPool.cancelAndRemoveAll()
    }
}
