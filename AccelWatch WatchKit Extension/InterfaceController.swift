//
//  InterfaceController.swift
//  AccelWatch WatchKit Extension
//
//  Created by jooneyp on 2016. 4. 19..
//  Copyright © 2016년 jooneyp. All rights reserved.
//

import WatchKit
import CoreMotion
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    @IBOutlet var labelTime: WKInterfaceLabel!
    @IBOutlet var labelStatus: WKInterfaceLabel!
    @IBOutlet var btnSend: WKInterfaceButton!
    @IBOutlet var btnStart: WKInterfaceButton!
    
    let motionManager = CMMotionManager()
    var accDataX = [String]()
    var accDataY = [String]()
    var accDataZ = [String]()
    var timeData = [String]()
    
    var min = 0
    var sec = 0
    var flag = 0
    var stamp = 0.0
    
    var recStatus: Bool!
    var session : WCSession!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
        
        if (WCSession.isSupported()) {
            let session = WCSession.defaultSession()
            session.delegate = self // conforms to WCSessionDelegate
            session.activateSession()
        }
        motionManager.accelerometerUpdateInterval = 0.01
        self.labelStatus.setText(String(format: "Stopped"))
        recStatus = false
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        btnSend.setHidden(true)
    
        if (motionManager.accelerometerAvailable == true) {
            let handler:CMAccelerometerHandler = {(data: CMAccelerometerData?, error: NSError?) -> Void in
                if (self.recStatus == true) {
                    self.stamp += 0.01
                    self.flag += 1
                    self.timeData.append(String(format: "%.2f", self.stamp))
                    self.accDataX.append(String(format: "%.3f", data!.acceleration.x))
                    self.accDataY.append(String(format: "%.3f", data!.acceleration.y))
                    self.accDataZ.append(String(format: "%.3f", data!.acceleration.z))
                    if self.flag % 100 == 0 {
                        self.sec += 1
                        self.labelTime.setText(String(format: "%02d:%02d", self.min, self.sec))
                        if self.sec % 59 == 0 {
                            self.min += 1
                            self.sec = 0
                        } else {
                        }
                    }
                } else {
                }
            }
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: handler)
        }
        else {
            self.labelStatus.setText("N/A")
            btnSend.setHidden(true)
            btnStart.setHidden(true)
        }
        
        if(WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func startBtnTapped() {
        if self.recStatus == false {
            self.recStatus = true
            labelStatus.setText("Recording")
            btnStart.setTitle("Pause")
            btnSend.setHidden(true)
        } else {
            self.recStatus = false
            labelStatus.setText("Paused")
            btnStart.setTitle("Resume")
            btnSend.setHidden(false)
        }
    }
    
    @IBAction func sendBtnTapped() {
        if(WCSession.isSupported()) {
            if self.stamp < 60.0 {
                let appAccData = ["accData":[timeData, accDataX, accDataY, accDataZ]]
                
                session.sendMessage(appAccData, replyHandler: {(reply: [String : AnyObject]) -> Void in
                        print(reply)
                    }, errorHandler: {(error) -> Void in
                        print(error)
                })
            } else {
                var t_timeData: [String] = []
                var t_accDataX: [String] = []
                var t_accDataY: [String] = []
                var t_accDataZ: [String] = []
                for i in 0 ..< (flag / 6000) + 1 {
                    let j = Int(i * 6000)
                    if j+6000 > flag {
                        t_timeData += timeData[j..<flag]
                        t_accDataX += accDataX[j..<flag]
                        t_accDataY += accDataY[j..<flag]
                        t_accDataZ += accDataZ[j..<flag]
                    } else {
                        t_timeData += timeData[j..<j+6000]
                        t_accDataX += accDataX[j..<j+6000]
                        t_accDataY += accDataY[j..<j+6000]
                        t_accDataZ += accDataZ[j..<j+6000]
                    }
                    var appAccData = ["accData":[t_timeData, t_accDataX, t_accDataY, t_accDataZ]]
                    session.sendMessage(appAccData, replyHandler: {(reply: [String : AnyObject]) -> Void in
                        print(reply)
                        }, errorHandler: {(error) -> Void in
                            print(error)
                    })
                    NSThread.sleepForTimeInterval(1)
                    t_timeData.removeAll()
                    t_accDataX.removeAll()
                    t_accDataY.removeAll()
                    t_accDataZ.removeAll()
                    appAccData.removeAll()
                }
            }
        }
        self.timeData.removeAll()
        self.accDataX.removeAll()
        self.accDataY.removeAll()
        self.accDataZ.removeAll()
        labelStatus.setText("Stopped")
        btnStart.setTitle("Start")
        labelTime.setText("00:00")
        btnSend.setHidden(true)
        self.stamp = 0.0
        self.min = 0
        self.sec = 0
        self.flag = 0
        self.recStatus = false
    }

}

extension Array {
    func splitBy(subSize: Int) -> [[Element]] {
        return 0.stride(to: self.count, by: subSize).map { startIndex in
            let endIndex = startIndex.advancedBy(subSize, limit: self.count)
            return Array(self[startIndex ..< endIndex])
        }
    }
}