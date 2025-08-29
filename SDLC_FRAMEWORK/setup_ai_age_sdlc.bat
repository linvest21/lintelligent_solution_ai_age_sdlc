@echo off
REM AI_AGE_SDLC Framework Setup Script
REM Version: 2.0
REM Platform: Windows
REM Description: One-command setup for AI-driven software development lifecycle

setlocal EnableDelayedExpansion

REM Framework info
set FRAMEWORK_VERSION=2.0
set SETUP_DATE=%date%

REM Colors for Windows (limited)
REM Using echo for output since Windows has limited color support in batch

echo.
echo ===============================================================================
echo     ___    ____       ___   ____  ______       _____ ____  __    ______
echo    /   ^|  /  _/      /   ^| / ___// ____/      / ___// __ \/ /   / ____/
echo   / /^| ^|  / /       / /^| ^|/ __ \/ __/         \__ \/ / / / /   / /     
echo  / ___ ^|_/ /       / ___ / /_/ / /___        ___/ / /_/ / /___/ /___   
echo /_/  ^|_/___/      /_/  ^|_\____/_____/       /____/_____/_____/\____/   
echo.
echo         FRAMEWORK SETUP - AI-Driven Age Software Development
echo         ====================================================
echo.
echo Version: %FRAMEWORK_VERSION%
echo Setup Date: %SETUP_DATE%
echo Platform: Windows
echo.

REM Check if we're in the right directory
if not exist "setup_ai_age_sdlc.bat" (
    echo ERROR: Must run from SDLC_FRAMEWORK directory
    echo Usage: cd SDLC_FRAMEWORK ^&^& setup_ai_age_sdlc.bat
    pause
    exit /b 1
)

echo [OK] Framework directory validated

REM Check prerequisites
echo.
echo Checking prerequisites...

where git >nul 2>nul
if errorlevel 1 (
    echo ERROR: Git is not installed or not in PATH
    echo Please install Git and try again
    pause
    exit /b 1
)

where curl >nul 2>nul
if errorlevel 1 (
    echo WARNING: curl not found. Some features may not work.
)

REM Check for Java if Java project
if "%PROJECT_TYPE%"=="3" (
    where java >nul 2>nul
    if errorlevel 1 (
        echo WARNING: Java not found. Install JDK 11+ for Java projects.
    )
    where mvn >nul 2>nul
    if errorlevel 1 (
        echo WARNING: Maven not found. Install Maven for Java projects.
    )
)

REM Check for Terraform if Terraform project
if "%PROJECT_TYPE%"=="4" (
    where terraform >nul 2>nul
    if errorlevel 1 (
        echo WARNING: Terraform not found. Install Terraform CLI.
    )
)

echo [OK] Prerequisites checked

REM Get project information
echo.
echo Project Setup Configuration
echo ==========================

set /p PROJECT_NAME="Enter project name (e.g., my-awesome-project): "
if "%PROJECT_NAME%"=="" (
    echo ERROR: Project name cannot be empty
    pause
    exit /b 1
)

echo.
echo Select project type:
echo 1. Node.js/TypeScript
echo 2. Python
echo 3. Java (Maven/Gradle)
echo 4. Terraform (Infrastructure)
echo 5. Generic (any language)
echo.
set /p PROJECT_TYPE="Enter choice (1-5): "

echo.
echo Select development mode:
echo 1. NEW project (create from scratch)
echo 2. MODIFICATION project (enhance existing)
echo.
set /p DEV_MODE="Enter choice (1-2): "

set /p GIT_REPO_URL="Enter Git repository URL (optional): "
set /p DEVELOPER_NAME="Enter your name for commits: "
set /p DEVELOPER_EMAIL="Enter your email for commits: "

echo.
echo [OK] Project configuration collected

REM Create directory structure
echo.
echo Creating directory structure...

md src tests docs config scripts workflows .github\workflows 2>nul

REM Create project-specific directories
if "%PROJECT_TYPE%"=="1" (
    md src\components src\utils tests\unit tests\integration 2>nul
)
if "%PROJECT_TYPE%"=="2" (
    md "src\%PROJECT_NAME%" tests\unit tests\integration requirements 2>nul
)
if "%PROJECT_TYPE%"=="3" (
    md src\main\java\com\%PROJECT_NAME% src\main\resources src\test\java\com\%PROJECT_NAME% target 2>nul
)
if "%PROJECT_TYPE%"=="4" (
    md modules environments\dev environments\staging environments\prod 2>nul
)
if "%PROJECT_TYPE%"=="5" (
    md src\main tests\unit 2>nul
)

