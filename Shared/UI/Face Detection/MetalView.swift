//
//  MetalView.swift
//  Jibber
//
//  Created by Martin Young on 4/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import MetalKit

/// A subclass of MTKView that keeps its own context and command queue for performance.
/// IsOpaque is false by default.
class MetalView: MTKView {

    var context: CIContext
    var commandQueue: MTLCommandQueue

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        let dev = device ?? MTLCreateSystemDefaultDevice()!
        self.context = CIContext(mtlDevice: dev, options: [.cacheIntermediates : false])
        self.commandQueue = dev.makeCommandQueue()!

        super.init(frame: frameRect, device: dev)

        self.isPaused = true
        self.enableSetNeedsDisplay = false
        self.framebufferOnly = false
        self.isOpaque = false
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
