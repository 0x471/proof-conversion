pragma circom 2.0.0;

template TwoInputCircuit() {
    // Public inputs
    signal input a;
    signal input b;
    
    // Private inputs
    signal input secret;
    signal input y;
    
    // Intermediate signals
    signal temp1;
    signal temp2;
    signal temp3;
    signal temp4;
    
    // Constraint 1: temp1 = a * b
    temp1 <== a * b;
    
    // Constraint 2: temp2 = a + b
    temp2 <== a + b;
    
    // Constraint 3: temp3 = temp1 + temp2 + secret
    temp3 <== temp1 + temp2 + secret;
    
    // Constraint 4: temp4 = temp3 * 2
    temp4 <== temp3 * 2;
    
    // Final constraint: verification
    temp4 === y;
}

// Main component with 2 public inputs
component main {public [a, b]} = TwoInputCircuit();