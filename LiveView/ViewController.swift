//
//  ViewController.swift
//  LiveView
//
//  Created by Danylo Kostyshyn on 25.01.2022.
//

import Cocoa
import LiveViewKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        testlibusb()
        uvc_example()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

