//
//  ReadingWidgetsLiveActivity.swift
//  ReadingWidgets
//
//  Created by ThiagoMotaMachado on 05/01/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ReadingWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ReadingWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingWidgetsAttributes.self) { context in
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

extension ReadingWidgetsAttributes {
    fileprivate static var preview: ReadingWidgetsAttributes {
        ReadingWidgetsAttributes(name: "World")
    }
}

extension ReadingWidgetsAttributes.ContentState {
    fileprivate static var smiley: ReadingWidgetsAttributes.ContentState {
        ReadingWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ReadingWidgetsAttributes.ContentState {
         ReadingWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ReadingWidgetsAttributes.preview) {
   ReadingWidgetsLiveActivity()
} contentStates: {
    ReadingWidgetsAttributes.ContentState.smiley
    ReadingWidgetsAttributes.ContentState.starEyes
}
