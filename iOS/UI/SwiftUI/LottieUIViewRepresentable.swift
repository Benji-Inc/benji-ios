//
//  LottieView.swift
//  Jibber
//
//  Created by Martin Young on 2/17/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import SwiftUI
import Lottie

struct LottieUIViewRepresentable: UIViewRepresentable {

    enum ReadingState {
        case notReading
        case reading
        case finishedReading
    }

    @Binding var readingState: ReadingState

    func makeUIView(context: UIViewRepresentableContext<LottieUIViewRepresentable>) -> AnimationView {
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFit

        let animation = Animation.named("visibility")
        animationView.animation = animation

        // TODO: Make this configurable
        let keypath = AnimationKeypath(keys: ["**", "Color"])
        let colorProvider = ColorValueProvider(UIColor.green.lottieColorValue)
        animationView.setValueProvider(colorProvider, keypath: keypath)

        // TODO: Make this configurable
        animationView.animationSpeed = 0.1
        animationView.loopMode = .playOnce
        animationView.currentProgress = 1

        return animationView
    }

    func updateUIView(_ uiView: AnimationView, context: Context) {
        if self.readingState == .reading{
            if !uiView.isAnimationPlaying && uiView.currentProgress > 0 {
                logDebug("calling play on \(uiView)")
                uiView.play(fromProgress: 1, toProgress: 0, loopMode: .playOnce)
            }
        } else if self.readingState == .finishedReading {
            uiView.stop()
            uiView.currentProgress = 0
        } else if self.readingState == .notReading {
            uiView.stop()
            uiView.currentProgress = 1
        }
    }
}
