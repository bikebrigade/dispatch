# setup

## Services

### Slack



### Twilio

* https://console.twilio.com/us1/account/keys-credentials/api-keys

Auth token for `TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN`.

`TWILIO_STATUS_CALLBACK`?

### Google Maps and storage

https://console.cloud.google.com

Create project

Select it

`/ billing` to find billing setup
Link / create
Set a budget?
Might have to fiddle to get project linked to billing account

Enable Geocoding API?

Enable Cloud Storage
Create Credentials
Service Account
Role Storage Object Admin?
Go to keys
Create new key
JSON
Create, downloads json to use as `GOOGLE_SERVICE_JSON`

Cloud Storage on the left, buckets
Create (if not available, link billing account)

Example `bike-bridage-dispatch-setup-test`, use as `GOOGLE_STORAGE_BUCKET`

### Mailchimp

Sign up
Have to give some kind of address
Used PO BOX I have

Skip a bunch of questions

Continue with free account?

https://us22.admin.mailchimp.com/account/api/
create a key

Use as `MAILCHIMP_API_KEY`

### SECRET_KEY_BASE

prob needs to come from mix command and/or have certain length/etc

### App setup

* create app (adjust fly.toml etc)
* fly deploy with config
* DATABASE_URL missing
* flyctl ext supabase create -a dan-dispatch-test in yul (sets DATABASE_URL)
* fly deploy again


----


NAME                      	DIGEST                          	CREATED AT
DATABASE_URL              	ff7cb5dd09077dd7                	May 15 2023 02:36
GOOGLE_MAPS_API_KEY       	1553a1b7624a27cfd85661d84186d572	Sep 22 2021 06:24
GOOGLE_SERVICE_JSON       	03d59aeb2602275275d4e53635c38242	Sep 22 2021 07:37
GOOGLE_SHEETS_SERVICE_JSON	5466f61077059af2493cc5367c1ab186	Sep 22 2021 07:24
HONEYBADGER_API_KEY       	717b4e1c49745f9d5285b411a17584a8	Sep 22 2021 06:23
IMPORTER_CHECKIN_URL      	c0b4a93c4b19145289ee1e48d7bbe837	Sep 22 2021 06:22
INCOMING_PHONE_NUMBERS    	f896f57e0cd4fd6fcb865a9ed898b77f	Sep 22 2021 06:22
LOGFLARE_API_KEY          	26e9b79fd3e26bd4e8f448d91c35a37b	Sep 22 2021 06:22
LOGFLARE_SOURCE_ID        	f9dea73d9d1421cff6de41dfaa40ea1b	Sep 22 2021 06:21
MAILCHIMP_API_KEY         	5fbb073d7884cdbd8d478fc2d97e6632	Sep 22 2021 06:21
MAILCHIMP_LIST_ID         	d2189324151991635af1b819e4c7cdec	Sep 22 2021 06:21
NEW_PHONE_NUMBER          	cf20024b57b68a58d899b57d189890d0	Sep 22 2021 06:20
PHONE_NUMBER              	303fb37e1236cd9e313b2c6a570ad33e	Sep 22 2021 06:20
RELEARELEASE_COOKIE       	3f10bfb7bc9be16a9f331af5a30bf95d	Sep 28 2021 07:21
RELEASE_COOKIE            	3f10bfb7bc9be16a9f331af5a30bf95d	Sep 28 2021 07:21
SECRET_KEY_BASE           	dbd89d9dc3f5f9d434ae6a26bff6668f	Sep 22 2021 07:11
SLACK_OAUTH_TOKEN         	ea548f190d747424436ec0ce1625bbe4	Jan 31 2022 21:50
SLACK_WEBHOOK_URL         	f6a2b135d5f7b1dcda6977ba35a483f7	Sep 22 2021 06:18
TASK_RUNNER_CHECKIN_URL   	0b64fdb86e4a8ff3                	May 15 2023 05:05
TWILIO_ACCOUNT_SID        	c431ab6c18b27b96dfcdf1ca2e89e8e5	Sep 22 2021 06:17
TWILIO_AUTH_TOKEN         	052a24bc71d91c14f30a5023ba603995	Sep 22 2021 06:17
TWILIO_STATUS_CALLBACK    	ea660024b0edb40e                	Mar 28 2024 14:23
