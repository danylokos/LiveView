//
//  LiveViewDemo.swift
//  LiveViewKit
//
//  Created by Danylo Kostyshyn on 25.01.2022.
//

import Foundation

public typealias Callback = @convention(c) (
    UnsafeMutablePointer<CChar>?
) -> Void

// https://vmanot.com/context-capturing-c-function-pointers-in-swift
public func cFunction(_ block: (@escaping @convention(block) (UnsafeMutablePointer<CChar>?) -> ()))
    -> (@convention(c) (UnsafeMutablePointer<CChar>?) -> ()) {
    return unsafeBitCast(
        imp_implementationWithBlock(block),
        to: (@convention(c) (UnsafeMutablePointer<CChar>?) -> ()).self
    )
}
