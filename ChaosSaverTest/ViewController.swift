//
//  ViewController.swift
//  ChaosSaverTest
//
//  Created by Charles Liske on 2/12/23.
//

import Cocoa
import ScreenSaver

class ViewController: NSViewController {
    
    private var saver: ScreenSaverView?
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        addScreensaver()

                timer = Timer.scheduledTimer(withTimeInterval: 1.0/30,
                                             repeats: true) { [weak self] _ in
                    self?.saver?.animateOneFrame()
                }
        // Do any additional setup after loading the view.
    }
    
    deinit {
            timer?.invalidate()
        }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    private func addScreensaver() {
            if let saver = ChaosSaverView(frame: view.frame, isPreview: false) {
                view.addSubview(saver)
                self.saver = saver
            }
        }


}

