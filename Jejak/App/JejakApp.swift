import SwiftUI

@main
struct JejakApp: App {
    init() { JejakFont.registerBundledFonts() }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
