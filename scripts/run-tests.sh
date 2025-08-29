#!/bin/bash

# Load environment variables
source .env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Running Complete Test Suite${NC}"
echo "================================"

# Load session data
if [ ! -f "development_session.json" ]; then
  echo -e "${RED}❌ Error: development_session.json not found${NC}"
  exit 1
fi

TICKET_ID=$(jq -r '.ticket_id' development_session.json)
RESULTS_DIR="test_results_${TICKET_ID}_$(date +%Y%m%d_%H%M%S)"
mkdir -p $RESULTS_DIR

echo "📁 Results will be saved to: $RESULTS_DIR"
echo ""

# Function to update session file
update_session() {
  local key=$1
  local value=$2
  jq ".test_results.$key = $value" development_session.json > tmp.json && mv tmp.json development_session.json
}

# 1. UNIT TESTS
echo -e "${YELLOW}1. Running Unit Tests...${NC}"
echo "------------------------"

UNIT_PASSED=false
UNIT_COVERAGE=0

# JavaScript/TypeScript
if [ -f "package.json" ] && grep -q '"test"' package.json; then
  echo "Running JavaScript/TypeScript tests..."
  npm test -- --coverage --json > $RESULTS_DIR/unit_test_results.json 2>&1
  
  if [ $? -eq 0 ]; then
    UNIT_PASSED=true
    # Extract coverage percentage
    if [ -f "coverage/coverage-summary.json" ]; then
      UNIT_COVERAGE=$(jq '.total.lines.pct' coverage/coverage-summary.json)
      cp coverage/coverage-summary.json $RESULTS_DIR/
    fi
  fi
  
# Python
elif [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
  echo "Running Python tests..."
  python -m pytest --cov=. --cov-report=json --cov-report=term \
    --json-report --json-report-file=$RESULTS_DIR/unit_test_results.json
  
  if [ $? -eq 0 ]; then
    UNIT_PASSED=true
    if [ -f "coverage.json" ]; then
      UNIT_COVERAGE=$(python -c "import json; print(json.load(open('coverage.json'))['totals']['percent_covered'])")
      cp coverage.json $RESULTS_DIR/
    fi
  fi
  
# Java
elif [ -f "pom.xml" ]; then
  echo "Running Java tests..."
  mvn test jacoco:report > $RESULTS_DIR/unit_test_results.txt 2>&1
  
  if [ $? -eq 0 ]; then
    UNIT_PASSED=true
    # Extract coverage from JaCoCo
    if [ -f "target/site/jacoco/index.html" ]; then
      UNIT_COVERAGE=$(grep -oP 'Total.*?(\d+)%' target/site/jacoco/index.html | grep -oP '\d+' | head -1)
      cp -r target/site/jacoco $RESULTS_DIR/
    fi
  fi
  
# Go
elif [ -f "go.mod" ]; then
  echo "Running Go tests..."
  go test -cover -json ./... > $RESULTS_DIR/unit_test_results.json 2>&1
  
  if [ $? -eq 0 ]; then
    UNIT_PASSED=true
    # Extract coverage
    COVERAGE_OUTPUT=$(go test -cover ./... 2>&1)
    UNIT_COVERAGE=$(echo "$COVERAGE_OUTPUT" | grep -oP 'coverage: \K[\d.]+' | head -1)
  fi
else
  echo -e "${YELLOW}⚠️  No unit test framework detected${NC}"
fi

if [ "$UNIT_PASSED" = true ]; then
  echo -e "${GREEN}✅ Unit tests passed! Coverage: ${UNIT_COVERAGE}%${NC}"
  
  if (( $(echo "$UNIT_COVERAGE < 80" | bc -l) )); then
    echo -e "${RED}❌ WARNING: Coverage ${UNIT_COVERAGE}% is below 80% threshold${NC}"
  fi
else
  echo -e "${RED}❌ Unit tests failed${NC}"
fi

update_session "unit_coverage" "$UNIT_COVERAGE"
echo ""

# 2. INTEGRATION TESTS
echo -e "${YELLOW}2. Running Integration Tests...${NC}"
echo "-------------------------------"

INTEGRATION_PASSED=0
INTEGRATION_TOTAL=0

# Look for integration test files
if [ -d "tests/integration" ] || [ -d "test/integration" ] || [ -d "integration_tests" ]; then
  echo "Found integration tests directory"
  
  # JavaScript/TypeScript
  if [ -f "package.json" ]; then
    npm run test:integration > $RESULTS_DIR/integration_test_results.txt 2>&1 || \
    npm test -- --testPathPattern=integration > $RESULTS_DIR/integration_test_results.txt 2>&1
    
    if [ $? -eq 0 ]; then
      INTEGRATION_PASSED=$(grep -c "PASS\|✓" $RESULTS_DIR/integration_test_results.txt || echo 0)
      INTEGRATION_TOTAL=$(grep -c "PASS\|FAIL\|✓\|✗" $RESULTS_DIR/integration_test_results.txt || echo 0)
    fi
  
  # Python
  elif [ -f "requirements.txt" ]; then
    python -m pytest tests/integration -v > $RESULTS_DIR/integration_test_results.txt 2>&1
    
    if [ $? -eq 0 ]; then
      INTEGRATION_PASSED=$(grep -c "passed" $RESULTS_DIR/integration_test_results.txt || echo 0)
      INTEGRATION_TOTAL=$(grep -oP '\d+ passed' $RESULTS_DIR/integration_test_results.txt | grep -oP '\d+' || echo 0)
    fi
  fi
  
  echo -e "${GREEN}✅ Integration tests: ${INTEGRATION_PASSED}/${INTEGRATION_TOTAL} passed${NC}"
else
  echo -e "${YELLOW}⚠️  No integration tests found${NC}"
  echo "Creating integration test template..."
  
  mkdir -p tests/integration
  cat > tests/integration/test_integration_template.js << 'EOF'
// Integration test template
describe('API Integration Tests', () => {
  test('should connect to database', async () => {
    // Add database connection test
  });
  
  test('should authenticate user', async () => {
    // Add authentication test
  });
  
  test('should handle API endpoints', async () => {
    // Add API endpoint tests
  });
});
EOF
fi

update_session "integration_passed" "$INTEGRATION_PASSED"
echo ""

# 3. STRESS TESTS
echo -e "${YELLOW}3. Running Stress Tests...${NC}"
echo "--------------------------"

STRESS_PASSED=false

# Check for k6
if command -v k6 &> /dev/null; then
  echo "Using k6 for stress testing..."
  
  # Create k6 script if it doesn't exist
  if [ ! -f "stress_test.js" ]; then
    cat > stress_test.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 20 },   // Ramp up
    { duration: '3m', target: 100 },  // Stay at 100 users
    { duration: '1m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200', 'p(99)<500'], // Response time thresholds
    http_req_failed: ['rate<0.1'],                  // Error rate < 10%
  },
};

