//
//  AppIntent.swift
//  GymTrackerComplications
//
//  Created by Jack on 1/31/25.
//

import WidgetKit
import AppIntents

/// Defines an intent allowing users to configure their complication to show data for a specific gym.
struct GymSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Gym Selection" }
    static var description: IntentDescription { "Choose which gym to display in the complication." }

    // Gym options available for selection
    @Parameter(title: "Select Gym", default: GymOption.mcComas)
    var selectedGym: GymOption
}

/// Enum for available gym options.
enum GymOption: String, AppEnum {
    case mcComas = "McComas Hall"
    case warMemorial = "War Memorial Hall"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Gym Options"
    }

    static var caseDisplayRepresentations: [GymOption: DisplayRepresentation] {
        [
            .mcComas: "McComas Hall",
            .warMemorial: "War Memorial Hall"
        ]
    }
}
