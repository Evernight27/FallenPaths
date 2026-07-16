class_name YomiConstants
extends RefCounted

## Deception state machine phase labels and behavioral constants.

const DECEPTION_PHASE_ESTABLISH := "Establish"
const DECEPTION_PHASE_PROBE := "Probe"
const DECEPTION_PHASE_EXPLOIT := "Exploit"
const DECEPTION_ESTABLISH_PROB: float = 0.5
const DECEPTION_PROBE_THRESHOLD: int = 3
const DECEPTION_EXPLOIT_BAIT_PROB_MAX: float = 0.5
## Deception resistance boosts on failure/success outcomes (record_deception_outcome).
const DECEPTION_RESISTANCE_ESTABLISH_SUCCESS_BOOST: float = 0.25
const DECEPTION_RESISTANCE_EXPLOIT_FAILURE_BOOST: float = 0.3
const DECEPTION_RESISTANCE_ESTABLISH_FAILURE_BOOST: float = 0.4
