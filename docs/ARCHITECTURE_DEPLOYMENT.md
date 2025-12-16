# Architecture: Deployment & Migration System

This document explains the architecture of the SIH Atellica system, focusing on the deployment model, migration process, and how datasets and template reports flow from headquarter to hospital installations.

---

## System Overview

```mermaid
flowchart TB
    subgraph HQ["Siemens Headquarter (Master)"]
        SA[("Siemens Admin<br/>(System Admin)")]
        HQ_DB[(PostgreSQL<br/>Database)]
        HQ_QLIK[("Qlik Sense<br/>Enterprise")]
        HQ_APP["Q+ Backend<br/>API Server"]

        SA -->|"Creates & Manages"| HQ_APP
        HQ_APP <-->|"Data"| HQ_DB
        HQ_APP <-->|"Qlik API"| HQ_QLIK
    end

    subgraph EXPORT["Export Process"]
        EXP_BTN["Export Button<br/>/dataset/export"]
        EXP_FILE["exported_dataset.json"]

        EXP_BTN --> EXP_FILE
    end

    subgraph INSTALLER["Installer Package"]
        PKG["Deployment Package"]
        MIG["Migration Scripts"]
        SEED["Seed Data<br/>(exported_dataset.json)"]

        PKG --> MIG
        PKG --> SEED
    end

    subgraph HOSP["Hospital Installation"]
        H_DB[(PostgreSQL<br/>Database)]
        H_QLIK[("Qlik Sense<br/>Enterprise")]
        H_APP["Q+ Backend<br/>API Server"]
        H_USER[("Hospital<br/>Users")]

        H_APP <-->|"Data"| H_DB
        H_APP <-->|"Qlik API"| H_QLIK
        H_USER -->|"Uses"| H_APP
    end

    HQ_APP --> EXP_BTN
    EXP_FILE --> PKG
    PKG -->|"Deploy"| H_APP
    MIG -->|"Run on Startup"| H_DB
```

---

## Multi-Tenant Hierarchy

The system supports multiple tenants (Qlik servers), customers (hospitals/headquarters), and applications within a single deployment.

```mermaid
erDiagram
    TENANT ||--o{ CUSTOMER : contains
    CUSTOMER ||--o{ MASHUP_APP : has
    MASHUP_APP ||--o{ QLIK_APP : uses
    CUSTOMER ||--o{ DATASET : owns
    DATASET ||--o{ REPORT : contains
    REPORT }o--|| TEMPLATE_REPORT : "based on"

    TENANT {
        string id PK "e.g., SIHPOCWEB"
        string name
        string host
        int qrsPort
        int qixPort
        string authType "windows|oauth|saas"
    }

    CUSTOMER {
        string id PK "e.g., SIH"
        string name
        string tenantId FK
    }

    MASHUP_APP {
        string id PK "e.g., qplus"
        string name
        string customerId FK
    }

    QLIK_APP {
        string id PK "Qlik App GUID"
        string name "compliance|audit"
        string mashupAppId FK
    }

    DATASET {
        int id PK
        string title
        json dimensions
        json measures
        json filters
        json visualizations
        string customerId FK
        string tenantId FK
        string appId FK
    }

    REPORT {
        int id PK
        string title
        string visualizationType
        json content
        boolean isSystem
        int templateId FK "Self-ref for templates"
        int datasetId FK
    }

    TEMPLATE_REPORT {
        int id PK
        boolean isSystem "true"
        int templateId "equals id"
    }
```

---

## Siemens Admin Role (System Master)

The Siemens Admin at headquarter is the master of the system with full control over datasets and template reports.

```mermaid
flowchart LR
    subgraph ROLES["User Roles"]
        ADMIN["Admin Role<br/>(Siemens Admin)"]
        USER["User Role<br/>(Hospital Staff)"]
    end

    subgraph ADMIN_CAPS["Admin Capabilities"]
        DS_CREATE["Create Datasets"]
        DS_UPDATE["Update Datasets"]
        DS_DELETE["Delete Datasets"]
        TR_CREATE["Create Template Reports"]
        TR_UPDATE["Update Template Reports"]
        EXPORT["Export Configuration"]
        NOTIFY["Send Notifications"]
    end

    subgraph USER_CAPS["User Capabilities"]
        VIEW_DS["View Datasets"]
        VIEW_TR["Use Template Reports"]
        CR_CUSTOM["Create Custom Reports"]
        SHARE["Share Reports"]
        FAV["Mark Favorites"]
    end

    ADMIN --> DS_CREATE
    ADMIN --> DS_UPDATE
    ADMIN --> DS_DELETE
    ADMIN --> TR_CREATE
    ADMIN --> TR_UPDATE
    ADMIN --> EXPORT
    ADMIN --> NOTIFY

    USER --> VIEW_DS
    USER --> VIEW_TR
    USER --> CR_CUSTOM
    USER --> SHARE
    USER --> FAV
```

