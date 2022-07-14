//
//  VideoView.swift
//  Jibber
//
//  Created by Martin Young on 6/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import AVFoundation

class VideoView: BaseView {
    
    var shouldPlay: Bool = false {
        didSet {
            guard let player = self.playerLayer.player else { return }
            
            if self.shouldPlay, !player.isPlaying {
                player.playImmediately(atRate: 1.0 )
            } else if !self.shouldPlay, player.isPlaying {
                player.pause()
            }
        }
    }

    var videoURL: URL? {
        didSet {
            self.updatePlayer(with: self.videoURL)
        }
    }

    let playerLayer = AVPlayerLayer(player: nil)
    /// An object that keeps looping the video back to the beginning.
    private var looper: AVPlayerLooper?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.layer.addSublayer(self.playerLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.playerLayer.frame = self.bounds
    }

    /// A task for loading a video track from a url.
    private var loadTracksTask: Task<Void, Never>?

    private func updatePlayer(with url: URL?) {
        self.loadTracksTask?.cancel()

        guard let videoURL = url else {
            // Stop playback if the url is nil.
            self.playerLayer.player = nil
            return
        }

        self.loadTracksTask = Task {
            // Retrieve the video asset.
            let asset = AVAsset(url: videoURL)
            let tracks = try? await asset.loadTracks(withMediaType: .video)

            guard !Task.isCancelled else { return }

            // We will only have one video track, so the first one is the one we want.
            guard let videoAsset = tracks?.first?.asset else { return }
            
            let videoItem = AVPlayerItem(asset: videoAsset)

            if let player = self.playerLayer.player {
                // No need to create a new player if we already have one. Just update the video.
                player.replaceCurrentItem(with: videoItem)
            } else {
                // If no player exists, create a new one and assign it the downloaded video.
                let player = AVQueuePlayer(items: [videoItem])
                player.automaticallyWaitsToMinimizeStalling = false
                self.playerLayer.player = player
            }
            
            guard let player = self.playerLayer.player as? AVQueuePlayer else { return }
            
            self.looper = AVPlayerLooper(player: player, templateItem: videoItem)
            
            if self.shouldPlay {
                player.playImmediately(atRate: 1.0)
            }
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
}
