# Cost-Optimized Billing Records Management with Azure Data Factory

## Overview
This solution manages a read-heavy Azure Cosmos DB database with over 2 million billing records (~600 GB, each up to 300 KB) by archiving records older than three months to Azure Blob Storage Cool Tier using Azure Data Factory (ADF). It ensures cost efficiency, simplicity, no data loss, no downtime, no API changes, and access latency within seconds.

## Requirements
- **Cost Reduction**: Minimize Cosmos DB storage and read costs.
- **Simplicity**: Use managed services for easy deployment and maintenance.
- **No Data Loss**: Records are copied before deletion.
- **No Downtime**: Archiving is non-disruptive.
- **No API Changes**: Existing read/write APIs remain unchanged.
- **Access Latency**: Recent records (Cosmos DB) accessible in ~5 ms, archived records (Blob Storage Cool Tier) in milliseconds to seconds.

## Solution Design
### 1. Archiving
- **ADF Pipeline**: Copies records older than three months from Cosmos DB to Azure Blob Storage Cool Tier as JSON files. The Cooler Tier balances low storage costs with fast retrieval.
- **Delete Activity**: Removes records from Cosmos DB only after successful transfer.

### 2. Read Logic
- **Application Logic**: Queries Cosmos DB for recent records (< 90 days). If not found, queries Blob Storage Cool Tier for archived records (> 90 days), preserving API contracts.
- **Failure Handling**: Handles Blob Storage failures with retries or error logging.

### 3. Cost Optimization
- **Hot/Cool Data Tiering**: Recent records stay in Cosmos DB (hot), older records move to Blob Storage Cool Tier (cool).
- **Read Cost Management**: Cool Tier read operations are cost-effective for archived records.
- **Efficient Archival**: ADF runs in non peak hours, with deletes after successful copies.

## Implementation Steps
### Step 1: Set Up Azure Services
- **Azure Data Factory**: Create an ADF instance and open ADF Studio.
- **Azure Blob Storage**: Create a storage account with GRS, add a container (e.g., `archived`), and set its access tier to Cool.

### Step 2: Configure ADF Linked Services and Datasets
- **Cosmos DB Linked Service**: Add a linked service for Cosmos DB with endpoint, primary key, and database name.
- **Blob Storage Linked Service**: Add a linked service for Blob Storage with account name and key.
- **Cosmos DB Dataset**: Create a dataset for the billing records collection, defining schema and partition key if needed.
- **Blob Storage Dataset**: Create a dataset for the `archived` container, set format to JSON, and configure dynamic file paths (e.g., `archived/record-id.json`).

### Step 3: Create ADF Data Flow and Copy Pipeline
1. **Source (Cosmos DB)**: Query records older than 90 days (e.g., `SELECT * FROM c WHERE c.timestamp < dateadd(day, -90, getcurrenttimestamp())`).
2. **Copy Activity**: Transfer data to Blob Storage in batches, writing JSON files in the Cool Tier.
3. **Dead Letter Queue (DLQ)**:
   - Enable fault tolerance: Skip and log incompatible rows to a Blob Storage folder (e.g., `adlq/billingrecords/`).
   - DLQ files include original record, error message, error code, and timestamp.
4. **Delete Activity**: Remove archived records from Cosmos DB after successful copy.
5. **Retries and Monitoring**: Configure retries (3 attempts, 60s interval) and enable monitoring/alerts.

### Step 4: Schedule and Monitor
- **Trigger**: Schedule pipeline daily during non-peak hours (e.g., 2 AM).
- **Monitoring**: Track runs, failures, and DLQ entries with ADF monitoring. Set alerts.

### Step 5: Update Application Read Logic
- Query Cosmos DB, then Blob Storage Cool Tier if needed. No API changes; update internal logic. Handle Blob Storage failures with retries.

### Step 6: Monitor and Optimize
- **ADF Monitoring**: Track runs and DLQ growth.
- **Cost Tracking**: Monitor Cosmos DB RU and Blob Storage read costs.
- **Performance**: Optimize Cosmos DB RU/s and Blob Storage access.

