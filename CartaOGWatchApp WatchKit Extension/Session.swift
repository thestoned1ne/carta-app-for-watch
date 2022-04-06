//
//  Session.swift
//  CartaOGWatchApp WatchKit Extension
//
//  Created by Brian Weber on 3/28/22.
//

import Foundation
import SwiftUI

final class Session: NSObject, WKExtendedRuntimeSessionDelegate {
    static let shared = Session();
    
    var tempIdx: Int;
    var timeIdx: Int;
    var atomizerMode: String = "Dab";
    
    private var dabSession = WKExtendedRuntimeSession();
    private override init() {
        self.tempIdx = UserDefaults.standard.integer(forKey: "sessionTempIdx");
        self.timeIdx = UserDefaults.standard.integer(forKey: "sessionTimeIdx");
        if(tempIdx == 0) {
            tempIdx = 1;
        }
        if(timeIdx == 0) {
            timeIdx = 1;
        }
        super.init();
        print("Temp idx: " + String(tempIdx));
        print("Time idx: " + String(timeIdx));
    }
    
    func start() {
        self.dabSession.delegate = self;
        self.dabSession.start();
    }
    
    func stop() {
        self.dabSession.invalidate();
        self.dabSession = WKExtendedRuntimeSession();
    }
    
    func updateSessionTime(index: Int) -> String {
        self.timeIdx = index;
        UserDefaults.standard.set(index, forKey: "sessionTimeIdx");
        return self.getTimeFromIndex(index: index);
    }
    
    func updateSessionTemp(index: Int) -> String {
        self.tempIdx = index;
        UserDefaults.standard.set(index, forKey: "sessionTempIdx");
        return self.getTempFromIndex(index: index);
    }
    
    func getTempFromIndex(index: Int) -> String {
        return atomizerMode == "Dab" ? Constants.dabTemps_F[index] : Constants.flowerTemps_F[index];
    }
    
    func getTimeFromIndex(index: Int) -> String {
        return atomizerMode == "Dab" ? Constants.dabTimes[index] : Constants.flowerTimes[index]
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
    }
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    }
    
}
