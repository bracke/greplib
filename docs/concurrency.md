# Concurrency

The API includes worker-count, queued-source, and in-flight-source options. Directory search uses the sequential path
when `Worker_Count = 1`. When `Worker_Count > 1`, a traversal producer task walks roots, assigns source sequence
numbers in accepted traversal order, acquires bounded source slots, and feeds a protected bounded source queue. Ada
worker tasks consume that queue and publish events into owned per-source event channels. The caller task drains those
channels, so user callbacks are not invoked by worker tasks.
The bounded source queue is the only way workers receive file work in concurrent directory search. Its capacity is
`Maximum_Queued_Sources`; live source slots are bounded by `Maximum_In_Flight_Sources`.

`Maximum_Queued_Events_Per_Source` bounds each per-source event channel by event count. A channel capacity of one is
valid and creates direct backpressure between a worker and deterministic delivery.
`Maximum_Queued_Event_Bytes_Per_Source` bounds queued event payload bytes. An event larger than that byte limit is
accepted only when its source channel is empty; an event that cannot fit behind already queued events stops that source.
Unexpected worker exceptions are contained at the worker boundary, published as fatal internal diagnostics for the
affected source when possible, and make the directory operation fail rather than being treated as an ordinary source
miss.

`Deterministic` result order drains sources by their traversal-assigned source sequence. `Completion_Order` drains the
next source as workers begin publishing source events, then keeps that source's event stream contiguous until completion
or cancellation. Source sequence assignment remains deterministic in both modes.

This is a bounded-concurrency layer with live traversal-producer/source-queue/worker/channel stages. Traversal enforces
source, path, depth, entry, filter, symlink, cycle, and filesystem-boundary rules before each accepted source is queued
to workers.

String, byte-array, stream, and file search all check an already-requested cancellation token after option validation
and before source events or input reads. Incremental stream search also checks cancellation after successful reads and
between processed bytes. Concurrent directory search combines the caller token with an operation-owned internal
cancellation source; callback `Stop_All_Search` requests that internal source so already-running worker file searches
observe cancellation at their normal checkpoints. A blocking Ada stream read or filesystem open can still delay
cancellation observation.
External cancellation during concurrent directory delivery cancels the traversal producer, source queue, free-slot
waiters, slot state, and per-source channels. Deterministic delivery only waits for source slots after traversal has
handed them to the worker queue, so it does not block on a source that was accepted but not actually queued.
