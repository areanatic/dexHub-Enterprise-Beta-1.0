# Generate Test Framework - Workflow Instructions

## Objective
Create a complete, production-ready test automation framework based on website analysis and user preferences.

---

## Process

### Step 1: Gather Requirements
```xml
<elicit-required>
<ask priority="1">What is the website URL you want to test?</ask>
<ask priority="1">Which programming language do you prefer?
  - Java (Selenium + TestNG/JUnit)
  - Python (Selenium + Pytest)
  - JavaScript (Playwright/WebdriverIO)
  - C# (Selenium + NUnit/MSTest)
</ask>
<ask priority="2">Which reporting tool do you want?
  - Allure (Recommended - beautiful interactive reports)
  - HTML (Simple, built-in)
  - ExtentReports (Rich HTML with charts)
  - Default (framework default)
</ask>
<ask priority="2">Do you need a CI/CD pipeline?
  - GitHub Actions (Recommended)
  - GitLab CI
  - Jenkins
  - Azure DevOps
  - None
</ask>
<ask priority="3">Any specific features to test? (Optional)
  - Example: login, search, checkout, contact form
  - Leave empty for automatic detection
</ask>
</elicit-required>
```

---

### Step 2: Analyze Website Structure

**Action:** Navigate to website and perform deep analysis

1. Load website
2. Identify all pages and navigation
3. Map interactive elements
4. Detect forms and workflows
5. Generate element locators
6. Identify test scenarios

---

### Step 3: Generate Project Structure

Based on language selection:

#### Java Project Structure
```
{project-name}/
├── pom.xml (Maven configuration)
├── src/
│   ├── main/java/
│   │   ├── pages/
│   │   │   ├── BasePage.java
│   │   │   ├── HomePage.java
│   │   │   └── [Feature]Page.java
│   │   ├── utils/
│   │   │   ├── ConfigReader.java
│   │   │   ├── DriverManager.java
│   │   │   ├── WaitHelper.java
│   │   │   └── Screenshot.java
│   │   └── config/
│   │       └── TestConfig.java
│   └── test/java/
│       ├── base/
│       │   └── BaseTest.java
│       ├── tests/
│       │   └── [Feature]Tests.java
│       └── listeners/
│           └── AllureListener.java
├── src/test/resources/
│   ├── config.properties
│   ├── testng.xml
│   └── allure.properties
├── .github/workflows/
│   └── test-automation.yml
├── .gitignore
└── README.md
```

#### Python Project Structure
```
{project-name}/
├── requirements.txt
├── pytest.ini
├── conftest.py
├── pages/
│   ├── __init__.py
│   ├── base_page.py
│   └── [feature]_page.py
├── tests/
│   ├── __init__.py
│   └── test_[feature].py
├── utils/
│   ├── __init__.py
│   ├── config_reader.py
│   ├── driver_manager.py
│   └── helpers.py
├── config/
│   └── config.yaml
├── .github/workflows/
│   └── pytest.yml
├── .gitignore
└── README.md
```

---

### Step 4: Generate Page Object Classes

For each identified page:

1. **Create Page Object Class**
   - Inherit from BasePage
   - Define element locators (@FindBy for Java, properties for Python)
   - Implement action methods
   - Add Allure @Step annotations
   - Include logging

2. **Locator Strategy**
   - Prefer: id, name, data-test-id
   - Fallback: CSS selectors
   - Last resort: XPath

3. **Method Patterns**
   - Fluent interface (return self)
   - Explicit waits
   - Screenshot on action
   - Logging for debugging

**Example Java Page Object:**
```java
public class HomePage extends BasePage {
    @FindBy(id = "search-input")
    private WebElement searchField;
    
    @Step("Enter search term: {searchTerm}")
    public HomePage enterSearchTerm(String searchTerm) {
        sendKeys(searchField, searchTerm);
        return this;
    }
    
    @Step("Click search button")
    public SearchResultsPage clickSearch() {
        click(searchButton);
        return new SearchResultsPage(driver);
    }
}
```

---

### Step 5: Generate Test Classes

For each identified test scenario:

1. **Create Test Class**
   - Extend BaseTest
   - Add test methods with proper annotations
   - Include Allure metadata (@Epic, @Feature, @Story)
   - Add assertions
   - Handle test data

2. **Test Structure**
   - Setup (inherited from BaseTest)
   - Test execution with clear steps
   - Assertions with meaningful messages
   - Cleanup (inherited)

