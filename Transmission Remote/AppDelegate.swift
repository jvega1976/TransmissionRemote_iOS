//
//  AppDelegate.swift
//  Transmission Remote
//
//  Created by  on 7/10/19.
//

import UIKit
import UserNotifications
import TransmissionRPC
import Categorization
import BackgroundTasks
import AVFoundation
import os

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    let defaults = UserDefaults(suiteName: TR_URL_DEFAULTS)!
    var chooseNav: UINavigationController!
    var torrentFile: TorrentFile!
    var magnetURL: MagnetURL!
    var isDownloading: Bool! = true
    var lastTimeChecked: TimeInterval!
    var session: RPCSession?
    let center = UNUserNotificationCenter.current()
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let dbConfig = [RPCServerConfig()]
        let data = try! PropertyListEncoder().encode(dbConfig)
        var appDefaults: [String: Any] = [TR_URL_CONFIG_KEY : data]
        appDefaults[TR_URL_ACTUAL_KEY] =  -1
        appDefaults[TR_URL_CONFIG_REQUEST] = 10
        appDefaults[TR_URL_CONFIG_REFRESH] = 5
        appDefaults["videoApplication"] = "none"
        appDefaults["DirectoryMapping"] = [Any]()
        appDefaults["SpeedMenuItems"] = [["rate": 50], ["rate": 100], ["rate": 250],["rate": 500],["rate": 1024]]
        appDefaults[USERDEFAULTS_KEY_WEBDAV] = "https://jvega:Nmjcup0112*@diskstation.johnnyvega.net:5006/others/Downloaded"
        defaults.register(defaults: appDefaults)
        defaults.synchronize()
        ServerConfigDB.shared.load()        
        center.requestAuthorization(options: [.alert,.criticalAlert,.sound,.badge,.provisional, .providesAppNotificationSettings], completionHandler: { granted, error in
            if !granted {
                os_log("NotificatioCenter authorization not granted")
            }
            if error != nil {
                os_log("%@",error!.localizedDescription)
            }
            // Enable or disable features based on authorization.
        })
        center.delegate = self
        center.removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        NotificationCenter.default.addObserver(self, selector: #selector(storeChanged(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
        // get changes that might have happened while this
        // instance of your app wasn't running
        NSUbiquitousKeyValueStore.default.synchronize()
        
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: "johnnyvega.Transmission-Remote.torrents", using: nil, launchHandler: { task in
                self.handleAppRefresh(bgTask: task as! BGAppRefreshTask)
        })
        
        if registered {
            os_log("Transmission Remote: Background Task registered")
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        }
        catch {
            os_log("%@",error.localizedDescription)
        }
        return true
    }

    
    @objc func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "johnnyvega.Transmission-Remote.torrents")
        if self.isDownloading {
            request.earliestBeginDate = Date(timeIntervalSinceNow: 2*60)
        } else {
            request.earliestBeginDate = Date(timeIntervalSinceNow: 120*60)
        }
        do {
            try BGTaskScheduler.shared.submit(request)
            os_log("Transmission Remote: Background Task scheduled to start after %{time_t}d",time_t(request.earliestBeginDate!.timeIntervalSince1970))
        } catch {
            guard let myError = error as? BGTaskScheduler.Error else {
                os_log("Could not schedule app refresh: %@",error.localizedDescription)
                return
            }
            switch myError.code {
                case .notPermitted:
                    os_log("App is Not permitted to launch Background Tasks")
                case .tooManyPendingTaskRequests:
                    os_log("Too many pending Tasks of the type requested")
                case .unavailable:
                    os_log("App can’t schedule background work")
                @unknown default:
                    os_log("Unknown Error")
            }
        }
    }
    
    
    @objc func handleAppRefresh(bgTask: BGAppRefreshTask) {
        
        self.scheduleAppRefresh()
        os_log("Transmission Remote: Starting Processing of Backgroud Task")
        guard let session = self.session else { return }
        
        let fields = [JSONKeys.id, JSONKeys.percentDone, JSONKeys.name, JSONKeys.status, JSONKeys.doneDate, JSONKeys.activityDate, JSONKeys.errorString]
        var arguments = JSONObject()
        arguments[JSONKeys.fields] = fields

        let request = RPCRequest(forMethod: JSONKeys.torrent_get, withArguments: arguments, usingSession: session, andPriority: .veryHigh, jsonCompletion:  { (json, error) in
            if error != nil {
                os_log("Transmission Remote: %@",error!.localizedDescription)
                return
            }
            guard let torrents = (json?[JSONKeys.arguments] as! JSONObject)[JSONKeys.torrents] as? [JSONObject] else {return}
            let lastTimeChecked = self.lastTimeChecked!
            self.lastTimeChecked = Date().timeIntervalSince1970
            self.isDownloading = torrents.contains(where:{ jsonObject in [TorrentStatus.download.rawValue, TorrentStatus.downloadWait.rawValue].contains(jsonObject[JSONKeys.status] as? Int) && jsonObject[JSONKeys.activityDate] as? TimeInterval ?? 0 >= lastTimeChecked })
            let torrentArray = torrents.filter({ jsonObject in jsonObject[JSONKeys.doneDate] as? TimeInterval ?? 0 >=  lastTimeChecked - 30 })
            var bagnumber = 0
            DispatchQueue.main.async {
                bagnumber = UIApplication.shared.applicationIconBadgeNumber
            }
            for trInfo in torrentArray {
                DispatchQueue.global(qos: .userInteractive).async {
                    let content = UNMutableNotificationContent()
                    content.title = String.localizedStringWithFormat("Torrent Finished")
                    content.body = String.localizedStringWithFormat("\"%@\" have been downloaded.", trInfo[JSONKeys.name] as! String)
                    content.sound = UNNotificationSound.default
                    content.userInfo = ["trId": trInfo[JSONKeys.id] as! Int]
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    bagnumber += 1
                    content.badge = NSNumber(value: bagnumber)
                    let request = UNNotificationRequest(identifier: trInfo[JSONKeys.name] as! String, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
                        if error != nil {
                            os_log("Transmission Remote: Notification for torrent: %@  failed with Error: %@",trInfo[JSONKeys.name] as! String, error!.localizedDescription)
                        }
                    })
                }
            }
            TorrentTableController.saveLastTimeChecked(self.lastTimeChecked)
            os_log("Transmission Remote: Finished Processing of Backgroud Task")
        })
        
        bgTask.expirationHandler = {
            // After all operations are cancelled, the completion block below is called to set the task to complete.
            request.cancel()
            os_log("Transmission Remote: Backgroud Task was Cancelled")
        }
        
        request.completionBlock = {
            os_log("Transmission Remote: Backgroud Task %@ successfully",!request.isCancelled ? "completed" : "did not completed")
            bgTask.setTaskCompleted(success: !request.isCancelled)
        }
        session.addTorrentRequest(request)
    }
    
    
    @objc func storeChanged(_ notification: Notification?) {

        let userInfo = notification?.userInfo
        let reason = userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber

        if reason != nil {
            let reasonValue = reason?.intValue ?? 0
            os_log("%@",String(format: "storeChanged with reason %ld", reasonValue))

            if (reasonValue == NSUbiquitousKeyValueStoreServerChange) || (reasonValue == NSUbiquitousKeyValueStoreInitialSyncChange) {

                let keys = userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [Any]
                let store = NSUbiquitousKeyValueStore.default
                let userDefaults = UserDefaults(suiteName: TR_URL_DEFAULTS)

                for key in keys ?? [] {
                    guard let key = key as? String else {
                        continue
                    }
                    let value = store.object(forKey: key)
                    userDefaults?.set(value, forKey: key)
                    os_log("storeChanged updated value for %@",key)
                    userDefaults?.synchronize()
                }
            }
        }
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
        completionHandler(.sound)
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        if globalRefreshTimer.isValid {
            globalRefreshTimer.invalidate()
            RPCSession.shared?.stopRequests()
        }
        if RPCSession.shared == nil {
            guard let config = ServerConfigDB.shared.defaultConfig else { return }
            do {
                self.session = try RPCSession(withURL: config.configURL!, andTimeout: config.requestTimeout)
            } catch {
                os_log("%@",error.localizedDescription)
            }
        }
        else {
            self.session = RPCSession.shared
        }
        let encoder = JSONEncoder()
        let items = TorrentCategorization.shared.itemsForSelectedCategory
        let highRange = items.count < 1000 ? items.count : 1000
        let torrents = Array(items[0..<highRange]) as? Array<Torrent>
        let data = try? encoder.encode(torrents)
        defaults.set(data, forKey: TORRENT_LIST)
        defaults.synchronize()
    }

    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if self.session != nil {
            self.isDownloading = true
            self.scheduleAppRefresh()
        }
    }

    
    func applicationWillEnterForeground(_ application: UIApplication) {
        DispatchQueue.global(qos: .userInteractive).async {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "johnnyvega.Transmission-Remote.torrents")
        }
    }

    
    func applicationDidBecomeActive(_ application: UIApplication) {
        do {
            try RPCSession.shared?.restart()
            DispatchQueue.main.async {
                self.center.removeAllDeliveredNotifications()
                UIApplication.shared.applicationIconBadgeNumber = 0
                NotificationCenter.default.post(name: .EnableTimers, object: nil, userInfo: nil)
            }
       } catch {
            if error.localizedDescription != "The network connection was lost." {
                displayErrorMessage(error.localizedDescription, using: (self.window?.rootViewController as? UINavigationController)?.topViewController)
            }
            self.applicationDidBecomeActive(UIApplication.shared)
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if globalRefreshTimer.isValid {
            globalRefreshTimer.invalidate()
        }
        RPCSession.shared?.stopRequests()
    }
}

