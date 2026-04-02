import SwiftUI

struct ContentView: View {
    private enum AppTab: Hashable {
        case log
        case history
        case map
        case stats
        case badges
        case dog
    }

    @ObservedObject var store: PoopStore
    @ObservedObject var locationManager: PoopLocationManager
    @ObservedObject var authManager: AuthManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .log

    var body: some View {
        Group {
            if authManager.isRestoringSession {
                ProgressView("Loading Pooppy...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .pooppyBackground()
            } else if authManager.ownerUserID == nil {
                SignInView(authManager: authManager)
            } else if store.selectedDog == nil {
                DogAccessView(store: store, authManager: authManager)
            } else {
                TabView(selection: $selectedTab) {
                    LogPoopView(store: store, locationManager: locationManager)
                        .tag(AppTab.log)
                        .tabItem {
                            Label("Log", systemImage: "plus.circle.fill")
                        }

                    PoopHistoryView(store: store)
                        .tag(AppTab.history)
                        .tabItem {
                            Label("History", systemImage: "list.bullet.rectangle")
                        }

                    PoopMapView(store: store)
                        .tag(AppTab.map)
                        .tabItem {
                            Label("Map", systemImage: "map.fill")
                        }

                    PoopStatsView(store: store)
                        .tag(AppTab.stats)
                        .tabItem {
                            Label("Stats", systemImage: "chart.bar.fill")
                        }

                    PoopBadgesView(store: store)
                        .tag(AppTab.badges)
                        .tabItem {
                            Label("Badges", systemImage: "rosette")
                        }

                    DogAccountView(store: store, authManager: authManager)
                        .tag(AppTab.dog)
                        .tabItem {
                            Label("Dog", systemImage: "person.2.fill")
                        }
                }
                .tint(PooppyTheme.cocoa)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(PooppyTheme.cream, for: .tabBar)
                .onAppear {
                    selectedTab = .log
                    locationManager.requestAccessIfNeeded()
                    locationManager.refreshLocation()
                }
            }
        }
        .task(id: authManager.ownerUserID) {
            if let ownerUserID = authManager.ownerUserID {
                await store.configure(ownerID: ownerUserID, ownerDisplayName: authManager.ownerDisplayName)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, authManager.ownerUserID != nil else { return }
            locationManager.requestAccessIfNeeded()
            locationManager.refreshLocation()
            Task {
                await store.refreshFromCloud()
            }
        }
    }
}
