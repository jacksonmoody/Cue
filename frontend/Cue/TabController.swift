//
//  TabController.swift
//  Cue
//
//  Created by Jackson Moody on 12/19/25.
//

import Foundation
import Combine

enum TabItem {
    case reflect
    case manage
    case survey
    case feedback
}

class TabController: ObservableObject {
    @Published var activeTab = TabItem.reflect

    func open(_ tab: TabItem) {
        activeTab = tab
    }
}
