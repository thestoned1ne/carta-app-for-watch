//
//  ContentView.swift
//  CartaOGWatchApp WatchKit Extension
//
//  Created by Brian Weber on 3/26/22.
//

import SwiftUI
import CoreBluetooth

struct MainView: View {
    var bluetooth = Bluetooth.shared
    var session: Session;
    @State private var syncTimer: Timer?;
    @State private var sendDabsTimer: Timer?;
    @State private var doInitialSetup = true;
    @State private var scanPresented: Bool = false;
    @State private var dabTimePresented: Bool = false;
    @State private var dabTempPresented: Bool = false;
    @State private var bluetoothDeviceList = [Bluetooth.Device]();
    @State private var isConnected: Bool = Bluetooth.shared.current != nil { didSet { if isConnected { scanPresented.toggle() } } };
    
    @State var response = Data();
    @State var string: String = "";
    @State var value: Float = 0;
    @State var state: Bool = false { didSet { bluetooth.send([UInt8(state.int)]) } };

    @State private var trySyncData: Bool = true;
    @State private var atomizerActive: Bool = false;
    ///@State private var atomizerMode: String = "Dab";
    @State private var atomizerTimeRemaining: Float = 0;
    @State private var tempDisplay: String;
    @State private var timeDisplay: String;
    @State private var dabCount: UInt = 0;
    @State private var flowerCount: UInt = 0;
    
    init() {
        self.session = Session.shared;
        self.tempDisplay = session.getTempFromIndex(index: session.tempIdx);
        self.timeDisplay = session.getTimeFromIndex(index: session.timeIdx);
    }

    var body: some View {
        VStack {
            if isConnected {
                if atomizerActive {
                    VStack {
                        Text(session.atomizerMode + " mode")
                        Spacer()
                        Spacer()
                        ProgressView()
                        Spacer()
                        Text(formatSecondsTimerDisplay(s: atomizerTimeRemaining) + " left").padding()
                        Button(action: { endDabs() }) {
                            Text("Too High")
                        }
                    }.padding()
                    .onAppear(perform: {
                        session.start();
                    })
                    .onDisappear(perform: {
                        session.stop();
                        trySyncData = true;
                        syncData();
                    })
                }
                else {
                    VStack {
                        Text("  " + session.atomizerMode + " mode").frame(maxWidth: .infinity, alignment: .leading).padding()
                        Button(action: { dabTimePresented.toggle() }) {
                            HStack{
                                Text("⏳ Time")
                                Spacer()
                            }
                            HStack{
                                Text(timeDisplay).foregroundColor(.gray)
                            }
                        }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                        Button(action: { dabTempPresented.toggle() }) {
                            HStack{
                                Text("🔥 Heat")
                                Spacer()
                            }
                            HStack{
                                Text(tempDisplay + " °F").foregroundColor(.gray)
                            }
                        }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                        HStack {
                            VStack {
                                Text("🍯").font(.system(size: 20))
                                Text(String(dabCount))
                            }.frame(width: 50)
                            Button(action: { sendDabs() }){
                                Text("🍳").font(.system(size: 30))
                            }
                            VStack {
                                Text("🌿").font(.system(size: 20))
                                Text(String(flowerCount))
                            }.frame(width: 50)
                        }.padding()
                        
                    }
                    .navigationBarHidden(true)
                }
            }
            else {
                VStack {
                    ProgressView()
                    Text("Searching...")
                }.padding()
            }
            Spacer()
        }
        .sheet(isPresented: $dabTimePresented){ DabTimeView(bluetooth: bluetooth, presented: $dabTimePresented, isConnected: $isConnected, timeDisplay: $timeDisplay) }
        .sheet(isPresented: $dabTempPresented){ DabTempView(bluetooth: bluetooth, presented: $dabTempPresented, isConnected: $isConnected, tempDisplay: $tempDisplay) }
        .onAppear{
            bluetooth.delegate = self;
        }
        
    }
    
