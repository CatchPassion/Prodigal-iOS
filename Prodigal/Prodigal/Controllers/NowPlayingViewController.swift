//
//  NowPlayingViewController.swift
//  Prodigal
//
/**   Copyright 2017 Bob Sun
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 *  Created by ___FULLUSERNAME___ on ___DATE___.
 *
 *          _
 *         ( )
 *          H
 *          H
 *         _H_
 *      .-'-.-'-.
 *     /         \
 *    |           |
 *    |   .-------'._
 *    |  / /  '.' '. \
 *    |  \ \ @   @ / /
 *    |   '---------'
 *    |    _______|
 *    |  .'-+-+-+|              I'm going to build my own APP with blackjack and hookers!
 *    |  '.-+-+-+|
 *    |    """""" |
 *    '-.__   __.-'
 *         """
 **/



import UIKit
import MediaPlayer
import StoreKit

import SnapKit
import MarqueeLabel

import Holophonor

class NowPlayingViewController: TickableViewController {
    
    
    var playingView: NowPlayingView = NowPlayingView()
    let seekView: SeekView = SeekView()
    private var _song: MediaItem!
    private var currentSelectionType: MenuMeta.MenuType! = .NowPlayingPopSeek
    var song: MediaItem {
        set {
            _song = newValue
            playingView.image.image = _song.getArtworkWithSize(size: CGSize(width: 200, height: 200)) ?? #imageLiteral(resourceName: "ic_album")
            playingView.title.text = _song.title
            playingView.artist.text = _song.artist
            playingView.album.text = _song.albumTitle
        }
        get {
            return _song
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playingView.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func attachTo(viewController vc: UIViewController, inView view:UIView) {
        vc.addChild(self)
        view.addSubview(self.view)
        self.view.isHidden = true
        self.view.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(view)
            maker.center.equalTo(view)
        }
        
        self.view.addSubview(playingView)
        playingView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.top.equalTo(self.view)
        }
        playingView.layoutIfNeeded()
        
        self.view.addSubview(seekView)
        seekView.snp.makeConstraints({ (maker) in
            maker.leading.trailing.bottom.top.equalToSuperview()
        })
    }
    
    override func hide(type: AnimType = .push, completion: @escaping () -> Void) {
        self.view.isHidden = true
        completion()
        PubSub.unsubscribe(target: self, name: PlayerTicker.kTickEvent)
    }
    
    override func show(type: AnimType) {
        self.view.isHidden = false
        self.playingView.loadTheme()
        PubSub.subscribe(target: self, name: PlayerTicker.kTickEvent, handler: {(notification:Notification) -> Void in
            let (current, duration) = (notification.userInfo?[PlayerTicker.kCurrent] as! Double , notification.userInfo?[PlayerTicker.kDuration] as! Double)
            let progress = Float(current) / Float(duration)
            DispatchQueue.main.async {
                self.playingView.progress.setProgress(progress, animated:true)
                self.playingView.updateLabels(now: current, all: duration)
            }
        })
        if #available(iOS 10.3, *) {
            let rand = Int.random(in: 0...10)
            if (rand >= 5) {
                SKStoreReviewController.requestReview()
            }
        }
    }
    
    override func getSelection() -> MenuMeta {
        if seekView.showMode != .Seek {
            return MenuMeta(name: "", type: .NowPlayingPopSeek)
        }
        if seekView.isHidden {
            return MenuMeta(name: "", type: .NowPlayingPopSeek)
        } else {
            seekView.showMode = .Volume
            seekView.toggle()
            return MenuMeta(name: "", type: .NowPlayingDoSeek).setObject(obj: Double(seekView.seekBar.progress))
        }
    }

    override func onNextTick() {
        seekView.onIncrease()
    }
    override func onPreviousTick() {
        seekView.onDecrease()
    }
    
    func show(withSong song: MediaItem?, type: AnimType = .push) {
        self.view.isHidden = false
        if song == nil {
            //Mark - TODO: Empty view
            return
        }
        playingView.loadTheme()
        self.song = song!
        PubSub.subscribe(target: self, name: PlayerTicker.kTickEvent, handler: {(notification:Notification) -> Void in
            let (current, duration) = (notification.userInfo?[PlayerTicker.kCurrent] as! Double , notification.userInfo?[PlayerTicker.kDuration] as! Double)
            let progress = Float(current) / Float(duration)
            DispatchQueue.main.async {
                self.playingView.progress.setProgress(progress, animated:true)
                self.playingView.updateLabels(now: current, all: duration)
            }
        })
    }
    
    private func initViews() {
    }
    
    func popSeek() {
        seekView.showMode = .Seek
        seekView.toggle()
    }
}

