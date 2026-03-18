//
//  ContentView.swift
//  TSUMap
//
//  Created by Artem on 17.03.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            CampusMapView().ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("TSUMap")
                        .font(.title)
                        .bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                    
                    Spacer()
                }
                Spacer()
                HStack {
                    Text("Укажите, где вы находитесь")
                        .font(.title2).bold()
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                }
                
            }.padding()
            
        }
    }
}

#Preview {
    ContentView()
}
