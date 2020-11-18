import Foundation
import Policy

let config = Config()

// read request from stdin
var raw = ""
while let line = readLine() {
    raw += line + "\n"
}

let result = validate(rawJSON: raw, config: config)

let encoder = JSONEncoder()
let data = try! encoder.encode(result)
print(String(data: data, encoding: .utf8)!)