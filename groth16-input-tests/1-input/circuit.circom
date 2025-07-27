pragma circom 2.0.0;

template OneInputCircuit() {
    // Public input
    signal input a;
    
    // Private inputs
    signal input secret;
    signal input y;
    
    // Intermediate signals
    signal temp1;
    signal temp2;
    signal temp3;
    
    // Constraint 1: temp1 = a * a
    temp1 <== a * a;
    
    // Constraint 2: temp2 = secret * 3
    temp2 <== secret * 3;
    
    // Constraint 3: temp3 = temp1 + temp2
    temp3 <== temp1 + temp2;
    
    // Final constraint: verification
    temp3 === y;
}

// Main component with 1 public input
component main {public [a]} = OneInputCircuit();