    func getMainService() -> CBService? {
        let mainService = bluetooth.current?.services?.first(where: { $0.uuid == CBUUID(string: "1011123e-8535-b5a0-7140-a304d2495cb7")})
        return mainService
    }
    
    func getReadCharacteristic(service: CBService) -> CBCharacteristic? {
        let readCharacteristic = service.characteristics?.first(where: { $0.uuid == CBUUID(string: "1011123e-8535-b5a0-7140-a304d2495cb8")})
        return readCharacteristic
    }
    
    func getWriteCharacteristic(service: CBService) -> CBCharacteristic? {
        let writeCharacteristic = service.characteristics?.first(where: { $0.uuid == CBUUID(string: "1011123e-8535-b5a0-7140-a304d2495cb9")})
        return writeCharacteristic
    }
    
    func syncData() {
        guard let current = bluetooth.current else {
            print("Bluetooth.current is not set!")
            return
        }
        let mainService = self.getMainService()
        guard let service = mainService else {
            print("MainService is not set!")
            return
        }
        let writeCharacteristicUnsafe = self.getWriteCharacteristic(service: service)
        guard let writeCharacteristic = writeCharacteristicUnsafe else {
            print("Failed to get write characteristic")
            return
        }
        let readCharacteristicUnsafe = self.getReadCharacteristic(service: service)
        guard let readCharacteristic = readCharacteristicUnsafe else {
            print("Failed to get read characteristic")
            return
        }
        
        if(doInitialSetup) {
            current.setNotifyValue(true, for: readCharacteristic)
            print("Enabled value notifications for read characteristic!")
            
        }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            if(dabCount == 0 && flowerCount == 0 || trySyncData) {
                let syncData: [UInt8] = [0xEE, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEE];
                current.writeValue(Data(syncData), for: writeCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
                print("Time sync success!");
                trySyncData = false
            }
            else {
                timer.invalidate()
            }
        })
        doInitialSetup = false;
        
