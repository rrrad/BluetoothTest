//
//  PerepheralViewController.swift
//  BluetoothTest
//
//  Created by Radislav Gaynanov on 10.05.2020.
//  Copyright © 2020 Radislav Gaynanov. All rights reserved.
//

import UIKit

class PerepheralViewController: UIViewController {
    var bluetoothManager = BluetoothManagerPerepheral()
    
    @IBOutlet weak var tetxInput: UILabel!
    
    @IBAction func sendResponce(_ sender: Any) {
        bluetoothManager.sendData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bluetoothManager.callBackToView = { [unowned self] str in
            self.tetxInput.text = str
        }
    }
    


}
