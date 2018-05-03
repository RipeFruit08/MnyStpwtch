//
//  NotificationsName+Extensions.swift
//  Timer
//
//  Created by Stephen Kim on 4/11/18.
// https://stackoverflow.com/questions/47500989/adding-dark-mode-to-ios-app
//  Copyright © 2018 Stephen Kim. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let darkModeEnabled = Notification.Name("com.yourApp.notifications.darkModeEnabled")
    static let darkModeDisabled = Notification.Name("com.yourApp.notifications.darkModeDisabled")
    static let userRateChanged = Notification.Name("com.yourApp.notifications.userRateChanged")
}
