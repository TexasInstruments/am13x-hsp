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

#ifndef MW_AM13X_SERIAL_H
#define MW_AM13X_SERIAL_H
#include "ti_sdk_dl_config.h"
#include "Uart_Hal.h"
#include <stddef.h>
#include <stdint.h>

#define LOG_BUFFER_SIZE_MAX 500U
/* Expected RX packet size in bytes (2 x float) */
#define MW_SERIAL_RX_PACKET_SIZE   4U

extern Uart_Hal_InstanceType mw_am13x_serial_UartInstance;

/* =============================================================================
 * Pin and peripheral configuration — UC4 on AM13E230X E2 LaunchPad
 * =============================================================================*/
#define MW_AM13X_SERIAL_UART_INSTANCE       UC4_INST_PTR
#define MW_SERIAL_RX_UC_IRQn                UC4_INT_IRQn
#define MW_SERIAL_RX_UC_IRQ_HANDLER         UC4_IRQHandler
#define MW_AM13X_SERIAL_UART_TX_PINCM       IOMUX_PINCM_PA0
#define MW_AM13X_SERIAL_UART_TX_FUNC        IOMUX_PA0_UC4_TX_SDA_PICO
#define MW_AM13X_SERIAL_UART_RX_PINCM       IOMUX_PINCM_PA1
#define MW_AM13X_SERIAL_UART_RX_FUNC        IOMUX_PA1_UC4_RX_SCL_SCLK

#define MW_AM13X_SERIAL_UART_BAUDRATE_BPS   5000000U    /* 5 Mbps                  */
#define MW_AM13X_SERIAL_UART_INPUT_CLOCK_HZ SEMIMCLK_FREQ_HZ  /* 100 MHz UC4 input clock */

int mw_am13x_serial_Init(void);
int mw_am13x_serial_Send(const uint8_t *data, size_t size);
void mw_am13x_serial_BufferSend(const void *sample, uint32_t item_size, uint32_t buffer_size);

/* -------------------------------------------------------------------------
 * RX API
 *
 * mw_am13x_serial_Init()     — also initialises the RX UART + interrupt
 * mw_am13x_serial_GetRxData() — non-blocking poll, returns true once per
 *                               new packet, clears the ready flag on read
 * -------------------------------------------------------------------------*/
bool mw_am13x_serial_GetRxData(float *outCh0, float *outCh1);
#endif /* MW_AM13X_SERIAL_H */