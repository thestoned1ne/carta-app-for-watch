//
//  ScanView.swift
//  app
//
//  Created by Sergey Romanenko on 25.04.2021.
//

import SwiftUI

struct DabTimeView: View {
    var bluetooth: Bluetooth
    @Binding var presented: Bool;
    @Binding var isConnected: Bool;
    @Binding var timeDisplay: String;
    
    var body: some View {
        List((Session.shared.atomizerMode == "Dab" ? Constants.dabTimes.indices : Constants.flowerTimes.indices), id: \.self){ index in
            if(index > 0) {
                let time = Session.shared.getTimeFromIndex(index: index);
                Button(action: {
                    print(time);
                    timeDisplay = Session.shared.updateSessionTime(index: index);
                    presented.toggle();
                }){
                    Text(time)
                }
            }
        }.listStyle(PlainListStyle()).padding(.vertical, 0);
    }
}
