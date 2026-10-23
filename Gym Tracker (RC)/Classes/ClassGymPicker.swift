import SwiftUI

/// The gym choice for classes: segmented, or a menu at accessibility sizes where segments would clip.
struct ClassGymPicker: View {
    @Binding var selection: ClassGymFilter
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("Gym", selection: $selection) { options }
                .pickerStyle(.menu)
        } else {
            Picker("Gym", selection: $selection) { options }
                .pickerStyle(.segmented)
        }
    }

    private var options: some View {
        ForEach(ClassGymFilter.allCases) { Text($0.title).tag($0) }
    }
}
