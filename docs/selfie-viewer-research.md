# Selfie viewer research

Researched 2026-11-05 in a separate agent fork. This is a proposed design, not an implemented or live-verified viewer.

## Recommendation

Yes: an in-app viewer is practical while keeping Drive as the source of truth. Start with a dispatcher-only gallery: responsive thumbnail grid, filenames and dates, a larger preview, previous/next controls, and an “Open in Drive” link. Load one page at a time. A rider-facing gallery needs stronger ownership metadata first.

The important implementation detail is a server-side image proxy. Google documents `thumbnailLink` as temporary (typically hours), potentially requiring credentials, and unsuitable for direct web use; it recommends a proxy. Never persist these URLs as permanent image addresses or expose service-account tokens to browsers. [Drive File resource](https://developers.google.com/workspace/drive/api/reference/rest/v3/files)

## What the repository already provides

- `lib/bike_brigade/google/base.ex` obtains service-account credentials through Goth and builds authorized Req requests. Its existing scopes include full Drive access. A new end-user Google login is unnecessary for this proposed server-mediated viewer, provided the service account can read the files.
- `lib/bike_brigade/google/drive.ex` currently implements uploads from a URL, with shared-drive support. It has no listing, metadata retrieval, or image download function yet.
- `lib/bike_brigade/messaging/google_drive_upload.ex` uploads permitted SMS media into one fixed folder. It names files with the message date and rider name, sometimes adding a campaign name parsed from the message body. It also accepts video, so a gallery cannot assume every folder entry is a photo.
- SMS media embeds retain `gdrive_url` and `gdrive_folder_url`, but no dedicated Drive ID field. SMS records themselves have rider and optional campaign associations, which may help a later historical import.
- `router.ex` has established dispatcher authentication for both LiveViews and controllers. The public `/app/delivery/:token` route identifies a particular campaign/rider; it should not expose the entire Drive folder.
- Existing `MediaStorage` writes to Google Cloud Storage for other features; it is separate from this Drive integration.

These are code observations only. No production credentials, files, or folder permissions were inspected.

## Proposed implementation

### 1. Paginated metadata listing

Add `Drive.list_images(folder_id, opts)` using `Google.request()` and `GET https://www.googleapis.com/drive/v3/files`. Keep the folder server-controlled. Suggested parameters:

```text
q = '<configured-selfie-folder>' in parents and trashed = false and mimeType contains 'image/'
pageSize = 36
orderBy = modifiedTime desc,name
fields = nextPageToken,incompleteSearch,files(id,name,mimeType,createdTime,modifiedTime,thumbnailLink,thumbnailVersion,webViewLink,parents,capabilities(canDownload))
supportsAllDrives = true
includeItemsFromAllDrives = true
```

Use `corpora=drive` plus the actual shared-drive ID if the configured folder belongs to a shared drive; the folder ID is not a substitute for that drive ID. Otherwise start with `corpora=user`. Google recommends these narrower corpora over `allDrives`; shared-drive inclusion needs the relevant flags. [Shared drive support](https://developers.google.com/workspace/drive/api/guides/enable-shareddrives)

`files.list` supplies `nextPageToken`; do not infer completion from page length. Follow tokens even after a short page, reset pagination if a token is rejected, and deduplicate by file ID when results change. Surface `incompleteSearch` rather than silently claiming the gallery is complete. Google's current reference warns that `createdTime` sorting on large collections can time out; `modifiedTime desc` is the proposed initial order. This orders updates, not delivery dates. [Files list reference](https://developers.google.com/workspace/drive/api/reference/rest/v3/files/list)

Use an asynchronous LiveView load with skeletons and an explicit retry state. A “Load more” button is a simple accessible first version; avoid enumerating the entire historical folder before rendering.

### 2. Authorized image endpoints

Add dispatcher-only controller routes, for example `/selfies/:id/thumbnail` and `/selfies/:id/image`. Both must run through the same dispatcher authorization as the gallery: an `<img>` request does not inherit LiveView authorization automatically.

Before fetching bytes, retrieve metadata and verify the file is an untrashed image directly inside the configured folder. Validate on proxy requests too; otherwise someone could substitute the ID of an unrelated private Drive file readable by the service account. Initially deny shortcuts and unexpected types. Never accept an arbitrary proxy URL from the browser.

For thumbnails, fetch Google's returned link on the server. Implement this as a narrow internal fetch path: HTTPS and verified Google thumbnail host only, with redirect validation so authorization headers cannot escape to unrelated hosts. On an expired link, refresh metadata and retry once. Return a placeholder on missing/not-yet-generated thumbnails and offer “Open in Drive.” `hasThumbnail` alone does not guarantee thumbnail access. [Drive File resource](https://developers.google.com/workspace/drive/api/reference/rest/v3/files)

For the larger image, use authorized `files.get` with `alt=media` and shared-drive support, checking `capabilities.canDownload`. Blob images are downloaded through this endpoint. [Download guide](https://developers.google.com/workspace/drive/api/guides/manage-downloads)

Keep upstream errors out of user-facing responses. Use finite timeouts, bounded response sizes and concurrency, and verify image response content types. Restrict initial inline rendering to supported raster formats; do not serve arbitrary SVG or HTML with app-origin privileges. Fetch originals only when a preview opens, not for every grid tile.

### 3. Caching and phone behavior

Suggested starting values, to tune after measuring: cache listing metadata for 30–60 seconds and thumbnail bytes for 5–15 minutes, keyed by file ID and thumbnail version. Use a bounded cache and private browser caching. Do not use a public CDN cache for these private photos. Reauthorize access before serving cached bytes; keep cache lifetime short enough that moved/deleted files disappear promptly.

Use `loading="lazy"`, fixed thumbnail aspect ratios, visible loading/error placeholders and mobile-sized touch targets. Keep full-resolution bytes out of LiveView assigns and websocket messages. Use the existing core modal with keyboard controls, focus handling, an accessible close button, and caption text. Initially support images; show video entries separately with “Open in Drive” if needed rather than downloading videos into the grid.

### 4. Associate new uploads precisely

Before a per-campaign or rider-only gallery, record the Drive file ID with `campaign_id`, `rider_id`, upload time and source in the app database, or add structured Drive `appProperties` during upload. Google supports application-private metadata and searching these properties. Store opaque IDs rather than rider contact details. [Custom file properties](https://developers.google.com/workspace/drive/api/guides/properties)

Prefer an app table if exact local joins and reliable filtering become requirements. A successful Drive upload followed by a failed database write needs reconciliation; the Drive file ID can be the deduplication key. Private Drive properties are another useful recovery aid if confirmed with the production service account.

Historical filenames are useful captions but are not reliable authorization or campaign identity. Existing SMS associations may recover some links, but incomplete associations must remain explicitly unknown. A folder-wide dispatcher gallery can show old files without that migration.

## Validation before shipping a viewer

- Stub list responses with multiple pages, short pages, rejected tokens, and incomplete searches; verify filters and selected fields.
- Check both gallery and binary endpoints deny unauthenticated/rider requests and unrelated file IDs, including when cached.
- Exercise private thumbnails, expired links, absent thumbnails, a deleted/moved file, and a Drive outage with retries/placeholders.
- Confirm actual service-account list/read/download permission against a deliberately selected test image and verify whether the folder is in a shared drive. Existing upload success alone does not prove every historical file is readable.
- Check iOS Safari and Android Chrome with a realistically sized gallery: first grid render, lazy loading, modal size, orientation, and keyboard navigation on desktop.
- Measure upstream calls and transferred bytes. If Drive thumbnail access is inconsistent or volume makes proxying expensive, evaluate generating bounded-size previews into private app-managed storage while retaining originals in Drive.

The simplest useful first release is therefore the authenticated gallery and thumbnail proxy, with Drive links as a fallback. Reliable campaign filtering and a rider-visible historical viewer are follow-on work requiring structured associations.
