//
//  zhuanyuApp.swift
//  zhuanyu
//
//  Created by zakk on 2026/2/4.
//

import SwiftUI
import SwiftData

@main
struct zhuanyuApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: RecipeRecord.self)
    }
}
