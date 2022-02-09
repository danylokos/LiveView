//
//  LiveViewDemo.swift
//  LiveViewKit
//
//  Created by Danylo Kostyshyn on 25.01.2022.
//

import Foundation

public func image(from data: UnsafePointer<UInt8>, size: (Int, Int)) -> CGImage? {
    defer {
        data.deallocate()
    }
    let (width, height) = size
    let numComponents = 3
    let colorspace = CGColorSpaceCreateDeviceRGB()
    guard
        let rgbData = CFDataCreate(nil, data, Int(height * width) * numComponents),
        let provider = CGDataProvider(data: rgbData),
        let imageRef = CGImage(
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bitsPerPixel: 8 * numComponents,
            bytesPerRow: Int(width) * numComponents,
            space: colorspace,
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }
    return imageRef
}
