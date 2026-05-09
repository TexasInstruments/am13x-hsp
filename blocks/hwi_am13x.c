/*
 * hwi_am13x.c
 *
 * Abstract:
 *      TI AM13x hardware interrupt block.
 *      Takes an interrupt handler function name as parameter and
 *      outputs a single function-call signal to a connected subsystem.
 *
 *      Parameters:
 *          HANDLER_NAME   - Name of the ISR function to be generated (string)
 *          PROLOG_CODE    - C code to execute at the start of the ISR, e.g. clear interrupt flag (string)
 *          EPILOG_CODE    - C code to execute at the end of the ISR, e.g. re-enable interrupt (string)
 *
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

#define S_FUNCTION_NAME  hwi_am13x
#define S_FUNCTION_LEVEL 2

#include "simstruc.h"
#include "matrix.h"

/* Logical definitions */
#if (!defined(__cplusplus))
#  ifndef false
#   define false (0U)
#  endif
#  ifndef true
#   define true  (1U)
#  endif
#endif

/*---------------------------------------------------------------------------
 * Parameters
 *   Param 0 : HANDLER_NAME  - ISR function name string, e.g. "Timer0_IRQHandler"
 *   Param 1 : PROLOG_CODE   - Code emitted at start of ISR, e.g. "TimerP_clearOverflowInt(0)"
 *   Param 2 : EPILOG_CODE   - Code emitted at end of ISR, e.g. "TimerP_reEnableInt(0)"
 *-------------------------------------------------------------------------*/
#define NUMPARAMS              3
#define HANDLER_NAME           (ssGetSFcnParam(S, 0))
#define PROLOG_CODE            (ssGetSFcnParam(S, 1))
#define EPILOG_CODE            (ssGetSFcnParam(S, 2))

#ifndef MATLAB_MEX_FILE
/* Since we have a target file for this S-function, declare an error here
 * so that, if for some reason this file is being used (instead of the
 * target file) for code generation, we can trap this problem at compile
 * time. */
#  error This_file_can_be_used_only_during_simulation_inside_Simulink
#endif

/*====================*
 * S-function methods *
 *====================*/

/* -------------------------------------------------------------------------
 * mdlCheckParameters
 * Validates that HANDLER_NAME is a non-empty string.
 * -----------------------------------------------------------------------*/
#define MDL_CHECK_PARAMETERS
static void mdlCheckParameters(SimStruct *S)
{
    /* HANDLER_NAME must not be empty */
    if (mxGetNumberOfElements(HANDLER_NAME) == 0) {
        ssSetErrorStatus(S, "Handler Name must not be empty.");
        return;
    }
}

/* -------------------------------------------------------------------------
 * mdlInitializeSizes
 * -----------------------------------------------------------------------*/
static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumSFcnParams(S, NUMPARAMS);

    if (ssGetNumSFcnParams(S) == ssGetSFcnParamsCount(S)) {
        mdlCheckParameters(S);
        if (ssGetErrorStatus(S) != NULL) {
            return;
        }
    } else {
        return; /* Parameter mismatch will be reported by Simulink */
    }

    /* Parameters are not tunable at runtime */
    ssSetSFcnParamNotTunable(S, 0);
    ssSetSFcnParamNotTunable(S, 1);
    ssSetSFcnParamNotTunable(S, 2);

    /* No input ports - interrupt is triggered by hardware, not a signal */
    ssSetNumInputPorts(S, 0);

    /* One function-call output port */
    ssSetNumOutputPorts(             S, 1);
    ssSetOutputPortWidth(            S, 0, 1);
    ssSetOutputPortDataType(         S, 0, SS_FCN_CALL);

    /* No states or work vectors needed */
    ssSetNumIWork(                   S, 0);
    ssSetNumRWork(                   S, 0);
    ssSetNumPWork(                   S, 0);
    ssSetNumSampleTimes(             S, 1);
    ssSetNumContStates(              S, 0);
    ssSetNumDiscStates(              S, 0);
    ssSetNumModes(                   S, 0);
    ssSetNumNonsampledZCs(           S, 0);

    ssSetOptions(S, (SS_OPTION_EXCEPTION_FREE_CODE              |
                     SS_OPTION_DISALLOW_CONSTANT_SAMPLE_TIME    |
                     SS_OPTION_ASYNCHRONOUS_INTERRUPT));

    ssSetSimStateCompliance(S, HAS_NO_SIM_STATE);
}

