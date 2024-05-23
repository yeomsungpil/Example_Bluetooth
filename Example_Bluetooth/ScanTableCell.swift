//
//  ScanTableCell.swift
//  Example_Bluetooth
//
//  Created by Limefriends on 5/22/24.
//

import UIKit

class ScanTableCell: UITableViewCell {
    
    static let identifier = "ScanTableCell"
    
    lazy var scanText = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(scanText)
        
        scanText.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(15)
        }
    }
    
    func setup(data: String?) {
        scanText.text = data
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
