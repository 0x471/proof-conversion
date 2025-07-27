pragma circom 2.0.0;

template ZeroInputCircuit() {
    // No public inputs - everything is private
    
    // Private inputs
    signal input secret;
    signal input y;
    
    // Intermediate signals
    signal temp1;
    signal temp2;
    signal temp3;
    
    // Constraint 1: temp1 = secret * secret
    temp1 <== secret * secret;
    
    // Constraint 2: temp2 = secret + 10
    temp2 <== secret + 10;
    
    // Constraint 3: temp3 = temp1 + temp2
    temp3 <== temp1 + temp2;
    
    // Final constraint: verification
    temp3 === y;
}

// Main component with 0 public inputs (no public array specified)
component main = ZeroInputCircuit();