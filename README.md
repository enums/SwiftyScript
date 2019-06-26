# SwiftyScript

Talk to terminal.

# Usage

## 0x01

```swift
// Use String
"echo Hello World".runAsBash()
```

## 0x02

```swift
// Run Other Progress
"""
echo 'import Foundation\nprint("Hello World From Swift")' > main.swift
swiftc main.swift
./main
""".runAsBash()
```

## 0x03

```swift
// Get Infomation From Command
let swiftTarget = "swift --version".runAsBash(printLogToConsole: false).log.components(separatedBy: "\n")[1]
print("\(swiftTarget)")
```

## 0x04

```swift
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
.runAsBash(name: "Build Project", printTaskInfo: true)
```

## 0x05

```swift
// Use Task
Task.init(language: .Bash, content: "echo Bye", printTaskInfo: false).run()
```
