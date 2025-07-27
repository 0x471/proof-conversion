pragma circom 2.0.0;

template FiveInputCircuit() {
    // Public inputs
    signal input a;
    signal input b;
    signal input c;
    signal input d;
    signal input e;
    
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
    
    // Constraint 1: temp1 = a * b
    temp1 <== a * b;
    
    // Constraint 2: temp2 = c + d
    temp2 <== c + d;
    
    // Constraint 3: temp3 = e * e
    temp3 <== e * e;
    
    // Constraint 4: temp4 = temp1 * temp2
    temp4 <== temp1 * temp2;
    
    // Constraint 5: temp5 = temp4 + temp3
    temp5 <== temp4 + temp3;
    
    // Constraint 6: temp6 = (a + b + c + d + e) * secret
    temp6 <== (a + b + c + d + e) * secret;
    
    // Constraint 7: temp7 = temp5 + temp6
    temp7 <== temp5 + temp6;
    
    // Final constraint: verification
    temp7 === y;
}

// Main component with 5 public inputs (RISC Zero default)
component main {public [a, b, c, d, e]} = FiveInputCircuit();