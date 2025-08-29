#!/bin/bash
# AI_AGE_SDLC Framework Setup Script
# Version: 2.0
# Platform: Linux/MacOS
# Description: One-command setup for AI-driven software development lifecycle

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Framework info
FRAMEWORK_VERSION="2.0"
SETUP_DATE=$(date +%Y-%m-%d)

show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
    ___    ____       ___   ____  ______       _____ ____  __    ______
   /   |  /  _/      /   | / ___// ____/      / ___// __ \/ /   / ____/
  / /| |  / /       / /| |/ __ \/ __/         \__ \/ / / / /   / /     
 / ___ |_/ /       / ___ / /_/ / /___        ___/ / /_/ / /___/ /___   
/_/  |_/___/      /_/  |_\____/_____/       /____/_____/_____/\____/   
                                                                        
        FRAMEWORK SETUP - AI-Driven Age Software Development
        ====================================================
EOF
    echo -e "${NC}"
    echo -e "${GREEN}Version: ${FRAMEWORK_VERSION}${NC}"
    echo -e "${GREEN}Setup Date: ${SETUP_DATE}${NC}"
    echo -e "${GREEN}Platform: $(uname -s)${NC}"
    echo ""
}

# Check if we're in the right directory
validate_framework() {
    if [[ ! -f "setup_ai_age_sdlc.sh" ]]; then
        echo -e "${RED}ERROR: Must run from SDLC_FRAMEWORK directory${NC}"
        echo "Usage: cd SDLC_FRAMEWORK && ./setup_ai_age_sdlc.sh"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Framework directory validated${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    local missing_tools=()
    
    # Check required tools
    for tool in git curl jq; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    # Check for project-specific tools (optional)
    local optional_tools=()
    if ! command -v node &> /dev/null; then
        optional_tools+=("node (for Node.js/TypeScript projects)")
    fi
    if ! command -v python3 &> /dev/null; then
        optional_tools+=("python3 (for Python projects)")
    fi
    if ! command -v java &> /dev/null; then
        optional_tools+=("java (for Java projects)")
    fi
    if ! command -v terraform &> /dev/null; then
        optional_tools+=("terraform (for Terraform projects)")
    fi
    
    if [ ${#optional_tools[@]} -gt 0 ]; then
        echo -e "${YELLOW}ℹ️ Optional tools not found: ${optional_tools[*]}${NC}"
        echo -e "${YELLOW}Install as needed for your project type${NC}"
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install missing tools and run again."
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
}

# Get project information
get_project_info() {
    echo -e "${BLUE}📋 Project Setup Configuration${NC}"
    echo ""
    
    # Get project name
    while [[ -z "$PROJECT_NAME" ]]; do
        read -p "Enter project name (e.g., my-awesome-project): " PROJECT_NAME
        if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo -e "${RED}Project name should only contain letters, numbers, hyphens, and underscores${NC}"
            PROJECT_NAME=""
        fi
    done
    
    # Get project type
    echo ""
    echo "Select project type:"
    echo "1. Node.js/TypeScript"
    echo "2. Python"
    echo "3. Java (Maven/Gradle)"
    echo "4. Terraform (Infrastructure)"
    echo "5. Generic (any language)"
    echo ""
    read -p "Enter choice (1-5): " PROJECT_TYPE
    
    # Get development mode
    echo ""
    echo "Select development mode:"
    echo "1. NEW project (create from scratch)"
    echo "2. MODIFICATION project (enhance existing)"
    echo ""
    read -p "Enter choice (1-2): " DEV_MODE
    
    # Get optional information
    read -p "Enter Git repository URL (optional): " GIT_REPO_URL
    read -p "Enter your name for commits: " DEVELOPER_NAME
    read -p "Enter your email for commits: " DEVELOPER_EMAIL
    
    echo ""
    echo -e "${GREEN}✅ Project configuration collected${NC}"
}

# Collect and validate credentials
collect_credentials() {
    echo ""
    echo -e "${BLUE}🔐 Credential Configuration${NC}"
    echo -e "${YELLOW}These credentials are required for the AI_AGE_SDLC framework to function${NC}"
    echo ""
    
    # Jira credentials
    echo -e "${CYAN}📋 Jira Configuration:${NC}"
    read -p "Enter Jira URL (e.g., https://yourcompany.atlassian.net): " JIRA_URL
    read -p "Enter Jira email: " JIRA_EMAIL
    read -sp "Enter Jira API token (hidden): " JIRA_API_TOKEN
    echo ""
    
    # Confluence credentials
    echo ""
    echo -e "${CYAN}📚 Confluence Configuration:${NC}"
    read -p "Enter Confluence URL (press Enter to use Jira URL + /wiki): " CONFLUENCE_URL
    if [[ -z "$CONFLUENCE_URL" ]]; then
        CONFLUENCE_URL="${JIRA_URL}/wiki"
        echo "Using: $CONFLUENCE_URL"
    fi
    read -p "Enter Confluence email (press Enter to use Jira email): " CONFLUENCE_EMAIL
    if [[ -z "$CONFLUENCE_EMAIL" ]]; then
        CONFLUENCE_EMAIL="$JIRA_EMAIL"
        echo "Using: $CONFLUENCE_EMAIL"
    fi
    read -sp "Enter Confluence API token (press Enter to use Jira token): " CONFLUENCE_API_TOKEN
    echo ""
    if [[ -z "$CONFLUENCE_API_TOKEN" ]]; then
        CONFLUENCE_API_TOKEN="$JIRA_API_TOKEN"
        echo "Using same token as Jira"
    fi
    
    # GitHub credentials
    echo ""
    echo -e "${CYAN}🐙 GitHub Configuration:${NC}"
    read -p "Enter GitHub organization/username: " GITHUB_OWNER
    read -p "Enter GitHub repository name: " GITHUB_REPO
    read -sp "Enter GitHub personal access token (hidden): " GITHUB_TOKEN
    echo ""
    
    # Validate credentials
    echo ""
    echo -e "${YELLOW}🔍 Validating credentials...${NC}"
    
    # Test Jira connection
    echo -n "Testing Jira connection... "
    JIRA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        -X GET \
        "${JIRA_URL}/rest/api/2/myself" 2>/dev/null)
    
    if [[ "$JIRA_RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ Success${NC}"
    else
        echo -e "${RED}❌ Failed (HTTP $JIRA_RESPONSE)${NC}"
        echo -e "${YELLOW}Warning: Jira credentials may be incorrect. Continue anyway? (y/n)${NC}"
        read -p "" continue_anyway
        if [[ "$continue_anyway" != "y" ]]; then
            exit 1
        fi
    fi
    
    # Test GitHub connection (if token provided)
    if [[ -n "$GITHUB_TOKEN" ]]; then
        echo -n "Testing GitHub connection... "
        GITHUB_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: token ${GITHUB_TOKEN}" \
            "https://api.github.com/user" 2>/dev/null)
        
        if [[ "$GITHUB_RESPONSE" == "200" ]]; then
            echo -e "${GREEN}✅ Success${NC}"
        else
            echo -e "${RED}❌ Failed (HTTP $GITHUB_RESPONSE)${NC}"
            echo -e "${YELLOW}Warning: GitHub token may be incorrect${NC}"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}✅ Credential configuration complete${NC}"
}

# Create directory structure
create_directory_structure() {
    echo -e "${YELLOW}📁 Creating directory structure...${NC}"
    
    # Create standard directories
    mkdir -p {src,tests,docs,config,scripts,workflows,.github/workflows}
    
    # Create project-specific directories based on type
    case $PROJECT_TYPE in
        1) # Node.js/TypeScript
            mkdir -p {src/components,src/utils,tests/unit,tests/integration}
            ;;
        2) # Python
            mkdir -p {src/${PROJECT_NAME},tests/unit,tests/integration,requirements}
            ;;
        3) # Java
            mkdir -p {src/main/java/com/${PROJECT_NAME//-//},src/main/resources,src/test/java/com/${PROJECT_NAME//-//},target}
            ;;
        4) # Terraform
            mkdir -p {modules,environments/{dev,staging,prod},scripts}
            ;;
        5) # Generic
            mkdir -p {src/main,tests/unit}
            ;;
    esac
    
    echo -e "${GREEN}✅ Directory structure created${NC}"
}

