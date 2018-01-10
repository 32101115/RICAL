//
//  BLECentralManager.swift
//  BlueToothCentral
//
//  Created by Olivier Robin on 30/10/2016.
//  Copyright © 2016 fr.ormaa. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit
import UserNotifications
import AudioToolbox
import AVFoundation
import CoreLocation


// Apple documentation :
// https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html

// UUID of peripheral service, and characteristics
// can be generated using "uuidgen" under osx console


let peripheralName = "Ipod"
// Service
//let BLEService = "00001901-0000-1000-8000-00805f9b34fb" // iphone
let BLEService = "00001901-0000-1000-8000-00805f9b34fc" // ipod

// Characteristics
let CH_READ  = "ffffffff-ffff-ffff-ffff-fffffffffff0"
//let CH_WRITE = "ffffffff-ffff-ffff-ffff-fffffffffff1" // iphone
let CH_WRITE = "ffffffff-ffff-ffff-ffff-fffffffffff2" // ipad

var TextToAdvertise = ""    // < 28 bytes needed.
var TextToNotify = "Notification: "                 // < 28 bytes needed ???



// BlueTooth do not work if it not instanciated, called, managed, from a uiview controller, linked to a .xib, or storyboard
//
class BLEPeripheralManager : NSObject, CBPeripheralManagerDelegate {
    
    //tracking beacon
    
    var loc: String = ""
    var distance: Double = 0.0
    
    let url = Bundle.main.url(forResource: "beep", withExtension: "wav")!
    
    var player : AVAudioPlayer!
    
    //CLBeaconRegion to identify the beacon
    var localBeacon: CLBeaconRegion!
    var beaconPeripheralData: NSDictionary!

    // use class variable, instead of variable in function :
    // allow to be retained in memory. if not, Swift can get ridd of them when it want.
    var localPeripheralManager: CBPeripheralManager! = nil
    var localPeripheral:CBPeripheral? = nil
    var createdService = [CBService]()
    
    var notifyCharac: CBMutableCharacteristic? = nil
    var notifyCentral: CBCentral? = nil
    
    // timer used to retry to scan for peripheral, when we don't find it
    var notifyValueTimer: Timer?
    
    // Delegate to a parent.will allow to display thing, or send value
    var delegate: BLEPeripheralProtocol?
    
    var cpt = 0
    
    //turn peripheral device into ibeacon
    func initLocalBeacon() {
        if localBeacon != nil {
            stopLocalBeacon()
            print("stop local beacon")
        }
        
        //let localBeaconUUID = "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5"
        let localBeaconMajor: CLBeaconMajorValue = 123
        let localBeaconMinor: CLBeaconMinorValue = 456
        
        let uuid = UUID(uuidString: BLEService)!
        localBeacon = CLBeaconRegion(proximityUUID: uuid, major: localBeaconMajor, minor: localBeaconMinor, identifier: "RICAL Ipad")
        
        beaconPeripheralData = localBeacon.peripheralData(withMeasuredPower: nil)
        //localPeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        
        
        print("beacon setting initiated")
    }
    
    func stopLocalBeacon() {
        localPeripheralManager.stopAdvertising()
        localPeripheralManager = nil
        beaconPeripheralData = nil
        localBeacon = nil
    }
    

    
    // start the PeripheralManager
    //
    func startBLEPeripheral() {

        delegate?.logToScreen(text: "startBLEPeripheral")
        delegate?.logToScreen(text: "Discoverable name : " + peripheralName)
        delegate?.logToScreen(text: "Discoverable service :\n" + BLEService)

        // start the Bluetooth periphal manager
        localPeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    
    
    // Stop advertising.
    //
    func stopBLEPeripheral() {
        delegate?.logToScreen(text: "stopBLEPeripheral")

        self.localPeripheralManager.removeAllServices()
        self.localPeripheralManager.stopAdvertising()
    }

    
    
    // delegate
    //
    // Receive bluetooth state
    //
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        delegate?.logToScreen(text: "peripheralManagerDidUpdateState")

        if peripheral.state == .poweredOn {
            //localPeripheralManager.startAdvertising(beaconPeripheralData as! [String: AnyObject]!)
            self.createServices()
        }
        else {
            delegate?.logToScreen(text: "cannot create services. state = " + getState(peripheral: peripheral))
            localPeripheralManager.stopAdvertising()

        }
    }
    

    
    
