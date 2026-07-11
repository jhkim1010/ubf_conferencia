import Cocoa
import FlutterMacOS
import GoogleSignIn

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // Google Sign-In OAuth 콜백 URL 처리
  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      GIDSignIn.sharedInstance.handle(url)
    }
  }
}
