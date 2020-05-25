//
//  BluetoothManagerPerepheral.swift
//  BluetoothTest
//
//  Created by Radislav Gaynanov on 10.05.2020.
//  Copyright © 2020 Radislav Gaynanov. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothManagerPerepheral: NSObject {
    var pereferalManager: CBPeripheralManager!
    var callBackToView: ((String) ->Void)?
    
    private var textDataForChange = ""
    private var value = "ГАВ"
   
    
    private var countValue = 0
    
    private var chunks = [Data]()
    
    private var subscribedCentral: CBCentral?
    private var myChar1: CBMutableCharacteristic?
    
    override init() {
        super.init()
        pereferalManager = CBPeripheralManager.init(delegate: self, queue: nil, options: [CBPeripheralManagerOptionRestoreIdentifierKey: "restorekey"])
        addServices()
    }
    
    
    func addServices() {
        let valueData = value.data(using: .utf8)!
        
        myChar1 = CBMutableCharacteristic.init(type: TransferService.characteristicUUID,
                                                   properties: [.notify, .write, .read],
                                                   value: nil,
                                                   permissions: [.readable, .writeable])
        
        let myChar2 = CBMutableCharacteristic.init(type: TransferService.characteristicUUID,
                                                   properties: [.read],
                                                   value: valueData,
                                                   permissions: [.readable])
        
        let myService = CBMutableService.init(type: TransferService.service, primary: true)
        myService.characteristics = [myChar1!, myChar2]
        pereferalManager.add(myService)
        print("start ADvertisement")
    }
    
    func start() {
        pereferalManager.startAdvertising([CBAdvertisementDataLocalNameKey: "RRRADDD", CBAdvertisementDataServiceUUIDsKey: [TransferService.service]])
    }
   
    func stop() {
        pereferalManager.stopAdvertising()
    }
    
    func sendData() {
        guard let central = subscribedCentral else {return}
        
        var sendDataIndex: Int = 0
        let mtu = central.maximumUpdateValueLength
        
        let data = prepareSendData()
        
        if mtu > data.count {
            pereferalManager.updateValue(prepareSendData(), for: myChar1!, onSubscribedCentrals: [central])
            print("value size min")
        } else {
            pereferalManager.updateValue("STX".data(using: .utf8)!, for: myChar1!, onSubscribedCentrals: [central])
            print("STX")
            repeat {
                let countDataTosend = data.count - sendDataIndex
                let amoutToSend = min(mtu, countDataTosend)
                let chunk = data.subdata(in: sendDataIndex ..< (sendDataIndex + amoutToSend))
                
                chunks.append(chunk)
                      print("STX VALUE")
                sendDataIndex += amoutToSend

            } while sendDataIndex < data.count
        
            chunks.append("ETX".data(using: .utf8)!)

        }
    }
    
    private func prepareSendData() -> Data {
        var str: String
        
        if countValue == 0 {
            str = value
            countValue += 1
        } else {
            str = value + String(countValue)
            countValue += 1
        }
        
        str = str + textDataForChange
        
        return str.data(using: .utf8)!
    }
}


extension BluetoothManagerPerepheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("pereferal state is unknown")
        case .resetting:
            print("pereferal state is resetting")
        case .unsupported:
            print("pereferal state is unsupported")
        case .unauthorized:
            print("pereferal state is unauthorized")
        case .poweredOff:
            print("pereferal state is poweredOff")
        case .poweredOn:
            self.start()
        @unknown default:
            print("pereferal state is unknown default")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        subscribedCentral = central
        pereferalManager.setDesiredConnectionLatency(.low, for: central)

    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            print(request.value!.count)
            guard let reqValue = request.value,
                let stringFromValue = String.init(data: reqValue, encoding: .utf8) else {continue}
            textDataForChange = stringFromValue
            if callBackToView != nil {
                callBackToView!(stringFromValue)
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if !chunks.isEmpty {
            request.value = chunks[0]
            print(request.value?.count as Any)
            chunks.remove(at: 0)
        }
        peripheral.respond(to: request, withResult: .success)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        if chunks.count != 0 {
            pereferalManager.updateValue(chunks[0], for: myChar1!, onSubscribedCentrals: [subscribedCentral!])
            chunks.remove(at: 0)
        }
    }
    
}
