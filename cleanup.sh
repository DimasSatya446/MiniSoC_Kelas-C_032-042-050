#!/bin/bash
# ============================================================================
# Mini SOC Cleanup Script
# ============================================================================
# Purpose: Stop and clean up all Mini SOC services
# Usage: ./cleanup.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════════════════"
echo "  Mini SOC - Cleanup Script"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

read -p "Are you sure you want to stop and remove all containers? (y/N): " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}[*] Stopping all services...${NC}"
    docker-compose down
    echo -e "${GREEN}[+] Services stopped${NC}"
    
    echo ""
    echo -e "${YELLOW}[*] Would you like to remove Docker volumes? (y/N)${NC}"
    read -p "This will delete all data stored in containers (y/N): " -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}[*] Removing volumes...${NC}"
        docker-compose down -v
        echo -e "${GREEN}[+] Volumes removed${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}[+] Cleanup completed${NC}"
    echo ""
    echo "To restart services later, run: ./start.sh"
else
    echo -e "${YELLOW}[*] Cleanup cancelled${NC}"
fi
