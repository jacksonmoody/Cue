//
//  CueWidgetLiveActivity.swift
//  CueWidget
//
//  Created by Jackson Moody on 12/19/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CueWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var workoutStartDate: Date
    }
    
    var workoutType: String
}

struct CueWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CueWidgetAttributes.self) { context in
            
            NotificationView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                }
                DynamicIslandExpandedRegion(.trailing) {
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.workoutStartDate, style: .timer)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(.gradientPurple)
                        .multilineTextAlignment(.center)
                }
                DynamicIslandExpandedRegion(.bottom) {
                }
            } compactLeading: {
                Image(.whiteRings)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 30)
            } compactTrailing: {
                Text(context.state.workoutStartDate, style: .timer)
                    .monospacedDigit()
                    .foregroundStyle(.gradientPurple)
                    .multilineTextAlignment(.leading)
                    .bold()
            } minimal: {
                Image(.whiteRings)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 30)
            }
            .keylineTint(.gradientBlue)
        }
        .supplementalActivityFamilies([.small])
    }
}

struct NotificationView: View {
    @Environment(\.activityFamily) var activityFamily
    var context: ActivityViewContext<CueWidgetAttributes>
    var body: some View {
        switch activityFamily {
        case .small:
            VStack(alignment: .leading) {
                Text(context.attributes.workoutType)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.8))
                
                Text(context.state.workoutStartDate, style: .timer)
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 30)
            .activityBackgroundTint(.gradientBlue)
            .activitySystemActionForegroundColor(.white)
        case .medium:
            HStack(spacing: 30) {
                Image(.whiteRings)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.workoutType)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(context.state.workoutStartDate, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .activityBackgroundTint(.gradientBlue)
            .activitySystemActionForegroundColor(.white)
        @unknown default:
            fatalError("Unsupported live activity size")
        }
    }
}

extension CueWidgetAttributes {
    fileprivate static var preview: CueWidgetAttributes {
        CueWidgetAttributes(workoutType: "Cue Session")
    }
}

extension CueWidgetAttributes.ContentState {
    fileprivate static var running: CueWidgetAttributes.ContentState {
        CueWidgetAttributes.ContentState(workoutStartDate: Date())
    }

}

// MARK: - Previews

#Preview("Lock Screen", as: .content, using: CueWidgetAttributes.preview) {
    CueWidgetLiveActivity()
} contentStates: {
    CueWidgetAttributes.ContentState.running
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: CueWidgetAttributes.preview) {
    CueWidgetLiveActivity()
} contentStates: {
    CueWidgetAttributes.ContentState.running
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: CueWidgetAttributes.preview) {
    CueWidgetLiveActivity()
} contentStates: {
    CueWidgetAttributes.ContentState.running
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: CueWidgetAttributes.preview) {
    CueWidgetLiveActivity()
} contentStates: {
    CueWidgetAttributes.ContentState.running
}