extension AppDelegate {
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // handle url - it is a .torrent file or magnet url
        // FIX: when user wants to load file serveral times in a row
        // or when user taps on torrent file in safari serveral times in a row
        if chooseNav != nil {
            chooseNav.dismiss(animated: false)
        }
        
        torrentFile = nil
        magnetURL = nil
        
        if MagnetURL.isMagnetURL(url) {
            magnetURL = MagnetURL(url: url)
        } else {
            if url.startAccessingSecurityScopedResource() {
                torrentFile = TorrentFile(fileURL: url)
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        if ServerConfigDB.shared.db.count > 0 && ((torrentFile != nil) || magnetURL != nil) {
            // presenting view controller to choose from several remote servers
            let chooseServerController = instantiateController(CONTROLLER_ID_CHOOSESERVER) as! AddFileController
            
            
            chooseServerController.isMagnet = magnetURL != nil
            
            if magnetURL != nil {
                chooseServerController.setTorrentTitle(magnetURL.name, andTorrentSize: magnetURL.torrentSizeString)
                chooseServerController.announceList = magnetURL.trackerList
            } else {
                chooseServerController.setTorrentTitle(torrentFile.name, andTorrentSize: torrentFile.torrentSizeString)
                
                chooseServerController.files = torrentFile.fileList
                chooseServerController.announceList = torrentFile.trackerList
            }
            
            let leftButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: #selector(dismissChooseServerController))
            
            let rightButton = UIBarButtonItem(title: NSLocalizedString("OK", comment: ""), style: .plain, target: self, action: #selector(addTorrentToSelectedServer))
            
            chooseServerController.navigationItem.leftBarButtonItem = leftButton
            chooseServerController.navigationItem.rightBarButtonItem = rightButton
            
            
            chooseNav = UINavigationController(rootViewController: chooseServerController)
            chooseNav.modalPresentationStyle = .formSheet
            
            window!.rootViewController?.present(chooseNav, animated: true)
        } else {
            let alert = UIAlertController(title: NSLocalizedString("There are no servers avalable", comment: ""), message: NSLocalizedString("Add server to the list and try again", comment: ""), preferredStyle: .alert)
            let okAlertAction = UIAlertAction(title: "OK", style: .cancel, handler: {_ in })
            alert.addAction(okAlertAction)
            chooseNav.present(alert, animated: true, completion: nil)
        }
        
        return true
        
    }
    
    
    func addTorrentToServer(withRPCConfig config: RPCServerConfig, priority: Int, startNow: Bool) {
        var session: RPCSession!
        if RPCSession.shared?.url != config.configURL {
            do {
                session = try RPCSession(withURL: config.configURL!, andTimeout: config.requestTimeout)
            } catch {
                displayErrorMessage(error.localizedDescription, using: (self.window?.rootViewController as? UINavigationController)?.topViewController)
                return
            }
        }
        else {
            session = RPCSession.shared!
        }
        
        if torrentFile != nil {
            session.addTorrent(usingFile: torrentFile, addPaused: false, withPriority: .veryHigh) { trId, error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: (self.window?.rootViewController as? UINavigationController)?.topViewController)
                    } else {
                        displayInfoMessage(NSLocalizedString("New torrent has been added", comment: ""), using: (self.window?.rootViewController as? UINavigationController)?.topViewController)
                        session.getInfo(forTorrents: [trId!], withPriority: .veryHigh, andCompletionHandler: { torrents, removed, error in
                            DispatchQueue.main.async {
                                if error != nil {
                                    displayErrorMessage(error!.localizedDescription, using: (self.window?.rootViewController as? UINavigationController)?.topViewController)
                                } else {
                                    TorrentCategorization.shared.updateItems(with: torrents!)
                                }
                            }
                        })
                    }
                }
            }
        } else if magnetURL != nil {
            
        }
    }
    
    @objc func addTorrentToSelectedServer() {
        let csc = chooseNav.viewControllers[0] as! AddFileController
        
        if csc.files != nil {
            torrentFile.fs = csc.files
        }

        addTorrentToServer(withRPCConfig: csc.rpcConfig!, priority: csc.bandwidthPriority - 1, startNow: csc.startImmidiately)
        dismissChooseServerController()
    }
    
    
    @objc func dismissChooseServerController() {
        chooseNav.dismiss(animated: true)
        chooseNav = nil
    }
    
}



