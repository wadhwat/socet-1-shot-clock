// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary design header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef _VGAME_CLOCK_H_
#define _VGAME_CLOCK_H_  // guard

#include "verilated.h"

//==========

class Vgame_clock__Syms;

//----------

VL_MODULE(Vgame_clock) {
  public:
    
    // PORTS
    // The application code writes and reads these signals to
    // propagate new values into/out from the Verilated model.
    VL_IN8(clk,0,0);
    VL_IN8(nrst,0,0);
    VL_IN8(tick_10hz,0,0);
    VL_IN8(enable,0,0);
    VL_IN8(game_clock_load,0,0);
    VL_OUT8(expired,0,0);
    VL_IN16(game_clock_load_value,13,0);
    VL_OUT16(current_time_value,13,0);
    
    // LOCAL SIGNALS
    // Internals; generally not touched by application code
    SData/*13:0*/ game_clock__DOT__time_left_tenths;
    
    // LOCAL VARIABLES
    // Internals; generally not touched by application code
    CData/*0:0*/ __Vclklast__TOP__clk;
    CData/*0:0*/ __Vclklast__TOP__nrst;
    
    // INTERNAL VARIABLES
    // Internals; generally not touched by application code
    Vgame_clock__Syms* __VlSymsp;  // Symbol table
    
    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Vgame_clock);  ///< Copying not allowed
  public:
    /// Construct the model; called by application code
    /// The special name  may be used to make a wrapper with a
    /// single model invisible with respect to DPI scope names.
    Vgame_clock(const char* name = "TOP");
    /// Destroy the model; called (often implicitly) by application code
    ~Vgame_clock();
    
    // API METHODS
    /// Evaluate the model.  Application must call when inputs change.
    void eval();
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();
    
    // INTERNAL METHODS
  private:
    static void _eval_initial_loop(Vgame_clock__Syms* __restrict vlSymsp);
  public:
    void __Vconfigure(Vgame_clock__Syms* symsp, bool first);
  private:
    static QData _change_request(Vgame_clock__Syms* __restrict vlSymsp);
    void _ctor_var_reset() VL_ATTR_COLD;
  public:
    static void _eval(Vgame_clock__Syms* __restrict vlSymsp);
  private:
#ifdef VL_DEBUG
    void _eval_debug_assertions();
#endif  // VL_DEBUG
  public:
    static void _eval_initial(Vgame_clock__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _eval_settle(Vgame_clock__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _sequent__TOP__1(Vgame_clock__Syms* __restrict vlSymsp);
    static void _settle__TOP__2(Vgame_clock__Syms* __restrict vlSymsp) VL_ATTR_COLD;
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

//----------


#endif  // guard