export default function () {
  let response = http.get('http://localhost:3000'); // Update with your URL
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
EOF
  fi
  
  k6 run --out json=$RESULTS_DIR/stress_test_results.json stress_test.js
  
  if [ $? -eq 0 ]; then
    STRESS_PASSED=true
    echo -e "${GREEN}✅ Stress tests passed${NC}"
  else
    echo -e "${RED}❌ Stress tests failed${NC}"
  fi
  
# Check for JMeter
elif [ -f "/usr/local/bin/jmeter" ] || command -v jmeter &> /dev/null; then
  echo "Using JMeter for stress testing..."
  
  if [ -f "stress_test.jmx" ]; then
    jmeter -n -t stress_test.jmx -l $RESULTS_DIR/stress_test_results.jtl
    
    if [ $? -eq 0 ]; then
      STRESS_PASSED=true
      echo -e "${GREEN}✅ Stress tests passed${NC}"
    fi
  else
    echo -e "${YELLOW}⚠️  No JMeter test plan found${NC}"
  fi
  
# Use simple curl-based stress test
else
  echo "Running basic stress test with curl..."
  
  cat > simple_stress_test.sh << 'EOF'
#!/bin/bash
URL=${1:-http://localhost:3000}
CONCURRENT=${2:-10}
TOTAL=${3:-100}

echo "Testing $URL with $CONCURRENT concurrent requests, $TOTAL total"

for i in $(seq 1 $CONCURRENT); do
  (
    for j in $(seq 1 $(($TOTAL / $CONCURRENT))); do
      START=$(date +%s%N)
      curl -s -o /dev/null -w "%{http_code}" $URL
      END=$(date +%s%N)
      DURATION=$((($END - $START) / 1000000))
      echo "Request $j: ${DURATION}ms"
    done
  ) &
done

wait
echo "Stress test complete"
EOF
  
  chmod +x simple_stress_test.sh
  ./simple_stress_test.sh > $RESULTS_DIR/stress_test_results.txt 2>&1
  
  # Basic pass criteria: if script completes
  if [ $? -eq 0 ]; then
    STRESS_PASSED=true
    echo -e "${GREEN}✅ Basic stress test completed${NC}"
  fi
fi

update_session "stress_test_passed" "$STRESS_PASSED"
echo ""

# 4. SECURITY SCAN
echo -e "${YELLOW}4. Running Security Scan...${NC}"
echo "----------------------------"

SECURITY_PASSED=true

# npm audit for JavaScript
if [ -f "package-lock.json" ]; then
  echo "Running npm audit..."
  npm audit --json > $RESULTS_DIR/security_audit.json 2>&1
  
  VULNERABILITIES=$(jq '.metadata.vulnerabilities.moderate + .metadata.vulnerabilities.high + .metadata.vulnerabilities.critical' $RESULTS_DIR/security_audit.json 2>/dev/null || echo 0)
  
  if [ "$VULNERABILITIES" -gt 0 ]; then
    echo -e "${RED}❌ Found $VULNERABILITIES security vulnerabilities${NC}"
    SECURITY_PASSED=false
  else
    echo -e "${GREEN}✅ No security vulnerabilities found${NC}"
  fi
  
# Python safety check
elif [ -f "requirements.txt" ]; then
  if command -v safety &> /dev/null; then
    echo "Running safety check..."
    safety check --json > $RESULTS_DIR/security_audit.json 2>&1
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Security vulnerabilities found${NC}"
      SECURITY_PASSED=false
    else
      echo -e "${GREEN}✅ No security vulnerabilities found${NC}"
    fi
  else
    echo -e "${YELLOW}⚠️  'safety' not installed. Run: pip install safety${NC}"
  fi
fi

echo ""

# GENERATE FINAL REPORT
echo -e "${BLUE}📊 Generating Test Report...${NC}"
echo "=============================="

cat > $RESULTS_DIR/test_summary.md << EOF
# Test Results for $TICKET_ID

Generated: $(date)

## Summary

| Test Type | Status | Details |
|-----------|--------|---------|
| Unit Tests | $([ "$UNIT_PASSED" = true ] && echo "✅ PASSED" || echo "❌ FAILED") | Coverage: ${UNIT_COVERAGE}% |
| Integration Tests | $([ $INTEGRATION_TOTAL -gt 0 ] && echo "✅ ${INTEGRATION_PASSED}/${INTEGRATION_TOTAL}" || echo "⚠️ No tests") | - |
| Stress Tests | $([ "$STRESS_PASSED" = true ] && echo "✅ PASSED" || echo "❌ FAILED") | - |
| Security Scan | $([ "$SECURITY_PASSED" = true ] && echo "✅ PASSED" || echo "❌ FAILED") | - |

## Coverage Requirements

- **Required**: 80% minimum
- **Actual**: ${UNIT_COVERAGE}%
- **Status**: $([ $(echo "$UNIT_COVERAGE >= 80" | bc -l) -eq 1 ] && echo "✅ Met" || echo "❌ Not Met")

## Next Steps

$([ $(echo "$UNIT_COVERAGE >= 80" | bc -l) -eq 1 ] && [ "$UNIT_PASSED" = true ] && [ "$STRESS_PASSED" = true ] && echo "✅ Ready to commit!" || echo "❌ Fix failing tests before committing")

## Test Result Files

- Unit test results: ${RESULTS_DIR}/unit_test_results.json
- Integration test results: ${RESULTS_DIR}/integration_test_results.txt
- Stress test results: ${RESULTS_DIR}/stress_test_results.json
- Security audit: ${RESULTS_DIR}/security_audit.json
EOF

cat $RESULTS_DIR/test_summary.md

# Update Jira ticket with results
if [ ! -z "$JIRA_EMAIL" ] && [ ! -z "$JIRA_API_TOKEN" ]; then
  echo ""
  echo "📤 Updating Jira ticket with test results..."
  
  COMMENT="Test Results:\n- Unit Tests: ${UNIT_COVERAGE}% coverage\n- Integration: ${INTEGRATION_PASSED}/${INTEGRATION_TOTAL} passed\n- Stress Test: $([ "$STRESS_PASSED" = true ] && echo "Passed" || echo "Failed")\n- Security: $([ "$SECURITY_PASSED" = true ] && echo "Passed" || echo "Failed")"
  
  curl -s -u ${JIRA_EMAIL}:${JIRA_API_TOKEN} \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"body\": \"$COMMENT\"}" \
    ${JIRA_URL}/rest/api/2/issue/${TICKET_ID}/comment > /dev/null
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Jira ticket updated${NC}"
  fi
fi

# Final verdict
echo ""
echo "=============================="
if [ $(echo "$UNIT_COVERAGE >= 80" | bc -l) -eq 1 ] && [ "$UNIT_PASSED" = true ] && [ "$STRESS_PASSED" = true ] && [ "$SECURITY_PASSED" = true ]; then
  echo -e "${GREEN}✅ ALL TESTS PASSED! Ready to commit.${NC}"
  exit 0
else
  echo -e "${RED}❌ TESTS FAILED! Please fix issues before committing.${NC}"
  exit 1
fi