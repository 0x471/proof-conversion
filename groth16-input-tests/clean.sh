#!/bin/bash

# Clean script for Groth16 test suite
# Removes all auto-generated files while preserving source files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}🧹 Groth16 Test Suite Cleanup${NC}"
echo -e "${BLUE}=============================${NC}"

# Circuit-specific artifacts to clean
CIRCUIT_ARTIFACTS=(
    "*.r1cs"
    "*.sym" 
    "*.wtns"
    "*_0000.zkey"
    "*_final.zkey" 
    "circuit_final.zkey"
    "circuit_0000.zkey"
    "proof.json"
    "public.json"
    "verification_key.json"
    "converted_proof.json"
    "converted_vk.json"
    "*input_test.env"
    "pot*.ptau"
    "circuit_js"
)

# Count total files to clean
TOTAL_FILES=0

# Clean each circuit directory
for circuit_dir in "$SCRIPT_DIR"/*-input; do
    if [ -d "$circuit_dir" ]; then
        circuit_name=$(basename "$circuit_dir")
        echo -e "${YELLOW}📂 Cleaning $circuit_name/...${NC}"
        
        cd "$circuit_dir"
        local_count=0
        
        for pattern in "${CIRCUIT_ARTIFACTS[@]}"; do
            # Count files matching pattern
            files=$(find . -name "$pattern" -type f 2>/dev/null | wc -l)
            if [ "$files" -gt 0 ]; then
                local_count=$((local_count + files))
                rm -rf $pattern 2>/dev/null
            fi
            # Also remove directories matching pattern  
            dirs=$(find . -name "$pattern" -type d 2>/dev/null | wc -l)
            if [ "$dirs" -gt 0 ]; then
                local_count=$((local_count + dirs))
                rm -rf $pattern 2>/dev/null
            fi
        done
        
        TOTAL_FILES=$((TOTAL_FILES + local_count))
        echo -e "  ${GREEN}✓${NC} Removed $local_count files/directories"
        cd "$SCRIPT_DIR"
    fi
done

# Clean work directories in scripts/
echo -e "${YELLOW}📂 Cleaning work directories...${NC}"
work_dirs_count=0

if [ -d "$REPO_ROOT/scripts" ]; then
    cd "$REPO_ROOT/scripts"
    for work_dir in *input_test_workdir; do
        if [ -d "$work_dir" ]; then
            rm -rf "$work_dir"
            work_dirs_count=$((work_dirs_count + 1))
        fi
    done
    
    # Clean groth16_cache
    if [ -d "groth16_cache" ]; then
        rm -rf groth16_cache
        work_dirs_count=$((work_dirs_count + 1))
    fi
fi

echo -e "  ${GREEN}✓${NC} Removed $work_dirs_count work directories"

# Clean temp directories in repo root
echo -e "${YELLOW}📂 Cleaning temp directories...${NC}"
temp_count=0

cd "$REPO_ROOT"
if [ -d "temp_groth16_work" ]; then
    rm -rf temp_groth16_work
    temp_count=$((temp_count + 1))
fi

if [ -d "temp_work" ]; then
    rm -rf temp_work  
    temp_count=$((temp_count + 1))
fi

echo -e "  ${GREEN}✓${NC} Removed $temp_count temp directories"

# Clean build directory (optional)
echo ""
echo -e "${YELLOW}Build directory cleanup:${NC}"
if [ -d "$REPO_ROOT/build" ]; then
    read -p "Remove build directory? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$REPO_ROOT/build"
        echo -e "  ${GREEN}✓${NC} Removed build directory"
    else
        echo -e "  ${BLUE}ℹ${NC} Build directory preserved"
    fi
else
    echo -e "  ${BLUE}ℹ${NC} No build directory found"
fi

# Clean shared PTAU (optional)
echo ""
echo -e "${YELLOW}Shared PTAU cleanup:${NC}"
if [ -f "$SCRIPT_DIR/shared_pot08_final.ptau" ]; then
    read -p "Remove shared PTAU file? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$SCRIPT_DIR/shared_pot08_final.ptau"
        echo -e "  ${GREEN}✓${NC} Removed shared PTAU file"
    else
        echo -e "  ${BLUE}ℹ${NC} Shared PTAU preserved"
    fi
else
    echo -e "  ${BLUE}ℹ${NC} No shared PTAU file found"
fi

echo ""
echo -e "${GREEN}✨ Cleanup complete!${NC}"
echo -e "${GREEN}📊 Total artifacts removed: $TOTAL_FILES${NC}"
echo -e "${BLUE}💡 Tip: Run './run_all_circuits.sh' to regenerate test artifacts${NC}"