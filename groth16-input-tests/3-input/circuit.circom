pragma circom 2.0.0;

template ThreeInputCircuit() {
    // Public inputs
    signal input a;
    signal input b;
    signal input c;
    
    // Private inputs
    signal input secret;
    signal input y;
    
    // Intermediate signals
    signal temp1;
    signal temp2;
    signal temp3;
    signal temp4;
    signal temp5;
    
    // Constraint 1: temp1 = a * b
    temp1 <== a * b;
    
    // Constraint 2: temp2 = c * c
    temp2 <== c * c;
    
    // Constraint 3: temp3 = temp1 + temp2
    temp3 <== temp1 + temp2;
    
    // Constraint 4: temp4 = (a + b + c) * secret
    temp4 <== (a + b + c) * secret;
    
    // Constraint 5: temp5 = temp3 + temp4
    temp5 <== temp3 + temp4;
    
    // Final constraint: verification
    temp5 === y;
}

// Main component with 3 public inputs
component main {public [a, b, c]} = ThreeInputCircuit();