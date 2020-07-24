//
//  SwiftUIToUIKitViewController.swift
//  UIKitSwiftUIDemo
//
//  Created by Danilo Campos on 6/16/20.
//  Copyright © 2020 Danilo Campos. See license file.
//

import UIKit
import SwiftUI

class SwiftUIToUIKitViewController: UIViewController {
    
    @IBOutlet weak var swiftUIContainerView: UIView!
    @IBOutlet weak var demoSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let swiftUIToggler = SwiftUISwitchToggle(externalSwitch: demoSwitch)
        let hostingController = UIHostingController(rootView: swiftUIToggler)
        
        hostingController.view.frame = swiftUIContainerView.bounds
        self.swiftUIContainerView.addSubview(hostingController.view)
        
    }
}
