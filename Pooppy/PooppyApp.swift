import SwiftUI

@main
struct PooppyApp: App {
    @StateObject private var store = PoopStore()
    @StateObject private var locationManager = PoopLocationManager()
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store, locationManager: locationManager, authManager: authManager)
                .task {
                    locationManager.requestAccessIfNeeded()
                }
        }
    }
}
