// GymTrackerWidgetBundle.swift
// GymTrackerWidget

import WidgetKit
import SwiftUI

@main
struct GymTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widget
        GymTrackerWidget()  // Make sure your home screen widget is included here
        
        // Lock Screen Widgets
        McComasCircularWidget()        // Lock screen circular widget for McComas
        WarMemorialCircularWidget()    // Lock screen circular widget for War Memorial
        BoulderingWallCircularWidget() // Lock screen circular widget for Bouldering Wall
        GymTrackerRectangularWidget()  // Lock screen rectangular widget for occupancy details
    }
}