        //print("Trying to read value for " + characteristic.uuid.uuidString)
        //current.readValue(for: characteristic)
    }
    
    func gotData(data: Data) {
        if(data.hex == "bb000c5500000000000000bb") {
            // Concentrate mode
            self.atomizerActive = false;
            session.atomizerMode = "Dab"
            print("Idle (concentrate mode)")
        }
        else if(data.hex == "bb000ca500000000000000bb") {
            // Flower mode
            self.atomizerActive = false;
            session.atomizerMode = "Flower"
            print("Idle (flower mode)")
        }
        else if(data.hex.hasPrefix("bb000a") && data.hex.hasSuffix("bb")) {
            // Hit counts
            let array = Array(data);
            let waxCount = ((UInt(array[3]) * 256) + UInt(array[4]));
            let herbCount = ((UInt(array[5]) * 256) + UInt(array[6]));
            self.dabCount = waxCount;
            self.flowerCount = herbCount;
            print("Wax hits: " + String(waxCount))
            print("Flower hits: " + String(herbCount))
        }
        else if(data.hex.hasPrefix("bb000c") && data.hex.hasSuffix("bb")) {
            // Atomizer mode, temperature, and session time remaining
            let array = Array(data);
            let atomizerMode = (array[3] == 85 ? "Dab" : (array[3] == 165 ? "Flower" : "Unknown"));
            if(atomizerMode != "Unknown") {
                session.atomizerMode = atomizerMode;
            }
            let atomizerTempSelector = array[4];
            let atomizerSessionRemaining = array[6];
            self.atomizerTimeRemaining = Float(atomizerSessionRemaining);
            self.atomizerActive = true;
            print("Atomizer mode: " + atomizerMode)
            print("Atomizer temperature index: " + String(atomizerTempSelector))
            print("Session time remaining: " + String(atomizerSessionRemaining))
        }
        else {
            print("Unknown state: " + data.hex)
        }
    }
    
    func endDabs() {
        guard let current = bluetooth.current else {
            print("Bluetooth.current is not set!")
            return
        }
        let mainService = self.getMainService()
        guard let service = mainService else {
            print("MainService is not set!")
            return
        }
        let writeCharacteristicUnsafe = self.getWriteCharacteristic(service: service)
        guard let writeCharacteristic = writeCharacteristicUnsafe else {
            print("Failed to get write characteristic")
            return
        }
        
        print("Session has been ended by the user");
        let endData: [UInt8] = [0xCC, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xCC];
        current.writeValue(Data(endData), for: writeCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    func sendDabs() {
        if(sendDabsTimer != nil) {
            sendDabsTimer?.invalidate();
        }
        sendDabsTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { timer in
            guard let current = bluetooth.current else {
                return
            }
            let mainService = self.getMainService()
            guard let service = mainService else {
                return
            }
            let writeCharacteristic = self.getWriteCharacteristic(service: service)
            guard let characteristic = writeCharacteristic else {
                return
            }
            let temp = session.getTempFromIndex(index: session.tempIdx);
            let time = session.getTimeFromIndex(index: session.timeIdx);
            print("Starting session at " + temp + "F for " + time)
            current.writeValue(Data([204, 0, 12, UInt8(session.tempIdx), 0, 0, UInt8(self.timeStringToSeconds(time: time)), 0, 0, 85, 0, 204]), for: characteristic, type: CBCharacteristicWriteType.withoutResponse);
            
            sendDabsTimer?.invalidate();
            sendDabsTimer = nil;
        });
    }
    
    func sendValue(_ value: Float) {
        if Int(value) != Int(self.value) {
            guard let sendValue = map(Int(value), of: 0...100, to: 0...255) else { return }
            bluetooth.send([UInt8(state.int), UInt8(sendValue)])
        }
        self.value = value
    }
    
    func map(_ value: Int, of: ClosedRange<Int>, to: ClosedRange<Int>) -> Int? {
        guard let ofmin = of.min(), let ofmax = of.max(), let tomin = to.min(), let tomax = to.max() else { return nil }
        return Int(tomin + (tomax - tomin) * (value - ofmin) / (ofmax - ofmin))
    }
    
    func timeStringToSeconds(time: String) -> Float {
        let parts = time.split(separator: ":")
        if parts.count < 2 {
            return 0.0
        }
        let m = Int(parts[0]) ?? 0,
            s = Int(parts[1]) ?? 0
        return Float(m*60+s)
    }
    
    func formatSecondsTimerDisplay(s: Float) -> String {
        let minutes = floor(s/60);
        let seconds = round(s.truncatingRemainder(dividingBy: 60));
        return String(Int(minutes)) + ":" + (seconds < 10 ? "0":"") + String(Int(seconds));
    }
    
}

extension MainView: BluetoothProtocol {
    func state(state: Bluetooth.State) {
        switch state {
        case .unknown: print("◦ .unknown")
        case .resetting: print("◦ .resetting")
        case .unsupported: print("◦ .unsupported")
        case .unauthorized: print("◦ bluetooth disabled, enable it in settings")
        case .poweredOff: print("◦ turn on bluetooth")
        case .poweredOn: print("◦ everything is ok")
        case .error: print("• error")
        case .connected:
            print("◦ connected to \(bluetooth.current?.name ?? "")")
            bluetooth.stopScanning();
            isConnected = true
            if(doInitialSetup || trySyncData) {
                syncTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { timer in
                    if(!doInitialSetup) {
                        print("Initial setup completed!")
                        timer.invalidate()
                        return
                    }
                    //print("Reading data!")
                    syncData()
                })
            }
        case .disconnected:
            print("◦ disconnected")
            isConnected = false;
            doInitialSetup = true;
        }
    }
    
    func list(list: [Bluetooth.Device]) {
        self.bluetoothDeviceList = list
    }
    
    func value(data: Data) {
        gotData(data: data)
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
