#!/bin/bash

# Test script for all Groth16 input count configurations
# Tests 1-6 public inputs with complete snarkjs → o1js pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get absolute path to proof-conversion repo
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$REPO_ROOT/groth16-input-tests"

# Shared PTAU file path
SHARED_PTAU="$TEST_ROOT/shared_pot08_final.ptau"

# Performance tracking (bash 3.x compatible)
SUITE_START_TIME=$(date +%s)

echo -e "${BLUE}🧪 Groth16 Input Count Testing Suite${NC}"
echo -e "${BLUE}====================================${NC}"
echo "Repository: $REPO_ROOT"
echo "Test suite: $TEST_ROOT"
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check circom
    if ! command -v circom &> /dev/null; then
        echo -e "${RED}❌ circom not found. Install from: https://docs.circom.io/getting-started/installation/${NC}"
        exit 1
    fi
    
    # Check snarkjs
    if ! command -v snarkjs &> /dev/null; then
        echo -e "${RED}❌ snarkjs not found. Install with: npm install -g snarkjs${NC}"
        exit 1
    fi
    
    # Check if Rust conversion tool exists
    if [ ! -f "$REPO_ROOT/pairing-utils/target/release/convert_from_snarkjs" ]; then
        echo -e "${YELLOW}⚠️ Rust conversion tool not built. Building Rust binaries...${NC}"
        cd "$REPO_ROOT/pairing-utils"
        
        # Build WASM package first
        ./build.sh
        
        # Build Rust binaries
        echo -e "${YELLOW}Building Rust release binaries...${NC}"
        cargo build --release
        
        cd "$TEST_ROOT"
    fi
    
    # Download shared PTAU file if needed
    if [ ! -f "$SHARED_PTAU" ]; then
        echo -e "${YELLOW}📥 Downloading shared powers of tau (ptau08)...${NC}"
        wget -q "https://storage.googleapis.com/zkevm/ptau/powersOfTau28_hez_final_08.ptau" -O "$SHARED_PTAU"
        echo -e "${GREEN}✅ Shared PTAU downloaded${NC}"
    else
        echo -e "${GREEN}✅ Shared PTAU already exists${NC}"
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Test single input count
test_input_count() {
    local input_count=$1
    local test_dir="$TEST_ROOT/${input_count}-input"
    local work_dir="$REPO_ROOT/scripts/${input_count}input_test_workdir"
    
    # Start timing this test
    local test_start_time=$(date +%s)
    echo "Debug: Test start time for ${input_count}-input: $test_start_time"
    
    echo -e "\n${BLUE}🧮 Testing ${input_count}-input circuit${NC}"
    echo "=================================="
    
    cd "$test_dir"
    
    # Step 1: Compile circuit
    echo -e "${YELLOW}1. Compiling circom circuit...${NC}"
    circom circuit.circom --r1cs --wasm --sym
    
    # Step 2: Calculate witness
    echo -e "${YELLOW}2. Calculating witness...${NC}"
    snarkjs wtns calculate circuit_js/circuit.wasm input.json witness.wtns
    
    # Step 3: Get constraint count (for reporting)
    echo -e "${YELLOW}3. Analyzing circuit constraints...${NC}"
    local constraints=$(snarkjs r1cs info circuit.r1cs | grep "# of Constraints" | cut -d':' -f3 | xargs)
    eval "CONSTRAINT_COUNT_$input_count=$constraints"
    echo "   Constraints: $constraints"
    
    # Step 4: Use shared powers of tau
    PTAU_FILE="pot08_final.ptau"
    if [ ! -f "$PTAU_FILE" ]; then
        echo -e "${YELLOW}4. Linking shared powers of tau...${NC}"
        ln -s "$SHARED_PTAU" "$PTAU_FILE"
    else
        echo -e "${GREEN}4. Powers of tau already linked${NC}"
    fi
    
    # Step 5: Setup
    echo -e "${YELLOW}5. Running Groth16 setup...${NC}"
    snarkjs groth16 setup circuit.r1cs "$PTAU_FILE" circuit_0000.zkey
    mv circuit_0000.zkey circuit_final.zkey
    
    # Step 6: Verify key
    echo -e "${YELLOW}6. Verifying final key...${NC}"
    snarkjs zkey verify circuit.r1cs "$PTAU_FILE" circuit_final.zkey
    
    # Step 7: Export verification key
    echo -e "${YELLOW}7. Exporting verification key...${NC}"
    snarkjs zkey export verificationkey circuit_final.zkey verification_key.json
    
    # Step 8: Generate proof
    echo -e "${YELLOW}8. Generating proof...${NC}"
    snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json
    
    # Step 9: Verify proof with snarkjs
    echo -e "${YELLOW}9. Verifying proof with snarkjs...${NC}"
    snarkjs groth16 verify verification_key.json public.json proof.json
    
    # Step 10: Convert to o1js format
    echo -e "${YELLOW}10. Converting to o1js format...${NC}"
    if ! "$REPO_ROOT/pairing-utils/target/release/convert_from_snarkjs" \
        proof.json public.json verification_key.json converted_proof.json converted_vk.json; then
        echo -e "${RED}❌ Conversion to o1js format failed${NC}"
        exit 1
    fi
    
    # Verify conversion outputs exist
    if [ ! -f "converted_proof.json" ] || [ ! -f "converted_vk.json" ]; then
        echo -e "${RED}❌ Conversion outputs missing: converted_proof.json or converted_vk.json${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Conversion successful${NC}"
    
    # Step 11: Pure data-driven approach (no environment variables needed)
    echo -e "${YELLOW}11. Using data-driven auto-detection for ${input_count} inputs...${NC}"
    echo -e "${GREEN}✅ VK and proof will auto-detect input count at runtime${NC}"
    
    # Step 12: Setup work directory for o1js pipeline
    echo -e "${YELLOW}12. Setting up o1js test environment...${NC}"
    # Create work directory structure that matches groth16_tree.sh expectations
    # groth16_tree.sh uses ../scripts/ prefix, so we need relative paths from repo root
    work_dir_relative="${input_count}input_test_workdir/e2e_groth16"
    work_dir_absolute="$REPO_ROOT/scripts/$work_dir_relative"
    cache_dir_absolute="$REPO_ROOT/scripts/groth16_cache"
    
    mkdir -p "$work_dir_absolute"
    mkdir -p "$cache_dir_absolute"
    
    # Create environment file with paths that match groth16_tree.sh expectations
    # groth16_tree.sh expects WORK_DIR to be relative path that works with ../scripts/ prefix
    env_file="$test_dir/${input_count}input_test.env"
    cat > "$env_file" << EOF
WORK_DIR=$work_dir_relative
CACHE_DIR=groth16_cache
VK_PATH=$test_dir/converted_vk.json
PROOF_PATH=$test_dir/converted_proof.json
EOF
    
    # Step 13: Generate auxiliary witness
    echo -e "${YELLOW}13. Generating auxiliary witness...${NC}"
    export NODE_OPTIONS="--max-old-space-size=65536"
    export GROTH16_VK_PATH="$test_dir/converted_vk.json"
    
    # Run auxiliary witness generation (requires being in repo root)
    cd "$REPO_ROOT"
    ./scripts/get_aux_witness_groth16.sh "$env_file"
    
    # Verify auxiliary witness was created
    aux_witness_path="$work_dir_absolute/aux_wtns.json"
    if [ ! -f "$aux_witness_path" ]; then
        echo -e "${RED}❌ Auxiliary witness generation failed: $aux_witness_path not found${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Auxiliary witness generated: $aux_witness_path${NC}"
    
    # Step 14: Run complete o1js recursive verification
    echo -e "${YELLOW}14. Running o1js recursive verification pipeline...${NC}"
    # groth16_tree.sh expects to run from a directory where:
    # - ../scripts/ points to the scripts directory
    # - ./build/ points to the build directory
    # So run from inside a subdirectory of the repo root
    cd "$REPO_ROOT"
    mkdir -p temp_groth16_work
    cd temp_groth16_work
    # Create symlink to build directory so ./build/ works
    ln -sf ../build build
    ../scripts/groth16_tree.sh "$env_file"
    cd "$REPO_ROOT"
    rm -rf temp_groth16_work
    
    # Calculate test duration
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - test_start_time))
    echo "Debug: Test end time for ${input_count}-input: $test_end_time"
    echo "Debug: Calculated duration for ${input_count}-input: $test_duration"
    eval "TEST_TIME_$input_count=$test_duration"
    
    echo -e "${GREEN}✅ ${input_count}-input test completed successfully! (${test_duration}s)${NC}"
    
    cd "$TEST_ROOT"
}

