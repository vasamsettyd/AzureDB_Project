# 🚀 Azure End-to-End Data Engineering Project – Medallion Architecture | ADF | Databricks | PySpark

This is a complete, **real-time cloud project** demonstrating how to build an enterprise-grade data pipeline using **Azure Data Factory**, **Azure Databricks**, **Azure Data Lake Gen2**, **PySpark**, **Delta Lake**, and **Unity Catalog** – all orchestrated under the **Medallion Architecture** framework.

## 📊 Project Architecture Overview

The project follows a **Bronze → Silver → Gold layered architecture**, starting from raw data ingestion to delivering clean, business-ready star schema models using dimension and fact tables.

![Star Schema Output](![fact](https://github.com/user-attachments/assets/10861ac1-0257-4591-bf72-59536003cf3d)
)

## 🧠 Core Concepts Implemented

| Concept                     | Tools / Techniques Used                                             |
|----------------------------|---------------------------------------------------------------------|
| Medallion Architecture     | Bronze (Raw) → Silver (Cleaned) → Gold (Star Schema)               |
| Data Ingestion             | Azure Data Factory (Incremental Load, Parameterized Copy)          |
| Transformation             | Azure Databricks + PySpark                                         |
| Slowly Changing Dimensions | SCD Type 1 using PySpark                                           |
| Surrogate Keys             | Generated using `monotonically_increasing_id()` in PySpark         |
| Unity Catalog              | Secure catalog/schema governance in Databricks                     |
| Job Orchestration          | Databricks Workflows                                               |
| Delta Lake                 | All layers written in Delta Format with ACID support               |
| Git Integration            | Project files and notebooks organized and pushed to GitHub         |

## 🧱 Azure Resource Group Setup

> Resource Group: `dikkiprojectcars`

Provisioned the following resources in Azure Portal:

| Resource Name        | Type                         | Location     |
|----------------------|------------------------------|--------------|
| `adfcarsdikki`       | Azure Data Factory (V2)       | UK South     |
| `datalakecarsdikki`  | Storage Account (ADLS Gen2)   | UK West      |
| `caraccess`          | Access Connector for Databricks | UK West   |
| `carsssss`           | Azure Databricks Service      | UK South     |
| `cardatkiserver`     | Azure SQL Server              | South Central US |
| `cardatabase`        | Azure SQL Database            | South Central US |

---![resource](https://github.com/user-attachments/assets/f0f2914e-2fe1-4659-a058-c274ce7f3e5c)

## 🗂️ Data Lake Zones (Medallion Architecture)

Created containers in ADLS Gen2:
- `bronze` – Raw source files (CSV/JSON)
- `silver` – Cleaned data with schema enforcement
- `gold` – Star schema: dimension + fact tables

## 🔄 Azure Data Factory – Incremental Pipeline (with Watermark Logic)

This pipeline performs **parameterized incremental loading** from raw source (`sourcecars_data`) to the Silver layer, based on `Date_ID` using a robust watermarking technique.

### 📌 Pipeline: `incrementalpipeline`

#### 🔁 Lookup Activity:

1. **`Lookup - lastload`**
   - Pulls the **last successfully loaded watermark** from SQL metadata table.
   - Query:
     ```sql
     SELECT * FROM watermarktable
     ```
![lastload](https://github.com/user-attachments/assets/aa0d4400-8cd9-4276-b64d-a75e2281d064)

2. **`Lookup - currentload`**
   - Calculates the **latest max(Date_ID)** from the source table.
   - Query:
     ```sql
     SELECT MAX(Date_ID) AS maxdata FROM sourcecars_data
     ```
![currentload lookup](https://github.com/user-attachments/assets/b4219efd-0ce6-45cb-b9a4-48941acfa1ad)

3. 📤 c. Copy Activity – Copy data1
   - Only fetches records between `lastload` and `currentload`.
   - ✅ **Expression Used**:
     ```sql
     SELECT * FROM sourcecars_data 
     WHERE Date_ID > '@{activity('lastload').output.value[0].last_load}' 
     AND Date_ID <= '@{activity('currentload').output.value[0].maxdata}'

This is how incremental loading is achieved using parameterized expressions.
![pipeline experssion bulder for copy data source](https://github.com/user-attachments/assets/8f1dccd5-a7a5-497a-b37a-90b59ce3371c)

4. **`Stored Proc![pipeline experssion bulder for copy data source]
edure - watermarkupdate`**
   - Updates watermark value after successful copy.
   - Procedure:
     ```sql
     EXEC [dbo].[updatewatermarktable] 
     @lastload = '@{activity('currentload').output.value[0].maxdata}'
![storedporcedure pipeline picture](https://github.com/user-attachments/assets/fe5ecf98-31bf-45aa-9ac2-efef4742b592)

📦 Parameterized Dataset Configuration
✅ For Lookup & Copy Activities:
Used @pipeline().parameters.tablename to dynamically assign SQL source

Query execution is fully dynamic and parameter-driven, ensuring reusability for future datasets
🔒 Security & Connectivity
Used linked service sqldblinked to securely connect to Azure SQL

## 🔐 Databricks Security: Unity Catalog + Access Connector

### 🔧 Access Connector Setup

- Configured **Access Connector for Azure Databricks**
- Used it to bridge Databricks with ADLS Gen2 securely
- Avoided manual token sharing

### 📚 Unity Catalog Implementation

- Created Unity Metastore
- Assigned catalog owner + storage credential
- Executed SQL in Databricks notebooks:
  ```sql
  CREATE CATALOG cars_catalog;
  CREATE SCHEMA cars_catalog.silver;
  CREATE SCHEMA cars_catalog.gold;
Managed data through Unity Catalog schema for secure, governed access













