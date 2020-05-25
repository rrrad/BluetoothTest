//
//  ListViewModel.swift
//  BluetoothTest
//
//  Created by Radislav Gaynanov on 09.05.2020.
//  Copyright © 2020 Radislav Gaynanov. All rights reserved.
//

import Foundation
import CoreBluetooth

class  ListViewModel {
    var bluetoothManager = BluetoothManagerCentral()
    let saveQueue = DispatchQueue.init(label: "savedata")
    var data = [CBPeripheral]() {
        didSet{
            if dataIsChange != nil {
                dataIsChange!()
            }
        }
    }
    var dataIsChange: (() -> Void)?
    
    init() {
        self.bluetoothManager.callBackPeripheral = { [unowned self] pereferals in
            self.saveQueue.async {
                self.data.append(pereferals)
            }
        }
    }
    
    func getCount() -> Int {
       return data.count
    }
    
    func getData(for index: Int) -> String {
        return data[index].name ?? "unknown"
    }
    
    func getPeripheral(for index: Int) -> CBPeripheral {
        return data[index]
    }
    
    func scan() {
        bluetoothManager.scanPereferals()
    }
    
    func stopScan() {
        bluetoothManager.stopScaning()
    }
}
