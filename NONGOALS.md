# Telme Non-Goals

This document defines what Telme explicitly does not attempt to do.

## Guaranteed delivery

- No acknowledgements, retries, or exactly-once semantics.
- Records may be lost if the process exits before flush or if a sink fails.
- Best-effort only; observability is not required for application correctness.

## Application correctness dependency

- The app must not rely on Telme for correctness. Observability is optional and best-effort.

## Unbounded buffering

- Buffer size is bounded by FlushConfig.maxRecordCount and flush timing.
- No unbounded in-memory queue; flush runs when thresholds are met.

## Unstructured logging

- All signals are normalized into TelmeRecord (kind, timestamp, event, eventInfo, correlation).
- No free-form string logs; events are typed (Event protocol) with structured metadata.

## Domain-specific semantics

- Telme does not define log levels, span semantics, or metric types.
- It normalizes and forwards; semantics are defined by event producers and record sinks.

## Built-in UI or dashboards

- No built-in visualization, dashboards, or UI. Export is via TelmeRecordSink; consumers build their own tooling.

## Persistence or durability

- Buffer is in-memory only. No disk, no WAL, no replay. Process exit loses unflushed records.
- Durability (if needed) is the responsibility of record sinks or higher layers.
