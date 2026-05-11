/**
 * \file  pil_main_am13x.c
 * \brief PIL main entry point for AM13E230X device
 *
 * This file provides the main entry point for Processor-in-the-Loop (PIL)
 * simulation with MATLAB/Simulink on AM13E230X device.
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

#include "xil_interface_lib.h"

/* SDK includes */
#include "device.h"
/* SysConfig generated include */
#include "ti_sdk_dl_config.h"


/* ========================================================================== */
/*                 Device Initialization                                      */
/* ========================================================================== */

/*
 * Initialize AM13E230X device and peripherals
 */

void SYSCFG_DL_FLASH_init(void)
{
    // Disable cache before changing wait states
    DL_FRI_disableDLB();
    DL_FRI_disableCache();

#if defined(MCLK_FREQ_HZ)
    #if   (MCLK_FREQ_HZ == 250000000)
        /* 250MHz - 4 wait states */
        DL_FRI_setReadWaitStates(0x4);

    #elif (MCLK_FREQ_HZ == 200000000)
        /* 200MHz - 3 wait states */
        DL_FRI_setReadWaitStates(0x3);

    #else
        #error "Unsupported MCLK_FREQ_HZ value"
    #endif
#endif

    // Enable cache to improve performance of code executed from flash.
    DL_FRI_enableDLB();
    DL_FRI_enableCache();
}


static void pil_DeviceInit(void)
{
    Device_Init();
    SYSCFG_DL_init(); /* Only clock configured, no UART config done */
}

/* ========================================================================== */
/*                 Main Function                                              */
/* ========================================================================== */

int main(void)
{
    XIL_INTERFACE_LIB_ERROR_CODE errorCode = XIL_INTERFACE_LIB_SUCCESS;
    int errorOccurred = 0;
    /* Avoid warnings about infinite loops */
    volatile int loop = 1;

    /* XIL initialization */
    const int argc = 0;
    void *argv = (void *)0;

    /* Target specific init call */
    pil_DeviceInit();

    errorCode = xilInit(argc, argv);
    errorOccurred = (errorCode != XIL_INTERFACE_LIB_SUCCESS);

    /* Main XIL loop */
    while ((loop != 0) && (errorOccurred == 0))
    {
        errorCode = xilRun();
        if (errorCode != XIL_INTERFACE_LIB_SUCCESS)
        {
            if (errorCode == XIL_INTERFACE_LIB_TERMINATE)
            {
                /* Orderly shutdown of rtiostream */
                errorOccurred = (xilTerminateComms() != XIL_INTERFACE_LIB_SUCCESS);
            }
            else
            {
                errorOccurred = 1;
            }
        }
    }

    /* Trap error with infinite loop */
    if (errorOccurred != 0)
    {
        while (loop != 0)
        {
            /* Error trap */
        }
    }

    return (int)errorCode;
}