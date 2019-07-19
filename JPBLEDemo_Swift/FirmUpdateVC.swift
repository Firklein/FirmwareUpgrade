//
//  FirmUpdateVC.swift
//  JPBLEDemo_Swift
//
//  Created by csj on 2018/11/9.
//  Copyright © 2018年 yintao. All rights reserved.
//

import UIKit
import CoreBluetooth

var comple1 = false

class FirmUpdateVC: UIViewController {
    
    var state : Int = 0 {
        willSet{
            print("升级状态1111：\(state)")
        }
        didSet{
            print("升级状态2222：\(state)")
            if state == 4 {
                self.backView.isHidden = true
                
                let alertController = UIAlertController.init(title: "固件升级", message: "固件升级完成!", preferredStyle: .alert)
                self.present(alertController, animated: true) {
                    alertController.dismiss(animated: false, completion: {
                        sleep(UInt32(1))
                        comple1 = true
                    })
                }
            } else if state == 5 {
                self.backView.isHidden = true
                let alertController = UIAlertController.init(title: "固件升级", message: "固件升级失败!", preferredStyle: .alert)
                self.present(alertController, animated: true) {
                    alertController.dismiss(animated: false, completion: {
                        sleep(UInt32(1))
                    })
                }
            }
        }
    }
    
    var proValue : Int = 0 {
        willSet{
            print("当前进度：\(proValue)")
        }
        didSet{
            self.proLabel.text = "当前进度：" + String(proValue) + "%"
        }
    }

    //系统蓝牙管理对象
    var manager : CBCentralManager!
    var discoveredPeripheralsArr :[CBPeripheral?] = []
    var advertisementDataArr : [NSDictionary?] = []
    var tableView : UITableView!
    //连接的外围
    var peri : CBPeripheral!
    //保存的设备特性
    var uploadCha : CBCharacteristic!
    
    //固件升级--连接的外围
    var updatePeri : CBPeripheral!
    let firmUpdateUUID = "FE59"
    
    var zippagke = ""
    var backView:UIView!
    var proLabel:UILabel!
    
    fileprivate var uploadManage:HYUploadManage!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView = UITableView.init(frame: CGRect(x: 0, y: 64, width: UIScreen.main.bounds.size.width, height: 260), style: UITableViewStyle.plain)
        tableView.delegate = self;
        tableView.dataSource = self;
        self.view.addSubview(tableView)
        
        
        let leftButton = UIButton.init(type: UIButtonType.custom)
        leftButton.frame = CGRect(x: 0,y: 0,width: 60,height: 20)
        leftButton.setTitle("扫描设备", for: UIControlState.normal)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        leftButton.setTitleColor(UIColor.red, for: UIControlState.normal)
        leftButton.addTarget(self, action: #selector(ViewController.startScan), for: UIControlEvents.touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: leftButton)
        
        manager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
    }
    
    //搜索蓝牙
    func startScan() {
        discoveredPeripheralsArr.removeAll()
        advertisementDataArr.removeAll()
        manager.stopScan()
        if comple1 == true {
            manager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
            self.perform(NSSelectorFromString("delayTime"), with: nil, afterDelay: 2.0);
        } else {
            manager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func delayTime() {
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func loadActivity() {
        // 设置activity的中心为按钮的中心
        self.backView = UIView.init()
        self.backView.frame = UIScreen.main.bounds
        self.backView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.7)
        self.view.addSubview(self.backView)
        
        self.proLabel = UILabel.init()
        self.proLabel.frame = CGRect(x: (UIScreen.main.bounds.size.width-300)/2, y: 300, width: 300, height: 20)
        self.proLabel.textColor = UIColor.white
        self.proLabel.textAlignment = NSTextAlignment.center
        self.proLabel.font = UIFont.systemFont(ofSize: 20)
        self.backView.addSubview(self.proLabel)
    }
    
    //开始升级
    func firmwareUpgrade() {
        let alertController = UIAlertController.init(title: "固件升级", message: "初始化完成，开始固件升级", preferredStyle: .alert)
        self.present(alertController, animated: true) {
            alertController.dismiss(animated: false, completion: {
                sleep(UInt32(1))
            })
        }
        self.loadActivity()
        let manage = HYUploadManage();
        manage.setCentralManager(manager)
        manage.setTargetPeripheral(updatePeri)
        manage.testScanVC(self)
        manage.startDFUProcess()
    }
    
    func hexToBytes(hexString:String) -> NSData {
        let data:NSMutableData = NSMutableData.init()
        for idx in 0..<hexString.count {
            if(idx%2 == 0) {
                let aRange:NSRange = NSMakeRange(idx, 2)
                let hexStr = hexString.substring(with: hexString.range(from: aRange)!)
                let scanner:Scanner = Scanner(string: hexStr)
                var intValue:UInt64 = 0
                scanner.scanHexInt64(&intValue)
                data.append(&intValue, length: 1)
            }
        }
        return data
    }
    
    //获取固件升级包
    func getFirmwarePackage() {
        let url = "https://lock.ke-er.com/lockerp/ajax/mobile.jsp?action=deviceUpdate"
        let urlStr = url + "&updateType="+"2"
        self.getDeviceUpdatepakge(updateUrl: urlStr)
    }
    
    //获取后台数据
    func getDeviceUpdatepakge(updateUrl:String) {
        //1.创建请求路径
        let url = NSURL(string: updateUrl)
        print("数据请求路径222:\(updateUrl)")
        let request = NSURLRequest.init(url: url! as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if (self.zippagke.contains("zip") == true) {
                var domains = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                if domains.count > 0 {
                    let url = NSURL(fileURLWithPath: domains[0]+"/zipfile.zip")
                    do {
                        try! data?.write(to: url as URL)
                        let a = [0x01]
                        let data = NSData(bytes: a, length: 1)
                        self.firmUpdateWriteToPeri(myData: data)
                    } catch {
                        print(error)
                    }
                }
            } else {
                self.zippagke = ""
                if data != nil{
                    let dict = try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                    let packDict:NSDictionary = dict as! NSDictionary
                    let packageUrl = packDict["url"] as! String
                    self.getZip(url: packageUrl)
                } else{
                    print("请求数据失败")
                }
            }
        }
        //5.开始执行任务
        task.resume()
    }
    
    func getZip(url:String) {
        print("开始获取固件升级包")
        zippagke = "zip"
        self.getDeviceUpdatepakge(updateUrl: url)
    }
}


extension FirmUpdateVC :UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripheralsArr.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cellId")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "cellId")
        }
        let peripheral = discoveredPeripheralsArr[indexPath.row]
        cell?.textLabel?.text = peripheral?.name
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPeripheral = discoveredPeripheralsArr[indexPath.row]
        manager.connect(selectedPeripheral!, options: nil)
    }
}

