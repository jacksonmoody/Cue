//
//  NavigationRouter.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/23/25.
//

import Foundation
import SwiftUI

enum Route: Hashable {
    case gear1
    case gear2
    case gear3
    case settings
}


@Observable
class NavigationRouter {
    var path = NavigationPath()

    func navigateToGear1() {
        path.append(Route.gear1)
    }
    
    func navigateToGear2() {
        path.append(Route.gear2)
    }
    
    func navigateToGear3() {
        path.append(Route.gear3)
    }
    
    func navigateToSettings() {
        path.append(Route.settings)
    }

    func navigateHome() {
        path = NavigationPath()
    }
}
