//
//  BluetoothSerial.swift
//  Example_Bluetooth
//
//  Created by Limefriends on 5/22/24.
//

import UIKit
import CoreBluetooth

// 블루투스를 연결하는 과정에서의 시리얼과 뷰의 소통을 위해 필요한 프로토콜
protocol BluetoothSerialDelegate: AnyObject {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?)
    func serialDidConnectPeripheral(peripheral: CBPeripheral)
}

extension BluetoothSerialDelegate {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) { }
    func serialDidConnectPeripheral(peripheral: CBPeripheral) { }
}

// 블루투스 통신을 담당할 시리얼을 클래스로 선언, CoreBluetooth를 사용하기 위한 프토토콜 추가
class BluetoothSerial: NSObject {
    
    static let shared = BluetoothSerial() // 싱글톤으로 적용 코드 최적화
    
    private override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    weak var delegate: BluetoothSerialDelegate?
 
    
    // centralManager : 블루투스 주변기기를 검색하고 연결하는 역할
    var centralManager: CBCentralManager!
    
    // pedingPeripheral : 현재 연결을 시도하고 있는 블루투스 주변기기
    var pendingPeripheral: CBPeripheral?
    
    // connectedPeripheral : 연결에 성공된 기기, 기기와 통신을 시작하게 되면 이 객체를 이용
    var connectedPeripheral: CBPeripheral?
    
    // 데이터를 주변기기에 보내기 위한 characteristic을 저장하는 변수
    weak var writeCharacteristic: CBCharacteristic?
    
    // 데이터를 주변 기기에 보내는 Type 설정
    // withResponse : 데이터를 보내면 이에 대한 답장이 오는 경우
    // withoutResponse: 데이터를 보내도 답장이 오지 않는 경우
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    
    // serviceUUID는 Peripheral이 가지고 있느 서비스의 UUID , 거의 모든 HM- 10 모듈이 기본적으로 갖고 있는 FFE0으로 설정, 하나의 기기에 여러 개의 serviceUUID를 가질 수 있음
    var serviceUUID = CBUUID(string: "FFE0")
    
    // characteristicUUID는 serviceUUID에 포함되어있음, 이를 이용하여 데이터를 송수신, FFE0 서비스가 갖고있는 FFE1으로 설정, 하나의 service는 여러개의 characteristicUUID를 가질 수 있음
    var characteristicUUID = CBUUID(string: "FFE1")
  

    /// 기기 검색 시작, 연결이 가능한 모든 주변기기를 serviceUUID를 통해 찾기
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        
        // 연결 가능한 기기를 검색, withService 파라미터에 nil을 입력하면 모든 종류의 기기 검색
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        
        // 특정 serviceUUID를 가진 주변 기기를 검색하여 반환
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        
        // 검색된 주변 기기 처리
        for peripheral in peripherals {
            delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: nil)
        }
    }
    
    
    /// 기기 검색을 중단
    func stopScan() {
        centralManager.stopScan()
    }
    
    // 파라미터로 넘어온 주변 기기를 CentralManager에 연결하도록 시도
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        // 연결 실패를 대비하여 현재 연결중인 주변기기를 저장
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    

    
}

extension  BluetoothSerial : CBCentralManagerDelegate, CBPeripheralDelegate {

    
    /// central 기기의 블루투스가 켜져있는지, 꺼져있는지에 대한 상태가 변할때 마다 호출
    /// 켜져있을때 - .powerOn, 꺼져있을때 - .powerdOff
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        pendingPeripheral = nil
        connectedPeripheral = nil
        
        switch central.state {
        case .poweredOn:
            // Bluetooth가 켜져 있을 때 스캔 시작
            startScan()
        case .poweredOff, .resetting, .unauthorized, .unsupported, .unknown:
            // Bluetooth가 꺼져 있거나 사용 불가 상태일 때 처리
            stopScan()
        @unknown default:
            break
        }
        
    }
    
    /// 기기가 검색될때마다 호출
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // RSSI는 기기의 신호 강도를 의미

         // 신호 강도 필터링 (예: -70dBm 이상인 경우)
         if RSSI.intValue > -70 {
             print("Discovered peripheral: \(peripheral.name ?? "Unknown") at RSSI: \(RSSI)")
             delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: RSSI)
         } else {
             print("Peripheral RSSI too low: \(RSSI)")
         }
         
    }
    
    /// 기기가 연결되면 호출
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        
        // peripheral의 Service들을 검색, 파라미터를 nil로 설정하면 peripheral의 모든 service를 검색
        peripheral.discoverServices([serviceUUID])
        
        delegate?.serialDidConnectPeripheral(peripheral: peripheral)
    }
    
    /// service 검색에 성공시 호출
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            // 검색된 모든 service에 대해서 characteristic을 검색, 파라미터를 nil로 설정하면 해당 service의 모든 characteristic를 검색
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    /// characteristic 검색 성공 시 호출
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            // 검색된 모든 characteristic에 대해 characteristicUUID를 한번 더 체크하고, 일치한다면 peripheral을 구독하고 통신을 위한 설정 완료
            if characteristic.uuid == characteristicUUID {
                // 해당 기기의 데이터를 구독
                peripheral.setNotifyValue(true, for: characteristic)
                // 데이터를 보내기 위한 characteristic을 저장
                writeCharacteristic = characteristic
                // 데이터를 보내는 타입을 설정, 주변기기가 어떤 type으로 설정되어 있는지에 따라 변경
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                
                delegate?.serialDidConnectPeripheral(peripheral: peripheral)

            }
        }
    }
    /// writeType이 .withResponse일 때, 블루투스 기기로부터의 응답이 왔을때 호출
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        /*
         .withoutresponse라면 호출이 되지 않음
         wirteType이 .withResponse인 블루투스 기기로부터 응답이 왔을때 필요한 코드 작성
         */
    }
    
    /// 블루투스 기기의 신호 강도를 요청하는 메서드
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // 신호 강도와 관련된 코드 작성
    }
}
