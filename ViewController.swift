//
//  ViewController.swift
//  VoiceNote
//
//  Created by Vinay Venkatesh on 11/12/20.
//

import UIKit
import AVFoundation
import Speech


class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    
    @IBOutlet weak var SaveBTN: UIButton!
    @IBOutlet weak var ClearText: UIButton!
    @IBOutlet weak var TextBox: UITextField!
    @IBOutlet weak var RecordBTN: UIButton!
    @IBOutlet weak var MuteBTN: UIButton!
    @IBOutlet weak var PlayStopBTN: UIButton!
    var soundRecorder : AVAudioRecorder!
    var soundPlayer : AVAudioPlayer?
    var fileName = "audioFile.m4a"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRecorder()
        MuteBTN.isHidden = true
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //Dispose of any resources that can be recreated
    }
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                }
            }
        }
    }

    func setupRecorder(){
        
        let recordSettings = [AVFormatIDKey : kAudioFormatAppleLossless,
                              AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                              AVEncoderBitRateKey : 320000, AVNumberOfChannelsKey : 2,
                              AVSampleRateKey : 44100.0 ] as [String : Any]
        do {
            try soundRecorder = AVAudioRecorder(url: getFileURL() as URL, settings: recordSettings as [String : AnyObject])
        } catch {
            NSLog("Something's Wrong")
        }
        
        do {
            soundRecorder.delegate = self
            soundRecorder.prepareToRecord()
        }
    }
    
    func getCacheDirectory() -> String {
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        return paths[0]
    }
    
    func getFileURL() throws -> NSURL{
        let path = NSURL(fileURLWithPath: getCacheDirectory()).appendingPathComponent(fileName)
        let pathString = (path?.path)!
        let filePath = NSURL(fileURLWithPath: pathString)
        
        return filePath
        
    }
    var counter = 0

    @IBAction func SaveButton(_ sender: UIButton) {
        counter += 1
        let alert = UIAlertController(title: "Set File Name", message: "", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Enter File Name"
        }

        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
            guard let textField = alert?.textFields?[0], let userText = textField.text else { return }
            print("User text: \(userText)")
            
            let fileName = userText
            let dir = try? FileManager.default.url(for: .documentDirectory,
                  in: .userDomainMask, appropriateFor: nil, create: true)

            // If the directory was found, we write a file to it and read it back
            if let fileURL = dir?.appendingPathComponent(fileName).appendingPathExtension("txt") {
                print(fileURL)
                print("Dir Found")
                //print(fileURL)

                // Write to the file named Test
                let outString = self.TextBox.text
                do {
                    try outString?.write(to: fileURL, atomically: true, encoding: .utf8)
                    print("Text Saved")
                } catch {
                    print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
                }
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func PrintText(_ sender: UIButton) {
        if sender.titleLabel?.text == "Print Text"{
            do{
                try transcribeAudio(url: getFileURL() as URL)
            } catch {
                print("Error")
            }
            sender.setTitle("Print Text", for: .normal)
        }
    }
    
    @IBAction func RecordAudio(_ sender: UIButton) {
        if ((UIImage(named:"record")!.isEqual(sender.image(for: .normal)))) {
            MuteBTN.isHidden = false
            requestTranscribePermissions()
            RecordBTN.setImage(UIImage(named:"recording"), for: .normal)
            soundRecorder.record()
        } else {
            MuteBTN.isHidden = true
            RecordBTN.setImage(UIImage(named:"record"), for: .normal)
            soundRecorder.stop()
        }
    }
    
    @IBAction func MuteMic(_ sender: UIButton) {
        if ((UIImage(named:"mute")!.isEqual(sender.image(for: .normal)))) {
            MuteBTN.setImage(UIImage(named:"unmute"), for: .normal)
            soundRecorder.pause()
        } else {
            MuteBTN.setImage(UIImage(named:"mute"), for: .normal)
            soundRecorder.record()
        }
    }
    
    @IBAction func PlayAudio(_ sender: UIButton) {
        if ((UIImage(named:"start")!.isEqual(sender.image(for: .normal)))) {
            PlayStopBTN.setImage(UIImage(named:"stop"), for: .normal)
            preparePlayer()
            soundPlayer?.play()
        } else {
            soundPlayer?.stop()
            PlayStopBTN.setImage(UIImage(named:"start"), for: .normal)
        }
    }
    
    
    @IBAction func ClearTextBox(_ sender: UIButton) {
        TextBox.text = ""
    }
    
    func preparePlayer(){
        do {
            try soundPlayer = AVAudioPlayer(contentsOf: getFileURL() as URL)
        } catch {
            NSLog("Something's Wrong")
        }
        do{
            soundPlayer?.delegate = self
            soundPlayer?.prepareToPlay()
            soundPlayer?.volume = 50.0
        }
        let path = NSURL(fileURLWithPath: getCacheDirectory()).appendingPathComponent(fileName)
        let pathString = (path?.path)!
        let asset = AVURLAsset(url: NSURL(fileURLWithPath: pathString) as URL, options: nil)
        let audioDuration = asset.duration
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
        
        if (audioDurationSeconds <= 0) {
            print("No audio recorded")
            PlayStopBTN.setImage(UIImage(named:"start"), for: .normal)
        }
    }
    
    func transcribeAudio(url: URL) {
        // create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)

        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                TextBox.insertText(result.bestTranscription.formattedString)
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        PlayStopBTN.setImage(UIImage(named:"start"), for: .normal)
    }
}

