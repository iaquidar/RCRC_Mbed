#pragma once
/* class IO_handler
*/
#include <cstdint>
#include "mbed.h"
#include "LinearCharacteristics.h"

class IO_handler
{
public:
    IO_handler();        // default constructor
    virtual ~IO_handler();   // deconstructor
    float read_ain1(void);       // read both encoders and calculate speeds
    float read_ain2(void);       // read both encoders and calculate speeds
    void write_aout(float);  // write current to motors (0,...) for motor 1, (1,...) for motor 2
    float get_set_value();
private:
    AnalogOut a_out;           // desired current values
    AnalogIn a_in1;
    AnalogIn a_in2;
    float set_value;
    LinearCharacteristics lc_in;
    LinearCharacteristics lc_out;
};