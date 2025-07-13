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
- **Efficient Archival**: ADF runs nightly, with deletes after successful copies.

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

## Cost Savings Example
| Component                | Size (GB) | Cost/Unit or Operation | Total Cost/Month (USD) |
|--------------------------|-----------|------------------------|------------------------|
| Cosmos DB (Current)      | 600       | $0.285 × 2 regions     | $342.00                |
| Cosmos DB (Proposed, Storage) | 300  | $0.285 × 2 regions     | $171.00                |
| Cosmos DB (Proposed, Reads) | -     | $0.285/M RU            | $0.285                 |
| Blob Storage Cool Tier (GRS) | 300   | $0.026/GB              | $7.80                  |
| Blob Storage Cool Tier Operations | - | Various                | $10.13132              |
| Blob Storage Geo-Replication | 300   | $0.086 (one-time)      | $25.80 (one-time)      |
| Blob Storage DLQ (Hot Tier, LRS) | 10 | $0.0208/GB            | $0.208                 |
| Blob Storage DLQ Operations | -    | Various                | $0.12654               |
| ADF (Data Flow + Activity) | -   | Various                | $74.401                |
| ADF (Data Movement)      | -         | $0.25/DIU-hour         | $0.0125                |
| **Total (Proposed, Monthly)** | 600 | -                    | **$263.96336**         |
| **Total (Proposed, One-Time)** | -  | -                    | **$25.8375**           |

### Notes
- **Cosmos DB**:
  - Current: 600 GB × $0.285/GB/month × 2 regions = $342.00/month.
  - Proposed: 300 GB × $0.285/GB/month × 2 regions = $171.00/month; 1M RUs × $0.285/M RU = $0.285/month.
- **Blob Storage Cool Tier (GRS)**:
  - Storage: 300 GB × $0.026/GB/month = $7.80/month.
  - Operations: 300,000 writes × $0.20/10,000 = $6.00; 30,000 list/create × $0.11/10,000 = $0.33; 1M reads × $0.01/10,000 = $1.00; 3,000 other × $0.0044/10,000 = $0.00132; 300 GB retrieval × $0.01/GB = $3.00. Total: **$10.13132/month**.
  - Geo-replication: 300 GB × $0.086/GB = $25.80 (one-time).
- **Blob Storage DLQ (Hot Tier, LRS)**:
  - Storage: 10 GB × $0.0208/GB/month = $0.208/month.
  - Operations: 5,000 writes × $0.11/10,000 = $0.055; 1,100 list/create × $0.11/10,000 = $0.0121; 10,000 reads × $0.0044/10,000 = $0.0044; 100 other × $0.0044/10,000 = $0.00004; 10 GB retrieval × $0.0055/GB = $0.055. Total: **$0.12654/month**.
- **ADF**:
  - Data Flow: 1 × 8 vCores × 31 hours × $0.30/vCore-hour = $74.40; 1 activity run × $0.001 = $0.001. Data Movement: 100 GB ÷ 2 GB/DIU-hour = 0.05 DIU-hours × $0.25 = $0.0125/month; Initial: 300 GB ÷ 2 GB/DIU-hour = 0.15 DIU-hours × $0.25 = $0.0375 (one-time). Total Monthly: **$74.4135/month**. One-Time: **$0.0375**.
- **Total Savings**: Current: $342.00/month. Proposed: $263.96336/month. Savings: $78.03664/month (~23%). One-time costs: $25.8375.
- **Corrections from Estimate ($395.3399/month)**:
  - Cosmos DB: Estimate ($85.785) ignores GRS; corrected to $171.285.
  - Blob Storage (Main): Estimate ($148.1044) includes geo-replication as monthly and 1,000 GB; corrected to $18.13132/month for 300 GB, $25.80 one-time.
  - Blob Storage (DLQ): Estimate ($24.254) assumes 1,000 GB; corrected to $0.33454 for 10 GB.
  - ADF: Estimate ($71.4965) excludes data movement; corrected to $74.4135.
- **Pricing Source**: Azure Blob Storage ($0.026/GB/month Cool Tier, $0.01/10,000 reads, $0.086/GB geo-replication), Cosmos DB ($0.285/GB/month, $0.285/M RU), ADF ($0.30/vCore-hour, $0.001/run, $0.25/DIU-hour), East US Hot Tier ($0.0208/GB/month, $0.0055/GB retrieval).

## Additional Considerations
- **Blob Storage Access**: 1M reads cost $1.00/month. Data retrieval ($0.01/GB) may add costs if downloading (e.g., $3.00 for 300 GB).
- **DLQ Management**: Monitor and reprocess DLQ files.
- **Performance**: Optimize Cosmos DB indexing and RU/s for reads.

## References
- [Azure Data Factory Cosmos DB Connector](https://learn.microsoft.com/en-us/azure/data-factory/connector-azure-cosmos-db)
- [ADF Copy Activity Performance](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-performance)
- [Azure Blob Storage Access Tiers Overview](https://learn.microsoft.com/en-us/azure/storage/blobs/access-tiers-overview)
- [Fault Tolerance of Copy Activity](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-fault-tolerance)
- [Session Log in a Copy Activity](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-log)
- [Troubleshoot Copy Activity Performance](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-performance-troubleshooting)
- [Handle Error Rows with Mapping Data Flows](https://learn.microsoft.com/en-us/azure/data-factory/how-to-data-flow-error-rows)