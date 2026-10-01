//
//  GraphDateManager.swift
//  Widgets
//
//  Created by Zoe Friedman on 30/10/2023.
//

import Foundation

// https://streamplate.atlassian.net/wiki/spaces/BRIGHT/pages/331251713/iOS+Graph+ViewModel+Architecture.
//
class GraphDateManager {
    static let todaysDate: Date = DateHelper.getDateInTimeZone(Date())

    // Dates are stored in "splices" due to pagination.
    var splice: [Date] = []

    private enum Constants {
        // 4 days + extra for scroll turnover.
        static let numDays = 5
        // 4 weeks + extra for scroll turnover.
        static let numWeeks = 5
        // 3 months + extra for scroll turnover.
        static let numMonths = 4
        // 3 three months + extra scroll for turnover.
        static let numThreeMonths = 4 * 3
        // 3 years + extra for scroll turnover.
        static let numYears = 4
    }

    func createSplice(
        endDate: Date = GraphDateManager.todaysDate,
        forTab tab: GraphTab
    ) {
        // Populates the splice with data up until today's date.
        switch tab {
        case .daily:
            let end = getDateFrom(endDate, addingDays: 1)
            let start = getDateFrom(end, addingDays: -Constants.numDays)
            splice = getDaySeparatedDates(start: start, end: end)
        case .weekly:
            let end = getDateFrom(endDate, addingWeeks: 1)
            let start = getDateFrom(end, addingWeeks: -Constants.numWeeks)
            splice = getWeekSeparatedDates(start: start, end: end)
        case .monthly:
            let end = getDateFrom(endDate, addingMonths: 1)
            let start = getDateFrom(end, addingMonths: -Constants.numMonths)
            splice = getMonthSeparatedDates(start: start, end: end)
        case .threeMonth:
            let end = getDateFrom(getEndForThreeMonthly(date: endDate), addingMonths: 3)
            let start = getDateFrom(end, addingMonths: -Constants.numThreeMonths)
            splice = getTriMonthlySeparatedDates(start: start, end: end)
        case .yearly:
            let end = getDateFrom(endDate.endOfYear(), addingYears: 1)
            let start = getDateFrom(end, addingYears: -Constants.numYears)
            splice = getYearlySeparatedDates(start: start, end: end)
        }
    }

    func getEndForThreeMonthly(date: Date) -> Date {
        let month = date.month()
        if month % 3 == 0 {
            return date.endOfMonth()
        } else {
            let rounded = month.roundedUp(toNearest: 3)
            let difference = rounded - month
            return date.byAdding(
                component: .month,
                value: difference
            )?.endOfMonth() ?? date.endOfMonth()
        }
    }

    func setPreviousSplice(_ tab: GraphTab) {
        guard let endDate = splice.first else {
            return
        }
        createSplice(endDate: endDate, forTab: tab)
    }

    func setNextSplice(_ tab: GraphTab) {
        guard let first = splice.last else {
            return
        }
        switch tab {
        case .daily:
            let start = getDateFrom(first, addingDays: -1)
            let end = getDateFrom(start, addingDays: Constants.numDays)
            splice = getDaySeparatedDates(start: start, end: end)
        case .weekly:
            let start = getDateFrom(first, addingWeeks: -1)
            let end = getDateFrom(start, addingWeeks: Constants.numWeeks)
            splice = getWeekSeparatedDates(start: start, end: end)
        case .monthly:
            let start = getDateFrom(first, addingMonths: -1)
            let end = getDateFrom(start, addingMonths: Constants.numMonths)
            splice = getMonthSeparatedDates(start: start, end: end)
        case .threeMonth:
            let start = getDateFrom(first, addingMonths: -3)
            let end = getDateFrom(start, addingMonths: Constants.numThreeMonths)
            splice = getTriMonthlySeparatedDates(start: start, end: end)
        case .yearly:
            let start = getDateFrom(first, addingYears: -1)
            let end = getDateFrom(start, addingYears: Constants.numYears)
            splice = getYearlySeparatedDates(start: start, end: end)
        }
    }

    static func areDatesEqual(_ d1: Date, _ d2: Date, basedOn tab: GraphTab) -> Bool {
        switch tab {
        case .daily:
            d1.hasSameHour(as: d2)
        case .weekly:
            d1.isSameDay(as: d2)
        case .monthly:
            d1.isSameDay(as: d2)
        case .threeMonth:
            d1.isInSameWeek(as: d2)
        case .yearly:
            d1.isInSameMonth(as: d2)
        }
    }
}

extension GraphDateManager {
    private func getDaySeparatedDates(start: Date, end: Date) -> [Date] {
        var dates: [Date] = []

        var currentDate = end
        while currentDate >= start {
            dates.append(currentDate)
            if let nextDate = currentDate.byAdding(
                component: .day,
                value: -1
            ) {
                currentDate = nextDate
            } else {
                break
            }
        }
        return dates.reversed()
    }

    private func getWeekSeparatedDates(start: Date, end: Date) -> [Date] {
        var dates: [Date] = []

        var currentDate = end
        while currentDate >= start {
            dates.append(currentDate)
            if let nextDate = currentDate.byAdding(
                component: .weekOfYear,
                value: -1
            ) {
                currentDate = nextDate
            } else {
                break
            }
        }
        return dates.reversed()
    }

    private func getMonthSeparatedDates(start: Date, end: Date) -> [Date] {
        var dates: [Date] = []

        var currentDate = end.endOfMonth()
        while currentDate >= start {
            dates.append(currentDate.endOfMonth())
            if let nextDate = currentDate.byAdding(
                component: .month,
                value: -1
            ) {
                currentDate = nextDate.endOfMonth()
            } else {
                break
            }
        }
        return dates.reversed()
    }

    private func getTriMonthlySeparatedDates(start: Date, end: Date) -> [Date] {
        var dates: [Date] = []

        var currentDate = end.endOfMonth()
        while currentDate >= start {
            dates.append(currentDate.endOfMonth())
            if let nextDate = currentDate.byAdding(
                component: .month,
                value: -3
            ) {
                currentDate = nextDate.endOfMonth()
            } else {
                break
            }
        }
        return dates.reversed()
    }

    private func getYearlySeparatedDates(start: Date, end: Date) -> [Date] {
        var dates: [Date] = []

        var currentDate = end
        while currentDate >= start {
            dates.append(currentDate)
            if let nextDate = currentDate.byAdding(
                component: .year,
                value: -1
            ) {
                currentDate = nextDate
            } else {
                break
            }
        }
        return dates.reversed()
    }

    private func getDateFrom(_ date: Date, addingDays days: Int) -> Date {
        date.byAdding(component: .day, value: days) ?? date
    }

    private func getDateFrom(_ date: Date, addingWeeks weeks: Int) -> Date {
        date.byAdding(component: .weekOfYear, value: weeks) ?? date
    }

    private func getDateFrom(_ date: Date, addingMonths months: Int) -> Date {
        date.byAdding(component: .month, value: months) ?? date
    }

    private func getDateFrom(_ date: Date, addingYears years: Int = 1) -> Date {
        date.byAdding(component: .year, value: years) ?? date
    }
}