**Example Java Test:**
```java
@Epic("Search Functionality")
@Feature("Product Search")
public class SearchTests extends BaseTest {
    
    @Test(priority = 1)
    @Description("Verify user can search for products")
    public void testProductSearch() {
        HomePage homePage = new HomePage(driver);
        SearchResultsPage resultsPage = homePage
            .enterSearchTerm("laptop")
            .clickSearch();
            
        Assert.assertTrue(resultsPage.hasResults(), 
            "Search results should be displayed");
    }
}
```

---

### Step 6: Create Configuration Files

Generate all required configuration:

- **pom.xml / requirements.txt**: Dependencies
- **testng.xml / pytest.ini**: Test execution config
- **config.properties / config.yaml**: Environment settings
- **allure.properties**: Reporting configuration
- **log4j2.xml / logging config**: Logging setup

---

### Step 7: Add Utility Classes

Create helper utilities:

1. **DriverManager**: WebDriver initialization and management
2. **ConfigReader**: Read configuration files
3. **WaitHelper**: Explicit wait utilities
4. **Screenshot**: Capture screenshots
5. **DataReader**: Read test data (CSV/JSON/Excel)
6. **APIHelper**: API testing support (if needed)

---

### Step 8: Setup Reporting

Configure selected reporting tool:

**Allure:**
- Add dependencies
- Configure listener
- Add allure.properties
- Setup Maven/Pytest plugin

**HTML Reports:**
- Configure built-in reporting
- Add report generation steps

**ExtentReports:**
- Add dependencies
- Create ExtentManager
- Configure listener

---

### Step 9: Create CI/CD Pipeline

Generate CI/CD configuration:

**GitHub Actions:**
```yaml
name: Test Automation

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup {language}
        uses: actions/setup-{language}@v3
      - name: Install dependencies
        run: {install_command}
      - name: Run tests
        run: {test_command}
      - name: Generate reports
        run: {report_command}
      - name: Upload reports
        uses: actions/upload-artifact@v3
```

---

### Step 10: Generate README

Create comprehensive documentation:

```markdown
# {Project Name} - Test Automation Framework

## Overview
Automated testing framework for {website_url}

## Tech Stack
- Language: {language}
- Framework: {framework}
- Test Tool: {test_framework}
- Reporting: {reporting}

## Prerequisites
- {language} {version}
- {build_tool}

## Setup
1. Clone repository
2. Install dependencies: `{install_command}`
3. Update config: `src/test/resources/config.properties`

## Running Tests
- All tests: `{run_all_command}`
- Specific test: `{run_specific_command}`
- Parallel: `{run_parallel_command}`

## Reports
- Generate: `{report_generate_command}`
- View: `{report_view_command}`

## Project Structure
{structure_tree}

## Test Scenarios
{test_list}

## Contributing
{contribution_guidelines}
```

---

### Step 11: Package Framework

1. Create all files in output folder
2. Verify structure completeness
3. Create ZIP archive (optional)
4. Generate framework summary

---

### Step 12: Display Summary

```xml
<template-output>
🎉 **Framework Generation Complete!**

**Project:** {project_name}-test-automation
**Location:** {draft_folder}

---

## Generated Components

✅ **{page_object_count} Page Object Classes**
{page_objects_list}

✅ **{test_count} Test Cases**
{tests_list}

✅ **Utilities & Configuration**
- DriverManager
- ConfigReader
- WaitHelper
- Screenshot utility
- Test data management

✅ **Reporting: {reporting_tool}**
- Configured and ready

✅ **CI/CD: {ci_cd_platform}**
- Pipeline configured

---

## Quick Start

1. **Navigate to framework:**
   ```bash
   cd {draft_folder}
   ```

2. **Install dependencies:**
   ```bash
   {install_command}
   ```

3. **Update configuration:**
   Edit `{config_file_path}` with your settings

4. **Run tests:**
   ```bash
   {run_command}
   ```

5. **View reports:**
   ```bash
   {report_command}
   ```

---

## Framework Features

- ✅ Page Object Model design pattern
- ✅ Selenium WebDriver with WebDriverManager
- ✅ Parallel test execution
- ✅ Screenshot on failure
- ✅ Comprehensive logging
- ✅ Allure reporting with rich visuals
- ✅ GitHub Actions CI/CD pipeline
- ✅ Cross-browser support (Chrome, Firefox, Edge)
- ✅ Headless execution support
- ✅ Configuration management
- ✅ Explicit wait strategies
- ✅ Retry mechanism for flaky tests

---

**Your framework is production-ready!** 🚀

**Need help?**
- Review README.md for detailed documentation
- Check config files for customization options
- Run `{help_command}` for more info

</template-output>
```

---

**Next Steps:**
- User navigates to framework folder
- Reviews and customizes configuration
- Runs tests to validate
- Views reports
- Integrates into development workflow
