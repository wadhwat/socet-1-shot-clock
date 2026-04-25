`timescale 1ns/1ps

module control_fsm #(
    parameter integer N_BUTTONS = 5,
    parameter integer TIMER_WIDTH = 14,
    parameter integer SHOT_TIMER_WIDTH = 10,
    parameter integer SECONDS_PER_MINUTE = 60,
    parameter integer TENTHS_PER_SECOND = 10,
    parameter integer FULL_PERIOD_MINUTES = 15,
    parameter integer SHOT_CLOCK_SECONDS = 30,
    parameter integer INTERMISSION_SECONDS = 75,
    parameter integer HALFTIME_MINUTES = 15,
    parameter integer FINAL_FLASH_TICKS = 50,
    parameter integer FINAL_FLASH_TOGGLE_TICKS = 5
)(
    input  logic clk,
    input  logic n_rst,

    input  logic [1:0] period_state,
    input  logic       shot_clock_expired,
    input  logic       game_clock_expired,
    input  logic       tick_10hz,

    input  logic [N_BUTTONS-1:0] conditioned_buttons,

    output logic        buzzer_trigger,
    output logic        period_increment,
    output logic        possession_increment,

    output logic        shot_clock_en,
    output logic        shot_clock_load,
    output logic [SHOT_TIMER_WIDTH-1:0] shot_clock_load_value,

    output logic        game_clock_en,
    output logic        game_clock_load,
    output logic [TIMER_WIDTH-1:0] game_clock_load_value,

    output logic        final_flash_active,
    output logic        final_flash_show_9999
);

    localparam integer BTN_START_STOP = 0;
    localparam integer BTN_POSSESSION = 1;
    localparam integer BTN_SHOT_RESET = 4;

    localparam logic [1:0] Q1 = 2'd0;
    localparam logic [1:0] Q2 = 2'd1;
    localparam logic [1:0] Q3 = 2'd2;
    localparam logic [1:0] Q4 = 2'd3;

    localparam logic [TIMER_WIDTH-1:0] FULL_PERIOD_TENTHS =
        TIMER_WIDTH'(FULL_PERIOD_MINUTES * SECONDS_PER_MINUTE * TENTHS_PER_SECOND);
    localparam logic [TIMER_WIDTH-1:0] INTERMISSION_TENTHS =
        TIMER_WIDTH'(INTERMISSION_SECONDS * TENTHS_PER_SECOND);
    localparam logic [TIMER_WIDTH-1:0] HALFTIME_TENTHS =
        TIMER_WIDTH'(HALFTIME_MINUTES * SECONDS_PER_MINUTE * TENTHS_PER_SECOND);
    localparam logic [TIMER_WIDTH-1:0] FINAL_FLASH_9999_VALUE = {TIMER_WIDTH{1'b1}};
    localparam logic [SHOT_TIMER_WIDTH-1:0] SHOT_CLOCK_TENTHS =
        SHOT_TIMER_WIDTH'(SHOT_CLOCK_SECONDS * TENTHS_PER_SECOND);

    typedef enum logic [1:0] {
        PHASE_GAME,
        PHASE_INTERMISSION,
        PHASE_HALFTIME,
        PHASE_FINAL_FLASH
    } phase_t;

    phase_t phase;
    logic running;
    logic final_flash_phase;
    logic [$clog2(FINAL_FLASH_TICKS + 1)-1:0] final_flash_ticks_left;
    logic [$clog2(FINAL_FLASH_TOGGLE_TICKS + 1)-1:0] final_flash_toggle_count;

    logic start_stop_pulse;
    logic possession_pulse;
    logic shot_reset_pulse;

    assign start_stop_pulse = conditioned_buttons[BTN_START_STOP];
    assign possession_pulse = conditioned_buttons[BTN_POSSESSION];
    assign shot_reset_pulse = conditioned_buttons[BTN_SHOT_RESET];

    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            phase                    <= PHASE_GAME;
            running                  <= 1'b0;
            final_flash_phase        <= 1'b0;
            final_flash_ticks_left   <= '0;
            final_flash_toggle_count <= '0;
        end else begin
            if (start_stop_pulse && (phase != PHASE_FINAL_FLASH)) begin
                running <= ~running;
            end

            if (game_clock_expired && running) begin
                case (phase)
                    PHASE_GAME: begin
                        case (period_state)
                            Q1, Q3: begin
                                phase   <= PHASE_INTERMISSION;
                                running <= 1'b1;
                            end
                            Q2: begin
                                phase   <= PHASE_HALFTIME;
                                running <= 1'b1;
                            end
                            Q4: begin
                                phase                    <= PHASE_FINAL_FLASH;
                                running                  <= 1'b0;
                                final_flash_phase        <= 1'b1;
                                final_flash_ticks_left   <= FINAL_FLASH_TICKS;
                                final_flash_toggle_count <= FINAL_FLASH_TOGGLE_TICKS;
                            end
                            default: begin
                                phase <= PHASE_GAME;
                            end
                        endcase
                    end
                    PHASE_INTERMISSION,
                    PHASE_HALFTIME: begin
                        phase   <= PHASE_GAME;
                        running <= 1'b1;
                    end
                    default: begin
                        phase <= phase;
                    end
                endcase
            end

            if (phase == PHASE_FINAL_FLASH && tick_10hz && (final_flash_ticks_left != '0)) begin
                final_flash_ticks_left <= final_flash_ticks_left - 1'b1;

                if (final_flash_toggle_count == 1) begin
                        final_flash_toggle_count <= FINAL_FLASH_TOGGLE_TICKS;
                    final_flash_phase        <= ~final_flash_phase;
                end else begin
                    final_flash_toggle_count <= final_flash_toggle_count - 1'b1;
                end
            end
        end
    end

    always_comb begin
        buzzer_trigger          = 1'b0;
        period_increment        = 1'b0;
        possession_increment    = possession_pulse;

        shot_clock_en           = running && (phase == PHASE_GAME);
        shot_clock_load         = shot_reset_pulse || shot_clock_expired;
        shot_clock_load_value   = SHOT_CLOCK_TENTHS;

        game_clock_en           = running && (phase != PHASE_FINAL_FLASH);
        game_clock_load         = 1'b0;
        game_clock_load_value   = FULL_PERIOD_TENTHS;

        final_flash_active      = (phase == PHASE_FINAL_FLASH) && (final_flash_ticks_left != '0);
        final_flash_show_9999   = final_flash_active && final_flash_phase;

        if (game_clock_expired && running) begin
            buzzer_trigger = 1'b1;

            case (phase)
                PHASE_GAME: begin
                    case (period_state)
                        Q1, Q3: begin
                            period_increment      = 1'b1;
                            game_clock_load       = 1'b1;
                            game_clock_load_value = INTERMISSION_TENTHS;
                        end
                        Q2: begin
                            period_increment      = 1'b1;
                            game_clock_load       = 1'b1;
                            game_clock_load_value = HALFTIME_TENTHS;
                        end
                        Q4: begin
                            game_clock_load       = 1'b1;
                            game_clock_load_value = FINAL_FLASH_9999_VALUE;
                        end
                        default: begin
                            game_clock_load       = 1'b1;
                            game_clock_load_value = FULL_PERIOD_TENTHS;
                        end
                    endcase
                end
                PHASE_INTERMISSION,
                PHASE_HALFTIME: begin
                    game_clock_load       = 1'b1;
                    game_clock_load_value = FULL_PERIOD_TENTHS;
                end
                default: begin
                    game_clock_load       = 1'b0;
                    game_clock_load_value = FULL_PERIOD_TENTHS;
                end
            endcase
        end

        if (phase == PHASE_FINAL_FLASH) begin
            game_clock_load = tick_10hz && (final_flash_ticks_left != '0);
            game_clock_load_value = final_flash_phase ? FINAL_FLASH_9999_VALUE : '0;
        end
    end

endmodule
