#define S1 true

#include "IO_handler.h"
#include <cstdint>



// constructors
IO_handler::IO_handler(void): a_out(PA_5),a_in1(PA_6),a_in2(PA_7)
{
    a_out.write(0);
    return;    
}
IO_handler::~IO_handler() {} 

float IO_handler::read_ain1(void)
{
    return a_in1.read();    
}
float IO_handler::read_ain2(void)
{
    return a_in2.read();    
}

void IO_handler::write_aout(float U_0_1)
{
    set_value = U_0_1;
    a_out.write(U_0_1);
}

float IO_handler::get_set_value()
{
    return set_value;
}