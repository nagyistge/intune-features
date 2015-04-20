//  Copyright (c) 2014 Venture Media Labs. All rights reserved.

import UIKit

/**
  A UIView that displays waveform samples. It uses RMS (root mean square) to combine multiple samples into an
  individual pixel.
*/
public class VMWaveformView: UIScrollView {
    @IBInspectable var lineColor: UIColor?
    @IBInspectable var markerColor: UIColor?

    var lineWidth: CGFloat = 1.0

    private var samples: UnsafePointer<Double> = nil
    private var samplesCount: Int = 0
    private var markIndex: Int = -1

    var sampleRate: Double = 44100

    var startFrame: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    private var endFrame: Int {
        get {
            return startFrame + Int(visibleDuration * Double(sampleRate))
        }
    }

    var duration: NSTimeInterval {
        get {
            return NSTimeInterval(samplesCount) / sampleRate
        }
    }

    var visibleDuration: NSTimeInterval = 5 {
        didSet {
            setNeedsLayout()
        }
    }

    var samplesPerPoint: CGFloat {
        get {
            return CGFloat(endFrame - startFrame) / bounds.size.width
        }
    }

    public func setSamples(samples: UnsafePointer<Double>, count: Int) {
        self.samples = samples
        samplesCount = count
        setNeedsLayout()
    }

    public func mark(#time: NSTimeInterval) {
        markIndex = Int(time * sampleRate)
        setNeedsDisplay()
    }

    override public func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        backgroundColor?.setFill()
        CGContextFillRect(context, rect)

        lineColor?.setFill()
        lineColor?.setStroke()
        CGContextSetLineWidth(context, lineWidth)

        let path = createPath()
        CGContextAddPath(context, path)
        CGContextFillPath(context)

        CGContextSaveGState(context)
        CGContextTranslateCTM(context, 0, bounds.size.height)
        CGContextScaleCTM(context, 1, -1)
        CGContextAddPath(context, path)
        CGContextFillPath(context)
        CGContextRestoreGState(context)

        markerColor?.setFill()
        let x = self.bounds.width * CGFloat(markIndex - startFrame) / CGFloat(endFrame - startFrame)
        CGContextFillRect(context, CGRect(x: x - 0.5, y: 0, width: 1, height: self.bounds.height))
    }

    override public func layoutSubviews() {
        contentInset.top = 0
        contentSize.height = bounds.height
        contentSize.width = CGFloat(samplesCount) / samplesPerPoint
        startFrame = max(0, Int(samplesPerPoint * bounds.minX))
        setNeedsDisplay()
    }

    private func createPath() -> CGPathRef {
        let height = bounds.size.height
        let pixelSize = contentScaleFactor
        let samplesPerPixel = Int(ceil(samplesPerPoint * pixelSize))

        var point = CGPointMake(bounds.minX, height/2);
        
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, point.x, point.y)
        
        for var sampleIndex = startFrame; sampleIndex < samplesCount && sampleIndex < endFrame; sampleIndex += samplesPerPixel {
            // Get the RMS value for the current pixel
            var value: Double = 0.0
            let size = vDSP_Length(min(samplesPerPixel, samplesCount - sampleIndex))
            vDSP_rmsqvD(samples + sampleIndex, 1, &value, size)

            point.x += pixelSize;
            point.y = height/2 - CGFloat(value) * height/2;
            CGPathAddLineToPoint(path, nil, point.x, point.y)
        }
        CGPathAddLineToPoint(path, nil, point.x, height/2)
        CGPathCloseSubpath(path)
        return path
    }
}
