/* =============================================================================
 * am13x_serial_util.c
 *
 * UART serial communication utility for AM13x (UC4 / UART4).
 *
 * Hardware:
 *   MCU      : TI AM13E230X (Cortex-M33)
 *   UART Inst: UC4  — PA0 (TX), PA1 (RX)
 *   Baud rate: 5 Mbps
 *   Protocol : Fixed-length packets
 *              TX: 1 x uint16_t (2 bytes) per mw_am13x_serial_Send() call
 *                  Called up to 3 times per ADC ISR tick by Simulink
 *                  generated while-iterator loop. Framed as:
 *                    Start frame : 0x5353 header + 2 data words
 *                    Data frame  : 2 data words only
 *                    End frame   : 2 data words + 0x4545 trailer
 *              RX: 2 x uint16_t (4 bytes) — speed reference + control word from host
 *
 * RX packet layout (host → target, 4 bytes):
 *   Bytes [0:1] — uint16_t raw0 : speed reference (signed int16 raw count)
 *   Bytes [2:3] — uint16_t raw1 : control word
 *                   bit[0]      : Start flag
 *                   bits[7:4]   : Debug_signals selector (upper nibble)
 *
 * TX packet layout (target → host):
 *   Sent directly by Simulink generated code via mw_am13x_serial_Send()
 *   3 x uint16_t per ISR tick, framed with 0x5353 header / 0x4545 trailer
 *
 * Interrupt:
 *   UC4_IRQHandler (MW_SERIAL_RX_UC_IRQ_HANDLER) is defined in the
 *   Simulink generated file. This file provides:
 *     - mw_am13x_serial_Init()         hardware init + NVIC enable
 *     - mw_am13x_serial_GetRxData()    read last decoded RX values
 *     - Uart_Hal_RxCompleteCallback()  HAL callback — decode + re-arm
 *     - mw_am13x_serial_Send()         TX polling (called from ADC ISR)
 *     - mw_am13x_serial_BufferSend()   buffered TX with sync header
 * =============================================================================
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

#include "Uart_Hal.h"
#include "dl_gpio.h"
#include "mw_am13x_serial.h"
#include "arch_interrupt.h"
#include "dl_unicommuart.h"
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>



/* =============================================================================
 * UART HAL instance — declared extern in mw_am13x_serial.h so the
 * Simulink generated IRQ handler can reference it directly.
 * =============================================================================*/
Uart_Hal_InstanceType mw_am13x_serial_UartInstance = {0};

/* =============================================================================
 * TX buffered send state
 * =============================================================================*/
#define LOG_BUFFER_BYTE_SIZE   (LOG_BUFFER_SIZE_MAX * sizeof(float))

static uint8_t  log_buffer[LOG_BUFFER_BYTE_SIZE];  /* circular TX burst buffer  */
static uint32_t log_index     = 0U;                /* write index into buffer   */
static uint32_t log_item_size = 0U;                /* item size of current data */

/* =============================================================================
 * RX state — written in interrupt context, read by application
 * mw_rxCh0 : last decoded speed reference (raw int16 count as float)
 * mw_rxCh1 : last decoded control word    (raw uint16 as float)
 * =============================================================================*/
static uint8_t         mw_rxHalBuf[MW_SERIAL_RX_PACKET_SIZE]; /* DMA-style HAL buffer */
static volatile float  mw_rxCh0       = 0.0f;
static volatile float  mw_rxCh1       = 0.0f;
static volatile bool   mw_rxDataReady = false;

/* =============================================================================
 * Private helpers
 * =============================================================================*/

/**
 * mw_rxRearm — re-arm the HAL for the next fixed-size RX packet.
 *
 * Must be called after every completed or discarded transfer to keep
 * the receiver live. Uart_Hal_RxInterrupt re-enables LTOUT internally
 * so we disable it immediately — we use fixed packet sizes and LTOUT
 * only causes spurious zero-byte callbacks when the line is idle.
 */
static void mw_rxRearm(void)
{
    (void)Uart_Hal_RxInterrupt(&mw_am13x_serial_UartInstance,
                               mw_rxHalBuf,
                               MW_SERIAL_RX_PACKET_SIZE);

    /* Suppress LTOUT — re-enabled by Uart_Hal_RxInterrupt, not needed */
    DL_UART_disableInterrupt(MW_AM13X_SERIAL_UART_INSTANCE,
                             DL_UART_INTERRUPT_LTOUT);
}

/* =============================================================================
 * Public API — Initialisation
 * =============================================================================*/

/**
 * mw_am13x_serial_Init — initialise UC4 UART and arm the first RX transfer.
 *
 * Call once during system initialisation before enabling the ADC ISR.
 * The RX interrupt (UC4_INT_IRQn) is enabled here at priority 14
 * (second lowest on Cortex-M33) so the ADC FOC ISR at priority 8
 * always preempts serial RX — motor control is never delayed by comms.
 *
 * Returns  0  on success
 *         -1  if Uart_Hal_Init fails
 */
