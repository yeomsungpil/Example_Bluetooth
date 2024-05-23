//
//  ViewController.swift
//  Example_Bluetooth
//
//  Created by Limefriends on 5/22/24.
//

import UIKit
import SnapKit

class ViewController: UIViewController, BluetoothSerialDelegate {
    
    lazy var scanButton: UIButton = {
       let button = UIButton()
        button.setTitle("스킨", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(scanButton)
        // Do any additional setup after loading the view.
        
        
        
        
        scanButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        scanButton.addTarget(self, action: #selector(scanButtonAction), for: .touchUpInside)
    }
    
    @objc func scanButtonAction() {
        let scanVC = ScanViewController()
        self.present(scanVC, animated: true)
    }
    
    
}

