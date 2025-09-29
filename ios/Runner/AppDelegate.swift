import UIKit
import Flutter
import firebase_core
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Request notification permissions
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .carPlay]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { granted, error in
                    if granted {
                        print("✅ Notification permission granted")
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else {
                        print("❌ Notification permission denied: \(error?.localizedDescription ?? "")")
                    }
                }
            )
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle notification when app is in foreground - SHOW IN NOTIFICATION CENTER
    override func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                       willPresent notification: UNNotification, 
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        print("📱 Foreground notification received: \(userInfo)")
        
        // IMPORTANT: Show notification in notification center even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound, .list]) // Added .list for notification center
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    // Handle notification tap
    override func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                       didReceive response: UNNotificationResponse, 
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 Notification tapped: \(userInfo)")
        
        completionHandler()
    }
}
