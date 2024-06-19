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


### App setup
