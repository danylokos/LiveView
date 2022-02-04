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
    
    func configureButtonsView() -> NSView {
        let buttonConfigs = [
            ("arrow.clockwise.circle", #selector(reload(_:))),
            ("command.circle", #selector(changeFrameDesc(_:))),
        ]
        let buttons: [NSButton] = buttonConfigs.map { (iconName, sel) in
            let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)!
            let button = NSButton(image: image, target: self, action: sel)
            return button
        }
        let stackView = NSStackView(views: buttons)
        return stackView
    }
    
    func configureViews() {
        let buttonsContainer = configureButtonsView()
        
        textView.textColor = NSColor.textColor
        
        view.addSubview(scrollView)
        view.addSubview(imageView)
        view.addSubview(buttonsContainer)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            buttonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5.0),
            buttonsContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 5.0)
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

    @objc func reload(_ sender: NSButton) {
        context.reload()
    }

    @objc func changeFrameDesc(_ sender: NSButton) {
        let frameDesc = LVFrameDesc(width: 1920, height: 1080, fps: 30)
        context.change(frameDesc)
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
    
    func context(_ context: LVContext, didUpdateFrameDescriptions frameDescs: UnsafeMutablePointer<LVFrameDesc>, count: UInt8) {
        let frameDescs = (0..<Int(count)).map { frameDescs[$0] }
        frameDescs.forEach {
            print("\($0.width)x\($0.height) @ \($0.fps)fps")
        }
    }
    
    func context(_ context: LVContext, didReceiveFrameData data: UnsafeMutablePointer<UInt8>, width: Int, height: Int) {
        DispatchQueue.main.async {
            let imageRef = image(from: data, size: (width, height))
            self.imageView.image = imageRef.flatMap { NSImage(cgImage: $0, size: NSZeroSize) }
        }
    }
    
}
