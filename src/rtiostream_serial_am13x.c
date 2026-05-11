/**
* \file  rtiostream_serial_am13x.c
* \brief rtIOStream serial implementation for AM13E230X device
*
* This file implements the rtIOStream interface for MATLAB/Simulink
* Processor-in-the-Loop (PIL) and External Mode communication over UART.
* It provides a ring buffer based receive mechanism with interrupt-driven
* UART reception and polling-based transmission.
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

#include "rtiostream.h"

/* SDK includes */
#include "Uart_Hal.h"
#include "arch_interrupt.h"
#include "dl_gpio.h"
/* SysConfig generated include */
#include "ti_sdk_dl_config.h"
/* STD includes */
#include <stdbool.h>

/* Buffer sizes in bytes */
#define RTIO_STREAM_FIFO_SIZE 1028U
#define RTIO_STREAM_HAL_RX_BUFFER_SIZE 8U

/* UART pin configuration for E2 version */
#define RTIO_STREAM_UART_INSTANCE       UC4_INST_PTR
#define RTIO_STREAM_UART_IRQn           UC4_INT_IRQn
#define RTIO_STREAM_UART_IRQ_HANDLER    UC4_IRQHandler

#define RTIO_STREAM_UART_TX_PINCM       IOMUX_PINCM_PA0
#define RTIO_STREAM_UART_TX_FUNC        IOMUX_PA0_UC4_TX_SDA_PICO
#define RTIO_STREAM_UART_RX_PINCM       IOMUX_PINCM_PA1
#define RTIO_STREAM_UART_RX_FUNC        IOMUX_PA1_UC4_RX_SCL_SCLK

/* UART communication parameters */
#define APPEND_U_IMPL(x) x##U
#define APPEND_U(x) APPEND_U_IMPL(x)

#if defined(AM13x_BAUDRATE)
#define RTIO_STREAM_UART_BAUDRATE_BPS   APPEND_U(AM13x_BAUDRATE)
#else
#define RTIO_STREAM_UART_BAUDRATE_BPS   5000000U
#endif

/* Uart is driven by SEMI CLK source*/
#define RTIO_STREAM_UART_INPUT_CLOCK_HZ SEMIMCLK_FREQ_HZ


/* ========================================================================== */
/*                 Private Variables                                          */
/* ========================================================================== */

/* RX Ring buffer */
static volatile uint8_t  rtioStream_RxBuffer[RTIO_STREAM_FIFO_SIZE];
static volatile uint32_t rtioStream_RxHead = 0U;
static volatile uint32_t rtioStream_RxTail = 0U;

/* HAL RX buffer */
static uint8_t rtioStream_HalRxBuffer[RTIO_STREAM_HAL_RX_BUFFER_SIZE];

/* HAL UART instance */
static Uart_Hal_InstanceType rtioStream_UartInstance = {0};

/* ========================================================================== */
/*                 Private Function Prototypes                                */
/* ========================================================================== */

static void     rtioStream_RxBufferInit(void);
static uint32_t rtioStream_RxBufferWrite(const uint8_t *dataPtr, uint32_t length);
static uint32_t rtioStream_RxBufferRead(uint8_t *dataPtr, uint32_t maxLength);
static void     rtioStream_StartHalRx(void);

/* ========================================================================== */
/*                 Private Functions                                          */
/* ========================================================================== */
static void rtioStream_RxBufferInit(void)
{
    rtioStream_RxHead = 0U;
    rtioStream_RxTail = 0U;
}

/*
* Drop entire chunk if buffer cannot hold it. Dropping (vs overwriting old data)
* simplifies logic - overwrite would require advancing tail pointer to prevent
* head==tail ambiguity, adding complexity and race conditions with concurrent reads.
*/

static uint32_t rtioStream_RxBufferWrite(const uint8_t *dataPtr, uint32_t length)
{
    uint32_t bytesWritten = 0U;
    uint32_t head;
    uint32_t tail;
    uint32_t availableSpace;

    head = rtioStream_RxHead;
    tail = rtioStream_RxTail;

    /* Calculate free space in ring buffer */
    if (head >= tail)
    {
        availableSpace = (RTIO_STREAM_FIFO_SIZE - 1U) - (head - tail);
    }
    else
    {
        availableSpace = (tail - head) - 1U;
    }

    /* Only write if entire chunk fits, otherwise drop all to preserve packet integrity */
    if (availableSpace >= length)
    {
        while (bytesWritten < length)
        {
            rtioStream_RxBuffer[head] = dataPtr[bytesWritten];
            head = (head + 1U) % RTIO_STREAM_FIFO_SIZE;
            bytesWritten++;
        }
        rtioStream_RxHead = head;
    }

    return bytesWritten;
}

static uint32_t rtioStream_RxBufferRead(uint8_t *dataPtr, uint32_t maxLength)
{
    uint32_t bytesRead = 0U;
    uint32_t tail;
    uint32_t head;

    tail = rtioStream_RxTail;
    head = rtioStream_RxHead;

    while ((bytesRead < maxLength) && (tail != head))
    {
        dataPtr[bytesRead] = rtioStream_RxBuffer[tail];
        tail = (tail + 1U) % RTIO_STREAM_FIFO_SIZE;
        bytesRead++;
        head = rtioStream_RxHead;
    }

    rtioStream_RxTail = tail;

    return bytesRead;
}

static void rtioStream_StartHalRx(void)
{
    (void)Uart_Hal_RxInterrupt(&rtioStream_UartInstance, rtioStream_HalRxBuffer, RTIO_STREAM_HAL_RX_BUFFER_SIZE);
}

