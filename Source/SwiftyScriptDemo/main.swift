//
//  main.swift
//  SwiftScript
//
//  Created by Yuu Zheng on 2019/6/24.
//
import Foundation
import SwiftyScript

// Use String
"echo Hello World".runAsBash(autoPrintLog: true)

// Run Other Progress
"""
echo 'import Foundation\nprint("Hello World From Swift")' > main.swift
swiftc main.swift
./main
""".runAsBash(autoPrintLog: true)

// Get Infomation From Command
let swiftTarget = "swift --version".runAsBash().log.components(separatedBy: "\n")[1]
print("\(swiftTarget)")

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
.runAsBash(name: "Build Project", autoPrintLog: true, autoPrintInfo: true)

// Use Task
Task.init(language: .Bash, content: "echo Bye", autoPrintLog: true).run()
