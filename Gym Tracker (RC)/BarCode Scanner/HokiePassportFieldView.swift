// HokiePassportFieldView.swift
// Gym Tracker
//
// OTP-style input for Campus ID: 9 digits in individual boxes with a dash (XXXX-XXXXX).

import SwiftUI

// MARK: - Digit Slot (on card, no box background)

private struct DigitSlotView: View {
    let digit: String
    let isActive: Bool

    var body: some View {
        Text(digit.isEmpty ? "X" : digit)
            .font(.system(.title3, design: .monospaced))
            .foregroundStyle(digit.isEmpty ? .secondary : .primary)
            .frame(width: 28, height: 40)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(isActive ? Color.customOrange : Color.primary.opacity(0.15))
            }
    }
}

// MARK: - Campus ID Field

struct CampusIDFieldView: View {
    @Binding var text: String
    var onTap: () -> Void

    private var digits: [Character] {
        Array(text.filter(\.isNumber).prefix(9))
    }

    private func digit(at index: Int) -> String {
        guard index < digits.count else { return "" }
        return String(digits[index])
    }

    /// Index of the “next” box (where the cursor effectively is)
    private var activeIndex: Int {
        min(digits.count, 8)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { i in
                DigitSlotView(digit: digit(at: i), isActive: activeIndex == i)
            }
            Text("–")
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.primary.opacity(0.5))
                .frame(minWidth: 16)
            ForEach(4..<9, id: \.self) { i in
                DigitSlotView(digit: digit(at: i), isActive: activeIndex == i)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = "123456"
        var body: some View {
            CampusIDFieldView(text: $text, onTap: {})
        }
    }
    return PreviewWrapper()
        .padding()
}
