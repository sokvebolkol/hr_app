import UIKit
import Flutter
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    print("📱 AppDelegate: Starting initialization")
    FirebaseApp.configure()
    print("📱 AppDelegate: Firebase configured")
    
    // Set notification delegate FIRST
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      print("📱 AppDelegate: Notification delegate set")
    }
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    print("📱 AppDelegate: Registered for remote notifications")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // CRITICAL: Handle APNS token registration
  override func application(_ application: UIApplication, 
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("📱 AppDelegate: ✅ APNS token received - length: \(deviceToken.count) bytes")
    
    // This connects APNS to Firebase
    Messaging.messaging().apnsToken = deviceToken
    print("📱 AppDelegate: ✅ APNS token set in Firebase")
    
    // Call super to ensure Flutter gets the token too
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Handle APNS registration failure
  override func application(_ application: UIApplication, 
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("📱 AppDelegate: ❌ APNS registration failed: \(error.localizedDescription)")
    print("📱 AppDelegate: ❌ This is why remote notifications don't work!")
    
    // Call super to ensure Flutter handles the error too
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
  
  // Handle foreground notifications (iOS 10+) - Updated to keep notifications in center
  @available(iOS 10, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                           willPresent notification: UNNotification,
                           withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
    print("📨 AppDelegate: Foreground notification received")
    print("📨 Title: \(notification.request.content.title)")
    print("📨 Body: \(notification.request.content.body)")
    
    // Show notification AND keep it in notification center
    if #available(iOS 14.0, *) {
      // iOS 14+: Use .list to keep in notification center
      completionHandler([[.banner, .list, .badge, .sound]])
    } else {
      // iOS 10-13: Use .alert to keep in notification center  
      completionHandler([[.alert, .badge, .sound]])
    }
  }
  
  // Handle notification tap (iOS 10+) - Add override keyword
  @available(iOS 10, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                             didReceive response: UNNotificationResponse,
                             withCompletionHandler completionHandler: @escaping () -> Void) {
    
    print("👆 AppDelegate: Notification tapped")
    let userInfo = response.notification.request.content.userInfo
    print("👆 UserInfo: \(userInfo)")
    
    // Call super to ensure Flutter handles the response too
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
