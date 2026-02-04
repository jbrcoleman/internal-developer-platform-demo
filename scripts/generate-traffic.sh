#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

URL=${1:-http://demo-app-1.local}
RPS=${2:-5}
DURATION=${3:-300}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Traffic Generator${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "  URL:      ${GREEN}$URL${NC}"
echo -e "  RPS:      ${GREEN}$RPS${NC}"
echo -e "  Duration: ${GREEN}${DURATION}s${NC}"
echo ""

# Calculate delay between requests
DELAY=$(echo "scale=3; 1/$RPS" | bc)

echo -e "${YELLOW}Generating traffic (Ctrl+C to stop)...${NC}"
echo ""

END=$((SECONDS + DURATION))
SUCCESS=0
ERRORS=0

while [ $SECONDS -lt $END ]; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null)

    if [ "$RESPONSE" = "200" ]; then
        ((SUCCESS++))
        echo -ne "\r${GREEN}Success: $SUCCESS${NC} | ${RED}Errors: $ERRORS${NC}"
    else
        ((ERRORS++))
        echo -ne "\r${GREEN}Success: $SUCCESS${NC} | ${RED}Errors: $ERRORS${NC}"
    fi

    sleep $DELAY
done

echo ""
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Summary:${NC}"
echo -e "  Total requests: $((SUCCESS + ERRORS))"
echo -e "  Successful:     ${GREEN}$SUCCESS${NC}"
echo -e "  Errors:         ${RED}$ERRORS${NC}"
if [ $((SUCCESS + ERRORS)) -gt 0 ]; then
    ERROR_RATE=$(echo "scale=2; $ERRORS * 100 / ($SUCCESS + $ERRORS)" | bc)
    echo -e "  Error rate:     $ERROR_RATE%"
fi
echo -e "${BLUE}========================================${NC}"