extension FirmUpdateVC :CBCentralManagerDelegate,CBPeripheralDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        switch central.state {
        case .unknown:
            print("CBCentralManagerStateUnknown")
        case .resetting:
            print("CBCentralManagerStateResetting")
        case .unsupported:
            print("CBCentralManagerStateUnsupported")
        case .unauthorized:
            print("CBCentralManagerStateUnauthorized")
        case .poweredOff:
            print("CBCentralManagerStatePoweredOff")
        case .poweredOn:
            print("CBCentralManagerStatePoweredOn")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        if (peripheral.name?.contains("DfuTarg") == true) {
            updatePeri = peripheral
            comple1 = false
            sleep(3)
            self.firmwareUpgrade()
            return
        }
        
        for (index, obtainedPeriphal)  in discoveredPeripheralsArr.enumerated() {
            if (obtainedPeriphal?.name == peripheral.name){
                discoveredPeripheralsArr.remove(at: index)
                break
            }
        }
        let name = peripheral.name
        if ((name?.contains("a-")) == true){
            discoveredPeripheralsArr.append(peripheral)
            advertisementDataArr.append(advertisementData as NSDictionary)
        }
        print("蓝牙数组：\(discoveredPeripheralsArr)")
        tableView.reloadData()
    }
    
    //连接上
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        peri = peripheral
        //外设寻找service
        peripheral .discoverServices(nil)
        peripheral.delegate = self
        self.title = peripheral.name
        manager .stopScan()
        let alertController = UIAlertController.init(title: "已连接上 \(peripheral.name ?? "")", message: nil, preferredStyle: .alert)
        self.present(alertController, animated: true) {
            alertController.dismiss(animated: false, completion: {
                sleep(UInt32(0.5))
            })
        }
    }
    
    //连接到Peripherals-失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?){
        print("连接到名字为111 \(String(describing: peripheral.name)) 的设备失败，原因是 \(String(describing: error?.localizedDescription))")
        peri = nil;
    }
    ///断开
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        print("连接到名字为222 \(String(describing: peripheral.name)) 的设备断开，原因是 \(String(describing: error?.localizedDescription))")
        self.startScan()
        peri = nil;
    }
    //扫描到Services"
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        if (error != nil){
            print("查找 services 时 \(peripheral.name ?? "") 报错 \(String(describing: error?.localizedDescription))")
        }
        for service in peripheral.services! {
            //需要连接的 CBCharacteristic 的 UUID
            print(service.uuid.uuidString)
            if service.uuid.uuidString .contains(firmUpdateUUID) {
                peripheral.discoverCharacteristics(nil, for: service);
            }
        }
    }
    
    //扫描到 characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        if error != nil{
            print("查找 characteristics 时 \(peripheral.name ?? "") 报错 \(error?.localizedDescription ?? "")")
        }
        if service.uuid.uuidString .contains(firmUpdateUUID) {
            for c in service.characteristics! {
                if  c.uuid.uuidString .contains("8EC90003") {
                    peripheral.setNotifyValue(true, for: c)
                    self.uploadCha = c;
                    sleep(3)
                    self.getFirmwarePackage()
                    
                } else if c.uuid.uuidString .contains("8EC90001") {
                    peripheral.setNotifyValue(true, for: c)
                } else if c.uuid.uuidString .contains("8EC90002") {
                    self.uploadCha = c;
                }
            }
        }
    }
    
    
    //获取蓝牙反馈值s
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if(error != nil){
            print("Error Reading characteristic value: \(String(describing: error?.localizedDescription))")
        } else{
            let data = characteristic.value
            print("收到的蓝牙反馈值： \(data! as NSData)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        if error != nil{
            print("写入 characteristics 时 \(peripheral.name ?? "") 报错 \(error?.localizedDescription ?? "")")
        } else {
            print("Write value success!")
        }
    }
    
    //发送蓝牙指令
    func firmUpdateWriteToPeri(myData:NSData) {
        if self.uploadCha != nil {
            peri.writeValue(myData as Data, for: self.uploadCha, type: CBCharacteristicWriteType.withResponse);
        }
    }
}


