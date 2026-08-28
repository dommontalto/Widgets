//
//  ExerciseRouteGenerator.swift
//  Widgets
//
//  Created by Dom Montalto on 28/8/2026.
//

import CoreLocation
import MapKit

nonisolated enum ExerciseRouteGenerator {
    // Each leg is one MKDirections request over the walking network. Legs that
    // route far longer than their crow-flies span have dipped into a side
    // street and doubled back — those waypoints drop out and the next leg
    // bridges the gap. The final leg keeps its endpoint regardless.
    static func route(through waypoints: [CLLocationCoordinate2D]) async -> ExercisePlannedRoute? {
        guard waypoints.count >= 2 else { return nil }

        var coordinates: [CLLocationCoordinate2D] = []
        var steps: [ExercisePlannedRouteStep] = []
        var distance: Double = 0

        var from = waypoints[0]

        for (offset, to) in waypoints.dropFirst().enumerated() {
            let request = MKDirections.Request()
            request.source = mapItem(at: from)
            request.destination = mapItem(at: to)
            request.transportType = .walking

            guard let leg = try? await MKDirections(request: request).calculate().routes.first else { continue }

            let isFinal = offset == waypoints.count - 2
            if !isFinal, leg.distance > straightLineDistance(from: from, to: to) * Constants.maxLegDetourFactor {
                continue
            }

            for step in leg.steps {
                let points = step.polyline.routeCoordinates
                guard !points.isEmpty else { continue }
                if let maneuver = maneuver(from: step.instructions), !coordinates.isEmpty {
                    steps.append(ExercisePlannedRouteStep(maneuver: maneuver, coordinateIndex: coordinates.count))
                }
                coordinates += points
            }
            distance += leg.distance
            from = to
        }

        // Directions can fail offline or over unroutable ground — fall back
        // to the raw points so the gesture still becomes a route.
        if coordinates.count < 2 {
            coordinates = waypoints
            steps = []
            distance = straightLineDistance(of: waypoints)
        }

        let routedLength = straightLineDistance(of: coordinates)
        let (pruned, keptIndexes) = prunedSpurs(coordinates)
        let prunedLength = straightLineDistance(of: pruned)
        if prunedLength < routedLength, routedLength > 0 {
            distance *= prunedLength / routedLength
            var remapped: [Int: Int] = [:]
            for (position, original) in keptIndexes.enumerated() {
                remapped[original] = position
            }
            steps = steps.compactMap { step in
                remapped[step.coordinateIndex].map {
                    ExercisePlannedRouteStep(maneuver: step.maneuver, coordinateIndex: $0)
                }
            }
            coordinates = pruned
        }

        return ExercisePlannedRoute(
            coordinates: coordinates,
            distanceMetres: distance,
            durationSeconds: distance / 1000 * Constants.runningSecondsPerKm,
            steps: steps
        )
    }

    // Distance-first generation: out half the target along a probed bearing,
    // a U-turn, then a routed leg home — so it always draws start to finish.
    static func outAndBack(targetMetres: Double, from start: CLLocationCoordinate2D) async -> ExercisePlannedRoute {
        let outTarget = targetMetres / 2
        let baseBearing = Double.random(in: 0 ..< 360)

        for attempt in 0 ..< Constants.generateBearings {
            let bearing = (baseBearing + Double(attempt) * 360 / Double(Constants.generateBearings))
                .truncatingRemainder(dividingBy: 360)
            var crow = outTarget * Constants.generateCrowFactor

            for _ in 0 ..< Constants.generateRefinements {
                let destination = coordinate(metres: crow, bearing: bearing, from: start)
                guard let out = await route(through: [start, destination]),
                      out.coordinates.count >= 2, out.distanceMetres > 0 else { break }

                let ratio = outTarget / out.distanceMetres
                if abs(1 - ratio) <= Constants.generateTolerance {
                    guard let turn = out.coordinates.last,
                          let back = await route(through: [turn, start]),
                          back.coordinates.count >= 2 else { break }

                    var combined = out
                    combined.steps.append(ExercisePlannedRouteStep(
                        maneuver: .uTurn,
                        coordinateIndex: combined.coordinates.count - 1
                    ))
                    combined = combined.appending(back)
                    combined.steps.append(ExercisePlannedRouteStep(
                        maneuver: .arrive,
                        coordinateIndex: combined.coordinates.count - 1
                    ))
                    return combined
                }
                crow = min(
                    max(crow * ratio, outTarget * Constants.generateCrowFloor),
                    outTarget * Constants.generateCrowCeiling
                )
            }
        }

        let destination = coordinate(metres: outTarget, bearing: baseBearing, from: start)
        return ExercisePlannedRoute(
            coordinates: [start, destination, start],
            distanceMetres: targetMetres,
            durationSeconds: targetMetres / 1000 * Constants.runningSecondsPerKm,
            steps: [
                ExercisePlannedRouteStep(maneuver: .uTurn, coordinateIndex: 1),
                ExercisePlannedRouteStep(maneuver: .arrive, coordinateIndex: 2),
            ]
        )
    }

    private static func maneuver(from instructions: String) -> ExerciseRouteManeuver? {
        let text = instructions.lowercased()
        if text.contains("u-turn") || text.contains("u turn") { return .uTurn }
        if text.contains("left") { return .left }
        if text.contains("right") { return .right }
        return nil
    }

    // Cuts out-and-back spurs from the routed polyline: a stretch that leaves
    // a point and returns to within a few metres of it is a dip into a side
    // road, not part of the route. Deliberate out-and-backs longer than
    // maxSpurLength survive.
    private static func prunedSpurs(
        _ coordinates: [CLLocationCoordinate2D]
    ) -> (coordinates: [CLLocationCoordinate2D], keptIndexes: [Int]) {
        guard coordinates.count > 2 else { return (coordinates, Array(coordinates.indices)) }

        var pruned: [CLLocationCoordinate2D] = []
        var keptIndexes: [Int] = []
        pruned.reserveCapacity(coordinates.count)
        keptIndexes.reserveCapacity(coordinates.count)

        var i = 0
        while i < coordinates.count {
            pruned.append(coordinates[i])
            keptIndexes.append(i)

            var pathLength: Double = 0
            var cutTo: Int?
            var j = i + 1

            while j < coordinates.count, pathLength <= Constants.maxSpurLength {
                pathLength += straightLineDistance(from: coordinates[j - 1], to: coordinates[j])
                if pathLength >= Constants.minSpurLength,
                   straightLineDistance(from: coordinates[i], to: coordinates[j]) <= Constants.spurReturnRadius {
                    cutTo = j
                }
                j += 1
            }

            i = cutTo ?? (i + 1)
        }

        return (pruned, keptIndexes)
    }

    private static func mapItem(at coordinate: CLLocationCoordinate2D) -> MKMapItem {
        if #available(iOS 26, *) {
            MKMapItem(
                location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                address: nil
            )
        } else {
            legacyMapItem(at: coordinate)
        }
    }

    @available(iOS, deprecated: 26.0)
    private static func legacyMapItem(at coordinate: CLLocationCoordinate2D) -> MKMapItem {
        MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
    }

    static func straightLineDistance(of points: [CLLocationCoordinate2D]) -> Double {
        zip(points, points.dropFirst()).reduce(0) { total, pair in
            total + straightLineDistance(from: pair.0, to: pair.1)
        }
    }

    static func straightLineDistance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        MKMapPoint(a).distance(to: MKMapPoint(b))
    }

    private static func coordinate(
        metres: Double,
        bearing: CLLocationDirection,
        from start: CLLocationCoordinate2D
    ) -> CLLocationCoordinate2D {
        let angular = metres / Constants.earthRadiusMetres
        let bearingRadians = bearing * .pi / 180
        let latitude = start.latitude * .pi / 180
        let longitude = start.longitude * .pi / 180

        let endLatitude = asin(
            sin(latitude) * cos(angular) + cos(latitude) * sin(angular) * cos(bearingRadians)
        )
        let endLongitude = longitude + atan2(
            sin(bearingRadians) * sin(angular) * cos(latitude),
            cos(angular) - sin(latitude) * sin(endLatitude)
        )
        return CLLocationCoordinate2D(
            latitude: endLatitude * 180 / .pi,
            longitude: endLongitude * 180 / .pi
        )
    }

    enum Constants {
        // Average recreational running pace, 5:30 min/km.
        static let runningSecondsPerKm: Double = 330
        // How much longer than crow-flies a leg may route before it reads as a
        // dip into a side street rather than a road genuinely winding.
        static let maxLegDetourFactor: Double = 2.5
        // Spur pruning: how close a return point must be to where it left, the
        // shortest detour worth cutting, and the longest stretch still treated
        // as a spur rather than a deliberate out-and-back.
        static let spurReturnRadius: CLLocationDistance = 20
        static let minSpurLength: CLLocationDistance = 40
        static let maxSpurLength: CLLocationDistance = 400

        static let earthRadiusMetres: Double = 6_371_000
        static let generateBearings = 3
        static let generateRefinements = 3
        static let generateCrowFactor: Double = 0.7
        static let generateCrowFloor: Double = 0.3
        static let generateCrowCeiling: Double = 1.5
        static let generateTolerance: Double = 0.12
    }
}

nonisolated extension MKPolyline {
    var routeCoordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}

@Observable
final class ExerciseRouteLocator: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var lastLocation: CLLocation?
    var isAuthorized = false

    // Whatever CoreLocation already holds, so a tap doesn't wait on a new fix.
    var cachedLocation: CLLocation? { lastLocation ?? manager.location }

    override init() {
        super.init()
        manager.delegate = self
        // A ten-metre fix arrives far sooner than a best-accuracy one, and the
        // map is flown to at neighbourhood zoom anyway.
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        isAuthorized = manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways
        if isAuthorized {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
