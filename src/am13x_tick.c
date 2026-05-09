/********************************************************************
 * Copyright (C) 2025-2026 Texas Instruments Incorporated.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
*/

#ifndef __ASM
#define __ASM __asm
#endif

#ifndef __STATIC_FORCEINLINE
#define __STATIC_FORCEINLINE __attribute__((always_inline)) static inline
#endif

#include <stdint.h>
#include <stdio.h>
#include "rtwtypes.h"
#include "am13x_main.h"
#include "ti_sdk_dl_config.h"


volatile uint32_t schedulerTickDivider = 0;
volatile uint32_t schedulerTickCounter = 0;

extern void rt_OneStep(void);

void SysTick_Handler(void)
{
    // Read volatile variables into local variables to avoid undefined behavior
    // IAR compiler requires this for strict volatile access ordering
    uint32_t counter = schedulerTickCounter;
    uint32_t divider = schedulerTickDivider;

    if (counter >= divider)
    {
        counter = 0;
    }

    if (0 == counter++)
    {
        rt_OneStep();
    }

    // Write back to volatile variable
    schedulerTickCounter = counter;
}

void TickConfig(float modelBaseRate, float systemClock)
{
    // convert frequency from MHz to Hz and multiply with modelBaseRate to get number of ticks
    uint32_t ticks = (uint32_t)(modelBaseRate * MCLK_FREQ_HZ );

    // Check if ticks exceed SysTick reload register limits
    if (ticks > SysTick_LOAD_RELOAD_Msk)
    {
        // Calculate tick divider to handle overflow
        schedulerTickDivider = (ticks + SysTick_LOAD_RELOAD_Msk - 1) / SysTick_LOAD_RELOAD_Msk;

        // Adjust ticks to fit within reload register
        uint32_t adjustedTicks = ticks / schedulerTickDivider;

        SysTick_Config(adjustedTicks);
    }
    else
    {
        // Standard SysTick configuration for simpler base rates
        schedulerTickDivider = 0; // No divider needed
        SysTick_Config(ticks);
    }
    NVIC_SetPriority(SysTick_IRQn, 15U);
}