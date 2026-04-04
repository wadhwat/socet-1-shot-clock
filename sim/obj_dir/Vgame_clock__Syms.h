// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef _VGAME_CLOCK__SYMS_H_
#define _VGAME_CLOCK__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODULE CLASSES
#include "Vgame_clock.h"

// SYMS CLASS
class Vgame_clock__Syms : public VerilatedSyms {
  public:
    
    // LOCAL STATE
    const char* __Vm_namep;
    bool __Vm_didInit;
    
    // SUBCELL STATE
    Vgame_clock*                   TOPp;
    
    // CREATORS
    Vgame_clock__Syms(Vgame_clock* topp, const char* namep);
    ~Vgame_clock__Syms() {}
    
    // METHODS
    inline const char* name() { return __Vm_namep; }
    
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

#endif  // guard
