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


class MyViewController: UIViewController, BLEPeripheralProtocol {
    
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var switchPeripheral: UISwitch!
    
    @IBOutlet weak var frontRightAlert: UIImageView!
    @IBOutlet weak var backLeftSide: UIImageView!
    @IBOutlet weak var frontLeftSide: UIImageView!
    @IBOutlet weak var backRightSide: UIImageView!
    @IBOutlet weak var frontRightSide: UIImageView!
    @IBOutlet weak var backRightAlert: UIImageView!
    @IBOutlet weak var frontLeftAlert: UIImageView!
    @IBOutlet weak var backLeftAlert: UIImageView!
    
    let green = UIImage(named: "green.jpg")
    let red = UIImage(named: "red.jpg")
    
    let url = Bundle.main.url(forResource: "beep", withExtension: "wav")!

    var player : AVAudioPlayer!

    var refreshLogs: Timer?
    var ble: BLEPeripheralManager?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MyViewController viewDidLoad")
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
        
        if (text == "FLF") {
            self.frontLeftAlert.image = red
            makeSounds()
        } else {
            self.frontLeftAlert.image = green
        }
        
        if(text == "FRF") {
            self.frontRightAlert.image = red
            makeSounds()
        } else {
            self.frontRightAlert.image = green
        }
        if(text == "FLS") {
            self.frontLeftSide.image = red
            makeSounds()
        } else {
            self.frontLeftSide.image = green
        }
        if(text == "BLS") {
            self.backLeftSide.image = red
            makeSounds()
        } else {
            self.backLeftSide.image = green
        }
        if(text == "BLB") {
            self.backLeftAlert.image = red
            makeSounds()
        } else {
            self.backLeftAlert.image = green
        }
        if(text == "BRB") {
            self.backRightAlert.image = red
            makeSounds()
        } else {
            self.backRightAlert.image = green
        }
        if(text == "BRS") {
            self.backRightSide.image = red
            makeSounds()
        } else {
            self.backRightSide.image = green
        }
        if(text == "FRS") {
            self.frontRightSide.image = red
            makeSounds()
        } else {
            self.frontRightSide.image = green
        }
    }
    func makeSounds() {
        
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        
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

