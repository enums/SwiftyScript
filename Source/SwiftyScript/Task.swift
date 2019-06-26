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
        static var name = "Default"
        static var workspace = "/tmp/SwiftScript"
        static var autoPrintLog = false
        static var autoPrintInfo = false
        static var logFormat = ">> [%@] %@"
        static var logErrorColor = Color.red
        static var logInfoColor = Color.cyan
        static var logSuccessColor = Color.green
        static var removeLastEmptyLineWhenReadingLog = true
        static var bootstrapProcessor: (Task) -> String = { task in
            if task.autoPrintLog {
                return "bash '\(task.scriptPath)' | tee '\(task.logPath)'"
            } else {
                return "bash '\(task.scriptPath)' > '\(task.logPath)'"
            }
        }
    }

    public var language: Language
    private(set) public var name: String
    private(set) public var workspace: String
    public var content: String
    public var autoPrintLog: Bool
    public var autoPrintInfo: Bool
    public var logFormat: String
    public var logInfoColor: Color
    public var logSuccessColor: Color
    public var logErrorColor: Color
    public var removeLastEmptyLineWhenReadingLog: Bool
    public var configure: ((String) -> String)?
    public var bootstrapProcessor: (Task) -> String
    
    public var environment = [String : String]()

    private(set) public var isRunning = false
    private(set) public var startDate: String? = nil
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
    private var bootstrapPath: String {
        return "\(workspacePath)/._swift_script_bootstrap_\(name).sh"
    }
    private var lockPath: String {
        return "\(workspacePath)/.swift_script.lock"
    }
    private var logPath: String {
        return "\(workspacePath)/\(name).txt"
    }

    public init(language: Language,
                name: String? = nil,
                workspace: String? = nil,
                content: String,
                autoPrintLog: Bool? = nil,
                autoPrintInfo: Bool? = nil,
                logFormat: String? = nil,
                logInfoColor: Color? = nil,
                logSuccessColor: Color? = nil,
                logErrorColor: Color? = nil,
                removeLastEmptyLineWhenReadingLog: Bool? = nil,
                bootstrapProcessor: ((Task) -> String)? = nil,
                configure: ((String) -> String)? = nil) {
        self.language = language
        self.name = name ?? DefaultValue.name
        self.workspace = workspace ?? DefaultValue.workspace
        self.content = content
        self.autoPrintLog = autoPrintLog ?? DefaultValue.autoPrintLog
        self.autoPrintInfo = autoPrintInfo ?? DefaultValue.autoPrintInfo
        self.logFormat = logFormat ?? DefaultValue.logFormat
        self.logInfoColor = logInfoColor ?? DefaultValue.logInfoColor
        self.logSuccessColor = logSuccessColor ?? DefaultValue.logSuccessColor
        self.logErrorColor = logErrorColor ?? DefaultValue.logErrorColor
        self.removeLastEmptyLineWhenReadingLog = removeLastEmptyLineWhenReadingLog ?? DefaultValue.removeLastEmptyLineWhenReadingLog
        self.bootstrapProcessor = bootstrapProcessor ?? DefaultValue.bootstrapProcessor
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
                try removeItemIfExist(path: bootstrapPath)
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

            let configuredContent = configure?(content) ?? content
            try configuredContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)

            let bootstrapContent = bootstrapProcessor(self)
            try bootstrapContent.write(toFile: bootstrapPath, atomically: true, encoding: .utf8)
        } catch {
            printError("Failed to create script file.".red)
            return .error(.createFileFailed)
        }

        // Run
        let process = Process.init()
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        process.currentDirectoryPath = workspacePath
        process.launchPath = language.launchPath
        process.arguments = [bootstrapPath]
        
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
        self.startDate = Utils.dateFormatter.string(from: Date.init())

        process.waitUntilExit()
        self.process = nil
        self.startDate = nil

        let status = process.terminationStatus

        // Result
        guard status == 0 else {
            printError("Task failed with code \(status) !".red)
            return .failed(Int(status))
        }

        printSuccess("Done!".green)
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

    public func readLog(removeLastEmptyLine: Bool? = nil) -> String? {
        guard let logFile = FileHandle.init(forReadingAtPath: logPath) else {
            printError("Faile to open log file.".red)
            return nil
        }
        defer { logFile.closeFile() }
        let data = logFile.readDataToEndOfFile()
        var content = String.init(data: data, encoding: .utf8) ?? "Cannot parse the log file."
        if removeLastEmptyLine ?? DefaultValue.removeLastEmptyLineWhenReadingLog, content.last == "\n" {
            content.removeLast()
        }
        return content
    }

    private func printInfo(_ msg: String) {
        guard autoPrintInfo else {
            return
        }
        Utils.printLog(String.init(format: DefaultValue.logFormat, name, msg).applyingColor(DefaultValue.logInfoColor))
    }

    private func printError(_ msg: String) {
        guard autoPrintInfo else {
            return
        }
        Utils.printLog(String.init(format: DefaultValue.logFormat, name, msg).applyingColor(DefaultValue.logErrorColor))
    }

    private func printSuccess(_ msg: String) {
        guard autoPrintInfo else {
            return
        }
        Utils.printLog(String.init(format: DefaultValue.logFormat, name, msg).applyingColor(DefaultValue.logSuccessColor))
    }

    private func killIncludeChildIfNeed() {
        guard let pid = pid else {
            return
        }
        Task.init(language: .Bash,
                  name: ".swift_script_killer_\(name)",
                  workspace: workspace,
                  content: "pkill -9 -P \(pid)",
                  autoPrintLog: false,
                  autoPrintInfo: false)
        .run()
    }
}