int mw_am13x_serial_Init(void)
{
    Uart_Hal_InitParamsType params;

    /* Disable and clear any pending UC4 interrupt before configuring */
    Arch_Interrupt_Disable(MW_SERIAL_RX_UC_IRQn);
    Arch_Interrupt_Clear(MW_SERIAL_RX_UC_IRQn);

    /* Configure TX and RX pins for UC4 peripheral function */
    DL_GPIO_initPeripheralOutputFunction(MW_AM13X_SERIAL_UART_TX_PINCM,
                                         MW_AM13X_SERIAL_UART_TX_FUNC);
    DL_GPIO_initPeripheralInputFunction(MW_AM13X_SERIAL_UART_RX_PINCM,
                                        MW_AM13X_SERIAL_UART_RX_FUNC);

    /* Initialise HAL with baud rate and clock parameters */
    Uart_Hal_InitParamsSetDefault(&params);
    params.HwRegsPtr    = MW_AM13X_SERIAL_UART_INSTANCE;
    params.BaudRateBps  = MW_AM13X_SERIAL_UART_BAUDRATE_BPS;
    params.InputClockHz = MW_AM13X_SERIAL_UART_INPUT_CLOCK_HZ;

    sint32 status = Uart_Hal_Init(&mw_am13x_serial_UartInstance, &params);
    if (status != UART_HAL_ERROR_NONE) { return -1; }

    /* Disable LTOUT — not needed for fixed-size packets */
    DL_UART_disableInterrupt(MW_AM13X_SERIAL_UART_INSTANCE,
                             DL_UART_INTERRUPT_LTOUT);

    /* Clear RX state */
    mw_rxCh0       = 0.0f;
    mw_rxCh1       = 0.0f;
    mw_rxDataReady = false;

    /* Priority 14 = second lowest on M33 (0 = highest, 15 = lowest).
     * ADC FOC ISR runs at priority 0 — always preempts serial RX. */
    Arch_Interrupt_SetPriority(MW_SERIAL_RX_UC_IRQn, 14U);
    Arch_Interrupt_Enable(MW_SERIAL_RX_UC_IRQn);

    /* Arm first RX transfer */
    mw_rxRearm();

    return 0;
}

/* =============================================================================
 * Public API — TX (polled)
 * =============================================================================*/

/**
 * mw_am13x_serial_Send — blocking polled transmit.
 *
 * Called from inside MTR1_FOC_INT1_Handler (ADC ISR) by Simulink
 * generated while-iterator code. Sends exactly 2 bytes (1 x uint16_t)
 * per call. Called up to 3 times per ISR tick depending on frame type
 * (Start / Data / End). Total blocking time per ISR tick:
 *   3 calls × 2 bytes × (1 / 5 Mbps) ≈ 9.6 µs worst case.
 *
 * The RX interrupt (UC4_INT) runs at priority 14 — lower than the
 * ADC ISR at priority 0 — so RX cannot preempt during TX polling.
 * This is intentional: motor control timing is never disturbed by comms.
 *
 * Returns  0  on success
 *         -1  on error or null/empty input
 */
int mw_am13x_serial_Send(const uint8_t *data, size_t size)
{
    Uart_Hal_TxStatusType txStatus = {0};

    if ((data == NULL) || (size == 0U)) { return -1; }

    if (Uart_Hal_TxPolling(&mw_am13x_serial_UartInstance,
                           (uint8_t *)data, size) != UART_HAL_ERROR_NONE)
    {
        return -1;
    }

    while (txStatus.IsTxComplete == false)
    {
        if (Uart_Hal_TxContinuePolling(&mw_am13x_serial_UartInstance,
                                       &txStatus) != UART_HAL_ERROR_NONE)
        {
            return -1;
        }
        if (txStatus.ErrorCodeMask != 0U) { return -1; }
    }

    return 0;
}

/**
 * mw_am13x_serial_BufferSend — accumulate samples then burst-send with sync header.
 *
 * Collects item_size bytes per call into an internal buffer. When
 * buffer_size items have accumulated, sends a 4-byte sync header
 * 'SSSS' (0x53535353) followed by the full buffer in one burst.
 *
 * This amortises UART overhead — instead of sending 2 bytes every
 * 500 µs (2 kHz), a burst of buffer_size*item_size bytes is sent
 * every (buffer_size * 500 µs) e.g. 100 items = 50 ms bursts.
 *
 * Parameters:
 *   sample      pointer to item_size bytes to append
 *   item_size   size of one sample in bytes (e.g. sizeof(float) = 4)
 *   buffer_size number of samples before a burst is sent
 */
