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
public struct TelmeRecord: Sendable,
						   Encodable {
	// MARK: + Default scope

	@inlinable
	init(
		recordId: UInt64,
		event: AnyEvent,
		eventInfo: EventInfo
	) {
		self.recordId = recordId
		self.kind = event.kind.lowercased()
		self.timestamp = .now

		self.event = event
		self.eventInfo = eventInfo

		self.correlation = .init(eventInfo: eventInfo)
	}

	// MARK: + Public scope

	public let recordId: UInt64
	public let kind: String
	public let timestamp: MonotonicNanostamp

	public let event: AnyEvent
	public let eventInfo: EventInfo

	public let correlation: Correlation

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
}
