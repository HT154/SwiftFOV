//
//  FOV.swift
//  SwiftFOV
//
//  Created by Joshua Basch on 1/2/17.
//  Copyright © 2017 HT154. All rights reserved.
//
//  SwiftFOV is based on libfov (https://code.google.com/archive/p/libfov/)
//

struct FOV {

    public enum Direction {
        case e, ne, n, nw, w, sw, s, se
    }

    private class Data {

        typealias Update = (inout Int, inout Int, Int) -> Void

        let pos: (x: Int, y: Int)
        let radius: UInt
        let updates: (dx: Update, dy0: Update, dy: Update)
        let applyTo: (edge: Bool, diag: Bool)
        let opaque: (Int, Int) -> Bool? // nil: not opaque, false: opaque no apply, true: opaque and apply
        let apply: (Int, Int, Int, Int) -> Void

        init(source pos: (x: Int, y: Int), radius: UInt,
             updates: (dx: Update, dy0: Update, dy: Update),
             applyTo: (edge: Bool, diag: Bool),
             opaque: @escaping (Int, Int) -> Bool?,
             apply: @escaping (Int, Int, Int, Int) -> Void) {
            self.pos = pos
            self.radius = radius
            self.updates = updates
            self.applyTo = applyTo
            self.opaque = opaque
            self.apply = apply
        }
    }

