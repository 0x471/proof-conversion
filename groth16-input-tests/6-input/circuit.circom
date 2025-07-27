pragma circom 2.0.0;

template SixInputCircuit() {
    // Public inputs
    signal input a;
    signal input b;
    signal input c;
    signal input d;
    signal input e;
    signal input f;
    
    // Private inputs
    signal input secret;
    signal input y;
    
    // Intermediate signals
    signal temp1;
    signal temp2;
    signal temp3;
    signal temp4;
    signal temp5;
    signal temp6;
    signal temp7;
    signal temp8;
    
    // Constraint 1: temp1 = a * b
    temp1 <== a * b;
    
    // Constraint 2: temp2 = c + d
    temp2 <== c + d;
    
    // Constraint 3: temp3 = e * f
    temp3 <== e * f;
    
    // Constraint 4: temp4 = temp1 * temp2
    temp4 <== temp1 * temp2;
    
    // Constraint 5: temp5 = temp4 + temp3
    temp5 <== temp4 + temp3;
    
    // Constraint 6: temp6 = (a + b + c + d + e + f) * secret
    temp6 <== (a + b + c + d + e + f) * secret;
    
    // Constraint 7: temp7 = temp5 + temp6
    temp7 <== temp5 + temp6;
    
    // Constraint 8: temp8 = temp7 * 2
    temp8 <== temp7 * 2;
    
    // Final constraint: verification
    temp8 === y;
}

// Main component with 6 public inputs
component main {public [a, b, c, d, e, f]} = SixInputCircuit();