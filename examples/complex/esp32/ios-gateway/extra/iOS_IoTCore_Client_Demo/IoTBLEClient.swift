//
//  IoTBLEClient.swift
//  iOS_IoTCore_Client
//
//  Created by Gal Zahavi on 7/16/20.
//  Copyright © 2020 Danilo Campos. All rights reserved.
//

import UIKit
import SwiftUI
import SwiftJWT
import CocoaMQTT
import AVKit
import CoreLocation
import CoreBluetooth
import Combine

class IoTBLEView: UIViewController, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager?
    var peripheral: CBPeripheral?
    var dumpDataCharacteristic: CBCharacteristic?

    let serviceUUID = CBUUID(string: "fdc59e94-27d1-4576-94c6-404b459c11ff")
    let dataUUID = CBUUID(string: "fdc59e94-27d3-4576-94c6-404b459c11ff")
    let readUUID = CBUUID(string: "fdc59e94-27d2-4576-94c6-404b459c11ff")
    
    let delegate = contentViewDelegate()

    var size: UInt16 = 0;
    var allData: Data = Data(capacity: 1)
    var disconnectValue = false
    var didDisconnect = false
    var mqtt:CocoaMQTT?
    
    private var cancellable: AnyCancellable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let centralQueue: DispatchQueue = DispatchQueue(label: "com.ryandetzel.BLE", attributes: .concurrent)
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        
        
        self.cancellable = delegate.$toDisconnect.sink{ value in
            print(value)
            if(value == true){
                
                self.mqtt!.disconnect()
                self.didDisconnect = true
                self.connected = false
            }
            else if(self.didDisconnect == true && value == false){
                self.didDisconnect = false
                self.connected = true
                self.getJWT()
            }
        }
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .unknown:
                print("Bluetooth status is UNKNOWN")
            case .resetting:
                print("Bluetooth status is RESETTING")
            case .unsupported:
                print("Bluetooth status is UNSUPPORTED")
            case .unauthorized:
                print("Bluetooth status is UNAUTHORIZED")
            case .poweredOff:
                print("Bluetooth status is POWERED OFF")
            case .poweredOn:
                print("Bluetooth status is POWERED ON")
                centralManager?.scanForPeripherals(withServices: [serviceUUID])
        } // END switch
    }
    
    @IBSegueAction func swiftUIAction(_ coder: NSCoder) -> UIViewController? {
        getJWT()
        return UIHostingController(coder: coder, rootView:SwiftUIClient(delegate: delegate, viewController: self))
    }
    
    @Published var switchIsOn = true
    @Published var command = ""
    @Published var sensorData = ""
    @Published var connected = true
    
    @IBAction func handleSwitch(_ sender: UISwitch) {

    }
    
    struct MyClaims: Claims {
        let iat: Date
        let exp: Date
        let aud: String
    }


    func getJWT(){
        let myHeader = Header()
        let myClaims = MyClaims(iat: Date(timeIntervalSinceNow: 0),exp: Date(timeIntervalSinceNow: 3600), aud: "class-does-iot-demos")
        
        var myJWT = JWT(header: myHeader, claims: myClaims)
        
        let privateKeyPath = """
        -----BEGIN EC PRIVATE KEY-----
        MHcCAQEEIHQy3AzIYZYvgSzXOnrVowZ0ZnMwQwZne2z7gylZ7nHCoAoGCCqGSM49
        AwEHoUQDQgAEh7N5ZehmvIVNQOIQzPq1frE1as5P8BvFFmAH0N4X5gk7GLUwiI3W
        O8GtpR/66l/D0uqhXuu6ZqGi9rIeLvvqdQ==
        -----END EC PRIVATE KEY-----
        """
        
        let privKey: Data = privateKeyPath.data(using: .utf8)!
        let jwtSigner = JWTSigner.es256(privateKey: privKey)
        let signedJWT = try! myJWT.sign(using: jwtSigner)
        cloudConnect(jwtstring: signedJWT)
    }

    func cloudConnect(jwtstring:String){
        mqtt = CocoaMQTT(clientID: "projects/class-does-iot-demos/locations/us-central1/registries/ios/devices/phone", host: "mqtt.googleapis.com", port: 8883)
        mqtt!.username = ""
        mqtt!.password = jwtstring
        mqtt?.enableSSL = true
        mqtt?.keepAlive = 6000
        print(jwtstring)
        mqtt!.connect()
        //mqtt?.publish("devices/phone/state", withString: "Connected")
        //mqtt?.publish("devices/phone/events", withString: "Hello")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Change `2.0` to the desired number of seconds.
            self.mqtt?.subscribe("/devices/phone/commands/#", qos: CocoaMQTTQOS(rawValue: 1)!)
            self.mqtt?.subscribe("/devices/phone/config", qos: CocoaMQTTQOS(rawValue: 1)!)
            print("Subscribed")
        }
       
        mqtt!.didReceiveMessage = { mqtt, message, id in
            print("Topic \(message.topic) : \(message.string!)")
    
            self.command = "\(message.topic) : \(message.string!)"
            
            if message.string! == "on" || message.string! == "off" {
                self.toggleFlash()
            }
        }
    }

    func publish(){
        
        mqtt?.publish("/devices/phone/state", withString: "Connected")
        
        if(self.sensorData != ""){
            mqtt?.publish("/devices/phone/events", withString: sensorData)
        }
        else{
            mqtt?.publish("/devices/phone/events", withString: "Text Empty")
        }
        
        print("Published")
    }

    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

           print(peripheral.name!)
           self.peripheral = peripheral
           self.peripheral?.delegate = self

           centralManager?.stopScan()
           centralManager?.connect(self.peripheral!)
            DispatchQueue.main.async { () -> Void in
                //ble connected
            };


       } // END func centralManager(... didDiscover peripheral

       func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
           self.peripheral?.discoverServices([serviceUUID])
       } // END func centralManager(... didConnect peripheral

       func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
           print("Disconnected!")
           DispatchQueue.main.async { () -> Void in
                 // discconected
             };
           connected = false
           centralManager?.scanForPeripherals(withServices: [serviceUUID])
           
       } // END func centralManager(... didDisconnectPeripheral peripheral

       func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
           for service in peripheral.services! {
               if service.uuid == serviceUUID {
                   peripheral.discoverCharacteristics(nil, for: service)
               }
           }
       } // END func peripheral(... didDiscoverServices

       func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
           for characteristic in service.characteristics! {
               if characteristic.uuid == readUUID {
                   // Read how many bytes we should read from the esp32.
                   peripheral.readValue(for: characteristic)
               }else if characteristic.uuid == dataUUID {
                   dumpDataCharacteristic = characteristic
               }
           } // END for
       } // END func peripheral(... didDiscoverCharacteristicsFor service


       func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

           if characteristic.uuid == readUUID {
               let data = characteristic.value!
               let value = data.withUnsafeBytes { (ptr: UnsafePointer<UInt16>) -> UInt16 in
                   return ptr.pointee
               }
               print("Should read \(value) bytes")
               size = value
               allData.removeAll()
           
               let dump = "dump".data(using: .utf8)!
               peripheral.writeValue(dump, for: dumpDataCharacteristic!, type: CBCharacteristicWriteType.withResponse)
               peripheral.setNotifyValue(true, for: dumpDataCharacteristic!)
                   
           } else if characteristic.uuid == dataUUID {
               let data = characteristic.value!
               allData.append(data)

              DispatchQueue.main.async { () -> Void in
                    if(self.connected == true){
                            self.sensorData = String(decoding: characteristic.value!, as: UTF8.self)
                            self.publish()
                    }else{
                        self.sensorData = ""
                    }
                };
   

               if (allData.count >= size){
                   peripheral.setNotifyValue(true, for: dumpDataCharacteristic!)

                   // We should verify the data.
                   print("\n" + String(decoding: characteristic.value!, as: UTF8.self) + "\n")
                   
               }
           } // END if characteristic.uuid ==...
       }
    
}
