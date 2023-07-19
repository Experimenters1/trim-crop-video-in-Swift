//
//  ViewController.swift
//  test1
//
//  Created by huy on 7/17/23.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMedia
import AssetsLibrary
import Photos

class ViewController: UIViewController {
    
    var isPlaying = true
    var isSliderEnd = true
    var playbackTimeCheckerTimer: Timer! = nil
    let playerObserver: Any? = nil
    
    let exportSession: AVAssetExportSession! = nil
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var asset: AVAsset!
    
    var url:NSURL! = nil
    var startTime: CGFloat = 0.0
    var stopTime: CGFloat  = 0.0
    var thumbTime: CMTime!
    var thumbtimeSeconds: Int!
    
    var videoPlaybackPosition: CGFloat = 0.0
    var cache:NSCache<AnyObject, AnyObject>!
    var rangeSlider: RangeSlider! = nil
    
    
    @IBOutlet weak var layoutContainer_test: UIView!
    @IBOutlet weak var selectButton_test: UIButton!
    @IBOutlet weak var videoLayer_test: UIView!
    @IBOutlet weak var cropButton_test: UIButton!
    
    
    @IBOutlet weak var frameContainerView_test: UIView!
    @IBOutlet weak var imageFrameView_test: UIView!
    
    @IBOutlet weak var startView_test: UIView!

    @IBOutlet weak var startTimeText_test: UILabel!
    

    
    @IBOutlet weak var endView_test: UIView!

    @IBOutlet weak var endTimeText_test: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let fileManager = FileManager.default
        guard let documentsFolderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        print(documentsFolderURL)
        
        loadViews()
        // Do any additional setup after loading the view.
    }
    
    func loadViews()
    {
      //Whole layout view
        layoutContainer_test.layer.borderWidth = 1.0
        layoutContainer_test.layer.borderColor = UIColor.white.cgColor
      
        selectButton_test.layer.cornerRadius = 5.0
        cropButton_test.layer.cornerRadius   = 5.0
      
      //Hiding buttons and view on load
        cropButton_test.isHidden         = true
        startView_test.isHidden          = true
        endView_test.isHidden            = true
      frameContainerView_test.isHidden = true
      
      //Style for startTime
      startTimeText_test.layer.cornerRadius = 5.0
      startTimeText_test.layer.borderWidth  = 1.0
      startTimeText_test.layer.borderColor  = UIColor.white.cgColor
      
      //Style for endTime
      endTimeText_test.layer.cornerRadius = 5.0
      endTimeText_test.layer.borderWidth  = 1.0
      endTimeText_test.layer.borderColor  = UIColor.white.cgColor
      
      imageFrameView_test.layer.cornerRadius = 5.0
      imageFrameView_test.layer.borderWidth  = 1.0
      imageFrameView_test.layer.borderColor  = UIColor.white.cgColor
      imageFrameView_test.layer.masksToBounds = true
      
      player = AVPlayer()

      
      //Allocating NsCahe for temp storage
      cache = NSCache()
    }
    
    
    //Action for select Video
    @IBAction func selectVideoUrl_test(_ sender: Any) {
        //Selecting Video type
        let myImagePickerController        = UIImagePickerController()
        myImagePickerController.sourceType = .photoLibrary
        myImagePickerController.mediaTypes = [(kUTTypeMovie) as String]
        myImagePickerController.delegate   = self
        myImagePickerController.isEditing  = false
        present(myImagePickerController, animated: true, completion: {  })
    }
    
    //Action for crop video
    @IBAction func cropVideo_test(_ sender: Any) {
        let start = Float(startTimeText_test.text!)
        let end   = Float(endTimeText_test.text!)
        cropVideo(sourceURL1: url, startTime: start!, endTime: end!)
    }
    
    

}

//Subclass of VideoMainViewController

extension ViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate{
    //Delegate method of image picker
      func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
          picker.dismiss(animated: true, completion: nil)
          
