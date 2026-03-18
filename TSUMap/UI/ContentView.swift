//
//  ContentView.swift
//  TSUMap
//
//  Created by Artem on 17.03.2026.
//

import SwiftUI

struct ContentView: View {
    
    @State private var startLocation: GridPoint? = nil
    @State private var endLocation: GridPoint? = nil
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CampusMapView(
                startLocation: $startLocation,
                endLocation: $endLocation
            ).ignoresSafeArea()
            
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
                VStack(spacing: 15) {
                    
                    if (startLocation == nil) {
                        HStack {
                            Text("Укажите, где вы находитесь")
                                .font(.title2).bold()
                                .padding(.horizontal, 24).padding(.vertical, 10)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                        }
                    } else {
                        HStack {
                            if endLocation == nil {
                                Text("Куда пойдём?")
                                    .font(.title2).bold()
                                    .padding(.horizontal, 12).padding(.vertical, 10)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
                                Spacer()
                            } else {
                                Button {
                                    withAnimation(.spring()) {
                                        startLocation = nil
                                        endLocation = nil
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.uturn.backward").font(.title3).bold()
                                        
                                        Text("Сбросить маршрут").font(.title3).bold()
                                    }
                                    .padding()
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
                                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                }
                
            }.padding().animation(.spring(), value: startLocation)
        }
    }
}

#Preview {
    ContentView()
}
