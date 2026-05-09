/**
 * @file xcp_platform_custom.h
 * @brief Platform-specific customizations for XCP protocol implementation
 *
 * This header defines platform-specific macros and functions for the XCP protocol
 * implementation on TI AM13E2x MCUs. It includes mutex handling, memory alignment,
 * packing pragmas, and timestamp functionality when external mode is enabled.
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

#ifndef XCP_PLATFORM_CUSTOM_H
#define XCP_PLATFORM_CUSTOM_H

#include <stdio.h>
#include <string.h>
#include <stdint.h>

/* SDK includes */
#include "arch_interrupt.h"
#include "arch_counter.h"
#include "xcp_cfg.h"  /* If this file exists */

#if defined(EXT_MODE) && (EXT_MODE == 1)
// Add missing defines
//#define XCP_PRINTF  printf  // or implement mw_printf

/* Add XCP_PRINTF */
#define XCP_PRINTF(...)

#ifdef XCP_MAX_CTO_SIZE
#undef XCP_MAX_CTO_SIZE
#define XCP_MAX_CTO_SIZE  0x08
#else
#define XCP_MAX_CTO_SIZE 0x08
#endif

#define XCP_MEM_BLOCK_1_SIZE        64
#define XCP_MEM_BLOCK_1_NUMBER      50
#define XCP_MEM_BLOCK_2_SIZE        256
#define XCP_MEM_BLOCK_2_NUMBER      50
#define XCP_MEM_BLOCK_3_SIZE        1024
#define XCP_MEM_BLOCK_3_NUMBER      10

/* ========================================================================== */
/*                 Mutex Macros                                               */
/* ========================================================================== */

#define XCP_MUTEX_DEFINE(lock)    uint32_t lock
#define XCP_MUTEX_INIT(lock)      lock = 0U
#define XCP_MUTEX_LOCK(lock)      lock = Arch_Interrupt_DisableAll()
#define XCP_MUTEX_UNLOCK(lock)    Arch_Interrupt_RestoreAll(lock)

/* ========================================================================== */
/*                 Packing/Alignment Macros                                   */
/* ========================================================================== */

#define PRAGMA(n)                _Pragma(#n)
#define XCP_PRAGMA_PACK_BEGIN(n) PRAGMA(pack(push, n))
#define XCP_PRAGMA_PACK_END()    PRAGMA(pack(pop))
#define XCP_ATTRIBUTE_ALIGNED(n)
#define XCP_ATTRIBUTE_PACKED

/* ========================================================================== */
/*                 Address Handling                                           */
/* ========================================================================== */

#define XCP_ADDRESS_GET(addressExtension, address)  (uint8_t*) ((uintptr_t) address)

/* ========================================================================== */
/*                 Sleep/Delay                                                */
/* ========================================================================== */

void XCP_Platform_Sleep(uint32_t s, uint32_t us);
#define XCP_SLEEP(s, us) XCP_Platform_Sleep((s), (us))

/* ========================================================================== */
/*                 Memory Alignment                                           */
/* ========================================================================== */

#define XCP_MEM_ALIGNMENT 4

/* ========================================================================== */
/*                 Timestamp                                                  */
/* ========================================================================== */

#ifndef XCP_TIMESTAMP_BASED_ON_SIMULATION_TIME
uint32_t XCP_Platform_GetTimestamp(void);
#define XCP_TIMESTAMP_GET()  XCP_Platform_GetTimestamp()
#define XCP_TIMESTAMP_UNIT   XCP_TIMESTAMP_UNIT_1US
#endif

#endif /* EXT_MODE */

/* ========================================================================== */
/*                 Profiling Timer                                            */
/* ========================================================================== */

uint32_t XCP_Platform_GetTimestampInMicros(void);
#define profileTimerRead() (XCP_Platform_GetTimestampInMicros())

#endif /* XCP_PLATFORM_CUSTOM_H */