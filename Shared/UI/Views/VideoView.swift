//
//  VideoView.swift
//  Ours
//
//  Created by Benji Dodgson on 5/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation

class VideoView: View {

    enum Repeat {
        case once
        case loop
    }

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    private var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get {
            self.playerLayer.player
        }
        set {
            self.playerLayer.player = newValue
        }
    }

    override var contentMode: UIView.ContentMode {
        didSet {
            switch self.contentMode {
            case .scaleAspectFit:
                self.playerLayer.videoGravity = .resizeAspect
            case .scaleAspectFill:
                self.playerLayer.videoGravity = .resizeAspectFill
            default:
                self.playerLayer.videoGravity = .resize
            }
        }
    }

    var `repeat`: Repeat = .once

    var data: Data? {
        didSet {
            guard let data = self.data else {
                self.teardown()
                return
            }

            let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("ours_post_video.mp4")

            do {
                try data.write(to: cacheURL, options: .atomicWrite)
            } catch let err {
                print("Failed with error: \(err)")
            }

            self.setup(url: cacheURL)
        }
    }

    var asset: AVAsset? {
        didSet {
            guard let asset = self.asset else {
                self.teardown()
                return
            }
            self.setup(asset: asset)
        }
    }

    deinit {
        self.teardown()
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setup(url: URL) {
        self.player = AVPlayer(playerItem: AVPlayerItem(url: url))
        self.setup()
    }

    private func setup(asset: AVAsset) {
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        self.setup()
    }

    func setup() {
        self.player?.currentItem?.addObserver(self,
                                              forKeyPath: "status",
                                              options: [.old, .new],
                                              context: nil)

        self.player?.addObserver(self, forKeyPath: "rate", options: [.old, .new], context: nil)


        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.itemDidPlayToEndTime(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: self.player?.currentItem)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.itemFailedToPlayToEndTime(_:)),
                                               name: .AVPlayerItemFailedToPlayToEndTime,
                                               object: self.player?.currentItem)
    }

    func teardown() {
        self.player?.pause()

        self.player?.currentItem?.removeObserver(self, forKeyPath: "status")

        self.player?.removeObserver(self, forKeyPath: "rate")

        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: self.player?.currentItem)

        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemFailedToPlayToEndTime,
                                                  object: self.player?.currentItem)

        self.player = nil
    }

    func replay() {
        self.player?.seek(to: .zero)
        self.player?.play()
    }

    @objc func itemDidPlayToEndTime(_ notification: NSNotification) {
        guard self.repeat == .loop else {
            return
        }
        
        self.replay()
    }

    @objc func itemFailedToPlayToEndTime(_ notification: NSNotification) {
        self.teardown()
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let status = self.player?.currentItem?.status, status == .failed {
            self.teardown()
        }

        if keyPath == "rate",
           let player = self.player,
           player.rate == 0,
           let item = player.currentItem,
           !item.isPlaybackBufferEmpty,
           CMTimeGetSeconds(item.duration) != CMTimeGetSeconds(player.currentTime()) {
            self.player?.play()
        }
    }
}
