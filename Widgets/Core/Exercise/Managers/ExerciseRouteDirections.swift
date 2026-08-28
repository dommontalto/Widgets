//
//  ExerciseRouteDirections.swift
//  Widgets
//
//  Created by Dom Montalto on 28/8/2026.
//

import CoreLocation
import MapKit

nonisolated struct ExerciseRouteDirections {
    struct Upcoming: Equatable {
        let maneuver: ExerciseRouteManeuver
        let metres: Double
        let stepIndex: Int
    }

    let route: ExercisePlannedRoute

    private let cumulativeMetres: [Double]

    init(route: ExercisePlannedRoute) {
        self.route = route

        var cumulative: [Double] = [0]
        cumulative.reserveCapacity(route.coordinates.count)
        for pair in zip(route.coordinates, route.coordinates.dropFirst()) {
            cumulative.append(cumulative[cumulative.count - 1] + MKMapPoint(pair.0).distance(to: MKMapPoint(pair.1)))
        }
        cumulativeMetres = cumulative
    }

    func nearestIndex(to coordinate: CLLocationCoordinate2D, from lastIndex: Int) -> Int {
        let point = MKMapPoint(coordinate)
        let start = min(max(0, lastIndex), max(0, route.coordinates.count - 1))
        let end = min(route.coordinates.count, start + Constants.searchWindow)

        var best = start
        var bestDistance = Double.greatestFiniteMagnitude
        for index in start ..< end {
            let distance = MKMapPoint(route.coordinates[index]).distance(to: point)
            if distance < bestDistance {
                bestDistance = distance
                best = index
            }
        }
        return best
    }

    func upcoming(after index: Int) -> Upcoming? {
        guard index < cumulativeMetres.count else { return nil }

        for (stepIndex, step) in route.steps.enumerated()
            where step.coordinateIndex > index && step.coordinateIndex < cumulativeMetres.count {
            return Upcoming(
                maneuver: step.maneuver,
                metres: max(0, cumulativeMetres[step.coordinateIndex] - cumulativeMetres[index]),
                stepIndex: stepIndex
            )
        }
        return nil
    }

    private enum Constants {
        static let searchWindow = 400
    }
}