/* -------------------------------------------------------------------------
 * mdlInitializeSampleTimes
 * Inherited sample time - block is asynchronously triggered by hardware.
 * -----------------------------------------------------------------------*/
static void mdlInitializeSampleTimes(SimStruct *S)
{
    int_T i;

    ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, FIXED_IN_MINOR_STEP_OFFSET);

    /* Register each output element as a callable system output */
    for (i = 0; i < ssGetOutputPortWidth(S, 0); i++) {
        ssSetCallSystemOutput(S, i);
    }
}

/* -------------------------------------------------------------------------
 * mdlOutputs
 * During simulation, unconditionally fire the function-call output.
 * -----------------------------------------------------------------------*/
static void mdlOutputs(SimStruct *S, int_T tid)
{
    ssCallSystemWithTid(S, 0, tid);
}

/* -------------------------------------------------------------------------
 * mdlTerminate
 * -----------------------------------------------------------------------*/
static void mdlTerminate(SimStruct *S)
{
    /* Nothing to clean up */
}

/* -------------------------------------------------------------------------
 * mdlRTW
 * Write the handler name parameter into the RTW (.rtw) file so the
 * companion TLC file can emit the correct ISR wrapper function.
 *
 * Generated RTW entry:
 *   Parameter {
 *     Name      "HANDLER_NAME"
 *     Value     "Timer0_IRQHandler"
 *   }
 *   Parameter {
 *     Name      "PROLOG_CODE"
 *     Value     "TimerP_clearOverflowInt(0)"
 *   }
 *   Parameter {
 *     Name      "EPILOG_CODE"
 *     Value     ""
 *   }
 * -----------------------------------------------------------------------*/
#define MDL_RTW
static void mdlRTW(SimStruct *S)
{
    char   handlerName[256];
    char   prologCode[1024];
    char   epilogCode[1024];
    mwSize nameLen = 256;
    mwSize codeLen = 1024;

    /* Read the handler name string from the mask parameter */
    if (mxGetString(HANDLER_NAME, handlerName, nameLen) != 0) {
        ssSetErrorStatus(S, "Failed to read Handler Name parameter.");
        return;
    }

    /* Read the prolog code string from the mask parameter */
    if (mxGetString(PROLOG_CODE, prologCode, codeLen) != 0) {
        ssSetErrorStatus(S, "Failed to read Prolog Code parameter.");
        return;
    }

    /* Read the epilog code string from the mask parameter */
    if (mxGetString(EPILOG_CODE, epilogCode, codeLen) != 0) {
        ssSetErrorStatus(S, "Failed to read Epilog Code parameter.");
        return;
    }

    /* Write all three string parameters into the RTW file.
     * The TLC block file (hwi_am13x.tlc) will use them to generate:
     *
     *   void <HANDLER_NAME>(void) {
     *       <PROLOG_CODE>;
     *       <subsystem step function>();
     *       <EPILOG_CODE>;
     *   }
     *
     * and register it with the AM13x VIM (Vector Interrupt Manager). */
    if (!ssWriteRTWParamSettings(S, 3,
                                 SSWRITE_VALUE_STR, "HANDLER_NAME",
                                 handlerName,
                                 SSWRITE_VALUE_STR, "PROLOG_CODE",
                                 prologCode,
                                 SSWRITE_VALUE_STR, "EPILOG_CODE",
                                 epilogCode)) {
        return; /* Error will be reported by Simulink */
    }
}

/*=============================*
 * Required S-function trailer *
 *=============================*/

#ifdef  MATLAB_MEX_FILE
#include "simulink.c"   /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"    /* Code generation registration function */
#endif

/* EOF: hwi_am13x.c */