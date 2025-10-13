# Guidelines for TCS Salesforce Project Documentation And Demo Video Presentation

## Project Documentation

Project documentation in a Salesforce CRM implementation serves as a comprehensive record of the application's purpose, design, development, and deployment. It ensures that business requirements are clearly defined and aligned with the system’s functionality. Documentation acts as a blueprint for developers and admins, guiding consistent development and future scalability. It supports user training, facilitates troubleshooting, and ensures smooth maintenance by detailing every component and its logic. Moreover, it aids in change management, audit compliance, and knowledge transfer, making it an essential asset for the successful execution and long-term sustainability of any Salesforce CRM project.

### Guidelines for Salesforce Documentation Submission

#### General Instructions:

* Submit the documentation in a **professional format** (preferably in Word or PDF).
* Use **clear headings**, **subheadings**, and **bullet points** for easy reading.
* Follow a **consistent font style and size** (e.g., Times New Roman, size 12 or 13).
* Ensure **no grammatical mistakes** and **proper alignment** of all sections.
* Plagiarism is strictly prohibited — your content must be **original**.

#### Mandatory Sections to Include:

* **Project Overview:**
    * A brief paragraph summarizing what your project CRM is about.
    * Highlight the key features and business needs for the CRM.
* **Objectives:**
    * Write a paragraph clearly stating the main goals of building the CRM.
    * Link the objectives to business value (e.g., better customer management, streamlined bookings).
* **Phase 1: Problem Understanding & Industry Analysis**
    * Requirement Gathering
    * Stakeholder Analysis
    * Business Process Mapping
    * Industry-specific Use Case Analysis
    * AppExchange Exploration
* **Phase 2: Org Setup & Configuration**
    * Salesforce Editions
    * Company Profile Setup
    * Business Hours & Holidays
    * Fiscal Year Settings
    * User Setup & Licenses
    * Login Access Policies
    * Dev Org Setup
    * Sandbox Usage
    * Deployment Basics
    > For each Salesforce concept you implement in your project (e.g., Company Profile Setup, Business Hours & Holidays, etc.), first explain the use case clearly in sentences or a paragraph. Provide the relevant screenshots for the same Use case. You may include multiple use cases under the same concept if required. Screenshots for each Salesforce Concepts developed are mandatory.
* **Phase 3: Data Modeling & Relationships**
    * Standard & Custom Objects
    * Fields
    * Record Types
    * Page Layouts
    * Compact Layouts
    * Schema Builder
    * Lookup vs Master-Detail vs Hierarchical Relationships
    * Junction Objects
    * External Objects
    > For each Salesforce concept you implement in your project (e.g., Compact layouts, Record Types, etc.), first explain the use case clearly in sentences or a paragraph. Provide the relevant screenshots for the same Use case. You may include multiple use cases under the same concept if required. Screenshots for each Salesforce Concepts developed are mandatory.
* **Phase 4: Process Automation (Admin)**
    * Validation Rules
    * Workflow Rules
    * Process Builder
    * Approval Process
    * Flow Builder (Screen, Record-Triggered, Scheduled, Auto-launched)
    * Email Alerts
    * Field Updates
    * Tasks
    * Custom Notifications
    > For each Salesforce concept you implement in your project (e.g., Validation Rules, Approval Process, Flows, etc.), first explain the use case clearly in sentences or a paragraph. Provide the relevant screenshots for the same Use case. You may include multiple use cases under the same concept if required. Screenshots for each Salesforce Concepts developed are mandatory.
* **Phase 5: Apex Programming (Developer)**
    * Classes & Objects
    * Apex Triggers (before/after insert/update/delete)
    * Trigger Design Pattern
    * SOQL & SOSL
    * Collections: List, Set, Map
    * Control Statements
    * Batch Apex
    * Queueable Apex
    * Scheduled Apex
    * Future Methods
    * Exception Handling
    * Test Classes
    * Asynchronous Processing
    > For each Salesforce concept you implement in your project (e.g., Apex Triggers, Batch Apex, Scheduled Apex, etc.), first explain the use case clearly in sentences or a paragraph. Provide the relevant screenshots for the same Use case. You may include multiple use cases under the same concept if required. Screenshots for each Salesforce Concepts developed are mandatory.
