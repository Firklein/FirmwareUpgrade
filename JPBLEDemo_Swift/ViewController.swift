//
//  ViewController.swift
//  JPBLEDemo_Swift
//
//  Created by yintao on 2016/10/18.
//  Copyright © 2016年 yintao. All rights reserved.
//

import UIKit
import CoreBluetooth

enum Enum_state:Int{
    case DeviceWoshou = 0
    case DeviceGetVersion
    case DeviceSetting
    case DeviceUpdate
    case DeviceFirm
    case DevicePackage
    case DeviceZip
}

//1为豪力士，2为中国结
let LOCKDEVICE = "2"
//豪力士的添加参数 waibao_id = 829858890
//中国结的添加参数 waibao_id = 815844231
let WAIBAOID = "815844231"
var comple = false

class ViewController: UIViewController {
    
    
    
    
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
    
    var dfuPeri:CBPeripheral!
    
    var stupState:Enum_state!
    //系统蓝牙管理对象
    var manager : CBCentralManager!
    var discoveredPeripheralsArr :[CBPeripheral?] = []
    var advertisementDataArr : [NSDictionary?] = []
    var tableView : UITableView!
    //连接的外围
    var connectedPeripheral : CBPeripheral!
    //保存的设备特性
    var savedCharacteristic : CBCharacteristic!
    /*
     *  蓝牙特性--固件升级
     */
    var uploadCha : CBCharacteristic!
    //kIndex值
    var kIndex : String!//kIndex
    var macStr : String!//mac
    var pwStr  : String!//密码
    var handKey: String!
    var settingKey : String!
    var isConnect:Bool!
    
    var lastString : NSString!
    var sendString : NSString!

    //需要连接的 CBCharacteristic 的 UUID
    let ServiceUUID1 =  "0000FFE7"
    let firmUpdateUUID = "FE59"
    
    //硬件版本
    var hardwareVersion:String!
    //固件版本
    var firmwareVersion:String!
    var flagCount = 0
    var firmData:NSData!
    //升级包
    var packageUrl:String!
    
//    var activity:UIActivityIndicatorView!
    var backView:UIView!
    var proLabel:UILabel!
    fileprivate var uploadManage:HYUploadManage!
    
    
    @IBOutlet weak var hardLabel: UILabel!
    @IBOutlet weak var firmLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let rightButton = UIButton.init(type: UIButtonType.custom)
        rightButton.frame = CGRect(x: 0,y: 0,width: 60,height: 20)
        rightButton.setTitle("设置版本", for: UIControlState.normal)
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        rightButton.setTitleColor(UIColor.red, for: UIControlState.normal)
        rightButton.addTarget(self, action: #selector(ViewController.goSetVersion), for: UIControlEvents.touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: rightButton)
        
        manager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
        
    }
    
