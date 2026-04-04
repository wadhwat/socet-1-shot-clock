// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vgame_clock.h for the primary calling header

#include "Vgame_clock.h"
#include "Vgame_clock__Syms.h"

//==========

VL_CTOR_IMP(Vgame_clock) {
    Vgame_clock__Syms* __restrict vlSymsp = __VlSymsp = new Vgame_clock__Syms(this, name());
    Vgame_clock* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Reset internal values
    
    // Reset structure values
    _ctor_var_reset();
}

void Vgame_clock::__Vconfigure(Vgame_clock__Syms* vlSymsp, bool first) {
    if (0 && first) {}  // Prevent unused
    this->__VlSymsp = vlSymsp;
}

Vgame_clock::~Vgame_clock() {
    delete __VlSymsp; __VlSymsp=NULL;
}

void Vgame_clock::eval() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vgame_clock::eval\n"); );
    Vgame_clock__Syms* __restrict vlSymsp = this->__VlSymsp;  // Setup global symbol table
    Vgame_clock* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
#ifdef VL_DEBUG
    // Debug assertions
    _eval_debug_assertions();
#endif  // VL_DEBUG
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Clock loop\n"););
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("../sv/src/game_clock.sv", 5, "",
                "Verilated model didn't converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

void Vgame_clock::_eval_initial_loop(Vgame_clock__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    _eval_initial(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        _eval_settle(vlSymsp);
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("../sv/src/game_clock.sv", 5, "",
                "Verilated model didn't DC converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

VL_INLINE_OPT void Vgame_clock::_sequent__TOP__1(Vgame_clock__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vgame_clock::_sequent__TOP__1\n"); );
    Vgame_clock* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    SData/*13:0*/ __Vdly__game_clock__DOT__time_left_tenths;
    // Body
    __Vdly__game_clock__DOT__time_left_tenths = vlTOPp->game_clock__DOT__time_left_tenths;
    if (vlTOPp->nrst) {
        if (vlTOPp->game_clock_load) {
            __Vdly__game_clock__DOT__time_left_tenths 
                = vlTOPp->game_clock_load_value;
            vlTOPp->expired = 0U;
        } else {
            vlTOPp->expired = (((IData)(vlTOPp->enable) 
                                & (IData)(vlTOPp->tick_10hz)) 
                               & (1U == (IData)(vlTOPp->game_clock__DOT__time_left_tenths)));
            if ((((IData)(vlTOPp->enable) & (IData)(vlTOPp->tick_10hz)) 
                 & (0U != (IData)(vlTOPp->game_clock__DOT__time_left_tenths)))) {
                __Vdly__game_clock__DOT__time_left_tenths 
                    = (0x3fffU & ((IData)(vlTOPp->game_clock__DOT__time_left_tenths) 
                                  - (IData)(1U)));
            }
        }
    } else {
        __Vdly__game_clock__DOT__time_left_tenths = 0U;
        vlTOPp->expired = 0U;
    }
    vlTOPp->game_clock__DOT__time_left_tenths = __Vdly__game_clock__DOT__time_left_tenths;
    vlTOPp->current_time_value = vlTOPp->game_clock__DOT__time_left_tenths;
}

void Vgame_clock::_settle__TOP__2(Vgame_clock__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vgame_clock::_settle__TOP__2\n"); );
    Vgame_clock* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->current_time_value = vlTOPp->game_clock__DOT__time_left_tenths;
}

void Vgame_clock::_eval(Vgame_clock__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vgame_clock::_eval\n"); );
    Vgame_clock* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    if ((((IData)(vlTOPp->clk) & (~ (IData)(vlTOPp->__Vclklast__TOP__clk))) 
         | ((~ (IData)(vlTOPp->nrst)) & (IData)(vlTOPp->__Vclklast__TOP__nrst)))) {
        vlTOPp->_sequent__TOP__1(vlSymsp);
    }
    // Final
    vlTOPp->__Vclklast__TOP__clk = vlTOPp->clk;
    vlTOPp->__Vclklast__TOP__nrst = vlTOPp->nrst;
}

void Vgame_clock::_eval_initial(Vgame_clock__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vgame_clock::_eval_initial\n"); );
    Vgame_clock* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->__Vclklast__TOP__clk = vlTOPp->clk;
    vlTOPp->__Vclklast__TOP__nrst = vlTOPp->nrst;
}

void Vgame_clock::final() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vgame_clock::final\n"); );
    // Variables
    Vgame_clock__Syms* __restrict vlSymsp = this->__VlSymsp;
    Vgame_clock* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vgame_clock::_eval_settle(Vgame_clock__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vgame_clock::_eval_settle\n"); );
    Vgame_clock* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_settle__TOP__2(vlSymsp);
}

VL_INLINE_OPT QData Vgame_clock::_change_request(Vgame_clock__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vgame_clock::_change_request\n"); );
    Vgame_clock* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    // Change detection
    QData __req = false;  // Logically a bool
    return __req;
}

#ifdef VL_DEBUG
void Vgame_clock::_eval_debug_assertions() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vgame_clock::_eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((nrst & 0xfeU))) {
        Verilated::overWidthError("nrst");}
    if (VL_UNLIKELY((tick_10hz & 0xfeU))) {
        Verilated::overWidthError("tick_10hz");}
    if (VL_UNLIKELY((enable & 0xfeU))) {
        Verilated::overWidthError("enable");}
    if (VL_UNLIKELY((game_clock_load & 0xfeU))) {
        Verilated::overWidthError("game_clock_load");}
    if (VL_UNLIKELY((game_clock_load_value & 0xc000U))) {
        Verilated::overWidthError("game_clock_load_value");}
}
#endif  // VL_DEBUG

void Vgame_clock::_ctor_var_reset() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vgame_clock::_ctor_var_reset\n"); );
    // Body
    clk = VL_RAND_RESET_I(1);
    nrst = VL_RAND_RESET_I(1);
    tick_10hz = VL_RAND_RESET_I(1);
    enable = VL_RAND_RESET_I(1);
    game_clock_load = VL_RAND_RESET_I(1);
    game_clock_load_value = VL_RAND_RESET_I(14);
    current_time_value = VL_RAND_RESET_I(14);
    expired = VL_RAND_RESET_I(1);
    game_clock__DOT__time_left_tenths = VL_RAND_RESET_I(14);
}