## Dead Letter Queue (DLQ) Handling
To ensure no data loss, ADF’s fault tolerance is used:
1. **Configuration**:
   - In Copy Activity’s “Settings”:
     - **Skip incompatible rows**: True.
     - **Log incompatible rows**: True.
     - **Error file path**: `adlq/billingrecords/`.
2. **Triggers for DLQ**:
   - Malformed/invalid JSON.
   - Data corruption.
   - Persistent row-level failures after retries.
3. **DLQ Content**:
   - JSON files with original record, `_adf_error_message`, `_adf_error_code`, `_adf_timestamp`.
4. **Reprocessing and Monitoring**:
   - Create a separate ADF pipeline to reprocess DLQ files after corrections.
   - Set alerts on DLQ container for unexpected growth.

| Component                | Size (GB) | Cost/Unit or Operation          | Total Cost/Month (USD) |
|--------------------------|-----------|--------------------------------|------------------------|
| Cosmos DB (Current)      | 600       | $0.285/GB, $0.000285/RU        | $171.57                |
| Cosmos DB (Proposed)     | 300       | $0.285/GB, $0.000285/RU        | $85.785                |
| Blob Storage Cool Tier (GRS) | 300   | $0.026/GB + Operations         | $40.93132              |
| Blob Storage DLQ (Hot Tier, LRS) | 30 | $0.0208/GB + Operations        | $4.3994                |
| Azure Data Factory (ADF) | -         | Various                        | $36.2495               |
| **Total (Proposed, Monthly)** | 630 | -                              | **$167.36522**         |
| **Total (Proposed, One-Time)** | -  | -                              | **$0.00**              |

## Component Breakdown and Single-Region Confirmation

1. **Cosmos DB (Current)**:
   - **Budget Source**: `ExportedEstimate (3).xlsx` specifies Azure Cosmos DB for NoSQL, single-region write (Central India), 600 GB storage, 2 million RUs.
   - **Cost**: $171.57/month.
   - **Details**:
     - Storage: 600 GB × $0.285/GB/month = $171.00.
     - RUs: 2 million RUs × $0.000285/RU = $0.57.
     - Total: $171.57/month.
   - **Single Region**: Central India (single-master write).

2. **Cosmos DB (Proposed)**:
   - **Budget Source**: `ExportedEstimate (4).xlsx` specifies Azure Cosmos DB for NoSQL, single-region write (Central India), 300 GB storage, 1 million RUs.
   - **Cost**: $85.785/month.
   - **Details**:
     - Storage: 300 GB × $0.285/GB/month = $85.50.
     - RUs: 1 million RUs × $0.000285/RU = $0.285.
     - Total: $85.785/month.
   - **Single Region**: Central India (single-master write).

3. **Blob Storage Cool Tier (GRS)**:
   - **Budget Source**: `ExportedEstimate (4).xlsx` specifies Block Blob Storage, GRS redundancy, Cool Access Tier, Central India, 300 GB capacity, with 30 × 10,000 write operations, 3 × 10,000 list/create operations, 100 × 10,000 read operations, and 300 GB geo-replication data transfer.
   - **Cost**: $40.93132/month.
   - **Details**:
     - Storage: 300 GB × $0.026/GB/month = $7.80.
     - Operations:
       - Writes: 30 × 10,000 × $0.20/10,000 = $6.00.
       - List/Create: 3 × 10,000 × $0.11/10,000 = $0.33.
       - Reads: 100 × 10,000 × $0.01/10,000 = $1.00.
       - Geo-replication: 300 GB × $0.086/GB/month = $25.80.
     - Total: $40.93132/month.
   - **Single Region with GRS**: Primary storage and access in Central India; GRS replicates to a secondary region for redundancy but does not affect API access.

4. **Blob Storage DLQ (Hot Tier, LRS)**:
   - **Budget Source**: `ExportedEstimate (4).xlsx` specifies Block Blob Storage, LRS redundancy, Hot Access Tier, Central India, 30 GB capacity, with 50 × 10,000 write operations, 11 × 10,000 list/create operations, 100 × 10,000 read operations, 1 × 10,000 other operations, and 1,000 GB data retrieval/write.
   - **Cost**: $4.3994/month.
   - **Details**:
     - Storage: 30 GB × $0.0208/GB/month = $0.624.
     - Operations and data retrieval/write contribute to the total, as per the budget.
   - **Single Region**: Central India (LRS, no geo-replication).