    //测试固件升级
    @IBAction func testUpdateFirm(_ sender: Any) {
        let updateVC = FirmUpdateVC()
        self.navigationController?.pushViewController(updateVC , animated: true)
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
    
    //进入设置页面
    func goSetVersion() {
        let setView = SetVC()
        //跳转
        self.navigationController?.pushViewController(setView , animated: true)
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
    
    //固件升级
    @IBAction func updateDevice(_ sender: UIButton) {
        let alertView = UIAlertController(title: "", message: "请输入密码", preferredStyle: .alert)
        alertView.addTextField {  (textField: UITextField!) -> Void in
            textField.placeholder = "请输入密码"
            textField.isSecureTextEntry = true
            textField.keyboardType = UIKeyboardType.numberPad
        }
        let acSure = UIAlertAction(title: "确定", style: UIAlertActionStyle.destructive) { (UIAlertAction) -> Void in
            print("click Sure")
            let password = alertView.textFields?.first
            self.pwStr = password?.text
            print(self.pwStr)
            if (self.isConnect == true) {
                self.stupState = Enum_state.DeviceWoshou
                let url1 = "https://lock.ke-er.com/lockerp/ajax/mobile.jsp?action=getSettingKey&mac="+self.macStr+"&kIndex="+self.kIndex
                let url2 = "&password="+self.pwStr+"&waibao_id="+WAIBAOID
                let url = url1+url2
                self.getDeviceUpdatepakge(updateUrl: url)
            }
        }
        let acCancel = UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel) { (UIAlertAction) -> Void in
            print("click Cancel")
        }
        alertView.addAction(acCancel)
        alertView.addAction(acSure)
        self.present(alertView, animated: true, completion: nil)
        
    }
    
    //获取固件版本号
    @IBAction func firmwareUpdate(_ sender: UIButton) {
        if (self.isConnect == true) {
            self.stupState = Enum_state.DeviceGetVersion
            let url1 = "https://lock.ke-er.com/lockerp/ajax/mobile.jsp?action=getHandKeyEncry&mac="+self.macStr+"&kIndex="+self.kIndex
            let url2 = "&waibao_id="+WAIBAOID
            let url = url1+url2
            self.getDeviceUpdatepakge(updateUrl: url)
        } else {
            let alertController = UIAlertController.init(title: "", message: "未连接蓝牙!", preferredStyle: .alert)
            self.present(alertController, animated: true) {
                alertController.dismiss(animated: false, completion: {
                    sleep(UInt32(2))
                })
            }
        }
    }
    
    //开始解密握手指令后的反馈内容
    func goSettingMode(setData:NSData) {
        let dataStr = ((setData.description.replacingOccurrences(of: " ", with: "")).replacingOccurrences(of: "<", with: "")).replacingOccurrences(of: ">", with: "")
        let url1 = "https://lock.ke-er.com/lockerp/ajax/mobile.jsp?action=getKeyDecry&mac="+self.macStr+"&kIndex="+self.kIndex
        let url2 = "&encKey="+dataStr+"&waibao_id="+WAIBAOID
        let url = url1+url2
        self.getDecryptionData(decryUrl: url)
    }
    
    //解密指令
    func jiemimingwen(jieData:NSData) {
        let dataStr = ((jieData.description.replacingOccurrences(of: " ", with: "")).replacingOccurrences(of: "<", with: "")).replacingOccurrences(of: ">", with: "")
        let url1 = "https://lock.ke-er.com/lockerp/ajax/mobile.jsp?action=getKeyDecry&mac="+self.macStr+"&kIndex="+self.kIndex
        let url2 = "&encKey="+dataStr+"&waibao_id="+WAIBAOID
        let url = url1+url2
        self.getDecryptionData(decryUrl: url)
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
        manage.setTargetPeripheral(dfuPeri) 
        manage.scanVC(self)
        manage.startDFUProcess()
    }
    
    //获取后台数据
    func getDeviceUpdatepakge(updateUrl:String) {
        //1.创建请求路径
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
            //解析json
            //参数options：.MutableContainers(json最外层是数组或者字典选这个选项)
            
            if (self.stupState == Enum_state.DeviceZip) {
                var domains = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                if domains.count > 0 {
                    let url = NSURL(fileURLWithPath: domains[0]+"/zipfile.zip")
                    do {
                        try! data?.write(to: url as URL)
                        //发送固件升级指令
                        self.stupState = Enum_state.DeviceFirm
                        self.writeToPeripheral(myData: self.firmData)
                    } catch {
                        print(error)
                    }
                }
            } else {
                if data != nil{
                    let dict = try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                    if (self.stupState == Enum_state.DeviceGetVersion) {
                        self.getDeviceVersionLink(dict: dict as! NSDictionary)
                    } else if (self.stupState == Enum_state.DeviceWoshou) {
                        self.getShakeHandsLink(dict: dict as! NSDictionary)
                    } else if (self.stupState == Enum_state.DeviceSetting) {
                        
                    } else if (self.stupState == Enum_state.DeviceUpdate) {
                        print(dict)
                        self.getUpdateFirmware(dict: dict as! NSDictionary)
                    } else if (self.stupState == Enum_state.DevicePackage) {
                        let packDict:NSDictionary = dict as! NSDictionary
                        self.packageUrl = packDict["url"] as? String
                        self.getZip(url: self.packageUrl)
                    }
                } else{
                    print("请求数据失败")
                }
            }
        }
        //5.开始执行任务
        task.resume()
    }
    
    //获取后台数据
    func getDecryptionData(decryUrl:String) {
        print("数据请求路径111:\(decryUrl)")
        let url = NSURL(string: decryUrl)
        let request = NSURLRequest.init(url: url! as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if data != nil{
                let dict = try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                
                
                if (self.stupState == Enum_state.DeviceGetVersion) {
                    self.getDeviceVersion(dict: dict as! NSDictionary)
                } else if (self.stupState == Enum_state.DeviceWoshou) {
                    print("握手指令解密后的内容:\(dict)")
                    self.getVersion(dict: dict as! NSDictionary)
                }
                if (self.stupState == Enum_state.DeviceSetting) {
                    print("进入设置指令解密后的内容:\(dict)")
                    
                    self.getFirmwarePackage()
                }
                if (self.stupState == Enum_state.DeviceFirm) {
                    print("固件升级指令解密后的内容:\(dict)")
//                    self.getFirmwarePackage()
                }
            } else{
                print("请求数据失败")
            }
        }
        //5.开始执行任务
        task.resume()
    }
    
    
    //获取握手指令
    func getShakeHandsLink(dict:NSDictionary) {
        self.handKey = dict["handKey"] as? String
        self.settingKey = dict["settingKey"] as? String
        print("握手指令:\(String(describing: self.handKey))----进入设置指令：\(String(describing: self.settingKey))")
        let shData:NSData = self.hexToBytes(hexString: self.handKey)
        print(shData)
        //发送握手指令
        self.writeToPeripheral(myData: shData)
        print("开始发送握手指令")
    }
    
    
    //为获取固件版本做准备  ----
    func getDeviceVersionLink(dict:NSDictionary) {
        let handkey = dict["handKey"] as! String
        let shData:NSData = self.hexToBytes(hexString: handkey)
        print(shData)
        //发送握手指令
        print("为获取版本号---开始发送握手指令")
        self.writeToPeripheral(myData: shData)
    }
    
