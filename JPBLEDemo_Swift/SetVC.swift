//
//  SetVC.swift
//  JPBLEDemo_Swift
//
//  Created by csj on 2018/5/9.
//  Copyright © 2018年 yintao. All rights reserved.
//

import UIKit

class SetVC: UIViewController {
    
    
    @IBOutlet weak var hardwareField: UITextField!
    @IBOutlet weak var firmwareField: UITextField!
//    @IBOutlet weak var typeField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let userDefault = UserDefaults.standard
        let oneValue = userDefault.string(forKey: "hardwareKey")
        hardwareField.text = oneValue
        let twoValue = userDefault.string(forKey: "firmwareKey")
        firmwareField.text = twoValue
    }
    
    @IBAction func saveVersion(_ sender: UIButton) {
        if (((hardwareField.text?.count)!>0)&&((firmwareField.text?.count)!>0)) {
            let userDefault = UserDefaults.standard
            userDefault.set(hardwareField.text, forKey: "hardwareKey")
            userDefault.set(firmwareField.text, forKey: "firmwareKey")
            self.navigationController?.popViewController(animated: true)
        } else {
            let alertController = UIAlertController.init(title: "设置", message: "请输入设置信息!", preferredStyle: .alert)
            self.present(alertController, animated: true) {
                alertController.dismiss(animated: false, completion: {
                    sleep(UInt32(2))
                })
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
