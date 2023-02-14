//
//  Float3.swift
//  ChaosSaver
//
//  Created by Charles Liske on 2/11/23.
//

import Foundation

struct Float3 {
    var x: Double
    var y: Double
    var z: Double
    static func + (left: Float3, right: Float3) -> Float3 {
        return Float3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
    }
    static func - (left: Float3, right: Float3) -> Float3 {
        return Float3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
    }
    static func * (left: Float3, right: Double) -> Float3 {
        return Float3(x: left.x * right, y: left.y * right, z: left.z * right)
    }
    static func * (left: Double, right: Float3) -> Float3 {
        return Float3(x: left * right.x, y: left * right.y, z: left * right.z)
    }
    static func * (left: Float3, right: Float3) -> Float3 {
        return Float3(x: left.x * right.x, y: left.y * right.y, z: left.z * right.z)
    }
    static func / (left: Float3, right: Double) -> Float3 {
        return Float3(x: left.x / right, y: left.y / right, z: left.z / right)
    }
    static func / (left: Double, right: Float3) -> Float3 {
        return Float3(x: right.x / left, y: right.y / left, z: right.z / left)
    }
}
