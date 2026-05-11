/**
 * @file xcp_platform_custom.c
 * @brief Platform-specific implementation for XCP protocol on TI AM13E2x MCUs
 */

 /********************************************************************
 * Copyright (C) 2026 Texas Instruments Incorporated.
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

#include "ti_sdk_dl_config.h"  /* Should define MCLK_FREQ_HZ */
#include "xcp_platform_custom.h"
#include "arch_counter.h"

/* ========================================================================== */
/*                 Private Definitions                                        */
/* ========================================================================== */

/* MCLK_FREQ_HZ should be defined externally (e.g., via compiler flag or ti_sdk_dl_config.h) */
#ifndef MCLK_FREQ_HZ
#error "MCLK_FREQ_HZ must be defined"
#endif

/** @brief CPU cycles per microsecond */
#define XCP_PLATFORM_CYCLES_PER_US (MCLK_FREQ_HZ / 1000000U)

/* ========================================================================== */
/*                 Public Functions                                           */
/* ========================================================================== */

#if defined(EXT_MODE) && (EXT_MODE == 1)

void XCP_Platform_Sleep(uint32_t s, uint32_t us)
{
    uint32_t totalUs = (s * 1000000U) + us;
    uint32_t startCycles = Arch_Counter_Read32();
    uint32_t delayCycles = totalUs * XCP_PLATFORM_CYCLES_PER_US;
    uint32_t currentCycles;
    uint32_t elapsedCycles;

    do
    {
        currentCycles = Arch_Counter_Read32();
        elapsedCycles = Arch_Counter_CalcDiff32(startCycles, currentCycles);
    } while (elapsedCycles < delayCycles);


}

uint32_t XCP_Platform_GetTimestamp(void)
{
    return Arch_Counter_Read32() / XCP_PLATFORM_CYCLES_PER_US;
}

#endif /* EXT_MODE */

uint32_t XCP_Platform_GetTimestampInMicros(void)
{
    return Arch_Counter_Read32() / XCP_PLATFORM_CYCLES_PER_US;
}