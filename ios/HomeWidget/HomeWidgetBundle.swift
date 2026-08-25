//
//  HomeWidgetBundle.swift
//  HomeWidget
//
//  Created by builder on 8/24/26.
//

import WidgetKit
import SwiftUI

@main
struct HomeWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeWidget()
        HomeWidgetControl()
        HomeWidgetLiveActivity()
    }
}
