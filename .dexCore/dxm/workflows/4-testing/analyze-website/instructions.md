# Analyze Website - Workflow Instructions

## Objective
Analyze a target website's structure, identify testable elements, and generate comprehensive recommendations for test automation framework.

---

## Process

### Step 1: URL Collection & Validation
```xml
<ask>
**Website Analysis**

Please provide the website URL you want to analyze for test automation:

Example: https://www.example.com
</ask>
```

**Validation:**
- Check URL format (http/https)
- Verify website is accessible
- Check for redirects or authentication requirements

---

### Step 2: Authentication Check
```xml
<ask>
Does this website require authentication (login)?

- If YES: Request test credentials (for analysis only)
- If NO: Proceed with public analysis
</ask>
```

---

### Step 3: Website Navigation & Analysis

**Action:** Open website programmatically

**Analysis Tasks:**

1. **Homepage Analysis**
   - Capture page title and meta information
   - Identify main navigation menu structure
   - Detect hero sections, call-to-action buttons
   - Find forms and input fields

2. **Element Detection**
   - All clickable elements (buttons, links)
   - Input fields (text, email, password, dropdowns)
   - Tables and data grids
   - Modal dialogs and popups
   - Dynamic content areas

3. **Page Structure Mapping**
   - Identify distinct pages/sections
   - Map navigation hierarchy
   - Detect URL patterns
   - Identify AJAX/SPA behavior

4. **Locator Strategy Analysis**
   - Count elements with IDs
   - Evaluate CSS class stability
   - Assess data-testid presence
   - Generate optimal locator recommendations

---

### Step 4: Test Scenario Identification

Based on website type, identify test scenarios:

**E-commerce Site:**
- Product search
- Product detail view
- Add to cart
- Checkout process
- User registration/login

**Corporate Site:**
- Navigation verification
- Contact form submission
- Content validation
- Search functionality

**SaaS Application:**
- User authentication
- Dashboard validation
- CRUD operations
- Settings management

---

### Step 5: Generate Analysis Report

Save comprehensive report to output folder with:
- Executive summary
- Page structure analysis
- Test scenario recommendations
- Framework recommendations
- Effort estimates
- Next steps

The report will guide framework generation decisions.

---

**Output:** Complete website analysis report saved to myDex/drafts/
