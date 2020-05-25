//
//  BluetoothManagerCentral2.swift
//  BluetoothTest
//
//  Created by Radislav Gaynanov on 14.05.2020.
//  Copyright © 2020 Radislav Gaynanov. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothManagerCentral: NSObject {
    var centralManager: CBCentralManager!
    var state = State.poweredOff
    private let outOfRangeHeuristics: Set<CBError.Code> = [.unknown, .connectionTimeout, .peripheralDisconnected, .connectionFailed]
    
    var callBackPeripheral: ((CBPeripheral) -> Void)?
    var callBackValueFromCharacteristic: ((String) -> Void)?
    

    private var textDataForChange = ""
    
    private var textToSend = "МЯУ"
    private var countValue = 0
    
    private var longDataFlag = false
    private var longData = Data() {
        didSet{
            if longDataFlag {
                readValue()
            }
        }
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager.init(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    enum State {
        case poweredOff
        case restoringConnectingPeripheral(CBPeripheral)
        case restoringConnectedPeripheral(CBPeripheral)
        case disconnected
        case scanning(Countdown)
        case connecting(CBPeripheral, Countdown)
        case discoveringServices(CBPeripheral, Countdown)
        case discoveringCharacteristics(CBPeripheral, Countdown)
        case connected(CBPeripheral)
        case outOfRange(CBPeripheral)
        
        var peripheral: CBPeripheral? {
            switch self {
            case .poweredOff: return nil
            case .restoringConnectingPeripheral(let p): return p
            case .restoringConnectedPeripheral(let p): return p
            case .disconnected: return nil
            case .scanning: return nil
            case .connecting(let p, _): return p
            case .discoveringServices(let p, _): return p
            case .discoveringCharacteristics(let p, _): return p
            case .connected(let p): return p
            case .outOfRange(let p): return p
            }
        }
    }
    
    func scanPereferals() {
        guard centralManager.state == .poweredOn  else {
            print("bluetooth is powered OFF, cannot SCAN")
            return
        }
        centralManager.scanForPeripherals(withServices: [TransferService.service],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        
        state = .scanning(Countdown.init(seconds: 0, closure: { [unowned self] in
            self.stopScaning()
            self.state = .disconnected
            print("Scan timed out")
        }))
        
    }
    
    func stopScaning() {
        centralManager.stopScan()
    }
    
    func connect(peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        state = .connecting(peripheral, Countdown.init(seconds: 0, closure: { [unowned self] in
            self.disconnect()
            print("Scan timed out")
        }))
    }
    
    func disconnect() {
        print("disconnect")
        if let peripheral = state.peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        state = .disconnected
    }
    
    func readValue() {
        guard case .connected(let peripheral) = state else {return}
        guard let ch = peripheral.desiredCharacretistic else {return}
        peripheral.readValue(for: ch)
    }
    
    func writeValue() {
        guard case .connected(let peripheral) = state else { return }
        var chunks = [Data]()
        let data = prepareSendData()
        var startIndex = 0
        
        let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
        if data.count < mtu {
            chunks.append(data)
        } else {
            repeat {
                let amoutByte = data.count - startIndex
                let byteToCopy = min(mtu, amoutByte)
                
                let chunk = data.subdata(in: startIndex ..< (startIndex + byteToCopy))
                chunks.append(chunk)
                startIndex += byteToCopy
            } while startIndex < data.count
        }
        guard let ch = peripheral.desiredCharacretistic else {return}
        for item in chunks {
            peripheral.writeValue(item, for: ch, type: .withResponse)
        }
    }
    
    private func prepareSendData() -> Data {
        var str: String
        
        if countValue == 0 {
            str = textToSend
            countValue += 1

        } else {
            str = textToSend + String(countValue)
            countValue += 1
        }
        str = str + textDataForChange
        return str.data(using: .utf8)!
    }
}

extension BluetoothManagerCentral: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central state is unknown")
        case .resetting:
            print("central state is resetting")
        case .unsupported:
            print("central state is unsupported")
        case .unauthorized:
            print("central state is unauthorized")
        case .poweredOff:
            state = .poweredOff
        case .poweredOn:
            if case .poweredOff = state {
                // если есть UUID Peripheral или Service можно быстро соеденится
                if let previousConnected = central.retrievePeripherals(withIdentifiers: [TransferPeripheral.peripheral]).first {
                    centralManager.connect(previousConnected)
                } else if let serviceConnected = central.retrieveConnectedPeripherals(withServices: [TransferService.service]).first {
                    centralManager.connect(serviceConnected)
                } else {
                    state = .disconnected
                }
            }
            if case .restoringConnectingPeripheral(let peripheral) = state {
                centralManager.connect(peripheral)
            }
            if case .restoringConnectedPeripheral(let peripheral) = state {
                centralManager.connect(peripheral)
                //можем проверить наличие характеристики если нет получаем если есть устанавливаем связь
            }
        @unknown default:
            print("central state is unknown default")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        guard case .scanning = state else {return}
        //здесь можно проверить на соответсвие переферала своим требованиям, напирмер название
        if callBackPeripheral != nil {
            callBackPeripheral!(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        if peripherals.count > 1 {
            print("warning: willRestoreState called > 1 connection")
        }
        if let peripheral = peripherals.first {
            switch peripheral.state {
            case .connecting:
                state = .restoringConnectingPeripheral(peripheral)
            case .connected:
                state = .restoringConnectedPeripheral(peripheral)
            default:
                break
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([TransferService.service])
        state = .discoveringServices(peripheral, Countdown.init(seconds: 0, closure: { [unowned self] in
            self.state = .disconnected
        }))
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        state = .disconnected
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if self.state.peripheral?.identifier == peripheral.identifier {
            // IME the error codes encountered are:
            // 0 = rebooting the peripheral.
            // 6 = out of range.
            if let error = error,
                (error as NSError).domain == CBErrorDomain,
                let code = CBError.Code(rawValue: (error as NSError).code),
                outOfRangeHeuristics.contains(code) {
                // Try reconnect without setting a timeout in the state machine.
                // With CB, it's like saying 'please reconnect me at any point
                // in the future if this peripheral comes back into range'.
                centralManager.connect(peripheral, options: nil)
                self.state = .outOfRange(peripheral)
            } else {
                // Likely a deliberate unpairing.
                self.state = .disconnected
            }
        }
    }
    
}

extension BluetoothManagerCentral: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard case .discoveringServices = state else { return }
        
        if let error = error {
            print(error.localizedDescription)
            self.disconnect()
            return
        }
        
        guard peripheral.services?.first != nil else {
            self.disconnect()
            return
        }
        
        peripheral.discoverCharacteristics(nil, for: (peripheral.services?.first)!)
        state = .discoveringCharacteristics(peripheral, Countdown.init(seconds: 0, closure: {[unowned self] in
            self.disconnect()
        }))
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard case .discoveringCharacteristics = state else {return}
        
        if let error = error {
            print(error.localizedDescription)
            self.disconnect()
            return
        }
        
        guard let characteristics = service.characteristics else {
            self.disconnect()
            return
        }
        
        for item in characteristics {
            if item.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: item)
            } else if item.properties.contains(.read){
                peripheral.readValue(for: item)
            }
        }
        
        state = .connected(peripheral)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    
        if let value = characteristic.value, callBackValueFromCharacteristic != nil {
            
            if String(data: value, encoding: .utf8)  == "STX" {
                longDataFlag = true
                print("STX")
            } else if String(data: value, encoding: .utf8)  == "ETX" {
                longDataFlag = false
                print("ETX")
            }
            if longDataFlag == false {
                print("result")
                longData.append(value)
                if let str = String.init(data: longData, encoding: .utf8) {
                    print(str)
                    textDataForChange = str
                    callBackValueFromCharacteristic!(String(str.count))
                }
            }  else if longDataFlag == true {
                print("Append")
                longData.append(value)
            }
        
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("RESPONSE")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}

extension CBPeripheral {
    var desiredCharacretistic: CBCharacteristic? {
        guard let service = services?.first else {return nil}
        guard let chars = service.characteristics else { return nil }
        
        for item in chars {
            if item.properties.contains(.notify) {
               return item
            }
        }
        return nil
    }
}
