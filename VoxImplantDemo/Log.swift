//
//  Log.swift
//  VoxImplantDemo
//
//  Created by Andrey Syvrachev on 17.02.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import UIKit

class Log: NSObject {
    static func info(_ format: String, _ args: CVarArg...) {
        logv(level: "INF", format: format, args: getVaList(args))
    }

    static func warning(_ format: String, _ args: CVarArg...) {
        logv(level: "WRN", format: format, args: getVaList(args))
    }
    
    static func error(_ format: String, _ args: CVarArg...) {
        logv(level: "ERR", format: format, args: getVaList(args))
    }
    
    static func debug(_ format: String, _ args: CVarArg...) {
        logv(level: "DBG", format: format, args: getVaList(args))
    }
    
    static fileprivate func logv(level:String, format: String, args: CVaListPointer){
        
        if let queueName = currentQueueName() {
            NSLogv("DEMO \(level) [\(queueName)] > \(format)", args)
        }else {
            NSLogv("DEMO \(level) > \(format)", args)
        }
    }
    
    static fileprivate func currentQueueName() -> String? {
        let name = __dispatch_queue_get_label(nil)
        return String(cString: name, encoding: .utf8)
    }
}
