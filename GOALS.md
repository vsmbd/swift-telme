# Telme Goals

This document defines what Telme must achieve.

## Unified observability pipeline

- Ingest all runtime signals through a single pipeline: EventDispatch (global sink), Checkpoint events, and TaskQueue events.
- Normalize into a single canonical form (TelmeRecord) so logs, telemetry, and internal events are handled uniformly.
- One default instance (`Telme.default`); setup once at bootstrap with a Checkpoint for correlation.

## Minimal overhead on hot paths

- Non-blocking ingest: events are enqueued asynchronously onto an internal queue.
- Allocation-light at ingestion time; buffering and flush run on a background queue.
- Timestamp and record id assigned on the ingest queue, not on the caller’s thread.

## Strong typing and bounded memory

- Records are strongly typed (TelmeRecord with EventInfo, AnyEvent, Correlation).
- FlushConfig bounds buffer size (`maxRecordCount`) and flush cadence (`checkInterval`, `flushInterval`).
- No unbounded growth; flush runs when count or interval threshold is reached.

## Clear separation from app logic

- Telme is an observability sink only. App logic does not depend on Telme for correctness.
- Best-effort delivery; no guarantees. Pipeline is resilient to overload and offline scenarios.

## Backend-agnostic export

- Pluggable record sinks via `TelmeRecordSink` and `addRecordSink(_:)`.
- Sinks receive normalized TelmeRecords; they decide formatting, batching, and transport (console, Loki, Grafana, etc.).
- No built-in UI or dashboards; export interface only.

## Failure-tolerant behavior

- Overload: flush and sink invocations do not block producers; drops and backpressure are sink responsibilities.
- No retries or persistence in Telme; buffer is in-memory only. Higher layers may add durability.
