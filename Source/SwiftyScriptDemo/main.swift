//
//  main.swift
//  SwiftScript
//
//  Created by Yuu Zheng on 2019/6/24.
//
import Foundation
import SwiftyScript

ScriptTask.DefaultValue.printTaskInfo = false

// Use String
"echo Hello World".fastRunAsScript(language: .Bash)

// Run Other Progress
"""
echo 'import Foundation\nprint("Hello World From Swift")' > main.swift
swiftc main.swift
./main
""".runAsScript(language: .Bash)

// Get Infomation From Command
let (result, log) = "swift --version".runAsScript(language: .Bash, output: .log)
if result == .success {
    let swiftTarget = log.components(separatedBy: "\n")[1]
    print("\(swiftTarget)")
} else {
    print(result)
}


// Build Project
let projects: [(name: String, buildTime: TimeInterval)] = [
    ("Project A", 2.0),
    ("Project B", 0.5),
    ("Project C", 0.1),
    ("Project D", 0.2),
    ("Project E", 2.5),
]

[
    "echo 'Building...'",
    projects.map { (name, time) in
    """
    echo '> Building \(name)...'
    echo 'runing xcbuild...'
    # do some job here
    sleep \(time)
    """
    }.joinedScript(),
    "echo 'Done.'",
]
.joinedScript()
.runAsScript(language: .Bash, name: "Build Project", printTaskInfo: true)

// Use Task
ScriptTask.init(language: .Bash, content: "echo Bye").run()

