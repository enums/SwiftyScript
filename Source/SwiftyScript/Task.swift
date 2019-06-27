//
//  Task.swift
//  SwiftScript
//
//  Created by Yuu Zheng on 2019/6/24.
//

import Foundation
import Rainbow

public extension Task {

    enum ErrorType {
        case alreadyRunning
        case workspaceLocked
        case createFileFailed
        case openLogFailed
    }

    enum Result {
        case error(ErrorType)
        case failed(Int)
        case success
    }

    enum Output {
        case log
        case console
    }

}

public func ==(l: Task.Result, r: Task.Result) -> Bool {
    switch (l, r) {
    case (.success, .success): return true
    case (.failed(let l), .failed(let r)): return l == r
    case (.error(let l), .error(let r)): return l == r
    default: return false
    }
}

public class Task {

    public struct DefaultValue {
        static public var output = Output.console
        static public var name = "Default"
        static public var workspace = "/tmp/SwiftScript"
        static public var printTaskInfo = true
        static public var removeLastEmptyLineWhenReadingLog = true
    }

    public var language: Language
    public var output: Output
    private(set) public var name: String
    private(set) public var workspace: String
    public var content: String
    public var printTaskInfo: Bool
    public var configure: ((String) -> String)?

    public var environment = [String : String]()

    private(set) public var isRunning = false
    private(set) public var startDate: Date? = nil
    private var process: Process? = nil
    public var pid: Int32? {
        return process?.processIdentifier
    }

    private var fm = FileManager.default
    private var workspacePath: String {
        return "\(workspace)/\(name)"
    }
    private var scriptPath: String {
        return "\(workspacePath)/\(name).sh"
    }
    private var lockPath: String {
        return "\(workspacePath)/.swift_script.lock"
    }
    private var logPath: String {
        return "\(workspacePath)/\(name).txt"
    }

    public init(language: Language,
                output: Output? = nil,
                name: String? = nil,
                workspace: String? = nil,
                content: String,
                printTaskInfo: Bool? = nil,
                configure: ((String) -> String)? = nil) {
        self.language = language
        self.output = output ?? DefaultValue.output
        self.name = name ?? DefaultValue.name
        self.workspace = workspace ?? DefaultValue.workspace
        self.content = content
        self.printTaskInfo = printTaskInfo ?? DefaultValue.printTaskInfo
        self.configure = configure
    }

    deinit {
        killIncludeChildIfNeed()
    }

    @discardableResult
    public func run() -> Result {
        guard !isRunning else {
            printError("Task is already running.".red)
            return .error(.alreadyRunning)
        }

        guard !fm.fileExists(atPath: lockPath) else {
            printError("Workspace is locked.".red)
            return .error(.workspaceLocked)
        }

        func removeItemIfExist(path: String) throws {
            if fm.fileExists(atPath: path) {
                try fm.removeItem(atPath: path)
            }
        }

        isRunning = true
        defer {
            do {
                try removeItemIfExist(path: lockPath)
            } catch {
                printError("Failed to unlock workspace.".red)
            }
            isRunning = false
        }

        do {
            try removeItemIfExist(path: workspacePath)
            try fm.createDirectory(atPath: workspacePath, withIntermediateDirectories: true, attributes: nil)

            guard fm.createFile(atPath: lockPath, contents: nil, attributes: nil) else {
                printError("Workspace is locked.".red)
                return .error(.workspaceLocked)
            }

            guard fm.createFile(atPath: logPath, contents: nil, attributes: nil) else {
                printError("Faile to create log file.".red)
                return .error(.createFileFailed)
            }

            let configuredContent = configure?(content) ?? content
            try configuredContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        } catch {
            printError("Failed to create script file.".red)
            return .error(.createFileFailed)
        }

        // Run
        let process = Process.init()

        switch output {
        case .log:
            guard let logFile = FileHandle.init(forUpdatingAtPath: logPath) else {
                printError("Faile to open log file.".red)
                return .error(.openLogFailed)
            }
            process.standardOutput = logFile
            process.standardError = logFile
        case .console:
            process.standardOutput = FileHandle.standardOutput
            process.standardError = FileHandle.standardError
        }

        process.currentDirectoryPath = workspacePath
        process.launchPath = language.launchPath
        process.arguments = [scriptPath]

        if process.environment == nil {
            process.environment = [:]
        }

        if let env = language.environment {
            env.forEach { process.environment?[$0.key] = $0.value }
        }
        environment.forEach { process.environment?[$0.key] = $0.value }
        process.launch()

        printInfo("Task is running at \(process.processIdentifier)...".cyan)
        self.process = process
        self.startDate = Date.init()

        process.waitUntilExit()

        var duration = "unknow"
        if let startDate = startDate {
            duration = String.init(format: "%.02f", Date.init().timeIntervalSince1970 - startDate.timeIntervalSince1970)
        }

        self.process = nil
        self.startDate = nil

        let status = process.terminationStatus

        // Result
        guard status == 0 else {
            printError("Task failed with code \(status) in \(duration)s!".red)
            return .failed(Int(status))
        }

        printSuccess("Done in \(duration)s!".green)
        return .success
    }

    public func terminate() {
        process?.terminate()
    }

    public func clean() {
        guard !isRunning else {
            return
        }
        try? fm.removeItem(atPath: workspacePath)
    }

    public func readLog() -> String? {
        guard let logFile = FileHandle.init(forReadingAtPath: logPath) else {
            printError("Faile to open log file.".red)
            return nil
        }
        defer { logFile.closeFile() }
        let data = logFile.readDataToEndOfFile()
        var content = String.init(data: data, encoding: .utf8) ?? "Cannot parse the log file."
        if DefaultValue.removeLastEmptyLineWhenReadingLog, content.last == "\n" {
            content.removeLast()
        }
        return content
    }

    private func printInfo(_ msg: String) {
        guard printTaskInfo else { return }
        Utils.printLog(">> [\(name)] \(msg)".cyan)
    }

    private func printError(_ msg: String) {
        guard printTaskInfo else { return }
        Utils.printLog(">> [\(name)] \(msg)".red)
    }

    private func printSuccess(_ msg: String) {
        guard printTaskInfo else { return }
        Utils.printLog(">> [\(name)] \(msg)".green)
    }

    private func killIncludeChildIfNeed() {
        guard let pid = pid else {
            return
        }
        Task.init(language: .Bash,
                  name: ".swift_script_killer_\(name)",
            workspace: workspace,
            content: "pkill -9 -P \(pid)").run()
    }
}

