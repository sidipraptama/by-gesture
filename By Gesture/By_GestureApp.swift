//
//  By_GestureApp.swift
//  By Gesture
//
//  Created by Sidi Praptama Aurelius Nurhalim on 16/01/25.
//

import SwiftUI

@main
struct By_GestureApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var isActive: Bool = false
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear() {
                    UIApplication.shared.isIdleTimerDisabled = true
                    AppDelegate.orientationLock = .portrait
                }
        }
    }
}
