//
//  Utils.swift
//  SwiftyScript
//
//  Created by enum on 2019/6/24.
//

import Foundation
import Rainbow

public class Utils {

    static var dateFormatter = { () -> DateFormatter in
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
    func runAsBash(name: String? = nil,
                   workspace: String? = nil,
                   autoPrintLog: Bool? = nil,
                   autoPrintInfo: Bool? = nil,
                   logFormat: String? = nil,
                   logInfoColor: Color? = nil,
                   logSuccessColor: Color? = nil,
                   logErrorColor: Color? = nil,
                   removeLastEmptyLineWhenReadingLog: Bool? = nil,
                   bootstrapProcessor: ((Task) -> String)? = nil,
                   configure: ((String) -> String)? = nil) -> (result: Task.Result, log: String) {
        return runAsScript(language: .Bash,
                           name: name,
                           workspace: workspace,
                           autoPrintLog: autoPrintLog,
                           autoPrintInfo: autoPrintInfo,
                           logFormat: logFormat,
                           logInfoColor: logInfoColor,
                           logSuccessColor: logSuccessColor,
                           logErrorColor: logErrorColor,
                           removeLastEmptyLineWhenReadingLog: removeLastEmptyLineWhenReadingLog,
                           bootstrapProcessor: bootstrapProcessor,
                           configure: configure)
    }

    @discardableResult
    func runAsScript(language: Language,
                     name: String? = nil,
                     workspace: String? = nil,
                     autoPrintLog: Bool? = nil,
                     autoPrintInfo: Bool? = nil,
                     logFormat: String? = nil,
                     logInfoColor: Color? = nil,
                     logSuccessColor: Color? = nil,
                     logErrorColor: Color? = nil,
                     removeLastEmptyLineWhenReadingLog: Bool? = nil,
                     bootstrapProcessor: ((Task) -> String)? = nil,
                     configure: ((String) -> String)? = nil) -> (result: Task.Result, log: String) {
        let task = Task.init(language: language,
                             name: name,
                             workspace: workspace,
                             content: self,
                             autoPrintLog: autoPrintLog,
                             autoPrintInfo: autoPrintInfo,
                             logFormat: logFormat,
                             logInfoColor: logInfoColor,
                             logSuccessColor: logSuccessColor,
                             logErrorColor: logErrorColor,
                             removeLastEmptyLineWhenReadingLog: removeLastEmptyLineWhenReadingLog,
                             bootstrapProcessor: bootstrapProcessor,
                             configure: configure)
        let result = task.run()
        return (result, result == .success ? task.readLog() ?? "" : "")
    }
}

public extension Array where Element == String {
    
    func joinedScript() -> Element {
        return self.joined(separator: "\n")
    }
    
}