/* ========================================================================== */
/*                 rtIOStream API Functions                                   */
/* ========================================================================== */
int rtIOStreamOpen(int argc, void *argv[])
{
    (void)argc;
    (void)argv;

    /* Disable and clear interrupts if any */
    Arch_Interrupt_Disable(RTIO_STREAM_UART_IRQn);
    Arch_Interrupt_Clear(RTIO_STREAM_UART_IRQn);

    /* Configure Tx/Rx pins. To be done before HAL init to avoid undefined state */
    DL_GPIO_initPeripheralOutputFunction(
        RTIO_STREAM_UART_TX_PINCM, RTIO_STREAM_UART_TX_FUNC);
    DL_GPIO_initPeripheralInputFunction(
        RTIO_STREAM_UART_RX_PINCM, RTIO_STREAM_UART_RX_FUNC);

    /* Get HAL param handle with defaults */
    Uart_Hal_InitParamsType uartInitParams;
    Uart_Hal_InitParamsSetDefault(&uartInitParams);

    /* Configure required UART params */
    uartInitParams.HwRegsPtr = RTIO_STREAM_UART_INSTANCE;
    uartInitParams.BaudRateBps = RTIO_STREAM_UART_BAUDRATE_BPS;
    uartInitParams.InputClockHz = RTIO_STREAM_UART_INPUT_CLOCK_HZ;

    /* Initialize UART HAL */
    sint32 status = Uart_Hal_Init(&rtioStream_UartInstance, &uartInitParams);
    if (status != UART_HAL_ERROR_NONE) {
        return RTIOSTREAM_ERROR;
    }

    /* Initialize state */
    rtioStream_RxBufferInit();

    /* Enable Interrupts NVIC */
    Arch_Interrupt_Enable(RTIO_STREAM_UART_IRQn);

    /* Start HAL RX and enable interrupts */
    rtioStream_StartHalRx();

    return RTIOSTREAM_NO_ERROR;
}

int rtIOStreamClose(int streamID)
{
    (void)streamID;

    /* Abort any pending RX */
    (void)Uart_Hal_RxAbort(&rtioStream_UartInstance);

    /* Disable UART interrupt */
    Arch_Interrupt_Disable(RTIO_STREAM_UART_IRQn);
    Arch_Interrupt_Clear(RTIO_STREAM_UART_IRQn);

    /* De-initialize UART HAL */
    (void)Uart_Hal_DeInit(&rtioStream_UartInstance);

    return RTIOSTREAM_NO_ERROR;
}

int rtIOStreamSend(int streamID, const void *data, size_t size, size_t *sizeTransferred)
{
    (void)streamID;
    Uart_Hal_TxStatusType txStatus = {0};
    sint32                apiStatus;

    /* Input validation */
    if ((data == NULL) || (size == 0U))
    {
        *sizeTransferred = 0U;
        return RTIOSTREAM_ERROR;
    }
    /* Polling and interrupt based Tx can be interchangeably used. Interrupts do not add any additional value */
    apiStatus = Uart_Hal_TxPolling(&rtioStream_UartInstance, (uint8*)data, size);
    if (UART_HAL_ERROR_NONE == apiStatus)
    {
        do
        {
            apiStatus = Uart_Hal_TxContinuePolling(&rtioStream_UartInstance, &txStatus);
        }
        while ((UART_HAL_ERROR_NONE == apiStatus) &&
               (txStatus.IsTxComplete == false) &&
               (txStatus.ErrorCodeMask == 0U));
        if ((txStatus.ErrorCodeMask != 0U) || (UART_HAL_ERROR_NONE != apiStatus))
        {
            *sizeTransferred = 0U;
            return RTIOSTREAM_ERROR;
        }
    }
    else
    {
        /* Uart_Hal_TxPolling() failed */
        *sizeTransferred = 0U;
        return RTIOSTREAM_ERROR;
    }
    *sizeTransferred = size;
    return RTIOSTREAM_NO_ERROR;
}

int rtIOStreamRecv(int streamID, void *buffer, size_t size, size_t *sizeTransferred)
{
    (void)streamID;
    *sizeTransferred = (size_t)rtioStream_RxBufferRead((uint8_t *)buffer, (uint32_t)size);

    return RTIOSTREAM_NO_ERROR;
}

/* ========================================================================== */
/*                 Interrupt Handler                                          */
/* ========================================================================== */

void RTIO_STREAM_UART_IRQ_HANDLER(void)
{
    Uart_Hal_InterruptHandler(&rtioStream_UartInstance);
}

/* ========================================================================== */
/*                 HAL Callbacks                                              */
/* ========================================================================== */

void Uart_Hal_RxCompleteCallback(Uart_Hal_InstanceType *instancePtr,
                                 Uart_Hal_RxStatusType *statusPtr,
                                 void *userArgsPtr)
{
    uint32_t receivedBytes;

    (void)userArgsPtr;

    if (instancePtr == &rtioStream_UartInstance)
    {
        /* Calculate received bytes */
        receivedBytes = statusPtr->SizeInBytes - statusPtr->RemainingSizeInBytes;

        /* Write received data to ring buffer */
        (void)rtioStream_RxBufferWrite(statusPtr->BufferPtr, receivedBytes);

        /* Restart RX for continuous reception */
        rtioStream_StartHalRx();
    }
}

/* Tx complete callback is expected to be defined by UART HAL */
void Uart_Hal_TxCompleteCallback(Uart_Hal_InstanceType *instancePtr,
                                 Uart_Hal_TxStatusType *statusPtr,
                                 void *userArgsPtr)
{
    (void)instancePtr;
    (void)statusPtr;
    (void)userArgsPtr;
}
