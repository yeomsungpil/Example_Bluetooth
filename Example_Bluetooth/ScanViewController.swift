//
//  ScanViewController.swift
//  Example_Bluetooth
//
//  Created by Limefriends on 5/22/24.
//

import UIKit
import CoreBluetooth

class ScanViewController: UIViewController {
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ScanTableCell.self, forCellReuseIdentifier: ScanTableCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
        return tableView
    }()
    
    static let identifier = "ScanViewController"
    
    // 현재 검색된 peripherallList
    var peripheralList: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        
        // scan 버튼을 눌러 기기 검색을 시작할때 마다 list를 초기화합니다.
        peripheralList = []
        // serial의 delegate를 ScanViewController로 설정, serial에서 delegate의 메서드를 호출하면 이 클래스에서 정의된 메서드가 호출
        BluetoothSerial.shared.delegate = self
        // 뷰가 로드된 후 검섹을 시작
        BluetoothSerial.shared.startScan()
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        BluetoothSerial.shared.stopScan()
    }
}

extension ScanViewController: BluetoothSerialDelegate {
    func serialDidConnectPeripheral(peripheral: CBPeripheral) {
        let connetSuccessAlert = UIAlertController(title: "블루투스 연결 성공", message: "\(peripheral.name ?? "")와 성공적으로 연결되었습니다.", preferredStyle: .alert)
        
        let confirm = UIAlertAction(title: "확인", style: .default) { _ in
            print("연결 정보", peripheral.name ?? "", peripheral.description, peripheral.canSendWriteWithoutResponse)
        }
        connetSuccessAlert.addAction(confirm)
        present(connetSuccessAlert, animated: true)
    }
    
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {
        // serial의 delegate에서 호출
        // 이미 저장되어 있는 기기라면 return
        for existing in peripheralList {
            if existing.peripheral.identifier == peripheral.identifier {
                return
            }
        }
        
        // 신호의 세기에 따라 정렬
        let fRSSI = RSSI?.floatValue ?? 0.0
        peripheralList.append((peripheral: peripheral, RSSI: fRSSI))
        peripheralList.sort { $0.RSSI < $1.RSSI }
        tableView.reloadData()
    }
    
    func serialDidReceiveMessage(message: String) {
        print("Received message: \(message)")
    }
    
}

extension ScanViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 선택된 peripheral을 연결, 검색을 중단, peripheralList에 저장된 peripheral중 클릭된 것을 찾아 연결
        BluetoothSerial.shared.stopScan()
        let selectedPeripheral = peripheralList[indexPath.row].peripheral
        // serial의 connectToperipeheral 함수에 선택된 peripheral을 연결하도록 요청
       
        BluetoothSerial.shared.connectToPeripheral(selectedPeripheral)
        print("선택된 블루투스 기기 : \(selectedPeripheral)")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // ScanCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ScanTableCell.identifier, for: indexPath) as? ScanTableCell else { return UITableViewCell() }
        let data = peripheralList[indexPath.row].peripheral.name
        
        if let data, data != "unknown" {
            cell.setup(data: data)
            return cell
        } else {
            let emptyCell = UITableViewCell()
            emptyCell.isHidden = true
            return emptyCell
        }
    }
}