echo [OK] Directory structure created

REM Deploy core SDLC files
echo.
echo Deploying AI_AGE_SDLC core files...

copy "SDLC_FRAMEWORK\core\CLAUDE.md" "." >nul
copy "SDLC_FRAMEWORK\core\CLAUDE_AI_AGE_SDLC.md" "docs\" >nul
copy "SDLC_FRAMEWORK\scripts\ai_age_sdlc_master.sh" "scripts\" >nul

REM Copy configuration and docs
xcopy "SDLC_FRAMEWORK\config\*" "config\" /s /q 2>nul
xcopy "SDLC_FRAMEWORK\docs\*" "docs\" /s /q 2>nul

echo [OK] Core SDLC files deployed

REM Create project templates
echo.
echo Creating project templates...

if "%PROJECT_TYPE%"=="1" call :create_nodejs_template
if "%PROJECT_TYPE%"=="2" call :create_python_template
if "%PROJECT_TYPE%"=="3" call :create_java_template
if "%PROJECT_TYPE%"=="4" call :create_terraform_template
if "%PROJECT_TYPE%"=="5" call :create_generic_template

echo [OK] Project templates created

REM Create environment template
echo.
echo Creating environment configuration...

(
echo # AI_AGE_SDLC Environment Configuration
echo # Copy to .env and fill in your actual values
echo.
echo # Jira Configuration
echo JIRA_URL=https://your-domain.atlassian.net
echo JIRA_EMAIL=your-email@company.com
echo JIRA_API_TOKEN=your-jira-api-token
echo.
echo # Confluence Configuration
echo CONFLUENCE_URL=https://your-domain.atlassian.net/wiki
echo CONFLUENCE_EMAIL=your-email@company.com
echo CONFLUENCE_API_TOKEN=your-confluence-api-token
echo.
echo # GitHub Configuration
echo GITHUB_OWNER=your-github-org
echo GITHUB_REPO=%PROJECT_NAME%
echo GITHUB_TOKEN=your-github-token
echo.
echo # SDLC Configuration
echo MIN_TEST_COVERAGE=80
echo MAX_RESPONSE_TIME_MS=200
echo STRESS_TEST_USERS=100
echo STRESS_TEST_DURATION=5m
echo AUTO_COMMIT_ON_SUCCESS=true
echo AUTO_PUSH_ON_SUCCESS=false
echo.
echo # Project Configuration
echo PROJECT_NAME=%PROJECT_NAME%
echo DEVELOPER_NAME=%DEVELOPER_NAME%
echo DEVELOPER_EMAIL=%DEVELOPER_EMAIL%
) > .env.template

echo [OK] Environment configuration created

REM Initialize git repository (for NEW projects)
if "%DEV_MODE%"=="1" (
    echo.
    echo Initializing Git repository...
    
    git init >nul
    git branch -m main >nul
    git checkout -b develop >nul
    
    REM Create .gitignore
    (
    echo # AI_AGE_SDLC .gitignore
    echo .env
    echo node_modules/
    echo dist/
    echo build/
    echo *.log
    echo __pycache__/
    echo *.pyc
    echo .pytest_cache/
    echo coverage/
    echo .coverage
    echo *.egg-info/
    echo .venv/
    echo venv/
    echo .mypy_cache/
    echo *.bak
    echo *.tmp
    ) > .gitignore
    
    if not "%GIT_REPO_URL%"=="" (
        git remote add origin "%GIT_REPO_URL%" >nul
    )
    
    echo [OK] Git repository initialized
)

REM Create project documentation
echo.
echo Creating project documentation...

(
echo # %PROJECT_NAME%
echo.
echo AI_AGE_SDLC Enabled Project - Complete automation from ticket to production.
echo.
echo ## Quick Start
echo.
echo ### Prerequisites
echo - Git, curl installed
echo - Node.js (for Node projects^) or Python 3.8+ (for Python projects^)
echo - Jira and Confluence access
echo - GitHub repository
echo.
echo ### Setup
echo 1. Configure environment:
echo    ```
echo    copy .env.template .env
echo    REM Edit .env with your credentials
echo    ```
echo.
echo 2. Start AI_AGE_SDLC:
echo    ```
echo    start_ai_sdlc.bat
echo    ```
echo.
echo ## AI_AGE_SDLC Features
echo.
echo - **Full Repository Management** (NEW/MODIFICATION projects^)
echo - **Intelligent Branch Stacking** on develop baseline
echo - **Automated Testing Orchestration** (unit, integration, stress, security^)
echo - **Self-Healing Workflows** with error recovery
echo - **Complete Traceability** from Jira to production
echo.
echo Generated by AI_AGE_SDLC Framework v%FRAMEWORK_VERSION%
echo Setup Date: %SETUP_DATE%
echo Developer: %DEVELOPER_NAME% ^<%DEVELOPER_EMAIL%^>
) > README.md

