//  Copyright (c) 2015 Venture Media Labs. All rights reserved.

import UIKit

/**
 A UIView that displays equalizer bars.
 */
public class VMEqualizerView: UIView {
    let decay: Float = 0.1

    /// The sample rate of the audio data
    var sampleRate: Float = 44100

    /// The maximum frequency to display
    let minFrequency: Float = 20

    /// The minimum frequency to display
    let maxFrequency: Float = 8000

    /// The minimum decibel value to display
    var decibelGround: Double = -100 {
        didSet {
            setNeedsDisplay()
        }
    }

    @IBInspectable var barColor: UIColor = UIColor.blueColor()

    private(set) internal var samples: UnsafePointer<Float> = UnsafePointer<Float>()
    private(set) internal var samplesCount: Int = 0

    func setSamples(samples: UnsafePointer<Float>, count: Int) {
        self.samples = samples
        samplesCount = count
        setNeedsDisplay()
    }

    override public func drawRect(rect: CGRect) {
        let fs = sampleRate / Float(samplesCount)

        let context = UIGraphicsGetCurrentContext()
        let barBounds = bounds

        barColor.setFill()
        var barRect = CGRect()
        barRect.origin.x = barBounds.minX
        barRect.size.width = barBounds.width / CGFloat(samplesCount)

        for var sampleIndex = 0; sampleIndex < samplesCount; sampleIndex += 1 {
            let f0 = Float(sampleIndex) * fs
            let f1 = Float(sampleIndex + 1) * fs

            let minX = xForFrequencyMel(f0)
            let maxX = xForFrequencyMel(f1)

            let dbValue = 10 * log10(Double(samples[sampleIndex]) + DBL_EPSILON)
            var value = (dbValue - decibelGround) / -decibelGround
            if value < 0 {
                value = 0
            }

            barRect.size.height = CGFloat(value) * barBounds.height
            barRect.size.width = maxX - minX
            barRect.origin.y = barBounds.maxY - barRect.height
            barRect.origin.x = minX

            CGContextFillRect(context, barRect)

        }
    }

    func xForFrequencyMel(f: Float) -> CGFloat {
        if f < minFrequency {
            return bounds.width
        }
        if f >= maxFrequency {
            return 0
        }

        let minM = 2595.0 * log10(1 + minFrequency/700.0)
        let maxM = 2595.0 * log10(1 + maxFrequency/700.0)
        let m = 2595.0 * log10(1 + f/700.0)
        return bounds.width * (1 - CGFloat(m - minM) / CGFloat(maxM - minM))
    }

    func xForFrequencyLinear(f: Float) -> CGFloat {
        if f < minFrequency {
            return bounds.width
        }
        if f >= maxFrequency {
            return 0
        }
        return bounds.width * (1 - CGFloat(f - minFrequency) / CGFloat(maxFrequency - minFrequency))
    }
}
