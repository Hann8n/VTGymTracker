//
//  WebView.swift
//  Gym Tracker
//
//  Created by Jack on 1/16/25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = backgroundColor()
        webView.scrollView.backgroundColor = backgroundColor()
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Helper function to determine background color based on the color scheme
    private func backgroundColor() -> UIColor {
        colorScheme == .dark
            ? UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
            : UIColor(red: 242 / 255, green: 242 / 255, blue: 247 / 255, alpha: 1.0)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // Show a loading indicator if necessary
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Hide the loading indicator
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Handle navigation errors
        }
    }
}
