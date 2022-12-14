//
//  File.swift
//  
//
//  Created by Aaron on 2022/12/12.
//

import Foundation

final class WeakBox<T: AnyObject> {
    weak var weakObject: T?
    init(_ object: T) {
        weakObject = object
    }
}
