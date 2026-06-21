//
//  YShopWidgetsLiveActivity.swift
//  YShopWidgets
//
//  Created by Mohammed on 21.06.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct YShopWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct YShopWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: YShopWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension YShopWidgetsAttributes {
    fileprivate static var preview: YShopWidgetsAttributes {
        YShopWidgetsAttributes(name: "World")
    }
}

extension YShopWidgetsAttributes.ContentState {
    fileprivate static var smiley: YShopWidgetsAttributes.ContentState {
        YShopWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: YShopWidgetsAttributes.ContentState {
         YShopWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: YShopWidgetsAttributes.preview) {
   YShopWidgetsLiveActivity()
} contentStates: {
    YShopWidgetsAttributes.ContentState.smiley
    YShopWidgetsAttributes.ContentState.starEyes
}
