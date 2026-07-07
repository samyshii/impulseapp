//
//  ImpulseWidgetBundle.swift
//  ImpulseWidget
//
//  The widget extension's entry point — WidgetKit looks for a single
//  @main WidgetBundle listing every widget this extension provides.
//

import WidgetKit
import SwiftUI

@main
struct ImpulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        ImpulseWidget()
    }
}
