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

📦 Data Transformation in Azure Databricks (Silver & Gold Layers)
This section documents the data cleansing, dimensional modeling, and star schema transformations performed using PySpark in Databricks, following the Medallion Architecture: Bronze → Silver → Gold.

All transformations from Silver to Gold layer are performed using PySpark notebooks inside Azure Databricks.

- Each dimension table is created using deduped, null-free logic.
- The fact table combines all dimensions using natural keys and applies core metrics like sales and units.

Notebook: Silver Notebook

📥 Reads ingested Bronze Delta table:
bronze.sourcecars_data

🧹 Cleansing steps performed:

Dropped nulls from critical columns

Renamed headers and standardized data types

Casted fields like Date_ID, Model_ID, Dealer_ID, etc. into consistent formats

Added audit columns:
withColumn("load_date", current_timestamp())
✅ Final DataFrame written to:
cars_catalog.silver.sourcecars_data

silver_df.write.format("delta").mode("overwrite").saveAsTable("cars_catalog.silver.sourcecars_data")

🟡 Gold Layer – Dimension Table Logic

Each dimension table (dim_model, dim_branch, dim_dealer, dim_date) was created using incremental data processing with surrogate key management and upsert logic, ensuring clean, business-ready dimension records.

This process follows a robust enterprise approach to building Slowly Changing Dimensions – Type 1 using Delta Lake, which allows overwrite-based updates on matching keys.

🔍 Step-by-Step Logic (applied in each dim_* notebook):
1. Load Source Data from Silver table:
The base DataFrame is loaded from cars_catalog.silver.sourcecars_data.

The current max surrogate key value is fetched from the existing dim_* table to avoid duplication.

This allows the continuation of surrogate keys for newly added records.

4. Generate Surrogate Keys for New Records:
New records are assigned surrogate keys by incrementing the previously fetched maximum key.

5. Combine Old and New Records:
The existing records (unchanged) and the new records (with surrogate keys) are combined into one DataFrame before final write.

6. Perform SCD Type 1 Merge (Upsert):
Final DataFrame is written to the Gold Delta table using Delta Lake upsert (merge) logic:

If a match is found on the business key → Update
If not found → Insert as new record

7. Delta Table Management:
All dimension tables are written and maintained as managed Delta tables in Unity Catalog under:

⭐ fact_sales – Gold Layer Fact Table
This notebook creates the final fact table by performing joins between the Silver layer fact data and all relevant dimension tables. The objective is to build a business-ready analytical dataset with surrogate key mappings and key metrics.

1. Load Silver Data and Dimension Tables
Loaded the main transactional dataset from:
cars_catalog.silver.sourcecars_data
Loaded each dimension from:
cars_catalog.gold.dim_model
cars_catalog.gold.dim_branch
cars_catalog.gold.dim_dealer
cars_catalog.gold.dim_date
2. Perform Inner Joins on Business Keys
Joined Silver data with each dimension based on actual business keys:
Model_ID → dim_model.Model_ID

Branch_ID → dim_branch.Branch_ID

Dealer_ID → dim_dealer.Dealer_ID

Date_ID → dim_date.Date_ID

These joins enrich the transactional data with clean dimension attributes, ensuring each record in the fact table is tied to a single version of each dimension entity.

3. Select Required Columns for the Fact Table
Chose only the necessary columns from joined tables for reporting and analytics.

This includes transactional fields and keys from each dimension.

4. Create a Surrogate Key for Fact Table
Generated a unique ID for each fact record:

5. Write Final Output to Delta Table
Stored the result as a managed Delta table:
Used overwrite mode to support full or incremental refreshes based on pipeline design.

OUTPUT : ![fact](https://github.com/user-attachments/assets/7a47d6f6-f099-4bc0-a4ac-bdfe65462b30)































