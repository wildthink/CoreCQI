//
//  File.swift
//  
//
//  Created by Jason Jobe on 9/14/20.
//

import Foundation
import Runtime

extension URL: DefaultConstructor {
    public init() {
        self = URL(string: "https://example.com")!
    }
}
