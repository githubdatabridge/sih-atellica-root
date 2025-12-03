# db-vm-script

## Info

- Using powershell script.
- Services
  - sih-atellica-qplus-backend
  - sih-atellica-qlik-service
  - sih-atellica-qplus-frontend
## Certificates structure
### For sih-atellica-qplus-backend and sih-atellica-qplus-frontend
Certificates need to be passed in side of service folder.
```
certificates/
└── server/
    ├── server.cert
    └── server.key
```
### For sih-atellica-qlik-service
Certificates need to be passed in side of service folder.
```
certificates/
├── server/
│   ├── server.cert
│   └── server.key
└── qlik
    ├── client.pem
    ├── root.pem	
    └── client_key.pem
```

### Steps to use

```
./main.ps1
```

```
----------------------------
 system requirements checking
----------------------------

[NODE] nodejs v16.14.2 installed



First service [`sih-atellica-qplus-backend`] will perform deployment of the CRUD api. Continuing with Y on terminal service will start and will open .env in Notepad and required variables have to be fill. 

```
## DEFAULT VALUES
## UNCOMMENT AND CHANGE IF NEEDED
# HOST=0.0.0.0
PORT=3004
# SSL=false
# TITLE=SIH Atellica Qplus Backend
# VERSION=v1

# APP_NAME=Insight

DB_HOST=localhost
DB_PORT=4432
DB_USER=postgres
DB_PASS=Dont4get
DB_DATABASE=sih_atellica_qplus_staging
# DB_SSL=false

# QLIK_SERVICE_HOST=http://localhost
# QLIK_SERVICE_PORT=3001

NODE_TLS_REJECT_UNAUTHORIZED=0

# API_KEY=f919861d-dda2-442e-b238-fee4f417445ba

# QLIK_APP_SESSION_HEADER=X-Qlik-Session

# LOG_DIR=logs
# LOG_FILE_TYPE=file
# LOG_LEVEL=info
# LOG_CORE_FILE=core.log
# LOG_DATE_PATTERN=YYYY-MM-DD
# LOG_MAX_SIZE=20m
# LOG_MAX_FILES=14d

# TENANT_FILE_PATH=src/
# TENANT_FILE_NAME=tenants_develop.json

# STATE_SECRET=very_secret_secret_very_secret_secret

## NODE_ENV production || staging || ''
# NODE_ENV=
## if NODE_ENV=production or staging then DOMAIN_NAME is required for redirect back after login
# DOMAIN_NAME=

## REQUIRED VALUES IF DEPLOYING AS WIN SERVICE
# SVC_DOMAIN=
# SVC_ACCOUNT=
# SVC_PWD=
```

After closing notepad for .env second notepad will be open but now for `tenants_develop.json` were have to provide host name for Qlik and callbackUrl for mashup App. After closing notepad deploying app api will continue. 

```
[
    {
        "id": "single_hardcoded_for_now",
        "name": "local 1",
        "host": "qs-i-dev.databridge.ch", <=[CHANGE]=
        "port": 4242,
        "customers": [
            {
                "id": "hardcoded_for_now",
                "name": "customer 1",
                "apps": [
                    {
                        "id": "sih-atellica-qplus",
                        "name": "sih-atellica-qplus",
                        "qlikApps": [
                            {
                                "id": "49992cc1-8863-4a9c-a45a-e640b6345513",
                                "name": "string"
                            }
                        ],
                        "callbackUrl": "https://localhost:8081/qlik/dashboards/overview" <=[CHANGE]=
                    }
                ]
            }
        ],
        "authType": "windows",
        "idProvider": null
    }
]
```
After closing notepad for `tenants_develop.json` script will run build and install windows service.

Same as for `db-insight-migrations` if something goes wrong you can repeat step or continue. Default is continue.

```
[sih-atellica-qplus-backend] Deploying Done. Do you want to continue or repeat? [Y/n]:
```

Third service [`sih-atellica-qlik-service`] will perform deployment of Db-Qlik Service. Continuing with Y on terminal service will start and will open .env in Notepad and required variables have to be fill. 

```
## DEFAULT VALUES
## UNCOMMENT AND CHANGE IF NEEDED
# HOST=localhost
PORT=3001
# TITLE=Qlik Service
# VERSION=v1
# SSL=false

# QS_REPOSITORY_USER_ID=sa_repository
# QS_REPOSITORY_USER_DIRECTORY=INTERNAL
# QS_ENGINE_USER_ID=sa_api
# QS_ENGINE_USER_DIRECTORY=INTERNAL

# NODE_TLS_REJECT_UNAUTHORIZED=1

## REQUIRED VALUES IF DEPLOYING AS WIN SERVICE
# SVC_DOMAIN=
# SVC_ACCOUNT=
# SVC_PWD=
```

After closing notepad for `.env` script will run build and install windows service.

Same as for `sih-atellica-qplus-backend` if something goes wrong you can repeat step or continue. Default is continue.

```
[sih-atellica-qlik-service] Deploying Done. Do you want to continue or repeat? [Y/n]:
```

Final service that will host mashup App [`sih-atellica-qplus-frontend`] will perform deployment. Continuing with Y on terminal service will start and will open .env in Notepad and required variables have to be fill. 

```
REACT_APP_QLIK_VP=localhost
REACT_APP_QLIK_HOST_NAME=qs-i-dev.databridge.ch
REACT_APP_QLIK_QPS_ENDPOINT = https://qs-i-dev.databridge.ch
REACT_APP_QLIK_APP=05cf243f-8413-42a2-a173-7f6b94c8a08e
REACT_APP_QLIK_APP_AUDIT=ac8fd1a5-8a29-432a-9126-d00dacddbaca
REACT_APP_QLIK_USER_DIRECTORY=VM-I-QS-DEV
REACT_APP_QLIK_GLOBAL_EVENTS=closed,warning,error
REACT_APP_QLIK_APP_EVENTS=closed,warning,error
REACT_APP_QLIK_LANG_VARIABLE=vDefault_Lang
REACT_APP_MAIN_DOMAIN=databridge.ch
REACT_APP_DEFAULT_THEME=db-theme-siemens-light

REACT_APP_TENANT_ID=single_hardcoded_for_now
REACT_APP_CUSTOMER_ID=hardcoded_for_now
REACT_APP_MASHUP_APP_ID=sih-atellica-qplus

## App endpoints

REACT_APP_INSIGHT_APP_API=https://localhost:3004

## Log information

REACT_APP_VERSION=$npm_package_version
REACT_APP_NAME=$npm_package_name

REACT_APP_RELEASE=bexio-insight-dev@$npm_package_version
REACT_APP_SENTRY_DSN=https://afbfd9b3db2248c8966db34ac3bfaa48@o445289.ingest.sentry.io/5421493

## App config

REACT_APP_APP_IS_LOGOUT=true

## Development config

PORT=8081
HOST=localhost
HTTPS=true
SKIP_PREFLIGHT_CHECK=true
FAST_REFRESH=true

TITLE=Mashup App
DESCRIPTION=Mashup App DESCRIPTION
STATIC_FILE_PATH=build\
PASSPHRASE=

## REQUIRED VALUES IF DEPLOYING AS WIN SERVICE
# SVC_DOMAIN=
# SVC_ACCOUNT=
# SVC_PWD=

```
After closing notepad for `.env` script will run build and install windows service.

Same as for `sih-atellica-qplus-backend` if something goes wrong you can repeat step or continue. Default is continue.

```
[sih-atellica-qplus-frontend] Deploying Done. Do you want to continue or repeat? [Y/n]:
```

