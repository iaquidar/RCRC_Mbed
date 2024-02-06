/* mbed Microcontroller Library
 * Copyright (c) 2019 ARM Limited
 * SPDX-License-Identifier: Apache-2.0
 */

#include "mbed.h"
#include "IO_handler.h"
#include "realtime_thread.h"
#include "GPA.h"
#include "DataLogger.h"
#include "uart_comm_thread_send.h"
#include "uart_comm_thread_receive.h"

float Ts = .0002;
GPA myGPA (1, 1000, 30, .1,.2, Ts);
DataLogger myDataLogger(1);

int main()
{
    IO_handler hardware;
    // the communication ...
    static BufferedSerial uart_serial(USBTX, USBRX, 115200);
    uart_comm_thread_send uart_com_send(&hardware,&uart_serial, .004f); // this is the communication thread
    uart_comm_thread_receive uart_com_receive(&uart_serial, .01f); // this is the communication thread
    // the ios and the rt-thread
    realtime_thread rt_thread(&hardware,Ts);
// start the three threads
    uart_com_receive.start_uart();
    uart_com_send.start_uart();
    rt_thread.start_loop();

    while (true) {
        ThisThread::sleep_for(500ms);
    }
}
