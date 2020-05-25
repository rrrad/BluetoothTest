//
//  PairViewController.swift
//  BluetoothTest
//
//  Created by Radislav Gaynanov on 10.05.2020.
//  Copyright © 2020 Radislav Gaynanov. All rights reserved.
//

import UIKit
import CoreBluetooth

class PairViewController: UIViewController {
    
    var bluetoothManager: BluetoothManagerCentral?
    var peripheral: CBPeripheral?
    
    @IBAction func sendData(_ sender: Any) {
        bluetoothManager?.writeValue()
    }
    
    @IBAction func read(_ sender: Any) {
        bluetoothManager?.readValue()
    }
    @IBOutlet weak var textOutput: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bluetoothManager?.connect(peripheral: peripheral!)
        bluetoothManager?.callBackValueFromCharacteristic = { [unowned self] str in
            self.textOutput.text = str
        }
    }
    
    
}
