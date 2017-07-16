//
//  GeometryObeysMouseManager.swift
//  Amethyst
//
//  Created by Ian Katz on 7/14/17.
//  Copyright © 2017 Ian Ynda-Hummel. All rights reserved.
//

import AppKit
import Foundation
import RxSwift
import RxSwiftExt
import Silica
import SwiftyJSON

private struct ObserveApplicationNotifications {
    enum Error: Swift.Error {
        case failed
    }

    fileprivate let application: SIApplication
    fileprivate let geometryManager: GeometryObeysMouseManager

    fileprivate func addObservers() -> Observable<Bool> {
        return _addObservers().retry(.exponentialDelayed(maxCount: 4, initial: 0.1, multiplier: 2))
    }

    private func _addObservers() -> Observable<Bool> {
        let application = self.application
        let geometryManager = self.geometryManager
        let windowManager = geometryManager.windowManager

        return Observable.create { observer in
            var success: Bool = false

            success = application.observeNotification(kAXWindowMovedNotification as CFString!, with: application) { accessibilityElement in
                guard let window = accessibilityElement as? SIWindow else {
                    return
                }

                guard let focusedWindow = SIWindow.focused(), let screen = focusedWindow.screen() else {
                    return
                }

                let windows = windowManager.windows(on: screen)

                let pointerLocation = NSPointToCGPoint(NSEvent.mouseLocation)

                // If there is no window at that point just focus the screen directly
                guard let secondWindow = SIWindow.secondWindowForScreenAtPoint(pointerLocation, withWindows: windows) ?? windows.first else {
                    screen.focusScreen()
                    return
                }

                print("window moved \(String(describing: window.title())) mouse at \(NSEvent.mouseLocation) \(secondWindow)")
            }

            guard success else {
                observer.on(.error(Error.failed))
                return Disposables.create()
            }

            application.observeNotification(kAXWindowResizedNotification as CFString!, with: application) { accessibilityElement in
                guard let window = accessibilityElement as? SIWindow else {
                    return
                }

                guard let focusedWindow = SIWindow.focused(), let screen = focusedWindow.screen() else {
                    return
                }
                print("window resized \(String(describing: window.title())) mouse at \(NSEvent.mouseLocation) \(screen)")

            }
            observer.on(.next(true))
            observer.on(.completed)
            return Disposables.create()
        }
    }
}

final class GeometryObeysMouseManager: NSObject {
    private let userConfiguration: UserConfiguration
    private var _windowManager: WindowManager?
    var windowManager: WindowManager {
        return _windowManager!
    }

    init(userConfiguration: UserConfiguration) {
        self.userConfiguration = userConfiguration
        super.init()
     }

    func setUpWithWindowManager(_ windowManager: WindowManager, configuration: UserConfiguration) {
        self._windowManager = windowManager
    }

    //windowManager.swapFocusedWindowScreenCounterClockwise()

}
