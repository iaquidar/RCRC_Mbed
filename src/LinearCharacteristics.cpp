#include "LinearCharacteristics.h"

using namespace std;

LinearCharacteristics::LinearCharacteristics(float gain,float offset){    // standard lin characteristics
    this->gain = gain;
    this->offset = offset;
    this->ulim = 999999.0;          // a large number
    this->llim = -999999.0;         // a large neg. number
}


LinearCharacteristics::LinearCharacteristics(float xmin, float xmax, float ymin, float ymax) {
    this->gain = (ymax - ymin)/(xmax - xmin);
    this->offset = xmin - (ymin/gain);
    this->ulim = 999999.0;          // a large number
    this->llim = -999999.0;         // a large neg. number
}

void LinearCharacteristics::set_limits(float min, float max) {
    this->llim = min;
    this->ulim = max;
    }


LinearCharacteristics::~LinearCharacteristics() {}


float LinearCharacteristics::evaluate(float x)
{   
    // calculate result as y(x) = gain * (x-offset)
    return (gain * (x - offset));
    //return x;
}
