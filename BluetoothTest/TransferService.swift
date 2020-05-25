//
//  TransferService.swift
//  BluetoothTest
//
//  Created by Radislav Gaynanov on 17.05.2020.
//  Copyright © 2020 Radislav Gaynanov. All rights reserved.
//

import Foundation
import CoreBluetooth

struct TransferService {
    static let service = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
    static let characteristicUUID = CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")
}
