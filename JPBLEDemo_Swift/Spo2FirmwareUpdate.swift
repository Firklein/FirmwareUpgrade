//
//  Spo2FirmwareUpdate.swift
//  JPBLEDemo_Swift
//
//  Created by csj on 2018/10/16.
//  Copyright © 2018年 yintao. All rights reserved.
//

import UIKit
import CoreBluetooth
import iOSDFULibrary

class Spo2FirmwareUpdate: UIViewController {
    
    var state : Int = 0 {
        willSet{
            print("升级状态1111：\(state)")
        }
        didSet{
            print("升级状态2222：\(state)")
            if state == 4 {
                //                self.activity.stopAnimating()
                self.backView.isHidden = true
                
                let alertController = UIAlertController.init(title: "固件升级", message: "固件升级完成!", preferredStyle: .alert)
                self.present(alertController, animated: true) {
                    alertController.dismiss(animated: false, completion: {
                        sleep(UInt32(1))
                        comple = true
                    })
                }
            } else if state == 5 {
                //                self.activity.stopAnimating()
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
    
    var errorMessage = ""
    
    var dfuPeripheral:CBPeripheral!
    
    //系统蓝牙管理对象
    var manager : CBCentralManager!
    var discoveredPeripheralsArr :[CBPeripheral?] = []
    var advertisementDataArr : [NSDictionary?] = []
    var tableView : UITableView!
    //连接的外围
    var connectedPeripheral : CBPeripheral!
    //保存的设备特性
    var savedCharacteristic : CBCharacteristic!
    var isConnect:Bool!
    
    //需要连接的 CBCharacteristic 的 UUID
    let ServiceUUID1 =  "FE59"
    //    8EC90004-F315-4F60-9FB8-838830DAEA50
    
    //升级包
    var packageUrl:String!
    
    //    var activity:UIActivityIndicatorView!
    var backView:UIView!
    var proLabel:UILabel!
    fileprivate var uploadManage:HYUploadManage!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView = UITableView.init(frame: CGRect(x: 0, y: 64, width: UIScreen.main.bounds.size.width, height: 260), style: UITableViewStyle.plain)
        tableView.delegate = self as? UITableViewDelegate;
        tableView.dataSource = self as? UITableViewDataSource;
        self.view.addSubview(tableView)
        manager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
        
        self.startScan();
    }
    
    func loadActivity() {
        // 设置activity的中心为按钮的中心
        
        self.backView = UIView.init()
        self.backView.frame = UIScreen.main.bounds
        self.backView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.7)
        self.view.addSubview(self.backView)
        
        //        self.activity = UIActivityIndicatorView.init()
        //        self.activity.frame = CGRect(x: (UIScreen.main.bounds.size.width-60)/2, y: (UIScreen.main.bounds.size.height-60)/2, width: 60, height: 60)
        //        self.activity.center = self.view.center
        //        // activity的菊花颜色
        //        self.activity.color = UIColor.red
        //        // 停止后，隐藏菊花
        //        self.activity.hidesWhenStopped = true
        //        // 添加activity到view中
        //        self.backView.addSubview(self.activity)
        
        self.proLabel = UILabel.init()
        self.proLabel.frame = CGRect(x: (UIScreen.main.bounds.size.width-300)/2, y: 300, width: 300, height: 20)
        self.proLabel.textColor = UIColor.white
        self.proLabel.textAlignment = NSTextAlignment.center
        self.proLabel.font = UIFont.systemFont(ofSize: 20)
        self.backView.addSubview(self.proLabel)
    }
    
    //搜索蓝牙
    func startScan() {
        discoveredPeripheralsArr.removeAll()
        advertisementDataArr.removeAll()
        manager.stopScan()
        if comple == true {
            manager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
            self.perform(NSSelectorFromString("delayTime"), with: nil, afterDelay: 2.0);
        } else {
            manager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func delayTime() {
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    //UITableViewDelegate,UITableViewDataSource
    
    //写入数据
    func viewController(_ peripheral: CBPeripheral,didWriteValueFor characteristic: CBCharacteristic,value : Data ) -> () {
        
        //只有 characteristic.properties 有write的权限才可以写
        if characteristic.properties.contains(CBCharacteristicProperties.write){
            //设置为  写入有反馈
            self.connectedPeripheral.writeValue(value, for: characteristic, type: .withResponse)
        }else{
            print("写入不可用~")
        }
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
        //        self.activity.startAnimating()
        let manage = HYUploadManage();
        manage.setCentralManager(manager)
        manage.setTargetPeripheral(dfuPeripheral)
        manage.scanVC(self)
        manage.startDFUProcess()
    }
    
    //获取后台数据
    func getDeviceUpdatepakge(updateUrl:String) {
        //1.创建请求路径
        //        let path = "http://0.0.0.0:tuicool@api.tuicool.com/api/articles/hot.json"
        //        //拼接参数(GET请求参数需要以"?"连接拼接到请求地址的后面，多个参数用"&"隔开，参数形式：参数名=参数值)
        //        //size:请求数据的长度
        //        let path2 = path + "?cid=0&size=30"
        //转换成url(统一资源定位符)
        let url = NSURL(string: updateUrl)
        print("数据请求路径222:\(updateUrl)")
        //2.创建请求对象
        //NSURLRequest类型的请求对象的请求方式一定是GET(默认GET且不能被改变)
        let request = NSURLRequest.init(url: url! as URL)
        //3.根据会话模式创建session(创建默认会话模式)
        //方式1：一般不采用
        //let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        //方式2：快速创建默认会话模式的session
        let session = URLSession.shared
        //4.创建任务
        //参数1：需要发送的请求对象
        //参数2：服务返回数据的时候需要执行的对应的闭包
        //闭包参数1：服务器返回给客户端的数据
        //闭包参数2：服务器响应信息
        //闭包参数3：错误信息
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            //注意：当前这个闭包是在子线程中执行的，如果想要在这儿执行UI操作必须通过线程间的通信回到主线程
            
            //            print(response)
            //            print("能接受到")
            //            print(NSThread.currentThread())
            
            //解析json
            //参数options：.MutableContainers(json最外层是数组或者字典选这个选项)
            var domains = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            if domains.count > 0 {
                let url = NSURL(fileURLWithPath: domains[0]+"/zipfile.zip")
                do {
                    try! data?.write(to: url as URL)
                } catch {
                    print(error)
                }
            }
        }
        //5.开始执行任务
        task.resume()
    }
    

    //获取固件更新指令
    func getUpdateFirmware(dict:NSDictionary) {
        //发送进入设置模式指令
        let setData:NSData = self.hexToBytes(hexString: "self.settingKey")
        self.writeToPeripheral(myData: setData)
    }

    //获取固件升级包
    func getFirmwarePackage() {
        let url = "https://pms.hotel580.com/lockerp/ajax/mobile.jsp?action=deviceUpdate"
        let urlStr = url + "&updateType="+LOCKDEVICE
        self.getDeviceUpdatepakge(updateUrl: urlStr)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension Data {
    var bytes : [UInt8]{
        return [UInt8](self)
    }
}

extension String {
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard  let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
}

extension ViewController :UITableViewDelegate,UITableViewDataSource{
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
        hardwareVersion = ""
        firmwareVersion = ""
        macStr = ""
        let selectedPeripheral = discoveredPeripheralsArr[indexPath.row]
        manager.connect(selectedPeripheral!, options: nil)
    }
}

extension ViewController :CBCentralManagerDelegate,CBPeripheralDelegate{
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
        //接下连接我们的测试设备，如果你没有设备，可以下载一个app叫lightbule的app去模拟一个设备
        /*
         一个主设备最多能连7个外设，每个外设最多只能给一个主设备连接,连接成功，失败，断开会进入各自的委托
         func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
         func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
         func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
         */
        //找到的设备必须持有它，否则CBCentralManager中也不会保存peripheral，那么CBPeripheralDelegate中的方法也不会被调用！
        
        //        print("进入次数\(peripheral)")
        
        if (peripheral.name?.contains("DfuTarg") == true) {
            dfuPeripheral = peripheral
            comple = false
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
        connectedPeripheral = peripheral
        isConnect = true
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
        isConnect = false
        //        self.startScan()
    }
    ///断开
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        print("连接到名字为222 \(String(describing: peripheral.name)) 的设备断开，原因是 \(String(describing: error?.localizedDescription))")
        self.startScan()
        //        let alertView = UIAlertController.init(title: "抱歉", message: "蓝牙设备\(String(describing: peripheral.name) )连接断开，请重新扫描设备连接", preferredStyle: UIAlertControllerStyle.alert)
        //        alertView.show(self, sender: nil)
        isConnect = false
    }
    // CBPeripheralDelegate
    
    
    //扫描到Services"
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        
        if (error != nil){
            print("查找 services 时 \(peripheral.name ?? "") 报错 \(String(describing: error?.localizedDescription))")
        }
        for service in peripheral.services! {
            //需要连接的 CBCharacteristic 的 UUID
            print(service.uuid.uuidString)
            if service.uuid.uuidString .contains(ServiceUUID1) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    
    //扫描到 characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        if error != nil{
            print("查找 characteristics 时 \(peripheral.name ?? "") 报错 \(error?.localizedDescription ?? "")")
        }
        for c in service.characteristics! {
            if c.uuid.uuidString .contains("8EC90004-F315-4F60-9FB8-838830DAEA50") {
                print(c.uuid.uuidString)
                savedCharacteristic = c
                connectedPeripheral!.setNotifyValue(true, for: c)
            }
        }
    }
    
    
    //获取蓝牙反馈值
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if(error != nil){
            print("Error Reading characteristic value: \(String(describing: error?.localizedDescription))")
        }else{
            let data = characteristic.value
            print("收到的蓝牙反馈值： \(data! as NSData)")
            //            manager.cancelPeripheralConnection(peripheral)
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
    func writeToPeripheral(myData:NSData) {
        if savedCharacteristic != nil {
            connectedPeripheral!.writeValue(myData as Data, for: savedCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
}