# Deploy core SDLC files
deploy_core_files() {
    echo -e "${YELLOW}📦 Deploying AI_AGE_SDLC core files...${NC}"
    
    # Copy core SDLC files
    cp core/CLAUDE.md .
    cp core/CLAUDE_AI_AGE_SDLC.md docs/
    
    # Copy and make executable the master script
    cp scripts/ai_age_sdlc_master.sh .
    chmod +x scripts/ai_age_sdlc_master.sh
    
    # Copy configuration files
    cp -r config/* config/ 2>/dev/null || true
    
    # Copy documentation
    cp -r docs/* docs/ 2>/dev/null || true
    
    echo -e "${GREEN}✅ Core SDLC files deployed${NC}"
}

# Create project templates
create_project_templates() {
    echo -e "${YELLOW}📄 Creating project templates...${NC}"
    
    case $PROJECT_TYPE in
        1) # Node.js/TypeScript
            create_nodejs_template
            ;;
        2) # Python
            create_python_template
            ;;
        3) # Java
            create_java_template
            ;;
        4) # Terraform
            create_terraform_template
            ;;
        5) # Generic
            create_generic_template
            ;;
    esac
    
    echo -e "${GREEN}✅ Project templates created${NC}"
}

create_nodejs_template() {
    # package.json
    cat > package.json << EOF
{
  "name": "${PROJECT_NAME}",
  "version": "1.0.0",
  "description": "AI_AGE_SDLC enabled Node.js project",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest --coverage",
    "test:watch": "jest --watch",
    "test:integration": "jest tests/integration",
    "lint": "eslint src/ tests/",
    "typecheck": "tsc --noEmit",
    "build": "tsc",
    "ai-sdlc": "./scripts/ai_age_sdlc_master.sh"
  },
  "keywords": ["ai-sdlc", "automation"],
  "author": "${DEVELOPER_NAME} <${DEVELOPER_EMAIL}>",
  "license": "MIT",
  "devDependencies": {
    "jest": "^29.0.0",
    "nodemon": "^3.0.0",
    "eslint": "^8.0.0",
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0"
  },
  "jest": {
    "coverageThreshold": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
EOF

    # tsconfig.json
    cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
EOF

    # Basic TypeScript files
    cat > src/index.ts << EOF
// ${PROJECT_NAME} - AI_AGE_SDLC Enabled Project
// Generated on: ${SETUP_DATE}

export class ${PROJECT_NAME^} {
    private name: string;

    constructor(name: string = "${PROJECT_NAME}") {
        this.name = name;
    }

    public greet(): string {
        return \`Hello from \${this.name}! AI_AGE_SDLC is active.\`;
    }
}

// Main execution
if (require.main === module) {
    const app = new ${PROJECT_NAME^}();
    console.log(app.greet());
}
EOF

    cat > tests/unit/index.test.ts << EOF
import { ${PROJECT_NAME^} } from '../../src/index';

describe('${PROJECT_NAME^}', () => {
    let app: ${PROJECT_NAME^};

    beforeEach(() => {
        app = new ${PROJECT_NAME^}();
    });

    test('should create instance', () => {
        expect(app).toBeInstanceOf(${PROJECT_NAME^});
    });

    test('should greet correctly', () => {
        const greeting = app.greet();
        expect(greeting).toContain('${PROJECT_NAME}');
        expect(greeting).toContain('AI_AGE_SDLC');
    });
});
EOF
}

create_python_template() {
    # requirements.txt
    cat > requirements.txt << EOF
# AI_AGE_SDLC Python Project Dependencies
pytest>=7.0.0
pytest-cov>=4.0.0
black>=23.0.0
flake8>=6.0.0
mypy>=1.0.0
EOF

    # setup.py
    cat > setup.py << EOF
from setuptools import setup, find_packages

setup(
    name="${PROJECT_NAME}",
    version="1.0.0",
    description="AI_AGE_SDLC enabled Python project",
    author="${DEVELOPER_NAME}",
    author_email="${DEVELOPER_EMAIL}",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    install_requires=[],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "black>=23.0.0",
            "flake8>=6.0.0",
            "mypy>=1.0.0",
        ]
    },
    python_requires=">=3.8",
)
EOF

    # Main Python module
    mkdir -p src/${PROJECT_NAME}
    cat > src/${PROJECT_NAME}/__init__.py << EOF
"""
${PROJECT_NAME} - AI_AGE_SDLC Enabled Python Project
Generated on: ${SETUP_DATE}
"""

__version__ = "1.0.0"

class ${PROJECT_NAME^}:
    """Main application class."""
    
    def __init__(self, name: str = "${PROJECT_NAME}"):
        self.name = name
    
    def greet(self) -> str:
        """Return a greeting message."""
        return f"Hello from {self.name}! AI_AGE_SDLC is active."

def main():
    """Main entry point."""
    app = ${PROJECT_NAME^}()
    print(app.greet())

if __name__ == "__main__":
    main()
EOF

    cat > tests/unit/test_${PROJECT_NAME}.py << EOF
"""Unit tests for ${PROJECT_NAME}."""

import pytest
from ${PROJECT_NAME} import ${PROJECT_NAME^}

class Test${PROJECT_NAME^}:
    """Test cases for ${PROJECT_NAME^} class."""
    
    def test_create_instance(self):
        """Test instance creation."""
        app = ${PROJECT_NAME^}()
        assert isinstance(app, ${PROJECT_NAME^})
    
    def test_greet(self):
        """Test greeting functionality."""
        app = ${PROJECT_NAME^}()
        greeting = app.greet()
        assert "${PROJECT_NAME}" in greeting
        assert "AI_AGE_SDLC" in greeting
EOF

    # pytest.ini
    cat > pytest.ini << EOF
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    --cov=src
    --cov-report=term-missing
    --cov-report=html
    --cov-fail-under=80
EOF
}

create_java_template() {
    # pom.xml for Maven
    cat > pom.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.aiagesdlc</groupId>
    <artifactId>${PROJECT_NAME}</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <name>${PROJECT_NAME}</name>
    <description>AI_AGE_SDLC enabled Java project</description>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <junit.version>5.9.2</junit.version>
        <jacoco.version>0.8.8</jacoco.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>\${junit.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
            </plugin>
            
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.0.0</version>
            </plugin>
            
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>\${jacoco.version}</version>
                <configuration>
                    <rules>
                        <rule>
                            <element>CLASS</element>
                            <limits>
                                <limit>
                                    <counter>LINE</counter>
                                    <value>COVEREDRATIO</value>
                                    <minimum>0.80</minimum>
                                </limit>
                            </limits>
                        </rule>
                    </rules>
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>prepare-agent</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>report</id>
                        <phase>test</phase>
                        <goals>
                            <goal>report</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>check</id>
                        <phase>test</phase>
                        <goals>
                            <goal>check</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
EOF

    # Main Java class
    JAVA_PACKAGE_PATH="src/main/java/com/${PROJECT_NAME//-//}"
    JAVA_CLASS_NAME="${PROJECT_NAME^}"
    JAVA_CLASS_NAME="${JAVA_CLASS_NAME//-/}"
    
    cat > ${JAVA_PACKAGE_PATH}/Application.java << EOF
package com.${PROJECT_NAME//-/.};

/**
 * ${PROJECT_NAME} - AI_AGE_SDLC Enabled Application
 * Generated by AI_AGE_SDLC Framework v2.0
 */
public class Application {
    
    private String projectName;
    
    public Application() {
        this.projectName = "${PROJECT_NAME}";
    }
    
    /**
     * Get greeting message
     * @return Greeting string
     */
    public String getGreeting() {
        return "Hello from " + projectName + " - AI_AGE_SDLC enabled!";
    }
    
    /**
     * Process data with validation
     * @param input Input data
     * @return Processed data
     */
    public String processData(String input) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException("Input cannot be null or empty");
        }
        return "Processed: " + input.trim();
    }
    
    public static void main(String[] args) {
        Application app = new Application();
        System.out.println(app.getGreeting());
        
        if (args.length > 0) {
            System.out.println(app.processData(String.join(" ", args)));
        }
    }
}
EOF

    # Test class
    JAVA_TEST_PATH="src/test/java/com/${PROJECT_NAME//-//}"
    cat > ${JAVA_TEST_PATH}/ApplicationTest.java << EOF
