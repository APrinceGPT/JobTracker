// DateFormatting.swift
// JobTracker

import Foundation

// MARK: - Date formatting helpers (MM/DD/YYYY text input)

let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MM/dd/yyyy"
    f.isLenient  = true
    return f
}()

func string(from date: Date) -> String { dateFormatter.string(from: date) }
func date(from string: String) -> Date? { dateFormatter.date(from: string) }
