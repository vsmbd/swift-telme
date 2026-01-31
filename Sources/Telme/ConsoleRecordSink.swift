//
//  ConsoleRecordSink.swift
//  Telme
//
//  Created by vsmbd on 30/01/26.
//

// MARK: - ConsoleRecordSink

public final class ConsoleRecordSink: TelmeRecordSink {
	public init() {
		//
	}
	
	public func sink(_ record: TelmeRecord) {
		print(record)
	}
}
