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

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.emotionCollectionView)
        self.view.addSubview(self.blurView)

        self.view.addSubview(self.loadingView)
        self.loadingView.contentMode = .scaleAspectFit
        self.loadingView.loopMode = .loop
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.emotionCollectionView.expandToSuperviewSize()
        self.blurView.expandToSuperviewSize()

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