    // Create 1 service
    // 2 Characteristics : 1 for read, 1 for write.
    //
    func createServices() {
        delegate?.logToScreen(text: "createServices")

        // service
        let serviceUUID = CBUUID(string: BLEService)
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        // characteristic
        var chs = [CBMutableCharacteristic]()

        // Read characteristic
        delegate?.logToScreen(text: "Charac. read : \n" + CH_READ)
        let characteristic1UUID = CBUUID(string: CH_READ)
        let properties: CBCharacteristicProperties = [.read, .notify ]
        let permissions: CBAttributePermissions = [.readable]
        let ch = CBMutableCharacteristic(type: characteristic1UUID, properties: properties, value: nil, permissions: permissions)
        chs.append(ch)
        
        // Write characteristic
        delegate?.logToScreen(text: "Charac. write : \n" + CH_WRITE)
        let characteristic2UUID = CBUUID(string: CH_WRITE)
        let properties2: CBCharacteristicProperties = [.write, .notify ]
        let permissions2: CBAttributePermissions = [.writeable]
        let ch2 = CBMutableCharacteristic(type: characteristic2UUID, properties: properties2, value: nil, permissions: permissions2)
        chs.append(ch2)
        
        // Create the service, add the characteristic to it
        service.characteristics = chs
        createdService.append(service)
        localPeripheralManager.add(service)
    }

    
    
    
    // delegate
    // service + Charactersitic added to peripheral
    //
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?){
        delegate?.logToScreen(text: "peripheralManager didAdd service")
        
        if error != nil {
            delegate?.logToScreen(text: ("Error adding services: \(String(describing: error?.localizedDescription))"))
        }
        else {
            delegate?.logToScreen(text: "service:\n" + service.uuid.uuidString)
            
            // Create an advertisement, using the service UUID
            let advertisement: [String : Any] = [CBAdvertisementDataServiceUUIDsKey : [service.uuid]]
            //CBAdvertisementDataLocalNameKey;: peripheralName]
            //28 bytes maxu !!!
            // only 10 bytes for the name
            // https://developer.apple.com/reference/corebluetooth/cbperipheralmanager/1393252-startadvertising
            
            // start the advertisement
            delegate?.logToScreen(text: "Advertisement datas: ")
            delegate?.logToScreen(text: String(describing: advertisement))
            self.localPeripheralManager.startAdvertising(advertisement)

            delegate?.logToScreen(text: "Starting to advertise.")
        }
    }
    
    
    
    // Advertising done
    //
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?){
        if error != nil {
            delegate?.logToScreen(text: ("peripheralManagerDidStartAdvertising Error :\n \(String(describing: error?.localizedDescription))"))
        }
        else {
            delegate?.logToScreen(text: "peripheralManagerDidStartAdvertising OK")
        }
    }
    

    // Central request to be notified to a charac.
    //
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        delegate?.logToScreen(text: "peripheralManager didSubscribeTo characteristic :\n" + characteristic.uuid.uuidString)
        
        if characteristic.uuid.uuidString == CH_READ {
            self.notifyCharac = characteristic as? CBMutableCharacteristic
            self.notifyCentral = central
            // start a timer, which will update the value, every xyz seconds.
            self.notifyValueTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.notifyValue), userInfo: nil, repeats: true)
        }
        
    }
    
    
    
    // called when Central manager send read request
    //
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
        //delegate?.logToScreen(text: "peripheralManager didReceiveRead")
        //delegate?.logToScreen(text: "request uuid: " + request.characteristic.uuid.uuidString)
        print("loc", distance)
        delegate?.logToScreen(text: "Direction :" + loc)
        // prepare advertisement data
        //let data: Data = TextToAdvertise.data(using: String.Encoding.utf16)!

        if (distance < 2.5) {
            request.value = loc.data(using: String.Encoding.utf16) //characteristic.value
            
            // Respond to the request
            localPeripheralManager.respond( to: request, withResult: .success)
            // acknowledge : ok
            peripheral.respond(to: request, withResult: CBATTError.success)
            
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            
            // Respond to the request
            localPeripheralManager.respond( to: request, withResult: .success)
            do {
                player = try AVAudioPlayer(contentsOf: url)
                guard let player = player else { return }
                //player.numberOfLoops = 1
                player.prepareToPlay()
                
                player.volume = 0.4
                //player.enableRate=true
                //player.rate=2.0
                
                player.play()
            } catch let error as NSError {
                print(error.description)
            }
        }
        
    }
    

    
    // called when central manager send write request
    //
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        /*delegate?.logToScreen(text: "peripheralManager didReceiveWrite")
        for r in requests {
            delegate?.logToScreen(text: "request uuid: " + r.characteristic.uuid.uuidString)
        }*/
        
        if requests.count > 0 {
            let str = NSString(data: requests[0].value!, encoding:String.Encoding.utf8.rawValue)!
            //let str = String(data: requests[0].value!, encoding: String.Encoding.utf8)
            //print("value sent by central Manager :\n" + String(describing: str))
            //delegate?.logToScreen(text: "value sent by central Manager :\n" + String(describing: str))
            print(str as Any)
            delegate?.logToScreen(text: (str as String))
        }
        peripheral.respond(to: requests[0], withResult: CBATTError.success)
    }
    
    
    
    
    func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        delegate?.logToScreen(text: "respnse requested")
    }
    
    
    
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        delegate?.logToScreen(text: "peripheral name changed")
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        delegate?.logToScreen(text: "peripheral service modified")
    }
    

 
    
    
}



