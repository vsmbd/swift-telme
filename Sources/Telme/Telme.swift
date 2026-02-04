//
//  Telme.swift
//  Telme
//
//  Created by vsmbd on 27/01/26.
//

import Dispatch
import SwiftCore
import EventDispatch

// MARK: - Telme

public protocol TelmeRecordSink: Sendable {
	func sink(_ record: TelmeRecord)
}

/// Lightweight observability pipeline that ingests, normalizes, and exports
/// all runtime signals produced by an application.
///
/// Telme treats logging, telemetry, and internal events as the same class of signal:
/// time-stamped, semi-structured data emitted at specific points in program execution.
///
/// Telme is non-blocking on hot paths and best-effort by design.
public final class Telme: @unchecked Sendable,
						  EventSink,
						  Entity {
	// MARK: + Private scope

	private var recordId: UInt64 = 0

	private let queue: DispatchQueue = .init(
		label: "swift-telme.queue",
		qos: .background
	)

	private var records: [TelmeRecord] = []
	private var recordSinks: [TelmeRecordSink] = []

	private var lastFlushTime: DispatchTime = .now()
	private var flushConfig: FlushConfig?
	private var flushPaused: Bool = false

	private init() {
		identifier = Self.nextID
	}

	private func flushBufferedRecords() {
		guard records.isEmpty == false else { return }

		let batch = records
		records = []
		lastFlushTime = DispatchTime.now()

		for record in batch {
			for sink in recordSinks {
				sink.sink(record)
			}
		}
	}

	private func flushAsPerConfig(_ config: FlushConfig) {
		let maxCountExceeded = records.count >= config.maxRecordCount

		let flushIntervalExceeded: Bool
		if let flushNanos = config.flushInterval.nanoseconds() {
			let currentNanos = DispatchTime.now().uptimeNanoseconds
			let lastFlushNanos = lastFlushTime.uptimeNanoseconds
			let elapsedNanos = currentNanos - lastFlushNanos

			flushIntervalExceeded = elapsedNanos >= flushNanos
		} else {
			flushIntervalExceeded = false
		}

		if maxCountExceeded || flushIntervalExceeded {
			flushBufferedRecords()
		}

		scheduleFlushCheck()
	}

	private func scheduleFlushCheck() {
		guard let flushConfig,
			  flushPaused == false else {
			flushBufferedRecords()
			return
		}

		let deadline = DispatchTime.now() + flushConfig.checkInterval
		queue.asyncAfter(deadline: deadline) { [weak self] in
			guard let self,
				  let flushConfig = self.flushConfig else { return }

			flushAsPerConfig(flushConfig)
			scheduleFlushCheck()
		}
	}

	// MARK: ++ Default sinks

	private func checkpointEventSink(_ event: CheckpointEvent) -> Void {
		let timestamp = MonotonicNanostamp.now

		switch event {
		case .created(let checkpoint):
			sink(
				event: event,
				info: .init(
					timestamp: timestamp,
					checkpoint: checkpoint
				)
			)

		case .correlated(
			from: _,
			to: let to
		):
			sink(
				event: event,
				info: .init(
					timestamp: timestamp,
					checkpoint: to
				)
			)
		}
	}

	private func taskQueueEventSink(_ event: TaskQueue.TaskQueueEvent) -> Void {
		sink(
			event: event,
			info: .init(
				timestamp: .now,
				checkpoint: event.taskInfo.checkpoint
			)
		)
	}

	// MARK: + Default scope

	// MARK: + Public scope

	public struct FlushConfig: Sendable {
		public let maxRecordCount: UInt8
		public let checkInterval: DispatchTimeInterval
		public let flushInterval: DispatchTimeInterval

		public init(
			maxRecordCount: UInt8 = 100,
			checkInterval: DispatchTimeInterval = .seconds(2),
			flushInterval: DispatchTimeInterval = .seconds(5)
		) {
			self.maxRecordCount = maxRecordCount
			self.checkInterval = checkInterval
			self.flushInterval = flushInterval
		}
	}

	/// The default, app-wide Telme instance.
	public static let `default`: Telme = .init()

	public let identifier: UInt64

	/// Configures buffering and periodic flush.
	/// Schedules a recurring check on the queue.
	/// Flush runs when buffered count reaches the limit or flushInterval has passed since last flush.
	/// Call once at bootstrap; subsequent calls are ignored.
	public func setup(
		_ checkpoint: Checkpoint,
		flushConfig: FlushConfig = .init()
	) {
		Checkpoint.setEventSink(checkpointEventSink(_:))
		TaskQueue.setEventSink(taskQueueEventSink(_:))

		EventDispatch.default.setGlobalSink(
			self,
			checkpoint.next(self)
		)

		queue.async { [weak self] in
			guard let self,
				  self.flushConfig == nil else { return }

			self.flushConfig = flushConfig
			lastFlushTime = DispatchTime.now()

			scheduleFlushCheck()
		}
	}

	public func addRecordSink(_ sink: TelmeRecordSink) {
		queue.async { [weak self] in
			guard let self else { return }

			recordSinks.append(sink)
		}
	}

	/// Delivers all buffered records to registered sinks immediately.
	/// Non-blocking; work runs on the internal queue.
	public func flush() {
		queue.async { [weak self] in
			guard let self else { return }

			flushBufferedRecords()
		}
	}

	/// Delivers buffered records to sinks, then stops scheduling further flush checks.
	public func pauseFlushing() {
		queue.async { [weak self] in
			guard let self else { return }

			flushBufferedRecords()
			flushPaused = true
		}
	}

	/// Resumes scheduling flush checks.
	public func resumeFlushing() {
		queue.async { [weak self] in
			guard let self else { return }

			flushPaused = false
			scheduleFlushCheck()
		}
	}

	// MARK: ++ EventSink

	public func sink<E: Event>(
		event: E,
		info: EventInfo
	) {
		queue.async { [weak self] in
			guard let self else { return }

			recordId += 1
			records.append(
				.init(
					recordId: recordId,
					event: AnyEvent(event),
					eventInfo: info
				)
			)
		}
	}
}

// MARK: + Helpers

fileprivate extension DispatchTimeInterval {
	/// Converts a dispatch interval to nanoseconds for elapsed-time comparison. Returns nil for .never.
	func nanoseconds() -> UInt64? {
		switch self {
		case .seconds(let value):
			return UInt64(value) * 1_000_000_000

		case .milliseconds(let value):
			return UInt64(value) * 1_000_000

		case .microseconds(let value):
			return UInt64(value) * 1_000

		case .nanoseconds(let value):
			return UInt64(value)

		case .never:
			fallthrough
		@unknown default:
			return nil
		}
	}
}
