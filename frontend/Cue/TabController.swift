//
//  TabController.swift
//  Cue
//
//  Created by Jackson Moody on 12/19/25.
//

import Foundation
import Combine

enum TabItem {
    case manage
    case survey
    case help
}

class TabController: ObservableObject {
    @Published var activeTab = TabItem.manage

    func open(_ tab: TabItem) {
        activeTab = tab
    }
}
