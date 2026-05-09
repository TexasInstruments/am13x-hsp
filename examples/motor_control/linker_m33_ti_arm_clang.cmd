/*
 * Generic Linker Command File for AM13E230X M33 Core - TI ARM Clang
 *
 * Extends the default linker with RAM function support.
 *
 * To place any function in RAM for faster execution, use:
 *   __attribute__((section(".TI.ramfunc"))) void myFunction(void) { ... }
 *
 * Or define a macro in your header:
 *   #define RAMFUNC __attribute__((section(".TI.ramfunc")))
 *   RAMFUNC void myFunction(void) { ... }
 */

-uinterruptVectors
--stack_size=0x1000
--heap_size=0x1000

MEMORY
{
    /* AM13E23019 */
    RAM_S  : ORIGIN = 0x20000000 , LENGTH = 0x18000    /* 96KB  - S-BUS data RAM  */
    RAM_C  : ORIGIN = 0x00C18000 , LENGTH = 0x8000     /* 32KB  - C-BUS code RAM  */
    FLASH  : ORIGIN = 0x00000000 , LENGTH = 0x80000    /* 512KB - Flash           */

    /* AM13E23018
    RAM_S  : ORIGIN = 0x20000000 , LENGTH = 0x18000
    RAM_C  : ORIGIN = 0x00C18000 , LENGTH = 0x8000
    FLASH  : ORIGIN = 0x00000000 , LENGTH = 0x40000 */

    /* AM13E23017
    RAM_S  : ORIGIN = 0x20000000 , LENGTH = 0x10000
    FLASH  : ORIGIN = 0x00000000 , LENGTH = 0x40000 */
}

SECTIONS
{
    /* Interrupt vector table - must be at address 0 */
    /* __INT_VECS_START used by arch_interrupt.c to set SCB VTOR */
    .intvecs      : > 0, RUN_START(__INT_VECS_START)

    /* Code and read-only data in FLASH */
    .text         : > FLASH, palign(8)
    .cinit        : > FLASH, palign(8)
    .rodata       : > FLASH, palign(8)

    /* Data in RAM_S */
    .data         : > RAM_S
    .bss          : > RAM_S
    .sysmem       : > RAM_S
    .stack        : > RAM_S
    .vtable       : > RAM_S

    /* Boot-time copy table */
    .binit        : > FLASH, palign(8)

    /*
     * Generic RAM Functions Section (.TI.ramfunc)
     *
     * Any function tagged with __attribute__((section(".TI.ramfunc")))
     * is loaded from FLASH at boot and copied to RAM_C for fast execution.
     *
     * Exported symbols for runtime verification and debugging:
     *   __TI_ramfunc_load_start  - load address in FLASH
     *   __TI_ramfunc_load_end    - end of load region in FLASH
     *   __TI_ramfunc_run_start   - run address in RAM_C
     *   __TI_ramfunc_run_end     - end of run region in RAM_C
     *   __TI_ramfunc_size        - total size in bytes
     */
    .TI.ramfunc : load = FLASH, palign(8), run = RAM_C, table(BINIT),
                  LOAD_START(__TI_ramfunc_load_start),
                  LOAD_END(__TI_ramfunc_load_end),
                  RUN_START(__TI_ramfunc_run_start),
                  RUN_END(__TI_ramfunc_run_end),
                  LOAD_SIZE(__TI_ramfunc_size)
}