    func getDeviceVersion(dict:NSDictionary) {
        print("为获取固件版本--开始解密获取硬件版本，固件版本")
        let setKey = dict["operKey"] as! String
        //硬件版本
        let aRange:NSRange = NSMakeRange(6, 2)
        let one = setKey.substring(with: setKey.range(from: aRange)!)
        let aRangeTwo:NSRange = NSMakeRange(8, 2)
        let two = setKey.substring(with: setKey.range(from: aRangeTwo)!)
        DispatchQueue.main.async(execute: {
            self.hardLabel.text = "当前硬件版本："+(one+two)
        })
        
        print("当前硬件版本："+(one+two))
        
        //固件版本
        let bRange:NSRange = NSMakeRange(10, 2)
        let three = setKey.substring(with: setKey.range(from: bRange)!)
        let bRangeTwo:NSRange = NSMakeRange(12, 2)
        let four = setKey.substring(with: setKey.range(from: bRangeTwo)!)
        DispatchQueue.main.async(execute:{
            self.firmLabel.text = "当前固件版本："+(three+four)
        })
        print("当前固件版本："+(three+four))
    }
    
    //获取硬件和固件版本号   然后发送进入设置模式指令
    func getVersion(dict:NSDictionary) {
        print("开始解密获取硬件版本，固件版本")
        let setKey = dict["operKey"] as! String
        
        let userDefault = UserDefaults.standard
        let oneValue = userDefault.string(forKey: "hardwareKey")
        let twoValue = userDefault.string(forKey: "firmwareKey")
        
        //硬件版本
        let aRange:NSRange = NSMakeRange(6, 2)
        let one = setKey.substring(with: setKey.range(from: aRange)!)
        let aRangeTwo:NSRange = NSMakeRange(8, 2)
        let two = setKey.substring(with: setKey.range(from: aRangeTwo)!)
        hardwareVersion = one+two
        DispatchQueue.main.async(execute: {
            self.hardLabel.text = "当前硬件版本："+self.hardwareVersion
        })
        
        print(hardwareVersion)
        
        //固件版本
        let bRange:NSRange = NSMakeRange(10, 2)
        let three = setKey.substring(with: setKey.range(from: bRange)!)
        let bRangeTwo:NSRange = NSMakeRange(12, 2)
        let four = setKey.substring(with: setKey.range(from: bRangeTwo)!)
        firmwareVersion = three+four
        DispatchQueue.main.async(execute:{
            self.firmLabel.text = "当前固件版本："+self.firmwareVersion
        })
        print(firmwareVersion)
        
        print("开始判断是否具备升级条件")
//        if (oneValue == hardwareVersion) {//固件版本一样
            if ((twoValue?.caseInsensitiveCompare(firmwareVersion).rawValue) == 1 || (twoValue?.caseInsensitiveCompare(firmwareVersion).rawValue) == 0) {
                self.stupState = Enum_state.DeviceUpdate
                let url1 = "https://lock.ke-er.com/lockerp/ajax/mobile.jsp?action=getUpdateKey&mac="+self.macStr+"&kIndex="+self.kIndex
                let url2 = "&dVersion="+oneValue!+"&gVersion="+twoValue!+"&waibao_id="+WAIBAOID
                let url = url1+url2
                self.getDeviceUpdatepakge(updateUrl: url)
            } else {
                print("不具备升级条件")
                let alertController = UIAlertController.init(title: "固件升级", message: "固件太低，不具备升级条件!", preferredStyle: .alert)
                self.present(alertController, animated: true) {
                    alertController.dismiss(animated: false, completion: {
                        sleep(UInt32(2))
                    })
                }
            }
//        } else {
//            print("硬件版本不一致，不具备升级条件")
//            let alertController = UIAlertController.init(title: "固件升级", message: "硬件版本不一致，不具备升级条件!", preferredStyle: .alert)
//            self.present(alertController, animated: true) {
//                alertController.dismiss(animated: false, completion: {
//                    sleep(UInt32(2))
//                })
//            }
//        }
    }
    
