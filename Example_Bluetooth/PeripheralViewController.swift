//
//  PeripheralViewController.swift
//  Example_Bluetooth
//
//  Created by Limefriends on 5/23/24.
//

import UIKit
import CoreBluetooth

class PeripheralViewController: UIViewController {
    
    var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic?
    var transferServiceUUID = CBUUID(string: "FFE0")
    var transferCharacteristicUUID = CBUUID(string: "FFE1")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func setupPeripheral() {
        // Characteristic 생성
        transferCharacteristic = CBMutableCharacteristic(type: transferCharacteristicUUID,
                                                         properties: [.notify, .read, .write],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])
        
        // Service 생성 및 추가
        let transferService = CBMutableService(type: transferServiceUUID, primary: true)
        transferService.characteristics = [transferCharacteristic!]
        peripheralManager.add(transferService)
        
        // 광고 시작
        peripheralManager.startAdvertising([CBAdvertisementDataServiceDataKey: [transferServiceUUID]])
    }
    
    func sendData() {
        guard let transferCharacteristic else { return }
        let data = "Hello, World!".data(using: .utf8)!
        peripheralManager.updateValue(data, for: transferCharacteristic, onSubscribedCentrals: nil)
    }
}

extension PeripheralViewController : CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            setupPeripheral()
        } else {
            print("Bluetooth is not available")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        sendData()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let value = request.value,
               request.characteristic.uuid == transferCharacteristicUUID {
                print("Received data: \(String(data: value, encoding: .utf8) ?? "N/A")")
            }
            peripheralManager.respond(to: request, withResult: .success)
        }
    }
    
}
