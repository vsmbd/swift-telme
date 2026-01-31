# Telme

Telme is a lightweight observability pipeline that ingests, normalizes, buffers, and exports
runtime signals produced by an application.

Telme treats logging, telemetry, and internal events as the same class of signal:
time-stamped, semi-structured data emitted at specific points in program execution.

It is designed to be:
- non-blocking on hot paths
- allocation-light at ingestion time
- resilient to overload and offline scenarios
- backend-agnostic (console, Grafana, etc.)

Telme is not required for application correctness. It is best-effort by design.

## Dependencies

Telme depends on **SwiftCore** (Checkpoint, TaskQueue, Entity, MonotonicNanostamp) and **EventDispatch**. At bootstrap you pass a **Checkpoint** (entity + call site) so the pipeline is correlated to an origin.

## Position in the stack

Telme sits above SwiftCore and EventDispatch and acts as the single global observability sink.

**Bootstrap:** Call once at app startup:

```swift
Telme.default.setup(.checkpoint(self))
```

`setup(_ checkpoint:flushConfig:)`:
- Registers Telme as the **Checkpoint** event sink (checkpoint created/correlated).
- Registers Telme as the **TaskQueue** event sink (task created/started/completed).
- Sets Telme as the **EventDispatch** global sink (all domain events).

Subsequent calls to `setup` are ignored.

Add record sinks (e.g. console, remote export) before or after setup:

```swift
Telme.default.addRecordSink(ConsoleRecordSink())
```

## Core concepts

### TelmeRecord

All signals are normalized into a canonical form:

- **recordId** – Process-wide sequence id (assigned by Telme at ingest).
- **kind** – String (event type from `Event.kind`, lowercased).
- **timestamp** – MonotonicNanostamp when the record was created (at normalization time).
- **event** – Type-erased event (AnyEvent).
- **eventInfo** – EventInfo (eventId, timestamp, checkpoint, taskInfo, extra).
- **correlation** – eventId, checkpoint, taskId (optional); derived from eventInfo.

Records are created internally by Telme; consumers receive them via `TelmeRecordSink.sink(_:)`.

### Flush and lifecycle

- **Single queue** – One private serial queue for ingest, buffer, and flush. No separate worker queue.
- **Buffering** – Records are appended in memory. Flush runs when either:
  - Buffered count reaches `FlushConfig.maxRecordCount`, or
  - `FlushConfig.flushInterval` has passed since the last flush.
- **FlushConfig** – `maxRecordCount` (default 100), `checkInterval` (default 2s), `flushInterval` (default 5s). Passed to `setup(_:flushConfig:)`.
- **flush()** – Delivers all buffered records to sinks immediately (non-blocking).
- **pauseFlushing()** – Flushes once, then stops scheduling further flush checks. Use from app lifecycle (e.g. `didEnterBackground`).
- **resumeFlushing()** – Resumes scheduling flush checks (e.g. `willEnterForeground`).

### TelmeRecordSink

Implement this protocol to receive normalized records (e.g. print, send to Loki/Grafana). Register with `addRecordSink(_:)`.

## Intended usage

- Structured events from EventDispatch (as global sink)
- Checkpoint and TaskQueue lifecycle events from SwiftCore (as their event sinks)
- Performance telemetry and internal diagnostics

Telme does not implement guaranteed delivery, persistence, or built-in dashboards; it normalizes and buffers in memory and delivers to pluggable sinks.
