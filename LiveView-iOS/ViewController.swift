//
//  ViewController.swift
//  LiveView-iOS
//
//  Created by Danylo Kostyshyn on 25.01.2022.
//

import UIKit
import LiveViewKit

class ViewController: UIViewController {
    
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupLibs()
        configureViews()
    }
    
    func setupLibs() {
        let cb: (@convention(c) (UnsafeMutablePointer<CChar>?) -> ()) = cFunction { cStr in
            guard let cStr = cStr else { return }
            let str = String(cString: cStr)
            print(str, terminator: "")
            self.appendLog(str)
        }
        init_log_cb(cb)
        testlibusb()
        uvc_example()
    }
    
    func configureViews() {
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func appendLog(_ str: String) {
        textView.textStorage.append(NSAttributedString(string: str))
    }


}

