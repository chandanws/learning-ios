//
//  ViewController.swift
//  TouchTracker
//
//  Created by Xiaoke Zhang on 2017/8/17.
//  Copyright © 2017年 Xiaoke Zhang. All rights reserved.
//

import UIKit

class DrawViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func loadView() {
        self.view = DrawView(frame:UIScreen.main.bounds)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

