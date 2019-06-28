//
//  Utils.swift
//  SwiftyScript
//
//  Created by enum on 2019/6/24.
//

import Foundation
import Rainbow

public class Utils {

    static public var dateFormatter = { () -> DateFormatter in
        let that = DateFormatter.init()
        that.timeZone = TimeZone.init(secondsFromGMT: 8 * 3600)
        that.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return that
    }()

    static public func printLog(_ log: String) {
        print("[\(dateFormatter.string(from: Date.init()))] ".blue + "\(log)")
    }
}

public extension String {

    @discardableResult
    func runAsScript(language: Language,
                     output: Task.Output? = nil,
                     name: String? = nil,
                     workspace: String? = nil,
                     printTaskInfo: Bool? = nil,
                     configure: ((String) -> String)? = nil) -> (result: Task.Result, log: String) {
        let task = Task.init(language: language,
                             output: output,
                             name: name,
                             workspace: workspace,
                             content: self,
                             printTaskInfo: printTaskInfo,
                             configure: configure)
        let result = task.run()
        return (result, result == .success ? task.readLog() ?? "" : "")
    }

    @discardableResult
    func fastRunAsScript(language: Language,
                         output: Task.Output? = nil,
                         name: String? = nil,
                         workspace: String? = nil,
                         printTaskInfo: Bool? = nil,
                         configure: ((String) -> String)? = nil) -> (result: Task.Result, log: String) {
        let task = Task.init(language: language,
                             output: output,
                             name: name,
                             workspace: workspace,
                             content: self,
                             printTaskInfo: printTaskInfo,
                             configure: configure)
        let result = task.fastRun()
        return (result, result == .success ? task.readLog() ?? "" : "")
    }
}

public extension Array where Element == String {
    
    func joinedScript() -> Element {
        return self.joined(separator: "\n")
    }
    
}
