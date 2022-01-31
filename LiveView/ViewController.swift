//
//  ViewController.swift
//  LiveView
//
//  Created by Danylo Kostyshyn on 25.01.2022.
//

import Cocoa
import LiveViewKit

class ViewController: NSViewController {
    
    private lazy var context: LVContext = {
        let context = LVContext.sharedInstance()
        context.delegate = self
        return context
    }()
    
    private let scrollView = NSTextView.scrollableTextView()
    private var textView: NSTextView { scrollView.documentView as! NSTextView }
    private let imageView = NSImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureViews()
        context.start()
    }
        
    func configureViews() {
        textView.textColor = NSColor.textColor
        
        view.addSubview(scrollView)
        view.addSubview(imageView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

extension ViewController {
    
    func appendLog(_ str: String) {
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.textColor]
        textView.textStorage?.append(NSAttributedString(string: str, attributes: attrs))
        textView.scrollToEndOfDocument(nil)
    }

}

extension ViewController: LVContextDelegate {
    
    func context(_ context: LVContext, logMessage message: UnsafeMutablePointer<CChar>?) {
        guard let cStr = message else { return }
        let str = String(cString: cStr)
        print(str, terminator: "")
        DispatchQueue.main.async {
            self.appendLog(str)
        }
    }
    
    func context(_ context: LVContext, didReceiveFrameData data: UnsafeMutablePointer<UInt8>, width: Int, height: Int) {
        DispatchQueue.main.async {
            let imageRef = image(from: data, size: (width, height))
            self.imageView.image = imageRef.flatMap { NSImage(cgImage: $0, size: NSZeroSize) }
        }
    }
    
}
