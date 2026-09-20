import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var starPrinter: StarPrinterChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    starPrinter = StarPrinterChannel(
      messenger: engineBridge.applicationRegistrar.messenger())
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    starPrinter?.dispose()
    starPrinter = nil
    super.applicationWillTerminate(application)
  }
}