### Role Verification Code

```typescript
// From src/lib/util.ts
function checkIfUserIsAdmin(userData: QlikAuthData, scopes?: string[]) {
    const isAdmin = userData.activeRole === 'admin';

    if (scopes && scopes.length) {
        return scopes.some((s) => userData.scopes.includes(s)) && isAdmin;
    }
    return isAdmin;
}
```

---

## Dataset & Template Report Structure

```mermaid
classDiagram
    class Dataset {
        +int id
        +string title
        +string description
        +JSON dimensions
        +JSON measures
        +JSON filters
        +JSON visualizations
        +string customerId
        +string tenantId
        +string appId
        +string qlikAppId
    }

    class Report {
        +int id
        +string title
        +string visualizationType
        +JSON content
        +boolean isSystem
        +boolean isPinwallable
        +int templateId
        +int datasetId
    }

    class TemplateReport {
        +int id
        +boolean isSystem = true
        +int templateId = id
        +string createdBy = "Admin"
    }

    class CustomReport {
        +int id
        +boolean isSystem = false
        +int templateId = null
        +string createdBy = "User"
    }

    Dataset "1" --> "*" Report : contains
    Report <|-- TemplateReport : type
    Report <|-- CustomReport : type
    CustomReport ..> TemplateReport : "can be based on"
```

---

## Migration & Deployment Flow

```mermaid
sequenceDiagram
    participant SA as Siemens Admin
    participant HQ as HQ Backend
    participant EXP as Export Service
    participant PKG as Installer Package
    participant HOSP as Hospital Backend
    participant MIG as Migration Runner
    participant DB as Hospital DB

    Note over SA,DB: Phase 1: Configuration at Headquarter

    SA->>HQ: Create Dataset
    HQ->>HQ: Validate Admin Role
    HQ->>HQ: Store Dataset

    SA->>HQ: Create Template Report
    HQ->>HQ: Mark as isSystem=true
    HQ->>HQ: Set templateId=reportId
    HQ->>HQ: Store Template Report

    Note over SA,DB: Phase 2: Export Configuration

    SA->>EXP: GET /dataset/export
    EXP->>HQ: GetDatasetsWithTemplateReports()
    HQ-->>EXP: Datasets + Template Reports
    EXP-->>SA: exported_dataset.json

    Note over SA,DB: Phase 3: Package & Deploy

    SA->>PKG: Include exported_dataset.json
    PKG->>PKG: Bundle with migration scripts
    PKG->>HOSP: Deploy to Hospital

    Note over SA,DB: Phase 4: Hospital Installation

    HOSP->>MIG: npm run migration:latest
    MIG->>MIG: Read exported_dataset.json
    MIG->>DB: syncDatasetsAndReports()

    loop For each Dataset
        MIG->>DB: INSERT/UPDATE Dataset
        loop For each Template Report
            MIG->>DB: INSERT/UPDATE Report
            MIG->>DB: Set templateId
        end
    end

    MIG-->>HOSP: Migration Complete
    HOSP-->>SA: Hospital Ready
```

---

## Export/Import Data Structure

### exported_dataset.json Format

```json
{
  "apps": {
    "compliance": "ece91d50-9e52-460c-8d50-8d6abf6442d3",
    "audit": "dc31bbe0-c11e-4d73-9188-5fba3813c4a5"
  },
  "datasets": [
    {
      "id": 3,
      "title": "Compliance Dataset",
      "qlikAppId": "ece91d50-...",
      "dimensions": "[{\"qId\":\"dim1\"}, ...]",
      "measures": "[{\"qId\":\"meas1\"}, ...]",
      "filters": "[{\"qId\":\"filter1\"}, ...]",
      "visualizations": "[{\"name\":\"table\"}, ...]",
      "customerId": "SIH",
      "tenantId": "SIHPOCWEB",
      "appId": "qplus",
      "reports": [
        {
          "id": 33,
          "title": "Monthly Compliance Report",
          "visualizationType": "table",
          "content": "{...}",
          "isSystem": true,
          "templateId": 33,
          "datasetId": 3
        }
      ]
    }
  ]
}
```