void mw_am13x_serial_BufferSend(const void   *sample,
                                 uint32_t      item_size,
                                 uint32_t      buffer_size)
{
    uint32_t byte_capacity = LOG_BUFFER_SIZE_MAX * (uint32_t)sizeof(float);

    /* Reset index if item size changes (e.g. data type switch) */
    if (log_item_size != item_size)
    {
        log_index     = 0U;
        log_item_size = item_size;
    }

    /* Guard: do not write past buffer end */
    if (((log_index + 1U) * item_size) > byte_capacity) { return; }

    /* Append sample to buffer */
    memcpy(&log_buffer[log_index * item_size], sample, item_size);
    log_index++;

    /* When full, send sync header then burst the buffer */
    if (log_index >= buffer_size)
    {
        static const uint8_t header[4] = {0x53U, 0x53U, 0x53U, 0x53U}; /* 'SSSS' */
        mw_am13x_serial_Send(header, sizeof(header));
        mw_am13x_serial_Send(log_buffer, buffer_size * item_size);
        log_index = 0U;
    }
}

/* =============================================================================
 * Public API — RX
 * =============================================================================*/

/**
 * mw_am13x_serial_GetRxData — copy last decoded RX packet to caller buffers.
 *
 * Always writes the last received values regardless of mw_rxDataReady.
 * This ensures the Simulink generated IRQ handler always gets valid
 * (last-known-good) values even if no new packet has arrived.
 *
 * The ready flag is cleared so the caller can detect staleness if needed.
 *
 * Parameters:
 *   outCh0   receives mw_rxCh0 — speed ref raw count as float
 *   outCh1   receives mw_rxCh1 — control word as float
 *
 * Returns true always (last-known-good semantics).
 */
bool mw_am13x_serial_GetRxData(float *outCh0, float *outCh1)
{
    if ((outCh0 != NULL) && (outCh1 != NULL))
    {
        *outCh0 = mw_rxCh0;
        *outCh1 = mw_rxCh1;
    }

    mw_rxDataReady = false;
    return true;
}

/* =============================================================================
 * HAL Callbacks — called by Uart_Hal_InterruptHandler inside the IRQ handler
 * =============================================================================*/

/**
 * Uart_Hal_RxCompleteCallback — decode received packet and re-arm for next.
 *
 * Called synchronously from Uart_Hal_InterruptHandler() which is itself
 * called at the top of MW_SERIAL_RX_UC_IRQ_HANDLER (defined in the
 * Simulink generated .c file).
 *
 * Packet decode:
 *   raw0 (int16_t cast) → mw_rxCh0 : speed reference raw count
 *   raw1 (uint16_t)     → mw_rxCh1 : control word
 *     The Simulink generated code then applies its own scaling:
 *       speedRef = (float)(int16_t)HALRx_o1 * 0.000244140625f * 4107.0f
 *       Debug_signals = (HALRx_o2 & 0xF0) >> 4
 *       Start = HALRx_o2 & 0x01
 *
 * On partial packet (LTOUT mid-transfer): drain FIFO and discard.
 * On zero bytes (idle timeout with LTOUT somehow re-enabled): ignore.
 * Always re-arms after any callback to keep the receiver live.
 */
void Uart_Hal_RxCompleteCallback(Uart_Hal_InstanceType *instancePtr,
                                 Uart_Hal_RxStatusType *statusPtr,
                                 void *userArgsPtr)
{
    uint32_t receivedBytes;
    uint16_t raw0, raw1;

    (void)userArgsPtr;

    if (instancePtr != &mw_am13x_serial_UartInstance)
    {
        return;
    }

    receivedBytes = statusPtr->SizeInBytes - statusPtr->RemainingSizeInBytes;

    if (receivedBytes == MW_SERIAL_RX_PACKET_SIZE)
    {
        /* Full valid packet — unpack 2 x uint16_t */
        memcpy(&raw0, &statusPtr->BufferPtr[0], sizeof(uint16_t));
        memcpy(&raw1, &statusPtr->BufferPtr[2], sizeof(uint16_t));

        /* Store as float — Simulink generated code applies scaling */
        mw_rxCh0       = (float)(int16_t)raw0;  /* signed: handles negative speed ref */
        mw_rxCh1       = (float)raw1;            /* unsigned: control word bitfield    */
        mw_rxDataReady = true;
    }
    else if (receivedBytes > 0U)
    {
        /* Partial packet — LTOUT fired mid-transfer, drain stale bytes */
        (void)Uart_Hal_ClearRxFIFO(instancePtr);
    }
    /* receivedBytes == 0: idle timeout, nothing to decode */

    /* Re-arm unconditionally to keep receiver live */
    mw_rxRearm();
}

/**
 * Uart_Hal_TxCompleteCallback — TX complete notification (unused).
 *
 * TX uses polling mode (Uart_Hal_TxPolling) so this callback is never
 * invoked. Provided as required by the HAL interface.
 */
void Uart_Hal_TxCompleteCallback(Uart_Hal_InstanceType *instancePtr,
                                 Uart_Hal_TxStatusType *statusPtr,
                                 void *userArgsPtr)
{
    (void)instancePtr;
    (void)statusPtr;
    (void)userArgsPtr;
}