package com.${PROJECT_NAME//-/.};

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Test suite for Application class
 * Ensures 80% code coverage requirement
 */
class ApplicationTest {
    
    private Application application;
    
    @BeforeEach
    void setUp() {
        application = new Application();
    }
    
    @Test
    @DisplayName("Should return greeting message")
    void shouldReturnGreeting() {
        String greeting = application.getGreeting();
        assertNotNull(greeting);
        assertTrue(greeting.contains("${PROJECT_NAME}"));
        assertTrue(greeting.contains("AI_AGE_SDLC"));
    }
    
    @Test
    @DisplayName("Should process valid input data")
    void shouldProcessValidInput() {
        String result = application.processData("test data");
        assertEquals("Processed: test data", result);
    }
    
    @Test
    @DisplayName("Should trim whitespace from input")
    void shouldTrimWhitespace() {
        String result = application.processData("  test data  ");
        assertEquals("Processed: test data", result);
    }
    
    @Test
    @DisplayName("Should throw exception for null input")
    void shouldThrowExceptionForNullInput() {
        assertThrows(IllegalArgumentException.class, () -> {
            application.processData(null);
        });
    }
    
    @Test
    @DisplayName("Should throw exception for empty input")
    void shouldThrowExceptionForEmptyInput() {
        assertThrows(IllegalArgumentException.class, () -> {
            application.processData("");
        });
    }
    
    @Test
    @DisplayName("Should throw exception for whitespace-only input")
    void shouldThrowExceptionForWhitespaceInput() {
        assertThrows(IllegalArgumentException.class, () -> {
            application.processData("   ");
        });
    }
}
EOF
}