# Main execution
main() {
    check_prerequisites
    
    # Use existing build - no rebuilding
    echo -e "${YELLOW}🔨 Using existing build (runtime config approach)...${NC}"
    cd "$REPO_ROOT"
    
    if [ ! -d "build" ]; then
        echo -e "${RED}❌ No build directory found. Please run 'npm run build' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Build directory found - using runtime configuration${NC}"
    cd "$TEST_ROOT"
    
    # Test each input count
    for input_count in 0 1 2 3 4 5 6; do
        if test_input_count "$input_count"; then
            echo -e "${GREEN}✅ ${input_count}-input test: PASSED${NC}"
        else
            echo -e "${RED}❌ ${input_count}-input test: FAILED${NC}"
            exit 1
        fi
    done
    
    # Calculate and display performance summary
    local suite_end_time=$(date +%s)
    local total_duration=$((suite_end_time - SUITE_START_TIME))
    
    echo -e "\n${BLUE}📊 Performance Summary${NC}"
    echo -e "${BLUE}===================${NC}"
    for i in 0 1 2 3 4 5 6; do
        eval "time_val=\$TEST_TIME_$i"
        eval "constraint_val=\$CONSTRAINT_COUNT_$i"
        echo "Debug: Retrieved TEST_TIME_$i = $time_val, CONSTRAINT_COUNT_$i = $constraint_val"
        echo -e "• ${i}-input: ${time_val}s (${constraint_val} constraints)"
    done
    echo -e "${BLUE}Total execution time: ${total_duration}s${NC}"
    
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}Groth16 supports 0-6 public inputs successfully${NC}"
}

# Run with specific input count if provided
if [ $# -eq 1 ]; then
    input_count=$1
    if [[ "$input_count" =~ ^[0-6]$ ]]; then
        check_prerequisites
        test_input_count "$input_count"
        
        # Show summary for single test
        echo -e "\n${BLUE}📊 Test Summary${NC}"
        echo -e "${BLUE}=============${NC}"
        eval "time_val=\$TEST_TIME_$input_count"
        eval "constraint_val=\$CONSTRAINT_COUNT_$input_count"
        echo -e "• ${input_count}-input: ${time_val}s (${constraint_val} constraints)"
    else
        echo -e "${RED}❌ Invalid input count: $input_count. Must be 0-6${NC}"
        exit 1
    fi
else
    main
fi