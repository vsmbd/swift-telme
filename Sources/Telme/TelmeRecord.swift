//
//  TelmeRecord.swift
//  Telme
//
//  Created by vsmbd on 27/01/26.
//

import SwiftCore
import EventDispatch

// MARK: - TelmeRecord

/// Canonical form for all observability signals.
/// All signals (logs, telemetry, events) are normalized into this structure.
@frozen
public struct TelmeRecord: Sendable {
	// MARK: + Default scope

	@inlinable
	init(
		recordId: UInt64,
		event: any Event,
		eventInfo: EventInfo
	) {
		self.timestamp = .now

		self.recordId = recordId
		self.kind = event.kind.lowercased()

		self.event = event
		self.eventInfo = eventInfo

		self.correlation = .init(eventInfo: eventInfo)
	}

	// MARK: + Public scope

	public struct Correlation: Sendable,
							   Encodable,
							   Hashable {
		// MARK: + Default scope

		@inlinable
		init(eventInfo: EventInfo) {
			self.eventId = eventInfo.eventId
			self.checkpoint = eventInfo.checkpoint
			self.taskId = eventInfo.taskInfo?.taskId
		}

		// MARK: + Public scope

		public let eventId: UInt64
		public let checkpoint: Checkpoint
		public let taskId: UInt64?
	}

	public let recordId: UInt64
	public let kind: String
	public let timestamp: MonotonicNanostamp

	public let event: any Event
	public let eventInfo: EventInfo

	public let correlation: Correlation
}

extension TelmeRecord: Encodable {
	private enum CodingKeys: String,
							 CodingKey {
		case recordId
		case kind
		case timestamp
		case event
		case eventInfo
		case correlation
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(
			recordId,
			forKey: .recordId
		)
		try container.encode(
			kind,
			forKey: .kind
		)
		try container.encode(
			timestamp,
			forKey: .timestamp
		)
		try container.encode(
			event,
			forKey: .event
		)
		try container.encode(
			eventInfo,
			forKey: .eventInfo
		)
		try container.encode(
			correlation,
			forKey: .correlation
		)
	}
}
