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

    static var Bash = Language.init(launchPath: "/bin/bash", environment: [
        "PATH": String.init(utf8String: getenv("PATH")) ?? "/usr/local/bin:/usr/bin:/bin:/usr/sbin",
        "HOME": String.init(utf8String: getenv("HOME")) ?? "/root"

    ])
    static var Ksh = Language.init(launchPath: "/bin/ksh", environment: [
        "PATH": String.init(utf8String: getenv("PATH")) ?? "/usr/local/bin:/usr/bin:/bin:/usr/sbin",
        "HOME": String.init(utf8String: getenv("HOME")) ?? "/root",
    ])

}
