//
//  ViewController.swift
//  LiveView-iOS
//
//  Created by Danylo Kostyshyn on 25.01.2022.
//

import UIKit
import LiveViewKit

class ViewController: UIViewController {
    
    private lazy var context: LVContext = {
        let context = LVContext.sharedInstance()
        context.delegate = self
        return context
    }()
    
    private let textView = UITextView()
    private let imageView = UIImageView()
    
    private var frameDescs = [LVFrameDesc]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true // Disable screen dimming
        configureViews()
        context.start()
    }
    
    func configureButtonsContainer() -> UIView {
        let buttonConfigs = [
            ("arrow.clockwise.circle", #selector(reload(_:))),
            ("doc.circle", #selector(toggleLogs(_:))),
            ("command.circle", #selector(changeFrameDesc(_:))),
            ("camera.circle", #selector(takePhoto(_:)))
        ]
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
        let buttons: [UIButton] = buttonConfigs.map { (iconName, sel) in
            let button = UIButton(type: .system)            
            button.setImage(UIImage(systemName: iconName, withConfiguration: largeConfig), for: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
            button.addTarget(self, action: sel, for: .touchUpInside)
            return button
        }
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .vertical
        stackView.spacing = 5
        return stackView
    }
    
    func configureViews() {
        let buttonsView = configureButtonsContainer()
        
        imageView.contentMode = .scaleAspectFill
        textView.alpha = 0.5
        textView.isEditable = false
        
        view.addSubview(imageView)
        view.addSubview(textView)
        view.addSubview(buttonsView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        buttonsView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5.0),
            buttonsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -5.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func appendLog(_ str: String) {
        textView.textStorage.append(NSAttributedString(string: str))
        let range = NSMakeRange(textView.text.count - 1, 0)
        textView.scrollRangeToVisible(range)
    }

}

extension ViewController {

    @objc func reload(_ sender: UIButton) {
        context.reload()
    }
    
    @objc func toggleLogs(_ sender: UIButton) {
        textView.isHidden.toggle()
    }
    
    @objc func takePhoto(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    @objc func changeFrameDesc(_ sender: UIButton) {
        let controller = UIAlertController(
            title: "Configure",
            message: "Change frame description",
            preferredStyle: .actionSheet
        )
        // Skip first - `default` description, sort by width
        frameDescs.dropFirst().sorted { $0.width < $1.width }.forEach { frameDesc in
            controller.addAction(
                UIAlertAction(
                    title: "\(frameDesc.width)x\(frameDesc.height) @ \(frameDesc.fps)fps",
                    style: .default,
                    handler: { _ in
                        self.context.change(frameDesc)
                    })
            )}
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(controller, animated: true)
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
    
    func context(_ context: LVContext, didUpdateFrameDescriptions
                 frameDescs: UnsafeMutablePointer<LVFrameDesc>, count: UInt8) {
        DispatchQueue.main.async {
            self.frameDescs = (0..<Int(count)).map { frameDescs[$0] }
            self.frameDescs.forEach {
                self.appendLog("\($0.width)x\($0.height) @ \($0.fps)fps\n")
            }
        }
    }
    
    func context(_ context: LVContext, didReceiveFrameData data: UnsafeMutablePointer<UInt8>, width: Int, height: Int) {
        DispatchQueue.main.async {
            let imageRef = image(from: data, size: (width, height))
            self.imageView.image = imageRef.flatMap{ UIImage(cgImage: $0) }
        }
    }
    
}