          url = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.mediaURL.rawValue)] as? NSURL
          asset   = AVURLAsset.init(url: url as URL)

          thumbTime = asset.duration
          thumbtimeSeconds      = Int(CMTimeGetSeconds(thumbTime))
          
          viewAfterVideoIsPicked()
          
          let item:AVPlayerItem = AVPlayerItem(asset: asset)
          player                = AVPlayer(playerItem: item)
          playerLayer           = AVPlayerLayer(player: player)
          playerLayer.frame     = videoLayer_test.bounds
          
          playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
          player.actionAtItemEnd   = AVPlayer.ActionAtItemEnd.none

          let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnVideoLayer))
          videoLayer_test.addGestureRecognizer(tap)
          tapOnVideoLayer(tap: tap)
          
          videoLayer_test.layer.addSublayer(playerLayer)
          player.play()
      }
    
    
    func viewAfterVideoIsPicked()
    {
      //Rmoving player if alredy exists
      if(playerLayer != nil)
      {
        playerLayer.removeFromSuperlayer()
      }
      
      createImageFrames()
      
      //unhide buttons and view after video selection
      cropButton_test.isHidden         = false
      startView_test.isHidden          = false
      endView_test.isHidden            = false
      frameContainerView_test.isHidden = false
      
      
      isSliderEnd = true
      startTimeText_test.text! = "\(0.0)"
      endTimeText_test.text   = "\(thumbtimeSeconds!)"
      createRangeSlider()
    }
    
    
    //Tap action on video player
      @objc func tapOnVideoLayer(tap: UITapGestureRecognizer)
    {
      if isPlaying
      {
        player.play()
      }
      else
      {
        player.pause()
      }
      isPlaying = !isPlaying
    }
    
    
    //MARK: CreatingFrameImages
    func createImageFrames()
    {
      //creating assets
      let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: asset)
      assetImgGenerate.appliesPreferredTrackTransform = true
      assetImgGenerate.requestedTimeToleranceAfter    = CMTime.zero;
      assetImgGenerate.requestedTimeToleranceBefore   = CMTime.zero;
      
      
      assetImgGenerate.appliesPreferredTrackTransform = true
      let thumbTime: CMTime = asset.duration
      let thumbtimeSeconds  = Int(CMTimeGetSeconds(thumbTime))
      let maxLength         = "\(thumbtimeSeconds)" as NSString

      let thumbAvg  = thumbtimeSeconds/6
      var startTime = 1
      var startXPosition:CGFloat = 0.0
      
      //loop for 6 number of frames
      for _ in 0...5
      {
        
        let imageButton = UIButton()
        let xPositionForEach = CGFloat(imageFrameView_test.frame.width)/6
        imageButton.frame = CGRect(x: CGFloat(startXPosition), y: CGFloat(0), width: xPositionForEach, height: CGFloat(imageFrameView_test.frame.height))
        do {
          let time:CMTime = CMTimeMakeWithSeconds(Float64(startTime),preferredTimescale: Int32(maxLength.length))
          let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
          let image = UIImage(cgImage: img)
          imageButton.setImage(image, for: .normal)
        }
        catch
          _ as NSError
        {
          print("Image generation failed with error (error)")
        }
        
        startXPosition = startXPosition + xPositionForEach
        startTime = startTime + thumbAvg
        imageButton.isUserInteractionEnabled = false
        imageFrameView_test.addSubview(imageButton)
      }
      
    }
    
    //Create range slider
    func createRangeSlider()
    {
      //Remove slider if already present
      let subViews = frameContainerView_test.subviews
      for subview in subViews{
        if subview.tag == 1000 {
          subview.removeFromSuperview()
        }
      }

      rangeSlider = RangeSlider(frame: frameContainerView_test.bounds)
      frameContainerView_test.addSubview(rangeSlider)
      rangeSlider.tag = 1000
      
      //Range slider action
      rangeSlider.addTarget(self, action: #selector(ViewController.rangeSliderValueChanged(_:)), for: .valueChanged)
      
      let time = DispatchTime.now() + Double(Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
      DispatchQueue.main.asyncAfter(deadline: time) {
        self.rangeSlider.trackHighlightTintColor = UIColor.clear
        self.rangeSlider.curvaceousness = 1.0
      }

    }
    
    //MARK: rangeSlider Delegate
      @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
      player.pause()
      
      if(isSliderEnd == true)
      {
        rangeSlider.minimumValue = 0.0
        rangeSlider.maximumValue = Double(thumbtimeSeconds)
        
        rangeSlider.upperValue = Double(thumbtimeSeconds)
        isSliderEnd = !isSliderEnd

      }
          
          

//      startTimeText_test.text = "\(rangeSlider.lowerValue)"
//      endTimeText_test.text   = "\(rangeSlider.upperValue)"
          
          
          let lowerValueString = String(format: "%.2f", rangeSlider.lowerValue)
          let upperValueString = String(format: "%.2f", rangeSlider.upperValue)

          startTimeText_test.text = lowerValueString
          endTimeText_test.text = upperValueString
      
      //print(rangeSlider.lowerLayerSelected)
      if(rangeSlider.lowerLayerSelected)
      {
        seekVideo(toPos: CGFloat(rangeSlider.lowerValue))

      }
      else
      {
        seekVideo(toPos: CGFloat(rangeSlider.upperValue))
        
      }
          
      //print(startTime)
    }
    
    
    //MARK: TextField Delegates
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
      let maxLength     = 3
      let currentString = startTimeText_test.text! as NSString
      let newString     = currentString.replacingCharacters(in: range, with: string) as NSString
      return newString.length <= maxLength
    }
    
    
    //Seek video when slide
    func seekVideo(toPos pos: CGFloat) {
      videoPlaybackPosition = pos
      let time: CMTime = CMTimeMakeWithSeconds(Float64(videoPlaybackPosition), preferredTimescale: player.currentTime().timescale)
      player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
      
      if(pos == CGFloat(thumbtimeSeconds))
      {
      player.pause()
      }
    }
    
    
    
    //Trim Video Function
    func cropVideo(sourceURL1: NSURL, startTime:Float, endTime:Float)
    {
      let manager                 = FileManager.default
      
      guard let documentDirectory = try? manager.url(for: .documentDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: nil,
                                                     create: true) else {return}
      guard let mediaType         = "mp4" as? String else {return}
      guard (sourceURL1 as? NSURL) != nil else {return}
      
      if mediaType == kUTTypeMovie as String || mediaType == "mp4" as String
      {
        let length = Float(asset.duration.value) / Float(asset.duration.timescale)
        //print("video length: \(length) seconds")
        
        let start = startTime
        let end = endTime
        //print(documentDirectory)
        var outputURL = documentDirectory.appendingPathComponent("output")
        do {
          try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
          //let name = hostent.newName()
          outputURL = outputURL.appendingPathComponent("1.mp4")
        }catch let error {
          print(error)
        }
        
        //Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
        exportSession.outputURL = outputURL
          exportSession.outputFileType = AVFileType.mp4
        
        let startTime = CMTime(seconds: Double(start ), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(end ), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously{
          switch exportSession.status {
          case .completed:
            print("exported at \(outputURL)")
                  self.saveToCameraRoll(URL: outputURL as NSURL?)
          case .failed:
              print("failed \(String(describing: exportSession.error))")
            
          case .cancelled:
              print("cancelled \(String(describing: exportSession.error))")
            
          default: break
    }}}}
    
    //Save Video to Photos Library
    func saveToCameraRoll(URL: NSURL!) {
        PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL as URL)
      }) { saved, error in
        if saved {
          DispatchQueue.main.async {
              let alertController = UIAlertController(title: "Cropped video was successfully saved", message: nil, preferredStyle: .alert)
              let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
              alertController.addAction(defaultAction)
              self.present(alertController, animated: true, completion: nil)
          }
      }}}

    
}

