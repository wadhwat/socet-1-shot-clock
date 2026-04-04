// Verilator C++ testbench for game_clock (matches sv/tb/game_clock_tb.sv scenarios).

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <random>

#include "verilated.h"
#include "Vgame_clock.h"

static constexpr int TIMER_WIDTH = 14;
static constexpr int PERIOD_MINUTES = 12;
static constexpr int SECONDS_PER_MINUTE = 60;
static constexpr int TENTHS_PER_SECOND = 10;
static constexpr int FULL_PERIOD_TENTHS =
    PERIOD_MINUTES * SECONDS_PER_MINUTE * TENTHS_PER_SECOND;
static constexpr uint32_t MAX_TENTHS = (1u << TIMER_WIDTH) - 1u;
static constexpr long long RANDOM_LOAD_ITERATIONS = 25600;
static constexpr uint32_t RANDOM_SEED = 0xACE10242u;

static int err_count = 0;

static void check_eq(const char* what, uint32_t got, uint32_t exp) {
    if (got != exp) {
        std::fprintf(stderr, "FAIL %s: got %u expected %u\n", what, got, exp);
        err_count++;
    }
}

static void clock_cycle(Vgame_clock* top) {
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
}

static void pulse_tick_10hz(Vgame_clock* top) {
    clock_cycle(top);
    top->tick_10hz = 1;
    clock_cycle(top);
    top->tick_10hz = 0;
}

static void apply_reset(Vgame_clock* top) {
    top->nrst = 0;
    top->tick_10hz = 0;
    top->enable = 0;
    top->game_clock_load = 0;
    top->game_clock_load_value = 0;
    for (int i = 0; i < 5; i++) clock_cycle(top);
    top->nrst = 1;
    clock_cycle(top);
}

static void load_timer(Vgame_clock* top, uint32_t v) {
    clock_cycle(top);
    top->game_clock_load = 1;
    top->game_clock_load_value = v & MAX_TENTHS;
    clock_cycle(top);
    top->game_clock_load = 0;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vgame_clock* top = new Vgame_clock;

    std::mt19937 rng{RANDOM_SEED};
    std::uniform_int_distribution<uint32_t> dist{0u, MAX_TENTHS};

    apply_reset(top);
    check_eq("after reset current_time", top->current_time_value, 0u);
    if (top->expired) {
        std::fprintf(stderr, "FAIL after reset expired\n");
        err_count++;
    }

    load_timer(top, static_cast<uint32_t>(12 * 60 * 10));
    check_eq("load 1200", top->current_time_value, 7200u);

    for (int n = 0; n < RANDOM_LOAD_ITERATIONS; n++) {
        uint32_t rv = dist(rng);
        char buf[64];
        std::snprintf(buf, sizeof(buf), "random load iter %d", n);
        load_timer(top, rv);
        check_eq(buf, top->current_time_value, rv);
    }

    load_timer(top, 10u);
    top->enable = 0;
    for (int i = 0; i < 3; i++) pulse_tick_10hz(top);
    check_eq("hold with enable=0", top->current_time_value, 10u);
    top->enable = 1;

    load_timer(top, 3u);
    top->enable = 1;
    pulse_tick_10hz(top);
    check_eq("dec 3->2", top->current_time_value, 2u);
    pulse_tick_10hz(top);
    check_eq("dec 2->1", top->current_time_value, 1u);
    pulse_tick_10hz(top);
    check_eq("dec 1->0", top->current_time_value, 0u);

    load_timer(top, 1u);
    top->enable = 1;
    clock_cycle(top);
    if (top->expired) {
        std::fprintf(stderr, "FAIL expired before terminal tick\n");
        err_count++;
    }
    pulse_tick_10hz(top);
    if (!top->expired) {
        std::fprintf(stderr, "FAIL expired not high after terminal tick\n");
        err_count++;
    }
    check_eq("time 0 after terminal", top->current_time_value, 0u);
    clock_cycle(top);
    if (top->expired) {
        std::fprintf(stderr, "FAIL expired not cleared next cycle\n");
        err_count++;
    }

    for (int i = 0; i < 4; i++) pulse_tick_10hz(top);
    check_eq("saturate at 0", top->current_time_value, 0u);

    load_timer(top, 2u);
    check_eq("reload after 0", top->current_time_value, 2u);
    pulse_tick_10hz(top);
    pulse_tick_10hz(top);
    if (!top->expired) {
        std::fprintf(stderr, "FAIL expired after reload countdown\n");
        err_count++;
    }
    check_eq("countdown to 0", top->current_time_value, 0u);
    clock_cycle(top);
    if (top->expired) {
        std::fprintf(stderr, "FAIL expired should clear next cycle after reload path\n");
        err_count++;
    }
    load_timer(top, static_cast<uint32_t>(FULL_PERIOD_TENTHS));
    check_eq("full period load", top->current_time_value,
             static_cast<uint32_t>(FULL_PERIOD_TENTHS));
    if (top->expired) {
        std::fprintf(stderr, "FAIL expired cleared on load\n");
        err_count++;
    }

    top->final();
    delete top;

    if (err_count == 0) {
        std::printf("PASS game_clock Verilator TB (%d random loads)\n", RANDOM_LOAD_ITERATIONS);
        return 0;
    }
    std::printf("FAIL game_clock_tb errors=%d\n", err_count);
    return 1;
}
