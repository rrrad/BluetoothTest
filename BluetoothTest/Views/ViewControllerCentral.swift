//
//  ViewController.swift
//  BluetoothTest
//
//  Created by Radislav Gaynanov on 09.05.2020.
//  Copyright © 2020 Radislav Gaynanov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let vm = ListViewModel()

    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func stopScan(_ sender: Any) {
        vm.stopScan()
    }
    @IBAction func scan(_ sender: Any) {
        vm.scan()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        
        vm.dataIsChange = {[unowned self] in
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else {return}
        if let target = segue.destination as? PairViewController {
            target.bluetoothManager = vm.bluetoothManager
            target.peripheral = vm.getPeripheral(for: indexPath.row)
        }
    }

}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        vm.getCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = vm.getData(for: indexPath.row)
        return cell
    }
    
    
}



