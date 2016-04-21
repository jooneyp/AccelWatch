//
//  ViewController.swift
//  AccelWatch
//
//  Created by jooneyp on 2016. 4. 19..
//  Copyright © 2016년 jooneyp. All rights reserved.
//

import UIKit
import WatchConnectivity
import CoreData

class ViewController: UIViewController, WCSessionDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var mainTableView: UITableView!
    var tableData = [String]()
    var secondData = [String]()
    var session: WCSession!
    
    var documentUbi: MyDocument?
    var documentLocal: MyDocument?
    var documentURL: NSURL?
    var ubiquityURL: NSURL?
    var metaDataQuery: NSMetadataQuery?
    
    var currentTime: String!
    
//    var document: MyDocument?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self;
            session.activateSession()
        }
        self.mainTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        //handle received message
        let value = message["accData"] as! NSArray
        let CSVData = dataToCSV(value)
        
        // Generate timestamp
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd_HH:mm:ss"
        let currentTime = formatter.stringFromDate(date)
        
        let filemgr = NSFileManager.defaultManager()
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let dataFilePath = dirPaths[0].stringByAppendingString("/" + currentTime + ".csv")
        
        documentURL = NSURL(fileURLWithPath: dataFilePath)
        documentLocal = MyDocument(fileURL: documentURL!)
        documentLocal!.csvData = CSVData
        
        ubiquityURL = filemgr.URLForUbiquityContainerIdentifier(nil)!.URLByAppendingPathComponent("Documents").URLByAppendingPathComponent(currentTime + ".csv")
        documentUbi = MyDocument(fileURL: ubiquityURL!)
        documentUbi!.csvData = CSVData
        
        if !filemgr.fileExistsAtPath(dataFilePath) {
            documentUbi?.saveToURL(ubiquityURL!,
                                forSaveOperation: .ForCreating,
                                completionHandler: {(success: Bool) -> Void in
                                    if success {
                                        print("iCloud create OK")
                                    } else {
                                        print("iCloud create failed")
                                    }
            })
            documentLocal?.saveToURL(documentURL!,
                                forSaveOperation: .ForCreating,
                                completionHandler: {(success: Bool) -> Void in
                                    if success {
                                        print("Local file create OK")
                                    } else {
                                        print("Local file create failed")
                                    }
            })
        } else {
            print("File Exists ERROR!")
        }
        
        let secondStart : Float = NSString(string: value[0].firstObject as! String).floatValue
        let secondEnd : Float = NSString(string: value[0].lastObject as! String).floatValue
        let dataSize = (secondEnd - secondStart) * 2.534
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableData.append(currentTime)
            self.secondData.append(String(format: "%.2f ~ %.2f", secondStart, secondEnd) + "secs / " + String(format: "%.2f", dataSize) + "KB")
            self.mainTableView.reloadData()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return tableData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
        cell.textLabel!.text = tableData[indexPath.row]
        cell.detailTextLabel!.text = secondData[indexPath.row]
        return cell
    }
    
    func dataToCSV(input: NSArray) -> String {
        var joinedData = ""
        
        for i in 0 ..< 4 {
            joinedData += input[i].componentsJoinedByString(",")
            joinedData += "\n"
        }
        
        let strings = joinedData.componentsSeparatedByString("\n").map { (string) -> [String] in string.componentsSeparatedByString(",")
        }
        
        let tData = transpose(strings)
        var transposedData = "time,X,Y,Z\n"
        
        for i in 0 ..< tData.count {
            for j in 0 ..< tData[i].count {
                transposedData += String(tData[i][j])
                if j < 3 {
                    transposedData += String(",")
                }
            }
            transposedData += String("\n")
        }
        return transposedData
    }
    
    func transpose<T>(input: [[T]]) -> [[T]] {
        if input.isEmpty { return [[T]]() }
        let count = input[0].count
        var out = [[T]](count: count, repeatedValue: [T]())
        for outer in input {
            for (index, inner) in outer.enumerate() {
                out[index].append(inner)
            }
        }
        return out
    }
}

class MyDocument: UIDocument {
    var document: MyDocument?
    var documentURL: NSURL?
    var ubiquityURL: NSURL?
    var metaDataQuery: NSMetadataQuery?
    var csvData: String?
    
    override func contentsForType(typeName: String) throws -> AnyObject {
        if let content = csvData {
            let length = content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            return NSData(bytes: content, length: length)
        } else {
            return NSData()
        }
    }
}