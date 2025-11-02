//
//  ProcessMonitor.swift
//  Sentinel
//
//  Monitors process lifecycle to detect when sessions end
//

import Foundation

class ProcessMonitor {
    static let shared = ProcessMonitor()

    private init() {}

    /// Check if a process with the given PID is still running
    func isProcessRunning(pid: Int) -> Bool {
        // Send signal 0 to check if process exists without affecting it
        let result = kill(pid_t(pid), 0)
        return result == 0
    }

    /// Get the working directory of a running process
    func getWorkingDirectory(pid: Int) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/lsof")
        task.arguments = ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse lsof output to extract working directory
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.hasPrefix("n") {
                        return String(line.dropFirst())
                    }
                }
            }
        } catch {
            print("Error getting working directory for PID \(pid): \(error)")
        }

        return nil
    }

    /// Monitor a set of PIDs and return which ones are no longer running
    func checkDeadProcesses(pids: [Int]) -> [Int] {
        return pids.filter { !isProcessRunning(pid: $0) }
    }
}
