#!/bin/bash
# ============================================================================
# Mini SOC Startup Script
# ============================================================================
# Purpose: Initialize and start all Mini SOC services
# Usage: ./start.sh
# ============================================================================

set -e

echo "═══════════════════════════════════════════════════════════════════════"
echo "  Mini SOC - Startup Script"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is running
echo -e "${BLUE}[*] Checking Docker daemon...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}[!] Docker is not running. Please start Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] Docker daemon is running${NC}"

# Check if docker-compose.yml exists
echo -e "${BLUE}[*] Checking docker-compose.yml...${NC}"
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}[!] docker-compose.yml not found in current directory${NC}"
    exit 1
fi
echo -e "${GREEN}[+] docker-compose.yml found${NC}"

# Start services
echo ""
echo -e "${BLUE}[*] Starting all services (this may take 2-3 minutes)...${NC}"
docker-compose up -d

# Wait for services to be healthy
echo ""
echo -e "${BLUE}[*] Waiting for services to become healthy...${NC}"
sleep 10

# Check service status
echo ""
echo -e "${BLUE}[*] Checking service status...${NC}"
echo ""
docker-compose ps

# Display service URLs
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo -e "${GREEN}[+] All services started successfully!${NC}"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "Services available at:"
echo ""
echo -e "${YELLOW}DVWA Application:${NC}"
echo "  URL: http://localhost:8080"
echo "  Username: admin"
echo "  Password: password"
echo ""
echo -e "${YELLOW}Wazuh Dashboard:${NC}"
echo "  URL: https://localhost:5601"
echo "  Username: admin"
echo "  Password: SecurePassword123!"
echo "  Note: Accept self-signed certificate warning"
echo ""
echo -e "${YELLOW}Nginx Health Check:${NC}"
echo "  URL: http://localhost/health"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Access DVWA at http://localhost:8080"
echo "  2. Set security level (top-right menu) to 'Low' for testing"
echo "  3. Run attack scenarios (see docs/attack-scenario.md)"
echo "  4. Monitor in Wazuh Dashboard (https://localhost:5601)"
echo ""
echo "Troubleshooting:"
echo "  View logs:           docker-compose logs -f"
echo "  Restart services:    docker-compose restart"
echo "  Stop services:       docker-compose down"
echo "  View specific logs:  docker-compose logs wazuh-manager"
echo ""
echo "Documentation:"
echo "  README.md            - Project overview"
echo "  docs/attack-scenario.md     - Attack examples"
echo "  docs/demo-flow.md    - Full demonstration guide"
echo "  docs/detection.md    - Detection rules explanation"
echo "  docs/incident-response.md   - Response procedures"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
