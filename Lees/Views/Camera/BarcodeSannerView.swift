//
//  BarcodeSannerView.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 12/12/2024.
//

import UIKit
import VisionKit


class ViewController: UIViewController {
    
    var scannerAvaiable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func startScanningPressed(_ sender: Any) {
        guard scannerAvaiable == true else {
            print("Scanner not available")
            return
        }
        
        let dataScanner = DataScannerViewController(recognizedDataTypes: [.barcode()], isHighlightingEnabled: true)
        present(dataScanner, animated: true) {
            try? dataScanner.startScanning()
        }
        
    }
}
