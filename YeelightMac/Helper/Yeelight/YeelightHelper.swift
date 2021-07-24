//
//  YeelightHelper.swift
//  YeelightMac
//
//

import Foundation
import Socket

struct Proprieties {
    
    var bright     = 0
    var ct         = 0
    var rgb        = 0
    var hue        = 0
    var sat        = 0
    var color_mode = 0
    var delayoff   = 0
    var name       = ""
    var power      = false
    var flowing    = false
    var music_on   = false
    var flow_params: [String: Any] = [:];
}

class Yeelight: NSObject, ObservableObject {
    
    @Published var address: String?
    @Published var connected = false
    @Published var proprieties = Proprieties()
    
    private var i = 1
    private var client: Socket?
    
    init(address: String) {
        super.init()
        initClient()
        connect(to: address)
    }
    
    override init(){
        super.init()
        initClient()
        guard let address = discover() else { return }
        connect(to: address)
    }
    
    func connect(to address: String) {
        self.address = address
        let (ip, port) = splitAddress(address)
        
        do {
            try client?.connect(to: ip, port: Int32(port))
            connected = true
        } catch {
            print(error.localizedDescription)
            connected = false
            return
        }
        
        updateProprieties()
        
        print("Connected: \(self.address ?? "???")")
    }
    
    func reconnect() {
        guard let address = address else { return }
        connect(to: address)
    }
    
    func discover() -> String?{
        guard
            let broadcast = try? Socket.create(family: .inet,
                                               type  : .datagram,
                                               proto : .udp)
        else {
            print("Unable to create broadcast")
            return nil
        }
      
        let discoverMessage = """
            M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1982\r\nMAN: "ssdp:discover"\r\nST: wifi_bulb
            """
        let discoverData = discoverMessage.data(using: .utf8)!
        
        do {
            let address = Socket.createAddress(for: "239.255.255.250", on: 1982)!
            try broadcast.udpBroadcast(enable: true)
            try broadcast.write(from: discoverData, to: address)
            try broadcast.setReadTimeout(value: 1000)
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
        var data = Data()
        
        guard
            let read = try? broadcast.readDatagram(into: &data),
            read.bytesRead > 0
        else {
            print("Unable to read datagram")
            return nil
        }
        
        let string = String(data: data, encoding: .utf8)!
        let rows   = string.split(separator: "\r\n").map(String.init)
        
        for s in rows {
            if s.contains("Location") {
                return String(s.suffix(19))
            }
        }
        
        print("Can't find any device")
        
        return nil
    }
    
    func closeConnection(){
        client?.close()
    }
    
    func updateProprieties(){
        let dict = sendCmdReply(id: i, method: "get_prop", params: ["power", "bright", "ct", "rgb", "hue", "sat", "color_mode", "flowing", "delayoff", "flow_params", "music_on", "name"], hasReply: true)
        let res = dict["result"] as! [Any]
        if(res[0] as! String == "on"){
            proprieties.power = true
        } else {
            proprieties.power = false
        }
        proprieties.bright = Int((res[1] as! NSString).intValue)
        proprieties.ct = Int((res[2] as! NSString).intValue)
        proprieties.rgb = Int((res[3] as! NSString).intValue)
        proprieties.hue = Int((res[4] as! NSString).intValue)
        proprieties.sat = Int((res[5] as! NSString).intValue)
        proprieties.color_mode = Int((res[6] as! NSString).intValue)
        proprieties.flowing = Int((res[7] as! NSString).intValue) == 0 ? false : true
        proprieties.delayoff = Int((res[8] as! NSString).intValue)
        proprieties.music_on = Int((res[10] as! NSString).intValue) == 1 ? true : false
        proprieties.name = (res[11] as! NSString) as String
        print(proprieties)
    }
    
    private func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return nil
    }
    
    private func joinArrayWithComma(_ array:[Any]) -> String {
        array.compactMap { (value) -> String? in (value is Int ? "\(value)" : ("\"\(value)\"")) }.joined(separator: ",")
    }
    
    private func readReply() -> Dictionary<String, Any>{
        var data = Data()

        do {
            let _ = try client?.read(into: &data)
            let s = String(data: data, encoding: String.Encoding.utf8)!
            let cs = (s as NSString).utf8String
            print("<- \(s)")
            if let json_r = get_one_json(UnsafeMutablePointer<Int8>(mutating: cs), Int32(s.count)) {
                let s1 = String(cString: json_r)
                print(s1)
                
                let d = convertToDictionary(text: s1)
                if(d == nil){
                    return [:]
                } else {
                    return d!
                }
            } else {
                return readReply()
            }
        } catch {
            return [:]
        }
    }
    
    private func splitAddress(_ address: String) -> (String, Int) {
        let parts = address.split(separator: ":").map(String.init)
        return (parts.first!, Int(parts.last!)!)
    }
    
    private func initClient() {
        do {
            client = try Socket.create()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: Send actions
    
    func toggle() {
        let _ = sendCmdReply(id: 1, method: "toggle", params: [], hasReply: false)
        proprieties.power.toggle()
    }
    
    func setBrightness(value: Int) {
        var bright = value;
        if(bright < 1){
            bright = 1;
        }
        if(bright > 100){
            bright = 100;
        }
        
        let _ = sendCmdReply(id: 1, method: "set_bright", params: [bright, "smooth", 500], hasReply: false)
        self.proprieties.bright = bright
    }
    
    func switchOn() {
        let _ = sendCmdReply(id: 1, method: "set_power", params: ["on", "smooth", 500], hasReply: false)
        proprieties.power = true
    }
    
    func switchOff() {
        let _ = sendCmdReply(id: 1, method: "set_power", params: ["off", "smooth", 500], hasReply: false)
        proprieties.power = false
    }
    
    func setColor(r: Int, g: Int, b: Int) {
        let _ = sendCmdReply(id: 1, method: "set_rgb", params: [r*65536+g*256+b, "smooth", 500], hasReply: false)
    }
    
    func setColor(h: Int, s: Int) {
        let _ = sendCmdReply(id: 1, method: "set_hsv", params: [h, s, "smooth", 500], hasReply: false)
    }
    
    private func sendCmdReply(id: Int, method: String, params: [Any], hasReply: Bool) -> Dictionary<String, Any>{
        let params_string = joinArrayWithComma(params)
        
        let cmd = "{\"id\":\(id),\"method\":\"\(method)\",\"params\":[\(params_string)]}\r\n";
        print("-> "+cmd)
        
        do {
            try client?.write(from: cmd)
        } catch {
            connected = false
            print("Reconnecting...")
            reconnect()
        }
        
        return readReply()
    }
}
