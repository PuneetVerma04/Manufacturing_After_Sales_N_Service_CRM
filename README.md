# Manufacturing After-Sales & Service CRM

## Overview
The Manufacturing After-Sales & Service CRM is a Salesforce-based solution designed to streamline after-sales services, warranty management, and customer support for manufacturing businesses. This project leverages Salesforce's powerful platform to manage service cases, dispatch engineers, and collect customer feedback efficiently.

## Key Features
- **Service Case Management**: Track and manage customer service cases with detailed information.
- **Engineer Dispatch**: Automatically assign and dispatch engineers based on proximity and required skills.
- **Warranty and AMC Tracking**: Manage product warranties and annual maintenance contracts (AMCs).
- **Customer Feedback**: Collect and analyze feedback to improve service quality.
- **Custom Reports**: Generate insightful reports for SLA compliance, engineer performance, and customer satisfaction.

## Project Structure
- **Custom Objects**: Includes `Registered_Product__c`, `Service_Case__c`, `Dispatch__c`, `Feedback__c`, `Engineer__c`, and `Service_Agent__c`.
- **Apex Classes**: Contains business logic for automation and custom functionalities.
- **Flows**: Automates processes like engineer assignment and status updates.
- **Layouts**: Custom layouts for enhanced user experience.
- **Lightning Web Components (LWCs)**: Modern UI components for dashboards and portals.

## Setup Instructions
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/PuneetVerma04/Manufacturing_After_Sales_N_Service_CRM.git
   cd Manufacturing_After_Sales_N_Service_CRM/mas-crm
   ```

2. **Authorize a Dev Hub**:
   ```bash
   sf org login web -d
   ```

3. **Create a Scratch Org**:
   ```bash
   sf org create scratch -f config/project-scratch-def.json -a MAS-Dev
   ```

4. **Push Source to Scratch Org**:
   ```bash
   sf project deploy start
   ```

5. **Assign Permission Sets**:
   ```bash
   sf org assign permset -n Manufacturing_After_Sales_N_Service_CRM
   ```

6. **Import Sample Data**:
   ```bash
   sf data import tree -p data/sample_data_plan.json
   ```

7. **Open the Org**:
   ```bash
   sf org open
   ```

## Documentation
- **Data Dictionary**: Refer to `data-dictionary.md` for detailed information about custom objects and fields.
- **Flows and Automation**: See `force-app/main/default/flows` for automation details.
- **Apex Classes**: Business logic is located in `force-app/main/default/classes`.

## Contributing
Contributions are welcome! Please fork the repository and submit a pull request.

## License
This project is licensed under the MIT License. See `LICENSE` for details.
