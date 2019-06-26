//
//  TaskSupport.swift
//  SwiftyScript
//
//  Created by enum on 2019/6/24.
//

import Foundation

public struct Language {
    
    public var launchPath: String
    public var environment: [String: String]? = nil
    
    public init(launchPath: String, environment: [String: String]? = nil) {
        self.launchPath = launchPath
        self.environment = environment
    }
    
}

public extension Language {
    
    static var Bash = Language.init(launchPath: "/bin/bash")
    
}
