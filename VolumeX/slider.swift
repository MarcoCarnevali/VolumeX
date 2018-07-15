//
//  slider.swift
//  VolumeIndicator
//
//  Created by Marco Carnevali on 14/07/2018.
//  Copyright © 2018 Marco Carnevali. All rights reserved.
//
import UIKit
import Foundation
import MediaPlayer

protocol volumeSliderDelegate {
    func shouldHideStatusBar(hide:Bool)
}

class volumeSlider: UIView {
    
    fileprivate let sliderWidth:CGFloat = 35
    fileprivate let sliderHeight:CGFloat = 5
    fileprivate let sliderX:CGFloat = 42
    fileprivate let sliderY:CGFloat = 0
    fileprivate let totWidth:CGFloat = 60
    fileprivate let totHeight:CGFloat = 10
    fileprivate let totX:CGFloat = 0
    fileprivate let totY:CGFloat = 21
    fileprivate let cornerRadius:CGFloat = 2
    fileprivate let notificationCenter = NotificationCenter.default
    fileprivate let audioSession = AVAudioSession.sharedInstance()
    fileprivate var delegate:volumeSliderDelegate?
    fileprivate var timer = Timer()
    fileprivate let volumeImage = UIImageView()
    fileprivate let slider = UIView()
    fileprivate let overColor = UIView()
    
    fileprivate struct Observation {
        static let VolumeKey = "outputVolume"
        static var Context = 0
    }
    
    //MARK: - INIT
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSlider()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupSlider()
    }
    
    fileprivate func setupSlider() {
        self.frame = CGRect(x: totX, y: totY, width: totWidth, height: totHeight)
        self.slider.frame = CGRect(x: sliderX, y: sliderY, width: sliderWidth, height: sliderHeight)
        self.slider.layer.cornerRadius = cornerRadius
        self.slider.backgroundColor = .lightGray
        self.addSubview(slider)
        setupImage()
        setupOverColor()
        listenToChanges()
    }
    
    
    fileprivate func setupImage(){
        self.volumeImage.frame = CGRect(x: sliderX-25, y: sliderY-10/2, width: 20, height: 15)
        self.volumeImage.alpha = 0
        self.addSubview(volumeImage)
    }
    fileprivate func setImage(level:Int) {
        if level == 0 {
            self.volumeImage.image = UIImage(named: "volumeMute")
        }else if level > 0 && level <= 5 {
            self.volumeImage.image = UIImage(named: "volumeMin")
        }else if level > 5 && level <= 10 {
            self.volumeImage.image = UIImage(named: "volumeMedium")
        }else if level > 10 && level <= 16 {
            self.volumeImage.image = UIImage(named: "volumeMax")
        }
        
        
    }
    
    fileprivate func setupOverColor(){
        overColor.frame = CGRect(x: 0, y: 0, width: 0, height: sliderHeight)
        overColor.backgroundColor = .black
        overColor.layer.cornerRadius = self.cornerRadius
        self.slider.addSubview(overColor)
    }
    
    public func setVolume(level:CGFloat){
        timer.invalidate()
        self.shouldHideVolumeSlider(hide: false)
        if level < 0 || level > 16 { return }
        let totalOfLevels:CGFloat = 16
        let overWidth: CGFloat = self.sliderWidth / totalOfLevels * level
        if overWidth < 0 || overWidth > sliderWidth { return }
        UIView.animate(withDuration: 0.3) {
            self.setImage(level: Int(level))
            self.overColor.frame.size.width = overWidth
        }
        self.delegate?.shouldHideStatusBar(hide: true)
        
        setTimer()
    }
    
    fileprivate func setTimer(){
        self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func timerFired(){
        self.delegate?.shouldHideStatusBar(hide: false)
        self.shouldHideVolumeSlider(hide: true)
    }

    fileprivate func listenToChanges(){
        do {
            try audioSession.setActive(true)
            audioSession.addObserver(self, forKeyPath: Observation.VolumeKey, options: [.initial, .new], context: &Observation.Context)
        }
        catch {
            print("Failed to activate audio session")
        }
        
       
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &Observation.Context {
            if keyPath == Observation.VolumeKey, let volume = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue {
                let realVolume:CGFloat = CGFloat(volume * 16)
                self.setVolume(level: realVolume)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    fileprivate func shouldHideVolumeSlider(hide:Bool){
        var alpha:CGFloat = 0
        if !hide { alpha = 1 }
        UIView.animate(withDuration: 0.4) {
            self.slider.alpha = alpha
            self.volumeImage.alpha = alpha
        }
    }
}

class volumeXController: UIViewController,volumeSliderDelegate {
    
    var isStatusBarHidden:Bool = false{
        didSet{
            UIView.animate(withDuration: 0.5) { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    let volume = volumeSlider()
    
    func enableVolumeX(){
        
        volume.delegate = self
        self.view.addSubview(volume)
        let volumeView = MPVolumeView(frame: .zero)
        view.addSubview(volumeView)
    }
    
    func shouldHideStatusBar(hide: Bool) {
        isStatusBarHidden = hide
    }
    
    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
}