* **Phase 6: User Interface Development**
    * Lightning App Builder
    * Record Pages
    * Tabs
    * Home Page Layouts
    * Utility Bar
    * LWC (Lightning Web Components)
    * Apex with LWC
    * Events in LWC
    * Wire Adapters
    * Imperative Apex Calls
    * Navigation Service
    > For each Salesforce concept you implement in your project (e.g., Record Pages, LWC , Apex with LWC, etc.), first explain the use case clearly in sentences or a paragraph. Provide the relevant screenshots for the same Use case. You may include multiple use cases under the same concept if required. Screenshots for each Salesforce Concepts developed are mandatory.
* **Phase 7: Integration & External Access**
    * Named Credentials
    * External Services
    * Web Services (REST/SOAP)
    * Callouts
    * Platform Events
    * Change Data Capture
    * Salesforce Connect
    * API Limits
    * OAuth & Authentication
    * Remote Site Settings
    > For each Salesforce concept you implement in your project (e.g., Remote Site Settings, Web Services, etc.), first explain the use case clearly in sentences or a paragraph. Provide the relevant screenshots for the same Use case. You may include multiple use cases under the same concept if required. Screenshots for each Salesforce Concepts developed are mandatory.
* **Phase 8: Data Management & Deployment**
    * Data Import Wizard
    * Data Loader
    * Duplicate Rules
    * Data Export & Backup
    * Change Sets
    * Unmanaged vs Managed Packages
    * ANT Migration Tool
    * VS Code & SFDX
    > For each Salesforce concept you implement in your project (e.g., Data Import Wizard, Duplicate Rules, etc.), first explain the use case clearly in sentences or a paragraph. Provide the relevant screenshots for the same Use case. You may include multiple use cases under the same concept if required. Screenshots for each Salesforce Concepts developed are mandatory.
* **Phase 9: Reporting, Dashboards & Security Review**
    * Reports (Tabular, Summary, Matrix, Joined)
    * Report Types
    * Dashboards
    * Dynamic Dashboards
    * Profiles
    * Roles
    * Users
    * Permission Sets
    * OWD
    * Sharing Rules
    * Sharing Settings
    * Field Level Security
    * Session Settings
    * Login IP Ranges
    * Audit Trail
    > For each Salesforce concept you implement in your project (e.g., Record Pages, LWC , Apex with LWC, etc.), first explain the use case clearly in sentences or a paragraph. Provide the relevant screenshots for the same Use case. You may include multiple use cases under the same concept if required. Screenshots for each Salesforce Concepts developed are mandatory.
* **Phase 10: Quality Assurance Testing**
    * You must prepare test cases for every Salesforce feature you implement (e.g., Record Creations in objects, Approval Process, Automatic Task Creation, Flows, Triggers, Validation Rules, etc.).
    * Each test case must include:
        * **Input details** (what data/action you are testing).
        * **Expected Output** (what should happen).
        * **Actual Output** (with results).
        * **Screenshots are mandatory** for both input and output. A simple tabular “Test Passed” is not acceptable.
    * You may use a structured format like:
        * Use Case / Scenario
        * Test Steps (with input)
        * Expected Result
        * Actual Result (with Screenshot)
* **Conclusion** (Include Conclusion of the Project)

#### Additional Points:

* In the documentation, provide only the necessary details required to create objects, flows, and other Salesforce components — avoid including step-by-step implementation instructions.
* Briefly describe **validation rules**, **approval processes**, **automation flows, etc** created.
* Include the **Testing Approach** (how testing was done for flows, reports, etc.).
* Mention **future enhancements** (like adding chatbot integration or AI suggestions in future).