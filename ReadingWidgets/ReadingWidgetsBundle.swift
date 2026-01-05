//
//  ReadingWidgetsBundle.swift
//  ReadingWidgets
//
//  Created by ThiagoMotaMachado on 05/01/26.
//

import WidgetKit
import SwiftUI

@main
struct ReadingWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ReadingWidgets()
        ReadingWidgetsControl()
        ReadingWidgetsLiveActivity()
    }
}