---

## Migration Script Logic

```mermaid
flowchart TD
    START[Migration Start] --> READ[Read exported_dataset.json]
    READ --> CHECK{Seed File Exists?}

    CHECK -->|No| SKIP[Skip Seeding]
    CHECK -->|Yes| PARSE[Parse JSON]

    PARSE --> ALTER[Alter templateId nullable]
    ALTER --> LOOP_DS[For Each Dataset]

    LOOP_DS --> EXISTS_DS{Dataset Exists?}
    EXISTS_DS -->|Yes| MERGE_DS[Merge/Update Dataset]
    EXISTS_DS -->|No| INSERT_DS[Insert Dataset]

    MERGE_DS --> LOOP_RPT[For Each Template Report]
    INSERT_DS --> LOOP_RPT

    LOOP_RPT --> EXISTS_RPT{Report Exists?}
    EXISTS_RPT -->|Yes| MERGE_RPT[Merge/Update Report]
    EXISTS_RPT -->|No| INSERT_RPT[Insert Report]

    MERGE_RPT --> SET_TMPL[Set templateId = id]
    INSERT_RPT --> SET_TMPL

    SET_TMPL --> MORE_RPT{More Reports?}
    MORE_RPT -->|Yes| LOOP_RPT
    MORE_RPT -->|No| MORE_DS{More Datasets?}

    MORE_DS -->|Yes| LOOP_DS
    MORE_DS -->|No| CLEANUP[Delete Orphan Datasets]

    CLEANUP --> DONE[Migration Complete]
    SKIP --> DONE
```

---

## Hospital vs Headquarter Installation

```mermaid
flowchart TB
    subgraph HQ_INSTALL["Headquarter Installation"]
        direction TB
        HQ_ADMIN["Siemens Admin<br/>Full Access"]
        HQ_FEATURES["Features:<br/>- Create/Edit Datasets<br/>- Create Template Reports<br/>- Export Configuration<br/>- Manage All Customers"]
    end

    subgraph HOSP_INSTALL["Hospital Installation"]
        direction TB
        HOSP_ADMIN["Local Admin<br/>Limited Access"]
        HOSP_USER["Hospital Users<br/>Standard Access"]
        HOSP_FEATURES["Features:<br/>- View Datasets (read-only)<br/>- Use Template Reports<br/>- Create Custom Reports<br/>- Share & Favorite"]
    end

    HQ_INSTALL -->|"Export & Deploy"| HOSP_INSTALL

    subgraph DATA_FLOW["Data Flow"]
        direction LR
        TEMPLATES["Template Reports"]
        DATASETS["Dataset Definitions"]
        CONFIG["App Configuration"]
    end

    HQ_INSTALL --> DATA_FLOW
    DATA_FLOW --> HOSP_INSTALL
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/database/seeds/exported_dataset.json` | Seed data for hospital deployments |
| `src/database/migrations/20240415115523_add-init-seed-datasets-and-reports.ts` | Migration that imports seed data |
| `src/actions/dataset/ExportDatasetAction.ts` | Exports datasets + template reports |
| `src/actions/dataset/CreateDatasetAction.ts` | Admin-only dataset creation |
| `src/actions/report/CreateReportAction.ts` | Report creation (template vs custom) |
| `src/repositories/DatasetRepository.ts` | GetDatasetsWithTemplateReports() |
| `src/lib/util.ts` | checkIfUserIsAdmin() role verification |
| `configuration.json` | Tenant/Customer/App hierarchy |

---

## Summary

1. **Siemens Admin** at headquarter creates and manages datasets and template reports
2. **Export** generates `exported_dataset.json` with all configurations
3. **Installer** bundles the export with migration scripts
4. **Hospital deployment** runs migrations that import the seed data
5. **Hospital users** can use template reports and create their own custom reports
6. **Multi-tenancy** allows the same system to serve multiple hospitals with isolated data

The system ensures that hospital installations always receive the latest dataset definitions and template reports from the headquarter while maintaining data isolation between different customers.
