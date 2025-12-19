//
//  TabController.swift
//  Cue
//
//  Created by Jackson Moody on 12/19/25.
//

import Foundation
import Combine

enum Tab {
    case manage
    case survey
    case help
}

class TabController: ObservableObject {
    @Published var activeTab = Tab.manage

    func open(_ tab: Tab) {
        activeTab = tab
    }
}
