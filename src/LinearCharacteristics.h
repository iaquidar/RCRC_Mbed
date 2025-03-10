// Linear Characteristics for different purposes (map Voltage to acc etc.)
#pragma once
class LinearCharacteristics{
     public:
            LinearCharacteristics(){};              // default constructor
            LinearCharacteristics(float, float);    // constructor with gain and 
            LinearCharacteristics(float, float, float, float);    // constructor with gain and offset
            void set_limits(float, float);
            float evaluate(float);                  // calculate y(x)
            float operator()(float x){              // calculate with () operator
                return evaluate(x);
                } 
            virtual     ~LinearCharacteristics();   // deconstructor
                
    private:
        // here: private functions and values...
        float gain;
        float offset;
        float ulim;
        float llim;
};
