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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true // Disable screen dimming
        configureViews()
        context.start()
    }
        
    func configureViews() {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
        let logButton = UIButton(type: .system)
        logButton.setImage(UIImage(systemName: "doc.circle", withConfiguration: largeConfig), for: .normal)
        
        logButton.addTarget(self, action: #selector(toggleLogs(_:)), for: .touchUpInside)
        let photoButton = UIButton(type: .system)
        photoButton.setImage(UIImage(systemName: "camera.circle", withConfiguration: largeConfig), for: .normal)
        photoButton.addTarget(self, action: #selector(takePhoto(_:)), for: .touchUpInside)
        
        [logButton, photoButton].forEach {
            $0.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        }
        
        let stackView = UIStackView(arrangedSubviews: [logButton, photoButton])
        stackView.axis = .vertical
        stackView.spacing = 5
        
        imageView.contentMode = .scaleAspectFill
        textView.alpha = 0.5
        
        view.addSubview(imageView)
        view.addSubview(textView)
        view.addSubview(stackView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5.0),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -5.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func toggleLogs(_ sender: UIButton) {
        textView.isHidden.toggle()
    }
    
    @objc func takePhoto(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    func appendLog(_ str: String) {
        textView.textStorage.append(NSAttributedString(string: str))
        let range = NSMakeRange(textView.text.count - 1, 0)
        textView.scrollRangeToVisible(range)
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
            self.imageView.image = imageRef.flatMap{ UIImage(cgImage: $0) }
        }
    }
    
}