echo [OK] Project documentation created

REM Create startup script for Windows
echo.
echo Creating startup script...

(
echo @echo off
echo echo Starting AI_AGE_SDLC for this project...
echo.
echo if not exist ".env" (
echo     echo Environment not configured. Copying template...
echo     copy .env.template .env
echo     echo Please edit .env with your credentials, then run this script again.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo REM Start the main SDLC orchestrator
echo echo For full functionality, use Git Bash or WSL to run:
echo echo ./scripts/ai_age_sdlc_master.sh
echo echo.
echo echo Opening configuration files...
echo notepad .env
echo pause
) > start_ai_sdlc.bat

echo [OK] Startup script created

REM Finalize setup
echo.
echo Finalizing setup...

REM Create initial commit for NEW projects
if "%DEV_MODE%"=="1" (
    git add -A >nul
    git commit -m "Initial commit: AI_AGE_SDLC project setup" >nul
)

REM Remove the SDLC_FRAMEWORK directory
rd /s /q SDLC_FRAMEWORK 2>nul

echo [OK] Setup finalized

REM Show completion message
echo.
echo ===============================================================================
echo                    AI_AGE_SDLC Setup Complete!
echo ===============================================================================
echo.
echo Project Details:
echo    Name: %PROJECT_NAME%
if "%PROJECT_TYPE%"=="1" echo    Type: Node.js/TypeScript
if "%PROJECT_TYPE%"=="2" echo    Type: Python
if "%PROJECT_TYPE%"=="3" echo    Type: Java
if "%PROJECT_TYPE%"=="4" echo    Type: Terraform
if "%PROJECT_TYPE%"=="5" echo    Type: Generic
if "%DEV_MODE%"=="1" echo    Mode: NEW Project
if "%DEV_MODE%"=="2" echo    Mode: MODIFICATION Project
echo    Framework Version: %FRAMEWORK_VERSION%
echo.
echo Next Steps:
echo 1. Configure environment: notepad .env
echo 2. Start development: start_ai_sdlc.bat
echo 3. For full features, use Git Bash: ./scripts/ai_age_sdlc_master.sh
echo.
echo Documentation:
echo    - README.md (project overview)
echo    - docs\CLAUDE_AI_AGE_SDLC.md (complete framework)
echo    - CLAUDE.md (Claude Code configuration)
echo.
echo Happy coding with AI_AGE_SDLC!
echo.
pause
exit /b 0

REM Template creation functions
:create_nodejs_template
(
echo {
echo   "name": "%PROJECT_NAME%",
echo   "version": "1.0.0",
echo   "description": "AI_AGE_SDLC enabled Node.js project",
echo   "main": "src/index.js",
echo   "scripts": {
echo     "start": "node src/index.js",
echo     "test": "jest --coverage",
echo     "lint": "eslint src/ tests/",
echo     "ai-sdlc": "bash ./scripts/ai_age_sdlc_master.sh"
echo   },
echo   "author": "%DEVELOPER_NAME% <%DEVELOPER_EMAIL%>",
echo   "license": "MIT"
echo }
) > package.json

(
echo // %PROJECT_NAME% - AI_AGE_SDLC Enabled Project
echo // Generated on: %SETUP_DATE%
echo.
echo class %PROJECT_NAME% {
echo     constructor(name = '%PROJECT_NAME%'^) {
echo         this.name = name;
echo     }
echo.
echo     greet(^) {
echo         return `Hello from ${this.name}! AI_AGE_SDLC is active.`;
echo     }
echo }
echo.
echo module.exports = %PROJECT_NAME%;
) > src\index.js
exit /b

:create_python_template
(
echo # AI_AGE_SDLC Python Project Dependencies
echo pytest^>=7.0.0
echo pytest-cov^>=4.0.0
echo black^>=23.0.0
echo flake8^>=6.0.0
) > requirements.txt

md "src\%PROJECT_NAME%" 2>nul
(
echo """
echo %PROJECT_NAME% - AI_AGE_SDLC Enabled Python Project
echo Generated on: %SETUP_DATE%
echo """
echo.
echo class %PROJECT_NAME%:
echo     """Main application class."""
echo     
echo     def __init__(self, name: str = "%PROJECT_NAME%"^):
echo         self.name = name
echo     
echo     def greet(self^) -^> str:
echo         """Return a greeting message."""
echo         return f"Hello from {self.name}! AI_AGE_SDLC is active."
echo.
echo if __name__ == "__main__":
echo     app = %PROJECT_NAME%()
echo     print(app.greet(^)^)
) > "src\%PROJECT_NAME%\__init__.py"
exit /b

:create_java_template
(
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<project xmlns="http://maven.apache.org/POM/4.0.0"
echo          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
echo          xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
echo          http://maven.apache.org/xsd/maven-4.0.0.xsd"^>
echo     ^<modelVersion^>4.0.0^</modelVersion^>
echo     ^<groupId^>com.aiagesdlc^</groupId^>
echo     ^<artifactId^>%PROJECT_NAME%^</artifactId^>
echo     ^<version^>1.0.0^</version^>
echo     ^<packaging^>jar^</packaging^>
echo     ^<name^>%PROJECT_NAME%^</name^>
echo     ^<description^>AI_AGE_SDLC enabled Java project^</description^>
echo     ^<properties^>
echo         ^<maven.compiler.source^>11^</maven.compiler.source^>
echo         ^<maven.compiler.target^>11^</maven.compiler.target^>
echo         ^<project.build.sourceEncoding^>UTF-8^</project.build.sourceEncoding^>
echo     ^</properties^>
echo     ^<dependencies^>
echo         ^<dependency^>
echo             ^<groupId^>org.junit.jupiter^</groupId^>
echo             ^<artifactId^>junit-jupiter^</artifactId^>
echo             ^<version^>5.9.2^</version^>
echo             ^<scope^>test^</scope^>
echo         ^</dependency^>
echo     ^</dependencies^>
echo ^</project^>
) > pom.xml

md "src\main\java\com\%PROJECT_NAME%" 2>nul
(
echo package com.%PROJECT_NAME%;
echo.
echo /**
echo  * %PROJECT_NAME% - AI_AGE_SDLC Enabled Application
echo  */
echo public class Application {
echo     private String projectName = "%PROJECT_NAME%";
echo.
echo     public String getGreeting(^) {
echo         return "Hello from " + projectName + " - AI_AGE_SDLC enabled!";
echo     }
echo.
echo     public static void main(String[] args^) {
echo         Application app = new Application(^);
echo         System.out.println(app.getGreeting(^)^);
echo     }
echo }
) > "src\main\java\com\%PROJECT_NAME%\Application.java"

md "src\test\java\com\%PROJECT_NAME%" 2>nul
(
echo package com.%PROJECT_NAME%;
echo import org.junit.jupiter.api.Test;
echo import static org.junit.jupiter.api.Assertions.*;
echo.
echo class ApplicationTest {
echo     @Test
echo     void shouldReturnGreeting(^) {
echo         Application app = new Application(^);
echo         String greeting = app.getGreeting(^);
echo         assertTrue(greeting.contains("%PROJECT_NAME%"^)^);
echo     }
echo }
) > "src\test\java\com\%PROJECT_NAME%\ApplicationTest.java"
exit /b

:create_terraform_template
(
echo # %PROJECT_NAME% - AI_AGE_SDLC Enabled Terraform Infrastructure
echo terraform {
echo   required_version = "^>= 1.0"
echo   required_providers {
echo     aws = {
echo       source  = "hashicorp/aws"
echo       version = "~^> 5.0"
echo     }
echo   }
echo }
echo.
echo provider "aws" {
echo   region = var.aws_region
echo }
echo.
echo resource "aws_s3_bucket" "example" {
echo   bucket = "${var.project_name}-${var.environment}"
echo }
) > main.tf

(
echo variable "project_name" {
echo   description = "Name of the project"
echo   type        = string
echo   default     = "%PROJECT_NAME%"
echo }
echo.
echo variable "environment" {
echo   description = "Environment name"
echo   type        = string
echo   default     = "dev"
echo }
echo.
echo variable "aws_region" {
echo   description = "AWS region"
echo   type        = string
echo   default     = "us-west-2"
echo }
) > variables.tf

(
echo output "bucket_name" {
echo   value = aws_s3_bucket.example.bucket
echo }
) > outputs.tf

(
echo environment = "dev"
echo project_name = "%PROJECT_NAME%"
echo aws_region = "us-west-2"
) > environments\dev\terraform.tfvars
exit /b

:create_generic_template
(
echo # %PROJECT_NAME% - AI_AGE_SDLC Enabled Project
echo # Generated on: %SETUP_DATE%
echo # 
echo # This is a generic project template.
echo # Customize based on your programming language and requirements.
) > src\main.txt
exit /b