5. **Azure Data Factory (ADF)**:
   - **Budget Source**: `ExportedEstimate (4).xlsx` specifies ADF in Central India, with 1 activity run, 0.5 × 8 General Purpose vCores × 31 hours.
   - **Cost**: $36.2495/month.
   - **Single Region**: Central India (Azure Integration Runtime).

6. **Total Costs**:
   - **Proposed Monthly**: $85.785 (Cosmos DB) + $40.93132 (Blob Storage GRS) + $4.3994 (Blob Storage DLQ) + $36.2495 (ADF) = $167.36522/month.
   - **One-Time**: $0.00 (no upfront costs).

## Notes
- **Single-Region Confirmation**: All services (Cosmos DB, Blob Storage, ADF) operate in Central India, as specified in the budgets. GRS for Blob Storage involves replication to a secondary region for redundancy, but primary access remains in Central India.
- **Cost Savings**: The proposed solution reduces monthly costs from $171.57 (current) to $167.36522, a modest saving due to Blob Storage and ADF costs, but optimized for scalability.
- **Geo-Redundant Storage (GRS)**: GRS ensures data durability without impacting API latency in Central India.
- **Implementation**: Monitor Blob Storage Cool Tier access latency and ADF pipeline failures to ensure performance and reliability.

## References
- [Azure Data Factory Cosmos DB Connector](https://learn.microsoft.com/en-us/azure/data-factory/connector-azure-cosmos-db)
- [ADF Copy Activity Performance](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-performance)
- [Azure Blob Storage Access Tiers Overview](https://learn.microsoft.com/en-us/azure/storage/blobs/access-tiers-overview)
- [Fault Tolerance of Copy Activity](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-fault-tolerance)
- [Session Log in a Copy Activity](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-log)
- [Troubleshoot Copy Activity Performance](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-performance-troubleshooting)
- [Handle Error Rows with Mapping Data Flows](https://learn.microsoft.com/en-us/azure/data-factory/how-to-data-flow-error-rows)



## Chat History References

The following links provide context from AI interactions related to the project:

- **Gemini Chat History**: [View Gemini Chat](https://g.co/gemini/share/4568d39051e8)
- **Grok AI Chat History**: [View Grok Chat](https://grok.com/share/c2hhcmQtMw%3D%3D_94ff86be-21ee-40ff-81a3-058a49f393db)

These conversations contain discussions on cost optimization strategies, Azure CosmosDB configurations, and related technical details.

## Budget Estimation Files

The project includes two Excel files for budget estimation, stored in the `Azure Price estimation` directory of the `cosmosdb-billing-cost-optimizer` repository:

- **Current Budget**
  - **File Path:** `Azure Price estimation/current-budget.xlsx`  
  - **Link:** [Current Budget](./Azure%20Price%20estimation/current-budget.xlsx)
  - **Description:** Contains the current budget allocation and cost breakdown for Azure Cosmos DB usage, including details on throughput (RU/s), storage, and other associated costs.

- **Proposed Budget Estimation**
  - **File Path:** `Azure Price estimation/proposed-budget-estimation.xlsx`  
  - **Link:** [Proposed Budget Estimation](./Azure%20Price%20estimation/proposed-budget-estimation.xlsx)
  - **Description:** Outlines the proposed budget adjustments based on optimization strategies, such as scaling throughput, optimizing data storage, or leveraging reserved capacity.

## Architecture Diagram

The architecture diagram for the CosmosDB billing cost optimizer is stored in the repository:

- **File Path**: `architecture.drawio.png`
- **Link**: [Architecture Diagram](architecture.drawio.png)
- **Description**: This diagram illustrates the high-level architecture of the cost optimization solution, including components such as Azure CosmosDB, azure blob storage azure data factory.
