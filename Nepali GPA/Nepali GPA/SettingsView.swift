//
//  SettingsView.swift
//  Nepali GPA
//
//  Created by David Thomas on 1/7/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var networkConfig: NetworkConfig
    
    var body: some View {
        Form {
            Section(header: Text("Server Configuration")) {
                TextField("Server URL", text: $networkConfig.serverURL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .navigationTitle("Settings")
    }
}
