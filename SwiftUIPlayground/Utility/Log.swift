//
//  Log.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 06/01/26.
//


import Foundation

enum Log {
    enum LogLevel {
        case info
        case warning
        case error
        
        fileprivate var prefix: String {
            switch self {
            case .info:    return "INFO 􀅵"
            case .warning: return "WARN ⚠️"
            case .error:   return "ALERT ❌"
            }
        }
    }
    
    struct Context {
        let file: String
        let function: String
        let line: Int
        var description: String {
            return "\((file as NSString).lastPathComponent):\(line) \(function)"
        }
    }
   
    static func info(_ items: Any..., shouldLogContext: Bool = true, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .info, items: items, shouldLogContext: shouldLogContext, context: context)
    }
    
    static func warning(_ items: Any..., shouldLogContext: Bool = true, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .warning, items: items, shouldLogContext: shouldLogContext, context: context)
    }
    
    static func error(_ items: Any..., shouldLogContext: Bool = true, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .error, items: items, shouldLogContext: shouldLogContext, context: context)
    }

    fileprivate static func handleLog(level: LogLevel, items: Any..., shouldLogContext: Bool, context: Context) {
        let logComponents = ["[\(level.prefix)]"]
        
        var fullString = logComponents.joined(separator: " ")
        if shouldLogContext {
            fullString += " ➜ \(context.description)"
        }
        
        #if DEBUG
        print(fullString, items)
        #endif
    }
}