create_terraform_template() {
    # main.tf
    cat > main.tf << EOF
# ${PROJECT_NAME} - AI_AGE_SDLC Enabled Terraform Infrastructure
# Generated by AI_AGE_SDLC Framework v2.0

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "${PROJECT_NAME}/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "${PROJECT_NAME}"
      Environment = var.environment
      ManagedBy   = "AI_AGE_SDLC"
      CreatedBy   = "${DEVELOPER_NAME}"
    }
  }
}

# Example resource - customize based on your needs
resource "aws_s3_bucket" "example" {
  bucket = "\${var.project_name}-\${var.environment}-\${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
EOF

    # variables.tf
    cat > variables.tf << EOF
# Variable definitions for ${PROJECT_NAME}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "${PROJECT_NAME}"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+\$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
EOF

    # outputs.tf
    cat > outputs.tf << EOF
# Outputs for ${PROJECT_NAME}

output "project_name" {
  description = "Name of the project"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.example.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.example.arn
}
EOF

    # Environment-specific configuration files
    for env in dev staging prod; do
        cat > environments/\${env}/terraform.tfvars << EOF
# Environment-specific variables for \${env}
environment = "\${env}"
project_name = "${PROJECT_NAME}"
aws_region = "us-west-2"

tags = {
  Environment = "\${env}"
  Team        = "DevOps"
  CostCenter  = "Engineering"
}
EOF
    done

    # Terraform module example
    cat > modules/example/main.tf << EOF
# Example reusable module
variable "name" {
  description = "Resource name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

output "resource_id" {
  description = "Resource identifier"
  value       = "example-\${var.name}-\${var.environment}"
}
EOF

    # Testing script
    cat > scripts/terraform-test.sh << 'EOF'
#!/bin/bash
# Terraform validation and testing script

set -e

echo "🔍 Validating Terraform configuration..."

# Format check
echo "Checking Terraform formatting..."
terraform fmt -check=true -recursive

# Validation
echo "Validating Terraform configuration..."
terraform validate

# Security scan (if tfsec is available)
if command -v tfsec &> /dev/null; then
    echo "Running security scan..."
    tfsec .
fi

# Plan validation
echo "Checking Terraform plan..."
terraform plan -out=tfplan

echo "✅ All Terraform validations passed!"
EOF
    chmod +x scripts/terraform-test.sh
}

create_generic_template() {
    # Basic README
    cat > src/main.txt << EOF
# ${PROJECT_NAME} - AI_AGE_SDLC Enabled Project
# Generated on: ${SETUP_DATE}
# 
# This is a generic project template.
# Customize based on your programming language and requirements.
EOF

    cat > tests/unit/basic_test.txt << EOF
# Basic test template for ${PROJECT_NAME}
# Customize based on your testing framework
EOF
}

# Create environment template
create_environment_config() {
    echo -e "${YELLOW}🔧 Creating environment configuration...${NC}"
    
    # Create .env.template with placeholder values
    cat > .env.template << EOF
# AI_AGE_SDLC Environment Configuration
# Copy to .env and fill in your actual values

# Jira Configuration
JIRA_URL=https://your-domain.atlassian.net
JIRA_EMAIL=your-email@company.com
JIRA_API_TOKEN=your-jira-api-token

# Confluence Configuration
CONFLUENCE_URL=https://your-domain.atlassian.net/wiki
CONFLUENCE_EMAIL=your-email@company.com
CONFLUENCE_API_TOKEN=your-confluence-api-token

# GitHub Configuration
GITHUB_OWNER=your-github-org
GITHUB_REPO=${PROJECT_NAME}
GITHUB_TOKEN=your-github-token

# SDLC Configuration
MIN_TEST_COVERAGE=80
MAX_RESPONSE_TIME_MS=200
STRESS_TEST_USERS=100
STRESS_TEST_DURATION=5m
AUTO_COMMIT_ON_SUCCESS=true
AUTO_PUSH_ON_SUCCESS=false

# Project Configuration
PROJECT_NAME=${PROJECT_NAME}
DEVELOPER_NAME=${DEVELOPER_NAME}
DEVELOPER_EMAIL=${DEVELOPER_EMAIL}
EOF

    # Create actual .env file with collected credentials if they were provided
    if [[ -n "$JIRA_URL" ]]; then
        echo -e "${YELLOW}📝 Creating .env file with provided credentials...${NC}"
        cat > .env << EOF
# AI_AGE_SDLC Environment Configuration
# Generated on $(date)

# Jira Configuration
JIRA_URL=${JIRA_URL}
JIRA_EMAIL=${JIRA_EMAIL}
JIRA_API_TOKEN=${JIRA_API_TOKEN}

# Confluence Configuration
CONFLUENCE_URL=${CONFLUENCE_URL}
CONFLUENCE_EMAIL=${CONFLUENCE_EMAIL}
CONFLUENCE_API_TOKEN=${CONFLUENCE_API_TOKEN}

# GitHub Configuration
GITHUB_OWNER=${GITHUB_OWNER}
GITHUB_REPO=${GITHUB_REPO}
GITHUB_TOKEN=${GITHUB_TOKEN}

# SDLC Configuration
MIN_TEST_COVERAGE=80
MAX_RESPONSE_TIME_MS=200
STRESS_TEST_USERS=100
STRESS_TEST_DURATION=5m
AUTO_COMMIT_ON_SUCCESS=true
AUTO_PUSH_ON_SUCCESS=false

# Project Configuration
PROJECT_NAME=${PROJECT_NAME}
DEVELOPER_NAME=${DEVELOPER_NAME}
DEVELOPER_EMAIL=${DEVELOPER_EMAIL}
EOF
        chmod 600 .env  # Secure the file
        echo -e "${GREEN}✅ .env file created with your credentials (secured with 600 permissions)${NC}"
    fi

    echo -e "${GREEN}✅ Environment configuration created${NC}"
}

# Initialize git repository
initialize_git() {
    if [[ "$DEV_MODE" == "1" ]]; then  # NEW project
        echo -e "${YELLOW}📋 Initializing Git repository...${NC}"
        
        git init
        git branch -m main
        git checkout -b develop
        
        # Create .gitignore
        cat > .gitignore << EOF
# AI_AGE_SDLC .gitignore
.env
node_modules/
dist/
build/
*.log
.DS_Store
__pycache__/
*.pyc
.pytest_cache/
coverage/
.coverage
*.egg-info/
.venv/
venv/
.mypy_cache/
*.bak
*.tmp
EOF

        # Add remote if provided
        if [[ -n "$GIT_REPO_URL" ]]; then
            git remote add origin "$GIT_REPO_URL"
        fi
        
        echo -e "${GREEN}✅ Git repository initialized${NC}"
    fi
}

# Create project documentation
create_project_docs() {
    echo -e "${YELLOW}📚 Creating project documentation...${NC}"
    
    cat > README.md << EOF
# ${PROJECT_NAME}

AI_AGE_SDLC Enabled Project - Complete automation from ticket to production.

## 🚀 Quick Start

### Prerequisites
- Git, curl, jq installed
- Node.js (for Node projects) or Python 3.8+ (for Python projects)
- Jira and Confluence access
- GitHub repository

### Setup
1. Configure environment:
   \`\`\`bash
   cp .env.template .env
   # Edit .env with your credentials
   \`\`\`

2. Start AI_AGE_SDLC:
   \`\`\`bash
   ./scripts/ai_age_sdlc_master.sh
   \`\`\`

## 🎯 AI_AGE_SDLC Features

- **Full Repository Management** (NEW/MODIFICATION projects)
- **Intelligent Branch Stacking** on develop baseline
- **Automated Testing Orchestration** (unit, integration, stress, security)
- **Self-Healing Workflows** with error recovery
- **Complete Traceability** from Jira to production

## 📁 Project Structure

\`\`\`
${PROJECT_NAME}/
├── CLAUDE.md                    # Claude Code configuration
├── src/                         # Source code
├── tests/                       # Test suites
├── docs/                        # Documentation
│   └── CLAUDE_AI_AGE_SDLC.md   # Complete SDLC framework
├── scripts/                     # Automation scripts
│   └── ai_age_sdlc_master.sh   # Main orchestrator
└── config/                      # Configuration files
\`\`\`

## 🛠️ Development Workflow

1. **Start with Jira ticket**: Get ticket ID (e.g., PROJ-123)
2. **Run AI_AGE_SDLC**: \`./scripts/ai_age_sdlc_master.sh\`
3. **Select mode**: Choose full automation or step-by-step
4. **Develop**: Claude Code will enforce all requirements
5. **Automatic validation**: Tests, coverage, security checks
6. **Automatic commit/push**: When all validations pass

## 🔒 Enforcement Rules

1. **No code without Jira ticket**
2. **No Jira ticket without Confluence specification**
3. **No commit without 80% test coverage**
4. **No modification outside authorized files**
5. **No push without stress test validation**

## 📊 Metrics

- Test Coverage: ≥80%
- Response Time: <200ms
- Security Issues: 0
- Code Quality: A+

---

**Generated by AI_AGE_SDLC Framework v${FRAMEWORK_VERSION}**
**Setup Date**: ${SETUP_DATE}
**Developer**: ${DEVELOPER_NAME} <${DEVELOPER_EMAIL}>
EOF

    echo -e "${GREEN}✅ Project documentation created${NC}"
}

# Create startup script
create_startup_script() {
    echo -e "${YELLOW}🚀 Creating startup script...${NC}"
    
    cat > start_ai_sdlc.sh << 'EOF'
#!/bin/bash
# AI_AGE_SDLC Project Startup Script

echo "🚀 Starting AI_AGE_SDLC for this project..."

# Check if environment is configured
if [[ ! -f ".env" ]]; then
    echo "⚠️ Environment not configured. Copying template..."
    cp .env.template .env
    echo "📝 Please edit .env with your credentials, then run this script again."
    exit 1
fi

# Start the main SDLC orchestrator
exec ./scripts/ai_age_sdlc_master.sh
EOF

    chmod +x start_ai_sdlc.sh
    
    echo -e "${GREEN}✅ Startup script created${NC}"
}

# Final setup and validation
finalize_setup() {
    echo -e "${YELLOW}🔍 Finalizing setup...${NC}"
    
    # Create initial commit for NEW projects
    if [[ "$DEV_MODE" == "1" ]]; then
        git add -A
        git commit -m "Initial commit: AI_AGE_SDLC project setup

Project: ${PROJECT_NAME}
Type: $(case $PROJECT_TYPE in 1) echo "Node.js/TypeScript";; 2) echo "Python";; 3) echo "Generic";; esac)
Setup Date: ${SETUP_DATE}
Framework Version: ${FRAMEWORK_VERSION}

✅ AI_AGE_SDLC Framework initialized
✅ Project structure created  
✅ Templates configured
✅ Documentation generated

🤖 Generated with AI_AGE_SDLC Framework v${FRAMEWORK_VERSION}

Co-authored-by: AI_AGE_SDLC <ai@sdlc.com>"
    fi
    
    # Remove the SDLC_FRAMEWORK directory
    rm -rf SDLC_FRAMEWORK/
    
    echo -e "${GREEN}✅ Setup finalized${NC}"
}

# Show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}🎉 AI_AGE_SDLC Setup Complete!${NC}"
    echo ""
    echo -e "${BLUE}📋 Project Details:${NC}"
    echo -e "   Name: ${PROJECT_NAME}"
    echo -e "   Type: $(case $PROJECT_TYPE in 1) echo "Node.js/TypeScript";; 2) echo "Python";; 3) echo "Java";; 4) echo "Terraform";; 5) echo "Generic";; esac)"
    echo -e "   Mode: $(case $DEV_MODE in 1) echo "NEW Project";; 2) echo "MODIFICATION Project";; esac)"
    echo -e "   Framework Version: ${FRAMEWORK_VERSION}"
    echo ""
    echo -e "${RED}🚫 CRITICAL: AI_AGE_SDLC IS 100% ENFORCED 🚫${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}ZERO TOLERANCE • NO EXCEPTIONS • NO BYPASSES${NC}"
    echo -e "${CYAN}CLAUDE.md IS the SDLC framework - NOT the shell scripts!${NC}"
    echo -e ""
    echo -e "When you use Claude Code, it will:"
    echo -e "  1. ${GREEN}✓${NC} Automatically read CLAUDE.md"
    echo -e "  2. ${GREEN}✓${NC} Enforce all SDLC rules and policies"
    echo -e "  3. ${GREEN}✓${NC} Require Jira tickets before coding"
    echo -e "  4. ${GREEN}✓${NC} Mandate 80% test coverage"
    echo -e "  5. ${GREEN}✓${NC} Control your entire development workflow"
    echo -e ""
    echo -e "The shell scripts are ONLY for initial setup!"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}🚀 How to Start Development:${NC}"
    echo -e "1. Open your project in Claude Code"
    echo -e "2. CLAUDE.md will be automatically loaded"
    echo -e "3. Start coding - Claude enforces all rules!"
    echo ""
    echo -e "${PURPLE}📚 Key Documentation:${NC}"
    echo -e "   - ${RED}CLAUDE.md${NC} - THE ACTUAL SDLC FRAMEWORK (Claude reads this!)"
    echo -e "   - HOW_IT_WORKS.md - Explains the architecture"
    echo -e "   - docs/CLAUDE_AI_AGE_SDLC.md - Extended documentation"
    echo ""
    if [[ -n "$JIRA_URL" ]]; then
        echo -e "${GREEN}✅ Credentials configured - ready for SDLC enforcement!${NC}"
    else
        echo -e "${YELLOW}⚠️  Remember to configure .env with your credentials${NC}"
    fi
    echo ""
    echo -e "${GREEN}The SDLC is now enforced through CLAUDE.md! 🤖✨${NC}"
}

# Main execution
main() {
    show_banner
    validate_framework
    check_prerequisites
    get_project_info
    collect_credentials
    
    echo ""
    echo -e "${BLUE}🔧 Setting up AI_AGE_SDLC project: ${PROJECT_NAME}${NC}"
    echo ""
    
    create_directory_structure
    deploy_core_files
    create_project_templates
    create_environment_config
    initialize_git
    create_project_docs
    create_startup_script
    finalize_setup
    show_completion
}

# Run main function
main "$@"