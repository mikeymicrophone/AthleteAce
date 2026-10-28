# Decision-model smoke results, October 14, 2026

The first live run used the eight examples in `spec/fixtures/decision_cases.json`, with keys from Doppler's `athleteace/dev` config. Each provider completed eight calls. No evaluation changed content or sports records.

| Provider | Model | Smoke labels matched | Reported input tokens | Estimated USD total | Median request time |
| --- | --- | ---: | ---: | ---: | ---: |
| Jev | jev-1.13.0 | 8 of 8 | 3,502 | $0.000147084 | 215 ms |
| OpenAI | gpt-6-luna | 7 of 8 | 1,786 | $0.000178600 | 277 ms |

The combined estimated token cost was $0.000325684. The estimates use reported usage and the stored input-token rates. They are not invoice reconciliation. The providers billed different input-token counts for equivalent application questions.

Luna chose `review` for the benign "Clutch" spectrum example, whose smoke label is `allow`. Both providers matched the remaining examples. Both selected `insufficient_evidence` for the same-name player and conflicting-team cases. The number-change example returned `7` from both.

The command exited nonzero because of the label difference, despite all calls completing. This is the intended signal to inspect disagreements. The dataset is too small to establish production accuracy or publishing thresholds. Automatic clearance remains disabled.

These are client-observed request times from one sequential run. The first Luna request took 1,183 ms. These timings do not establish sustained throughput or production latency.

See [the comparison procedure](moderation-operations.md#run-the-smoke-comparison) to repeat the run. Repeating it makes new paid calls and retains earlier evaluation records.
