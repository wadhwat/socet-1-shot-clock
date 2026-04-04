---
name: Implement game clock RTL+TB
overview: Implement `game_clock.sv` as a tenths-of-second countdown timer driven by `tick_10hz`, and add `game_clock_tb.sv` to verify load, run, stop-at-zero, one-cycle `expired` pulse behavior, and randomized loads within the timer’s representable range.
todos:
  - id: define-rtl-interface-and-params
    content: Create `game_clock` module ports/params/constants and internal countdown register.
    status: completed
  - id: implement-countdown-and-expiry
    content: Implement load-priority countdown logic with one-cycle `expired` pulse at terminal transition.
    status: completed
  - id: write-self-checking-testbench
    content: Implement `game_clock_tb` with pulse helpers, deterministic scenarios, and a loop of randomized loads (range tied to timer bit width) verifying `current_time_value` after each load.
    status: in_progress
  - id: run-sim-and-verify
    content: Execute simulation and confirm all test checks pass.
    status: pending
isProject: false
---

# Implement game clock RTL and testbench

## Scope

- Add a new `game_clock` RTL module in [/home/merca/socet-1-shot-clock/sv/src/game_clock.sv](/home/merca/socet-1-shot-clock/sv/src/game_clock.sv).
- Add a self-checking testbench in [/home/merca/socet-1-shot-clock/sv/tb/game_clock_tb.sv](/home/merca/socet-1-shot-clock/sv/tb/game_clock_tb.sv).

## Design decisions

- Use `tick_10hz` as the countdown event (`1 tick = 0.1s`).
- Interpret `game_clock_load_value` in tenths of a second.
- Do not define a hardcoded default start time; only load when `game_clock_load` is asserted.

## RTL implementation plan

- Define parameters for clock representation constants (e.g., `PERIOD_MINUTES`, `SECONDS_PER_MINUTE`, `TENTHS_PER_SECOND`, `FULL_PERIOD_TENTHS`) and width parameter for the timer bus.
- Implement a register for remaining time in tenths (`time_left_tenths`).
- Sequential behavior on `posedge clk` / `negedge nrst`:
  - Reset clears timer and `expired`.
  - `game_clock_load` has priority: load `game_clock_load_value` into timer, clear `expired`.
  - Else clear `expired` by default each cycle, and if `enable && tick_10hz`:
    - If timer > 0, decrement by 1.
    - If timer == 1 before decrement, assert `expired` for exactly one cycle (the cycle after timer reaches 0).
    - If already 0, hold at 0 and keep `expired` low.
- Drive `current_time_value` from internal timer register.

## Testbench plan

- Build a deterministic clock/reset testbench with a short helper task to generate single-cycle `tick_10hz` pulses.
- Instantiate DUT with the same `TIMER_WIDTH` (or equivalent) parameter as RTL so tests and random bounds stay aligned with the implementation.
- Add self-check scenarios with assertions/check tasks:
  - Load test value and verify immediate update of `current_time_value`.
  - **Randomized loads (loop):** Drive `game_clock_load` with `game_clock_load_value` from a random source (e.g. `$urandom_range`) on each iteration. Constrain values to the full unsigned range representable by the timer bus—`**0` through `(2^TIMER_WIDTH)-1`**—so every trial stays within the bit width of `game_clock` (same localparam/`TIMER_WIDTH` as the DUT). After the load takes effect (posedge where load is sampled), **check that `current_time_value` equals the loaded value**, proving different starting times load correctly from the module output.
  - Repeat for a configurable iteration count (e.g. tens or hundreds of trials) to exercise many distinct starting values.
  - Verify no decrement when `enable=0` even if `tick_10hz` pulses.
  - Verify decrement-by-1 on each valid `enable && tick_10hz` pulse.
  - Verify saturation at zero (never underflows).
  - Verify `expired` is high for exactly one cycle on terminal transition and low otherwise.
  - Verify reloading after expiry clears `expired` and resumes normal operation.
- Optionally seed `$urandom` once at test start for reproducible runs (e.g. plusarg or fixed seed).
- Print pass/fail summary and call `$finish`.

## Validation

- Run local simulation with the project’s simulator flow (or direct tool command) and ensure testbench passes with no assertion failures.