class NowPlayingView: UIView {
    
    let image = UIImageView()
    let title = MarqueeLabel(), artist = MarqueeLabel(), album = MarqueeLabel(), total = UILabel(), current = UILabel()
    let progressContainer = UIView()
    let progress = UIProgressView()
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
        addSubview(image)
        addSubview(title)
        addSubview(artist)
        addSubview(album)
        addSubview(progressContainer)
        
        progressContainer.snp.makeConstraints { (maker) in
            maker.leading.bottom.equalTo(self).offset(8)
            maker.trailing.equalTo(self).offset(-8)
            maker.height.equalTo(64)
        }
        progressContainer.addSubview(progress)
        
        progress.snp.makeConstraints { (maker) in
            maker.leading.trailing.top.equalTo(progressContainer)
            maker.height.equalTo(10)
        }
        progress.trackTintColor = UIColor.lightGray
        progressContainer.backgroundColor = UIColor.clear
        progressContainer.addSubview(current)
        progressContainer.addSubview(total)
        
        current.snp.makeConstraints { (maker) in
            maker.leading.bottom.equalToSuperview()
            maker.top.equalTo(progress.snp.bottomMargin).offset(5)
            maker.width.equalTo(100)
        }
        
        total.snp.makeConstraints { (maker) in
            maker.trailing.bottom.equalToSuperview()
            maker.top.equalTo(progress.snp.bottomMargin).offset(5)
            maker.width.equalTo(100)
        }
        current.textAlignment = .left
        total.textAlignment = .right
        
        image.snp.makeConstraints { (maker) in
            maker.leading.top.equalTo(self).offset(8)
            maker.trailing.equalTo(self.snp.centerX).offset(-8)
            maker.bottom.equalTo(progressContainer.snp.top)
        }
        image.image = #imageLiteral(resourceName: "ic_album")
        image.contentMode = .scaleAspectFit
        
        title.snp.makeConstraints { (maker) in
            maker.leading.equalTo(self.snp.centerX).offset(8)
            maker.trailing.equalTo(self).offset(-8)
            maker.height.equalTo(30)
            maker.centerY.equalTo(self).offset(-60)
        }
        title.speed = .duration(8)
        title.fadeLength = 10
        
        album.snp.makeConstraints { (maker) in
            maker.leading.trailing.height.equalTo(title)
            maker.centerY.equalTo(self).offset(-15)
        }
        album.speed = .duration(8)
        album.fadeLength = 10
        
        artist.snp.makeConstraints { (maker) in
            maker.leading.trailing.height.equalTo(album)
            maker.centerY.equalTo(self).offset(30)
        }
        artist.speed = .duration(8)
        artist.fadeLength = 10
        
    }
    
    func loadTheme() {
        let color = ThemeManager.currentTheme.textColor
        
        title.textColor = color
        album.textColor = color
        artist.textColor = color
        total.textColor = color
        current.textColor = color
    }
    
    func updateLabels(now: TimeInterval, all: TimeInterval) {
        let (minNow, secNow) = (Int(now / 60), Int(now.truncatingRemainder(dividingBy:60)))
        let (minAll, secAll) = (Int(all / 60), Int(all.truncatingRemainder(dividingBy:60)))
        
        current.text = "\(String(format:"%02d", minNow)):\(String(format:"%02d", secNow))"
        total.text = "\(String(format:"%02d", minAll)):\(String(format:"%02d", secAll))"
    }
}
