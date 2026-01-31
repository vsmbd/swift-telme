//
//  DefaultSinkEvents.swift
//  Telme
//
//  Created by vsmbd on 30/01/26.
//

import SwiftCore
import EventDispatch

// MARK: - Checkpoint events

extension CheckpointEvent: @retroactive Event {
	public var kind: String {
		switch self {
		case .created:
			typeName + "_created"

		case .correlated:
			typeName + "_correlated"
		}
	}
}

// MARK: - TaskQueue events

extension TaskQueue.TaskQueueEvent: @retroactive Event {
	public var kind: String {
		switch executionState {
		case .created:
			typeName + "_created"

		case .started:
			typeName + "_started"

		case .completed:
			typeName + "_completed"
		}
	}
}