    public static func castCircle(from pos: (x: Int, y: Int), radius r: UInt, includeStart: Bool = false, apply: @escaping (Int, Int, Int, Int) -> Void, opaque: @escaping (Int, Int) -> Bool?) {
        /*
         * Octants are defined by (x,y,r) where:
         *  x = [p]ositive or [n]egative x increment
         *  y = [p]ositive or [n]egative y increment
         *  r = [y]es or [n]o for reflecting on axis x = y
         *       90
         *   \pmy|ppy/
         *    \  |  /
         *     \ | /
         *   mpn\|/ppn
         *180----@---- 0
         *   mmn/|\pmn
         *     / | \
         *    /  |  \
         *   /mmy|mpy\
         *      270
         */

        if includeStart {
            apply(pos.x, pos.y, 0, 0)
        }

        let ppn = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in x = pos.x + dx },
                                 { x, y, dy0 in y = pos.y + dy0 },
                                 { x, y, dy in y = pos.y + dy }),
                       applyTo: (true, true), opaque: opaque, apply: apply)
        let ppy = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in y = pos.y + dx },
                                 { x, y, dy0 in x = pos.x + dy0 },
                                 { x, y, dy in x = pos.x + dy }),
                       applyTo: (true, false), opaque: opaque, apply: apply)

        let pmn = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in x = pos.x + dx },
                                 { x, y, dy0 in y = pos.y - dy0 },
                                 { x, y, dy in y = pos.y - dy }),
                       applyTo: (false, true), opaque: opaque, apply: apply)
        let pmy = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in y = pos.y + dx },
                                 { x, y, dy0 in x = pos.x - dy0 },
                                 { x, y, dy in x = pos.x - dy }),
                       applyTo: (false, false), opaque: opaque, apply: apply)

        let mpn = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in x = pos.x - dx },
                                 { x, y, dy0 in y = pos.y + dy0 },
                                 { x, y, dy in y = pos.y + dy }),
                       applyTo: (true, true), opaque: opaque, apply: apply)
        let mpy = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in y = pos.y - dx },
                                 { x, y, dy0 in x = pos.x + dy0 },
                                 { x, y, dy in x = pos.x + dy }),
                       applyTo: (true, false), opaque: opaque, apply: apply)

        let mmn = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in x = pos.x - dx },
                                 { x, y, dy0 in y = pos.y - dy0 },
                                 { x, y, dy in y = pos.y - dy }),
                       applyTo: (false, true), opaque: opaque, apply: apply)
        let mmy = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in y = pos.y - dx },
                                 { x, y, dy0 in x = pos.x - dy0 },
                                 { x, y, dy in x = pos.x - dy }),
                       applyTo: (false, false), opaque: opaque, apply: apply)

        castOctant(ppn)
        castOctant(ppy)
        castOctant(pmn)
        castOctant(pmy)
        castOctant(mpn)
        castOctant(mpy)
        castOctant(mmn)
        castOctant(mmy)
    }

    public static func castBeam(from pos: (x: Int, y: Int), radius r: UInt, direction: Direction, angle: Float, includeStart: Bool = false, apply: @escaping (Int, Int, Int, Int) -> Void, opaque: @escaping (Int, Int) -> Bool?) {
        if angle < 0 {
            return
        } else if angle >= 360 {
            castCircle(from: pos, radius: r, includeStart: includeStart, apply: apply, opaque: opaque)
            return
        }

        if includeStart {
            apply(pos.x, pos.y, 0, 0)
        }

        let a = angle / 90

        let ppn = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in x = pos.x + dx },
                                 { x, y, dy0 in y = pos.y + dy0 },
                                 { x, y, dy in y = pos.y + dy }),
                       applyTo: (true, true), opaque: opaque, apply: apply)
        let ppy = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in y = pos.y + dx },
                                 { x, y, dy0 in x = pos.x + dy0 },
                                 { x, y, dy in x = pos.x + dy }),
                       applyTo: (true, false), opaque: opaque, apply: apply)

        let pmn = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in x = pos.x + dx },
                                 { x, y, dy0 in y = pos.y - dy0 },
                                 { x, y, dy in y = pos.y - dy }),
                       applyTo: (false, true), opaque: opaque, apply: apply)
        let pmy = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in y = pos.y + dx },
                                 { x, y, dy0 in x = pos.x - dy0 },
                                 { x, y, dy in x = pos.x - dy }),
                       applyTo: (false, false), opaque: opaque, apply: apply)


        let mpn = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in x = pos.x - dx },
                                 { x, y, dy0 in y = pos.y + dy0 },
                                 { x, y, dy in y = pos.y + dy }),
                       applyTo: (true, true), opaque: opaque, apply: apply)
        let mpy = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in y = pos.y - dx },
                                 { x, y, dy0 in x = pos.x + dy0 },
                                 { x, y, dy in x = pos.x + dy }),
                       applyTo: (true, false), opaque: opaque, apply: apply)

        let mmn = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in x = pos.x - dx },
                                 { x, y, dy0 in y = pos.y - dy0 },
                                 { x, y, dy in y = pos.y - dy }),
                       applyTo: (false, true), opaque: opaque, apply: apply)
        let mmy = Data(source: pos, radius: r,
                       updates: ({ x, y, dx in y = pos.y - dx },
                                 { x, y, dy0 in x = pos.x - dy0 },
                                 { x, y, dy in x = pos.x - dy }),
                       applyTo: (false, false), opaque: opaque, apply: apply)

        switch direction {
        case .e: castBeamCardinal(angle: a, data: ppn, pmn, ppy, mpy, pmy, mmy, mpn, mmn)
        case .w: castBeamCardinal(angle: a, data: mpn, mmn, pmy, mmy, ppy, mpy, ppn, pmn)
        case .n: castBeamCardinal(angle: a, data: mpy, mmy, mmn, pmn, mpn, ppn, pmy, ppy)
        case .s: castBeamCardinal(angle: a, data: pmy, ppy, mpn, ppn, mmn, pmn, mmy, mpy)
        case .ne: castBeamDiagonal(angle: a, data: pmn, mpy, mmy, ppn, mmn, ppy, mpn, pmy)
        case .nw: castBeamDiagonal(angle: a, data: mmn, mmy, mpn, mpy, pmy, pmn, ppy, ppn)
        case .se: castBeamDiagonal(angle: a, data: ppn, ppy, pmy, pmn, mpn, mpy, mmn, mmy)
        case .sw: castBeamDiagonal(angle: a, data: pmy, mpn, ppy, mmn, ppn, mmy, pmn, mpy)
        }
    }

    private static func castBeamCardinal(angle a: Float, data p1: Data, _ p2: Data, _ p3: Data, _ p4: Data, _ p5: Data, _ p6: Data, _ p7: Data, _ p8: Data) {
        let endSlope = betweenf(a, 0, 1)
        castOctant(p1, dx: 1, slope: (0, endSlope))
        castOctant(p2, dx: 1, slope: (0, endSlope))

        if a - 1 > FLT_EPSILON { // a > 1.0
            let startSlope = betweenf(2 - a, 0, 1)
            castOctant(p3, dx: 1, slope: (startSlope, 1))
            castOctant(p4, dx: 1, slope: (startSlope, 1))
        }

        if a - 2 > FLT_EPSILON { // a > 2.0
            let endSlope = betweenf(a - 2, 0, 1)
            castOctant(p5, dx: 1, slope: (0, endSlope))
            castOctant(p6, dx: 1, slope: (0, endSlope))
        }

        if a - 3 > FLT_EPSILON { // a > 3.0
            let startSlope = betweenf(4 - a, 0, 1)
            castOctant(p7, dx: 1, slope: (startSlope, 1))
            castOctant(p8, dx: 1, slope: (startSlope, 1))
        }
    }

    private static func castBeamDiagonal(angle a: Float, data p1: Data, _ p2: Data, _ p3: Data, _ p4: Data, _ p5: Data, _ p6: Data, _ p7: Data, _ p8: Data) {
        let startSlope = betweenf(1 - a, 0, 1)
        castOctant(p1, dx: 1, slope: (startSlope, 1))
        castOctant(p2, dx: 1, slope: (startSlope, 1))

        if a - 1 > FLT_EPSILON { // a > 1.0
            let endSlope = betweenf(a - 1, 0, 1)
            castOctant(p3, dx: 1, slope: (0, endSlope))
            castOctant(p4, dx: 1, slope: (0, endSlope))
        }

        if a - 2 > FLT_EPSILON { // a > 2.0
            let startSlope = betweenf(3 - a, 0, 1)
            castOctant(p5, dx: 1, slope: (startSlope, 1))
            castOctant(p6, dx: 1, slope: (startSlope, 1))
        }

        if a - 3 > FLT_EPSILON { // a > 3.0
            let endSlope = betweenf(a - 3, 0, 1)
            castOctant(p7, dx: 1, slope: (0, endSlope))
            castOctant(p8, dx: 1, slope: (0, endSlope))
        }
    }

    // Limit x to the range [a, b].
    private static func betweenf(_ x: Float, _ a: Float, _ b: Float) -> Float {
        if x - a < FLT_EPSILON { // x < a
            return a
        } else if x - b > FLT_EPSILON { // x > b
            return b
        } else {
            return x
        }
    }

    private static func slope(_ dx: Float, _ dy: Float) -> Float {
        if dx <= -FLT_EPSILON || dx >= FLT_EPSILON {
            return dy / dx
        }

        return 0
    }

    private static func castOctant(_ data: Data, dx: Int = 1, slope: (start: Float, end: Float) = (0, 1)) {
        if dx == 0 {
            castOctant(data, dx: dx + 1, slope: slope)
            return
        } else if UInt(dx) > data.radius {
            return
        }

        let dy0 = Int(0.5 + Float(dx) * slope.start)
        var dy1 = Int(0.5 + Float(dx) * slope.end)

        var x = 0
        var y = 0

        data.updates.dx(&x, &y, dx)
        data.updates.dy0(&x, &y, dy0)

        // We do diagonal lines on every second octant, so they don't get done twice.
        if !data.applyTo.diag && dy1 == dx {
            dy1 -= 1
        }

        let h = UInt(sqrt(Float(data.radius * data.radius - UInt(dx * dx))))

        if UInt(dy1) > h {
            if h == 0 { return }

            dy1 = Int(h)
        }

        var slope = slope
        var prevBlocked: Bool?
        var dy = dy0
        while dy <= dy1 {
            data.updates.dy(&x, &y, dy)

            if let applyOpaque = data.opaque(x, y) {
                if applyOpaque && (data.applyTo.edge || dy > 0) {
                    data.apply(x, y, x - data.pos.x, y - data.pos.y)
                }

                if prevBlocked == false {
                    let newSlope = (slope.start, self.slope(Float(dx) + 0.5, Float(dy) - 0.5))
                    castOctant(data, dx: dx + 1, slope: newSlope)
                }

                prevBlocked = true
            } else {
                if data.applyTo.edge || dy > 0 {
                    data.apply(x, y, x - data.pos.x, y - data.pos.y)
                }

                if prevBlocked == true {
                    slope.start = self.slope(Float(dx) - 0.5, Float(dy) - 0.5)
                }

                prevBlocked = false
            }

            dy += 1
        }

        if prevBlocked == false {
            castOctant(data, dx: dx + 1, slope: slope)
        }
    }

}