    //获取固件更新指令
    func getUpdateFirmware(dict:NSDictionary) {
        let updateKey = dict["updateKey"]
        print("服务器请求到的固件升级指令:\(updateKey as! String)")
        let updateData:NSData = self.hexToBytes(hexString: updateKey as! String)
        firmData = updateData
        
        
        self.stupState = Enum_state.DeviceSetting
        //发送进入设置模式指令
        let setData:NSData = self.hexToBytes(hexString: self.settingKey)
        self.writeToPeripheral(myData: setData)
        print("开始发送进入设置模式指令")
    }
    
    //获取固件升级包
    func getFirmwarePackage() {
        self.stupState = Enum_state.DevicePackage
//        let userDefault = UserDefaults.standard
//        let typeValue = userDefault.string(forKey: "typeKey")
//        var lockType = "2"
//        if (typeValue?.count)!>0  {
//            lockType = typeValue!
//        } else {
//            lockType = "2"
//        }
        
        let url = "https://lock.ke-er.com/lockerp/ajax/mobile.jsp?action=deviceUpdate" 
        let urlStr = url + "&updateType="+LOCKDEVICE
        self.getDeviceUpdatepakge(updateUrl: urlStr)
    }
    
    func getZip(url:String) {
        print("开始获取固件升级包")
        self.stupState = Enum_state.DeviceZip
        self.getDeviceUpdatepakge(updateUrl: url)
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
        let dict:NSDictionary = advertisementDataArr[indexPath.row]!
        let aData:NSData = dict.value(forKey: "kCBAdvDataManufacturerData") as! NSData
        let dataStr = ((aData.description.replacingOccurrences(of: " ", with: "")).replacingOccurrences(of: "<", with: "")).replacingOccurrences(of: ">", with: "")
        kIndex = dataStr
        macStr = selectedPeripheral?.name?.components(separatedBy: "-").last
        manager.connect(selectedPeripheral!, options: nil)
        
        print("kindex值：\(kIndex,"") ---mac值： \(String(describing: macStr))")
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
            dfuPeri = peripheral
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
        connectedPeripheral = nil;
//        self.startScan()
    }
    ///断开
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        print("连接到名字为222 \(String(describing: peripheral.name)) 的设备断开，原因是 \(String(describing: error?.localizedDescription))")
        self.startScan()
//        let alertView = UIAlertController.init(title: "抱歉", message: "蓝牙设备\(String(describing: peripheral.name) )连接断开，请重新扫描设备连接", preferredStyle: UIAlertControllerStyle.alert)
//        alertView.show(self, sender: nil)
        connectedPeripheral = nil;
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
                } else if c.uuid.uuidString .contains("8EC90001") {
                    peripheral.setNotifyValue(true, for: c)
                } else if c.uuid.uuidString .contains("8EC90002") {
                    self.uploadCha = c;
                }
            }
        } else {
            for c in service.characteristics! {
                print("特征id：\(c.uuid.uuidString)")
                if c.uuid.uuidString .contains("0000FEC8") {
                    print(c.uuid.uuidString)
                    peripheral.setNotifyValue(true, for: c)
                }
                if c.uuid.uuidString .contains("0000FEC7") {
                    print(c.uuid.uuidString)
                    savedCharacteristic = c
                }
            }
        }
    }
    
    
    //获取蓝牙反馈值s
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if(error != nil){
            print("Error Reading characteristic value: \(String(describing: error?.localizedDescription))")
        }else{
            let data = characteristic.value
            print("收到的蓝牙反馈值： \(data! as NSData)")
            if (stupState == Enum_state.DeviceGetVersion) {
                self.flagCount+=1
                if flagCount == 1 {
                    self.goSettingMode(setData: data! as NSData)
                }
                
            } else if (stupState == Enum_state.DeviceWoshou) {
                self.goSettingMode(setData: data! as NSData)
            } else if (stupState == Enum_state.DeviceSetting) {
                self.jiemimingwen(jieData: data! as NSData)
            } else if (stupState == Enum_state.DeviceFirm) {
//                self.jiemimingwen(jieData: data! as NSData)
                
                let shData:NSData = self.hexToBytes(hexString: "01")
                self.firmUpdateWriteToPeri(myData: shData);
                sleep(3)
//                manager.cancelPeripheralConnection(peripheral)
            }
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
    
    func firmUpdateWriteToPeri(myData:NSData) {
        if self.uploadCha != nil {
            connectedPeripheral.writeValue(myData as Data, for: self.uploadCha, type: CBCharacteristicWriteType.withResponse);
        }
    }
}
