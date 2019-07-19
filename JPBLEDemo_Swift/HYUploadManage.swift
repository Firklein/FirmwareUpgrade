//
//  HYUploadManage.swift
//  SmartRing
//
//  Created by ZJ on 06/09/2017.
//  Copyright © 2017 HY. All rights reserved.
//

import UIKit
import CoreBluetooth
import iOSDFULibrary


class HYUploadManage: NSObject, DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate {
    fileprivate var selectedFirmware : DFUFirmware?
    fileprivate var selectedFileURL  : URL?
    fileprivate var dfuPeripheral    : CBPeripheral?
    fileprivate var centralManager   : CBCentralManager?
    fileprivate var dfuController    : DFUServiceController?
    fileprivate var scanVC    : ViewController?
    fileprivate var testScanVC : FirmUpdateVC?

    func getBundledFirmwareURLHelper() -> URL? {
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]

        let zipPath:NSString = NSString.init(string: path)
        
        return NSURL.fileURL(withPath: zipPath.appendingPathComponent("zipfile.zip") as String)
    }
    
    func setCentralManager(_ centralManager: CBCentralManager) {
        self.centralManager = centralManager
    }
    
    func setTargetPeripheral(_ targetPeripheral: CBPeripheral) {
        self.dfuPeripheral = targetPeripheral
    }
    
    func scanVC(_ scanVC: ViewController?) {
        self.scanVC = scanVC
    }
    
    func testScanVC(_ scanVC : FirmUpdateVC? ) {
        self.testScanVC = scanVC
    }
    
    func startDFUProcess() {
        guard dfuPeripheral != nil else {
            print("No DFU peripheral was set")
            return
        }
        selectedFileURL  = getBundledFirmwareURLHelper()
        print(selectedFileURL as Any)
        selectedFirmware = DFUFirmware(urlToZipFile: selectedFileURL!)
        
        let dfuInitiator = DFUServiceInitiator(centralManager: centralManager!, target: dfuPeripheral!)
        dfuInitiator.delegate = self
        dfuInitiator.progressDelegate = self
        dfuInitiator.logger = self
        
        // This enables the experimental Buttonless DFU feature from SDK 12.
        // Please, read the field documentation before use.
        dfuInitiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        dfuController = dfuInitiator.with(firmware: selectedFirmware!).start()
    }
    
    //MARK: - DFUServiceDelegate
    
    func dfuStateDidChange(to state: DFUState) {
        print("Changed state to: \(state.description())")
        
        switch state {
        case .connecting, .starting, .enablingDfuMode, .uploading:
            self.scanVC?.state = 1
        case .validating:
            self.scanVC?.state = 2
        case .disconnecting:
            self.scanVC?.state = 3
        case .completed:
            self.scanVC?.state = 4
        case .aborted:
            self.scanVC?.state = 5 
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        self.scanVC?.errorMessage = message
        print("Error \(error.rawValue): \(message)")
        
        // Forget the controller when DFU finished with an error
        dfuController = nil
    }
    
    //MARK: - DFUProgressDelegate

    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        self.scanVC?.proValue = progress
    }
    
    //MARK: - LoggerDelegate
    
    func logWith(_ level: LogLevel, message: String) {
        print("\(level.name()): \(message)")
    }
}
















