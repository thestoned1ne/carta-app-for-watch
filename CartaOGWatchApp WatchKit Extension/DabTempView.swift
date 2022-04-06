//
//  ScanView.swift
//  app
//
//  Created by Sergey Romanenko on 25.04.2021.
//

import SwiftUI

struct DabTempView: View {
    var bluetooth: Bluetooth
    @Binding var presented: Bool;
    @Binding var isConnected: Bool;
    @Binding var tempDisplay: String;
    
    var body: some View {
        List(Session.shared.atomizerMode == "Dab" ? Constants.dabTemps_F.indices : Constants.flowerTemps_F.indices, id: \.self){ index in
            if(index > 0) {
                let temp = Session.shared.getTempFromIndex(index: index);
                Button(action: {
                    tempDisplay = Session.shared.updateSessionTemp(index: index);
                    presented.toggle()
                }){
                    Text(temp)
                }
            }
        }
        .listStyle(PlainListStyle())
        .padding(.vertical, 0)
    }
}
