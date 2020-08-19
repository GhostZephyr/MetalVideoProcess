//
//  NaviViewController.swift
//  SimpleVideoTransition
//
//  Created by RenZhu Macro on 2020/7/2.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit
import MetalVideoProcess
import AVFoundation
import MetalVideoProcess

class NaviViewController: UIViewController {
    @IBOutlet weak var naviStackView: UIStackView!

    var transitionTimeRange = CMTimeRange.init()
    
    let N = 14
    private func getTransition(index: Int) -> (titleName: String, transObject: MetalVideoProcessTransition) {
        switch index {
        case 0:
        return (titleName: "倒影", transObject: MetalVideoProcessReflectTransition())
        case 1:
        return (titleName: "闪白", transObject: MetalVideoProcessShanBaiTransition())
        case 2:
        return (titleName: "向下擦除", transObject: MetalVideoProcessEraseDownTransition())
        case 3:
        return (titleName: "叠化", transObject: MetalVideoProcessFadeTransition())
        case 4:
        return (titleName: "镜像翻转", transObject: MetalVideoProcessMirrorRotateTransition())
        case 5:
        return (titleName: "燃烧", transObject: MetalVideoProcessBurnTransition())
        case 6:
        return (titleName: "立方体", transObject: MetalVideoProcessCubeTransition())
        case 7:
        return (titleName: "向上擦除", transObject: MetalVideoProcessEraseUpTransition())
        case 8:
        return (titleName: "向左擦除", transObject: MetalVideoProcessEraseLeftTransition())
        case 9:
        return (titleName: "向右擦除", transObject: MetalVideoProcessEraseRightTransition())
        case 10:
        return (titleName: "变形", transObject: MetalVideoProcessMorphTransition())
        case 11:
        return (titleName: "圆形蒙版", transObject: MetalVideoProcessCircleEraseTransition())
        case 12:
        return (titleName: "上移", transObject: MetalVideoProcessVerticalUpGlitchTransition())
        default:
        return (titleName: "倒影", transObject: MetalVideoProcessReflectTransition())
        }
    }
    private func getButton(index: Int) -> UIButton {
        let splitNum = 5.0
        let pieceWidth = Double(self.view.frame.width) / splitNum
        let buttonWidth = pieceWidth * 0.8
        let dIndex = Double(index)
        let indexX = fmod(dIndex, splitNum) * pieceWidth
        let indexY = (floor(dIndex / splitNum)) * pieceWidth + 100.0
        
        let buttonFrame = CGRect(x: indexX, y: indexY, width: buttonWidth, height: buttonWidth)
        
        let but = UIButton(frame: buttonFrame)
        but.backgroundColor = UIColor(red: 0.3, green: 0.4, blue: 0.3, alpha: 0.7)
        but.setTitle(getTransition(index: index).titleName, for: .normal)
       
        but.titleLabel?.adjustsFontSizeToFitWidth = true
        but.addTarget(self, action: #selector(self.swithController(_:)), for: .touchUpInside)
        
        but.tag = index
        return but
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for index in 0...N - 1 {
            self.view.addSubview(getButton(index: index))
        }
    }
    
    @IBAction func swithController(_ sender: UIButton) {
        
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController")  as! ViewController
        
        let trans = getTransition(index: sender.tag)
        
        viewController.transition = trans.transObject
        
        self.present(viewController, animated: true, completion: nil)
    }
}


