//
//  MoneyFlowApp.swift
//  MoneyFlow
//
//  Created by Sadat Ahmed on 20/11/24.
//

import SwiftUI
import CoreData

@main
struct MoneyFlowApp: App {
    @StateObject private var dataController = DataController()
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    
    var body: some Scene {
        WindowGroup {
            if isFirstLaunch {
                OnboardingView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .onAppear {
                        dataController.seedDefaultCategories()
                    }
            } else {
                MainTabView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .onAppear {
                        dataController.seedDefaultCategories()
                    }
            }
        }
    }
}
