//
//  ViewController.swift
//  LiveView
//
//  Created by Danylo Kostyshyn on 25.01.2022.
//

import Cocoa
import LiveViewKit

class ViewController: NSViewController {
    
    private let scrollView = NSTextView.scrollableTextView()
    private var textView: NSTextView { scrollView.documentView as! NSTextView }

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
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func appendLog(_ str: String) {
        textView.textStorage?.append(NSAttributedString(string: str))
        textView.scrollToEndOfDocument(nil)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

