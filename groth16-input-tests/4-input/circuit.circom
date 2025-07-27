pragma circom 2.0.0;

template FourInputCircuit() {
    // Public inputs
    signal input a;
    signal input b;
    signal input c;
    signal input d;
    
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
    
    // Constraint 1: temp1 = a * b
    temp1 <== a * b;
    
    // Constraint 2: temp2 = c * d
    temp2 <== c * d;
    
    // Constraint 3: temp3 = temp1 + temp2
    temp3 <== temp1 + temp2;
    
    // Constraint 4: temp4 = a + b + c + d
    temp4 <== a + b + c + d;
    
    // Constraint 5: temp5 = temp4 * secret
    temp5 <== temp4 * secret;
    
    // Constraint 6: temp6 = temp3 + temp5
    temp6 <== temp3 + temp5;
    
    // Final constraint: verification
    temp6 === y;
}

// Main component with 4 public inputs
component main {public [a, b, c, d]} = FourInputCircuit();