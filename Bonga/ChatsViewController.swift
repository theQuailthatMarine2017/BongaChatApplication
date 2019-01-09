//
//  ChatsViewController.swift
//  Bonga
//
//  Created by RastaOnAMission on 16/10/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import FirebaseFirestore

class ChatsViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, IQAudioRecorderViewControllerDelegate {
    
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var chatRoomId: String!
    var memberIds: [String]!
    var membersToPush: [String]!
    var titleName: String!
    var isGroup: Bool?
    var group: NSDictionary?
    var withUser: [FUser] = []
    
    let legitTypes = [kAUDIO,kVIDEO,kTEXT,kLOCATION,kPICTURE]
    
    var maxMessageNumber = 0
    var minMessageNumber = 0
    var loadOld = false
    var loadedMessageCount = 0
    
    var typingCounter = 0
    var typingListener: ListenerRegistration?
    var updatedMessageListener: ListenerRegistration?
    var newChatListener: ListenerRegistration?
    
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessages: [NSDictionary] = []
    var allPictureMessages: [String] = []
    var initialLoadComplete = false
    
    var jsqAvatarDictionary: NSMutableDictionary?
    var avatarImageDictionary: NSMutableDictionary?
    var showAvatar = true
    var firstLoad: Bool?
    
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    let leftBarButton: UIView = {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 80))
        return view
        
    }()
    
    
    let avatarButton: UIButton = {
        
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
        
    }()
    
    let titleLabel: UILabel = {
        
        let label = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        label.textAlignment = .left
        label.font = UIFont(name: label.font.fontName, size: 14)
        return label
    }()
    
    let subTitle: UILabel = {
        
        let title = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 10)
        
        return title
        
    }()
    
    override func viewDidLayoutSubviews() {
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createTypingObserver()
        navigationItem.largeTitleDisplayMode = .never
        
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        setCustomHeader()
        loadMessages()
        
        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()!.firstname
        
        jsqAvatarDictionary = [ : ]
        
        // fix for iphone x
        let constraint = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        
        constraint.priority = UILayoutPriority(rawValue: 1000)
        
        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        // custom send button
        
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
       
    }
    
    func createTypingObserver() {
        
        typingListener = reference(.Typing).document(chatRoomId).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else {
                return
            }
            
            if snapshot.exists {
                
                for data in snapshot.data()! {
                    
                    if data.key != FUser.currentId() {
                        
                        let typing = data.value as! Bool
                        self.showTypingIndicator = typing
                        
                        if typing {
                            self.scrollToBottom(animated: true)
                        }
                        
                    }
                }
                
            } else {
                reference(.Typing).document(self.chatRoomId).setData([FUser.currentId() : false])
            }
            
        })
        
    }
    
    func typingCounterStart() {
        
        typingCounter += 1
        
        typingCounterSave(typing: true)
        
        self.perform(#selector(self.typingCounterStop), with: nil, afterDelay: 2.0)
        
        
        
    }
    
    @objc func typingCounterStop() {
        
        typingCounter -= 1
        
        if typingCounter == 0 {
            typingCounterSave(typing: false)
        }
    }
    
    func typingCounterSave(typing: Bool) {
        
        reference(.Typing).document(chatRoomId).updateData([FUser.currentId() : typing])
        
    }
    
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        typingCounterStart()
        
        return true
    }
    
    // set cutstom header title
    
    func setCustomHeader() {
        
        leftBarButton.addSubview(avatarButton)
        leftBarButton.addSubview(titleLabel)
        leftBarButton.addSubview(subTitle)
        leftBarButton.addSubview(avatarButton)
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
        
        self.navigationItem.rightBarButtonItem = infoButton
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButton)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        if isGroup! {
            avatarButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
        } else {
            avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
        }
        
        getUsersFromFirestore(withIds: memberIds) { (withUsers) in
            
            self.withUser = withUsers
            self.getAvatarImages()
            if !self.isGroup! {
                self.setUpUIForSingleChat()
            }
        }
        
    }
    
    func getAvatarImages() {
        
        if showAvatar {
            
            collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
            
            avatarImageFrom(fuser: FUser.currentUser()!)
            
            for user in withUser {
                avatarImageFrom(fuser: user)
            }
        }
        
    }
    
    func avatarImageFrom(fuser: FUser) {
        
        if fuser.avatar != "" {
            dataImageFromString(pictureString: fuser.avatar) { (imageData) in
                
                if imageData == nil {
                    return
                }
                
                if self.avatarImageDictionary != nil {
                    self.avatarImageDictionary!.removeObject(forKey: fuser.objectId)
                    self.avatarImageDictionary!.setObject(imageData!, forKey: fuser.objectId as NSCopying)
                } else {
                    self.avatarImageDictionary = [fuser.objectId : imageData!]
                }
                // create JSQ Avatars
                self.createJSQMessageAvatar(avatarDictionary: self.avatarImageDictionary)
            }
        }
        
    }
    
    func createJSQMessageAvatar(avatarDictionary: NSMutableDictionary?) {
        
        let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        
        if avatarDictionary != nil {
            for memberId in memberIds {
                if let avatarImageData = avatarDictionary![memberId] {
                    let jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: avatarImageData as! Data), diameter: 70)
                    
                    self.jsqAvatarDictionary!.setValue(jsqAvatar, forKey: memberId)
                } else {
                    self.jsqAvatarDictionary!.setValue(defaultAvatar, forKey: memberId)
                }
            }
            
            self.collectionView.reloadData()
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = messages[indexPath.row]
        
        var avatar: JSQMessageAvatarImageDataSource
        
        if let testAvatar = jsqAvatarDictionary!.object(forKey: message.senderId) {
            avatar = testAvatar as! JSQMessageAvatarImageDataSource
        } else {
            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        }
        return avatar
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        
        let senderId = messages[indexPath.row].senderId
        var selectedUser: FUser?
        
        if senderId  == FUser.currentId() {
            selectedUser = FUser.currentUser()
        } else {
            for user in withUser {
                if user.objectId == senderId {
                    selectedUser = user
                }
            }
        }
        // show profile picture
        presentUserProfile(forUser: selectedUser!)
    }
    
    func presentUserProfile(forUser: FUser) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userProfile") as! UserProfileTableViewController
        
        profileVC.user = forUser
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    @objc func infoButtonPressed() {
        
        let mediaVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mediaGallery") as! PictureGalleryCollectionViewController
        mediaVC.allImageLinks = allPictureMessages
        self.navigationController?.pushViewController(mediaVC, animated: true)
        
    }
    
    @objc func showGroup() {
        
        print("show group")
        
    }
    
    func setUpUIForSingleChat() {
        
        let withUsers = withUser.first!
        
        imageFromData(pictureData: withUsers.avatar) { (image) in
            
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        
        titleLabel.text = withUsers.fullname
        
        if withUsers.isOnline {
            subTitle.text = "Online"
        } else {
            subTitle.text = "Offline"
        }
        
        avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
    }
    
    @objc func showUserProfile() {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userProfile") as! UserProfileTableViewController
        
        profileVC.user = withUser.first!
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    // jsq data source functions
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        
        if data.senderId != FUser.currentId() {
            if data.text != nil {
                cell.textView.textColor = UIColor.black
            }
        }

        if data.senderId == FUser.currentId() {
            if data.text != nil {
                cell.textView.textColor = UIColor.white
            }
        }
        
        return cell
        
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId() {
            return outgoingBubble
        } else {
            return incomingBubble
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        
        if indexPath.item % 3 == 0 {
            let message = messages[indexPath.row]
            
            return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        let message = objectMessages[indexPath.row]
        let status: NSAttributedString
        let attributedStringColor = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        
        switch message[kSTATUS] as! String {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            let statusText = "Read" + " " + readTimefrom(dateString: message[kREADDATE] as! String)
            
            status = NSAttributedString(string: statusText, attributes: attributedStringColor)
        default:
            status = NSAttributedString(string: "✔️")
        }
        
        if indexPath.row == (messages.count - 1) {
            return status
        } else {
            return NSAttributedString(string: "")
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId() {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
    @objc func backAction() {
        
        clearRecentCounter(chatRoomId: chatRoomId)
        stopListeners()
        self.navigationController?.popViewController(animated: true)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
        let camera = Camera(delegate_: self)
        
        let optionsMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            
            camera.PresentMultyCamera(target: self, canEdit: true)
            
        }
        
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            
            camera.PresentVideoLibrary(target: self, canEdit: true)
        }
        
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            
            if self.haveAccessToUserLocation() {
                
                self.sendMessage(text: nil, date: Date(), picture: nil, location: kLOCATION, video: nil, audio: nil)
                
            }
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        optionsMenu.addAction(takePhotoOrVideo)
        optionsMenu.addAction(sharePhoto)
        optionsMenu.addAction(shareVideo)
        optionsMenu.addAction(shareLocation)
        optionsMenu.addAction(cancelAction)
        
        if ( UI_USER_INTERFACE_IDIOM() == .pad) {
            if let currentPopoverpresentioncontroller = optionsMenu.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentioncontroller.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionsMenu,animated: true, completion: nil)
            }
        } else {
            self.present(optionsMenu, animated: true, completion: nil)
        }
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        sendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        
        picker.dismiss(animated: true, completion: nil)
    }
    

    
    
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        if text != "" {
            self.sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            updateSendButton(isSend: false)
        } else {
            
            let audioVC = AudioViewController(delegate_: self)
            audioVC.presentAudioRecorder(target: self)
            
        }
        
        
    }
    override func textViewDidChange(_ textView: UITextView) {
        
        if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
    }
    func updateSendButton(isSend: Bool) {
        
        if isSend {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        } else {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
    }
    
    // audio
    
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        
        controller.dismiss(animated: true, completion: nil)
        
        self.sendMessage(text: nil, date: Date(), picture: nil, location: nil, video: nil, audio: filePath)
    }
    
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        
        var outgoingMessages: OutGoingMessages?
        let currentUser = FUser.currentUser()!
        
        // text message
        
        if let text = text {
            
            outgoingMessages = OutGoingMessages(message: text, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        
        // picture message
        
        if let pic = picture {
            
            uploadImage(image: pic, chatRoomId: chatRoomId, view: self.navigationController!.view) { (imageLink) in
                
                if imageLink != nil {
                    
                    let text = "[\(kPICTURE)]"
                    
                    outgoingMessages = OutGoingMessages(message: text, pictureLink: imageLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessages?.sendMessage(chatRoomID: self.chatRoomId, messageDictonary: outgoingMessages!.messageDictionary, membersId: self.memberIds, membersToPush: self.membersToPush)
                    
                    
                }
            }
            
            return
        }
        
        // video message
        
        if let video = video {
            
            let videoData = NSData(contentsOfFile: video.path!)
            let thumbnail = videoThumbnail(video: video).jpegData(compressionQuality: 0.3)
            
            uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: self.navigationController!.view) { (videoLink) in
                
                if videoLink != nil {
                    
                    let text = "[\(kVIDEO)]"
                    
                    outgoingMessages = OutGoingMessages(message: text, video: videoLink!, thumbNail: thumbnail! as NSData, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessages?.sendMessage(chatRoomID: self.chatRoomId, messageDictonary: outgoingMessages!.messageDictionary, membersId: self.memberIds, membersToPush: self.membersToPush)
                    
                }
                
            }
            return
            
            
        }
        
        //send audio
        
        if let audioPath = audio {
            
            uploadAudio(audioPath: audioPath, chatRoomId: chatRoomId, view: self.navigationController!.view) { (audioLink) in
                
                if audioLink != nil {
                    
                    let text = "[\(kAUDIO)]"
                    
                    outgoingMessages = OutGoingMessages(message: text, audio: audioLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kAUDIO)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessages?.sendMessage(chatRoomID: self.chatRoomId, messageDictonary: outgoingMessages!.messageDictionary, membersId: self.memberIds, membersToPush: self.membersToPush)
                }
            }
            return
        }
        
        // send location
        
        if location != nil {
            
            let lat: NSNumber = NSNumber(value: appDelegate.coordinates!.latitude)
            let long: NSNumber = NSNumber(value: appDelegate.coordinates!.longitude)
            
            let text = "[\(kLOCATION)]"
            
            outgoingMessages = OutGoingMessages(message: text, latitude: lat, longitude: long, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kLOCATION)
            
        }
        
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessages!.sendMessage(chatRoomID: chatRoomId, messageDictonary: outgoingMessages!.messageDictionary, membersId: memberIds, membersToPush: membersToPush)
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
        self.loadMoreMessages(maxNumber: maxMessageNumber, minNumber: minMessageNumber)
        self.collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        print("did tap message bubble")
        
        let messageDictionary = objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        switch messageType {
        case kPICTURE:
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQPhotoMediaItem
            
            let photos = IDMPhoto.photos(withImages: [mediaItem.image])
            
            let browser = IDMPhotoBrowser(photos: photos)
            
            self.present(browser!, animated: true, completion: nil)
            
        case kLOCATION:
            
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQLocationMediaItem
            
            let mapView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "map") as! MapViewController
            
            mapView.location = mediaItem.location
            
            self.navigationController?.pushViewController(mapView, animated: true)
            
        case kVIDEO:
            
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! VideoMessage
            
            let player = AVPlayer(url: mediaItem.fileUrl! as URL)
            
            let moviePlayer = AVPlayerViewController()
            
            let session = AVAudioSession.sharedInstance()
            
            try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            
            moviePlayer.player = player
            
            self.present(moviePlayer, animated: true) {
                
                moviePlayer.player!.play()
            }
            
        default:
            print("Text message")
        }
        
    }
    
    
    
    func loadMessages() {
        
        updatedMessageListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else {
                return
            }
            
            if !snapshot.isEmpty {
                
                snapshot.documentChanges.forEach({ (change) in
                    
                    if change.type == .modified {
                        
                        self.updateMessage(messageDictionary: change.document.data() as NSDictionary)
                        
                    }
                    
                })
                
            }
            
        })
        
        
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            
            guard let snapshot = snapshot else {
                self.initialLoadComplete = true
                self.listenForNewChats()
                return
            }
            
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            self.loadedMessages = self.removeBadMessages(allMessages: sorted)
            
            self.insertMessage()
            self.finishReceivingMessage(animated: true)
            self.initialLoadComplete = true
            
            // get picture messages
            self.getPictureMessages()
            
            // get old messages in background
            self.getOldMessages()
            self.listenForNewChats()
            
            
            
        }
        
    }
    
    func updateMessage(messageDictionary: NSDictionary) {
        
        for index in 0 ..< objectMessages.count {
            let temp = objectMessages[index]
            
            if messageDictionary[kMESSAGEID] as! String == temp[kMESSAGEID] as! String {
                objectMessages[index] = messageDictionary
                self.collectionView!.reloadData()
            }
        }
        
    }
    
    func listenForNewChats() {
        
        var lastMessageDate = "0"
        
        if loadedMessages.count > 0 {
            lastMessageDate = loadedMessages.last![kDATE] as! String
        }
        
        newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else {
                return
            }
            
            if !snapshot.isEmpty {
                
                for diff in snapshot.documentChanges {
                    
                    if (diff.type == .added) {
                        
                        let item = diff.document.data() as NSDictionary
                        
                        if let type = item[kTYPE] {
                            
                            if self.legitTypes.contains(type as! String) {
                                
                                if type as! String == kPICTURE {
                                    self.addNewPictureMessageLink(link: item[kPICTURE] as! String)
                                }
                                
                                if self.insertIntialLoadMessage(messageDictionary: item) {
                                    
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                    
                                }
                                
                                self.getOldMessages()
                                self.finishReceivingMessage()
                            }
                        }
                        
                    }
                }
            }
            
        })
    }
    
    func getOldMessages() {
        
        if loadedMessages.count > 10 {
            
            let firstMessageDate = loadedMessages.first![kDATE] as! String
            
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                
                guard let snapshot = snapshot else {
                    return
                }
                
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                
                self.loadedMessages = self.removeBadMessages(allMessages: sorted) + self.loadedMessages
                
                // get picture messages
                self.getPictureMessages()
                
                self.maxMessageNumber = self.loadedMessages.count  - self.loadedMessageCount - 1
                self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
                
            }
            
        }
        
    }
    
    // Insert Messages
    
    func insertMessage() {
        
        maxMessageNumber = loadedMessages.count - loadedMessageCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in minMessageNumber ..< maxMessageNumber {
            
            let messageDictionary  = loadedMessages[i]
            
            insertIntialLoadMessage(messageDictionary: messageDictionary)
            loadedMessageCount += 1
        }
        
        self.showLoadEarlierMessagesHeader = (loadedMessageCount != loadedMessages.count)
        
    }
    
    func insertIntialLoadMessage(messageDictionary: NSDictionary) -> Bool {
        
        let incomingMessages = IncomingMessages(collectionView_: self.collectionView!)
        
        if (messageDictionary[kSENDERID] as! String) != FUser.currentId() {
            
            OutGoingMessages.updateMessages(withId: messageDictionary[kMESSAGEID] as! String, chatRoomId: chatRoomId, membersId: memberIds)
            
        }
        
        let message = incomingMessages.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        if message != nil {
            objectMessages.append(messageDictionary)
            messages.append(message!)
        }
        
        return isIncoming(messageDictionary: messageDictionary)
    }
    
    func loadMoreMessages(maxNumber: Int, minNumber: Int) {
        
        if loadOld {
            maxMessageNumber = minNumber - 1
            minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        }
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in (minMessageNumber ... maxMessageNumber).reversed() {
            
            let messageDictionary = loadedMessages[i]
            insertNewMessage(messageDictionary: messageDictionary)
            loadedMessageCount += 1
            
        }
        
        loadOld = true
        self.showLoadEarlierMessagesHeader = (loadedMessageCount != loadedMessages.count)
    }
    
    func insertNewMessage(messageDictionary: NSDictionary) {
        
        let incomingMessages = IncomingMessages(collectionView_: self.collectionView!)
        
        let message = incomingMessages.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
        
    }
    
    func isIncoming(messageDictionary: NSDictionary) -> Bool {
        if FUser.currentId() == messageDictionary[kSENDERID] as! String {
            return false
        } else {
            return true
        }
    }
    
    func addNewPictureMessageLink(link: String) {
        allPictureMessages.append(link)
    }
    
    func getPictureMessages() {
        allPictureMessages = []
        
        for message in loadedMessages {
            if message[kTYPE] as! String == kPICTURE {
                allPictureMessages.append(message[kPICTURE] as! String)
            }
        }
    }
    
    func removeBadMessages(allMessages: [NSDictionary]) -> [NSDictionary] {
        
        var tempMessages = allMessages
        
        for message in tempMessages {
            
            if message[kTYPE] != nil {
                if !self.legitTypes.contains(message[kTYPE] as! String) {
                    tempMessages.remove(at: tempMessages.index(of: message)!)
                }
            } else {
                tempMessages.remove(at: tempMessages.index(of: message)!)
            }
        }
        
        return tempMessages
        
    }
    
    func stopListeners() {
        
        if typingListener != nil {
            typingListener!.remove()
        }
        
        if newChatListener != nil {
            newChatListener!.remove()
        }
        
        if updatedMessageListener != nil {
            updatedMessageListener!.remove()
        }
        
    }
    
    func haveAccessToUserLocation() -> Bool {
        
        if appDelegate.locationManager != nil {
            
            return true
            
        } else {
            
            ProgressHUD.showError("Permision Are Denied")
            return false
        }
        
    }

}
