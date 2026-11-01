import SwiftUI

@main
struct MyApp: App {
    init() { NotificationHandler.install() }

    var body: some Scene {
        WindowGroup {
            DalLaunchView()
        }
    }
}
