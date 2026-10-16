# Unified messaging rollout

Run the database migration before deploying the new inbox. The flag is off by default.

Dispatchers can opt a user in through **Users → Edit → Unified messaging inbox**.
The existing rollout task also supports dispatcher users:

```sh
mix feature_flags unified_messaging user dispatcher@example.com true
mix feature_flags unified_messaging user dispatcher@example.com false
mix feature_flags unified_messaging 25
mix feature_flags unified_messaging 100
mix feature_flags unified_messaging 0
```

Percentage rollouts use deterministic user-ID buckets. Setting `0` disables the
inbox for all dispatchers; saved groups and messages remain in the database.
Other existing rider flags continue to use the original task behavior.

Enabled users visiting `/messages` open `/messages/inbox`. Rider conversation
links continue to work. Delivery-task details remain available on their existing
route. The new inbox is guarded by both dispatcher authorization and the opt-in.

Campaigns include campaigns overlapping the current Toronto-local week,
Monday–Sunday. **Only my campaigns** defaults on and filters by program lead.
Campaign membership supplies the recipient roster, including backup riders.

**Save this group** is optional for a new bulk message. Saved groups store the
creator, initial body, and a snapshot of recipients in PostgreSQL. They are shared
between dispatchers, and reopening one shows individual rider conversations.
Messaging a campaign or an existing saved group does not create another group.

Sends use the existing SMS service, signatures, attachments, initial-message flow,
and status callbacks. Each rider receives a separate message. Sends are processed
synchronously, matching the existing bulk-send implementation; saved groups are
durable, but there is no new background delivery queue. Partial failures identify
the riders who need an individual retry rather than resending to successful riders.
