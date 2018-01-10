//
//  ViewController.swift
//  BlueToothPeripheral
//
//  Created by Olivier Robin on 30/10/2016.
//  Copyright © 2016 fr.ormaa. All rights reserved.
//

import UIKit
import CoreBluetooth
import UserNotifications
import AudioToolbox
import AVFoundation
import CoreLocation

class MyViewController: UIViewController, BLEPeripheralProtocol, CLLocationManagerDelegate {
    
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var switchPeripheral: UISwitch!

    
    var arr = [Double](repeating: 0.0, count: 8)
    
    let locationManager = CLLocationManager()

    
    var refreshLogs: Timer?
    var ble: BLEPeripheralManager?

    //let uuid = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
    let beacon0 = CLBeaconRegion(proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 102, minor: 38455, identifier: "b0")
    let beacon1 = CLBeaconRegion(proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 47, minor: 37616, identifier: "b1")
    let beacon2 = CLBeaconRegion(proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 105, minor: 57739, identifier: "b2")
    let beacon3 = CLBeaconRegion(proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 104, minor: 50343, identifier: "b3")
    let beacon4 = CLBeaconRegion(proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 103, minor: 45171, identifier: "b4")
    let beacon5 = CLBeaconRegion(proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 101, minor: 59100, identifier: "b5")
    let beacon6 = CLBeaconRegion(proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 30, minor: 38600, identifier: "b6")
    let beacon7 = CLBeaconRegion(proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, major: 106, minor: 12125, identifier: "b7")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BLEPeripheralManager().initLocalBeacon()
        locationManager.delegate = self
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedAlways) {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.startRangingBeacons(in: beacon0)
        locationManager.startRangingBeacons(in: beacon1)
        locationManager.startRangingBeacons(in: beacon2)
        locationManager.startRangingBeacons(in: beacon3)
        locationManager.startRangingBeacons(in: beacon4)
        locationManager.startRangingBeacons(in: beacon5)
        locationManager.startRangingBeacons(in: beacon6)
        locationManager.startRangingBeacons(in: beacon7)
        
        print("MyViewController viewDidLoad")
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        let knownBeacons = beacons.filter{$0.proximity != CLProximity.unknown}
        if (knownBeacons.count > 0) {
            if (String(describing: knownBeacons[0].major) == "102") {
                arr[0] = knownBeacons[0].accuracy
            }
            if (String(describing: knownBeacons[0].major) == "47"){
                arr[1] = knownBeacons[0].accuracy
            }
            if (String(describing: knownBeacons[0].major) == "105"){
                arr[2] = knownBeacons[0].accuracy
            }
            if (String(describing: knownBeacons[0].major) == "104"){
                arr[3] = knownBeacons[0].accuracy
            }
            if (String(describing: knownBeacons[0].major) == "103"){
                arr[4] = knownBeacons[0].accuracy
            }
            if (String(describing: knownBeacons[0].major) == "101"){
                arr[5] = knownBeacons[0].accuracy
            }
            if (String(describing: knownBeacons[0].major) == "30"){
                arr[6] = knownBeacons[0].accuracy
            }
            if (String(describing: knownBeacons[0].major) == "106"){
                arr[7] = knownBeacons[0].accuracy
            }
            //print(knownBeacons[0] as CLBeacon)
        }
        var closest: Double = arr.min()!;
        ble?.distance = closest;
        var index = arr.index(of: closest)
        if (index == 0) {
            if (arr[7] < arr[1]) {
                ble?.loc = "FLS"
            } else if (arr[7] > arr[1]) {
                ble?.loc = "FLF"
            }
        } else if (index == 1) {
            if (arr[0] < arr[2]) {
                ble?.loc = "FLF"
            } else if (arr[0] > arr[2]) {
                ble?.loc = "FRF"
            }
        } else if (index == 2) {
            if (arr[1] < arr[3]) {
                ble?.loc = "FRF"
            } else if (arr[1] > arr[3]) {
                ble?.loc = "FRS"
            }
        } else if (index == 3) {
            if (arr[2] < arr[4]) {
                ble?.loc = "FRS"
            } else if (arr[2] > arr[4]) {
                ble?.loc = "BRS"
            }
        } else if (index == 4) {
            if (arr[3] < arr[5]) {
                ble?.loc = "BRS"
            } else if (arr[3] > arr[5]) {
                ble?.loc = "BRB"
            }
        } else if (index == 5) {
            if (arr[4] < arr[6]) {
                ble?.loc = "BRB"
            } else if (arr[4] > arr[6]) {
                ble?.loc = "BLB"
            }
        } else if (index == 6) {
            if (arr[5] < arr[7]) {
                ble?.loc = "BLB"
            } else if (arr[5] > arr[7]) {
                ble?.loc = "BLS"
            }
        } else if (index == 7) {
            if (arr[6] < arr[0]) {
                ble?.loc = "BLS"
            } else if (arr[6] > arr[0]) {
                ble?.loc = "FLS"
            }
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // Activate / disActivate the peripheral
    @IBAction func switchPeripheralOnOff(_ sender: AnyObject) {

        if self.switchPeripheral.isOn {
            print("starting peripheral")
            ble = BLEPeripheralManager()
            ble?.delegate = self
            ble!.startBLEPeripheral()
        }
        else {
            print("stopping Peripheral")
        ble!.stopBLEPeripheral()
        }
    
    }


    

    func logToScreen(text: String) {
        var str = logTextView.text + "\n"
        str += text
        logTextView.text = str
    }
    
}

