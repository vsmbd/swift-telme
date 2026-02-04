//
//  ConsoleRecordSink.swift
//  Telme
//
//  Created by vsmbd on 30/01/26.
//

import Foundation

// MARK: - ConsoleRecordSink

public final class ConsoleRecordSink: TelmeRecordSink {
	// MARK: + Private scope

	private let encoder: JSONEncoder = {
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [
			.prettyPrinted,
			.sortedKeys
		]
		return jsonEncoder
	}()

	// MARK: + Public scope

	public init() {
		//
	}

	public func sink(_ records: [TelmeRecord]) {
		for record in records {
			do {
				let data = try encoder.encode(record)

				if let json = String(
					data: data,
					encoding: .utf8
				) {
					print(json)
				}
			} catch {
				print(record)
			}
		}
	}
}
