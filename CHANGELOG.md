# 2022-03-14
  - Maps of all the riders integrated into rider search
  - Indicator when resending campaign messages
# 2022-02-10
  - Sorting for opportunities page
# 2022-01-29
  - Refresh of rider page
# 2022-01-12
  - Added emoji keyboard
# 2022-01-13
  - Edit tags for riders
# 2021-12-06
  - Add location picker to campaigns
# 2021-11-02
  - Duplicate previous campaign and message template
# 2021-10-25
  - Track dispatcher that sent a message, or campaign that it belongs to and display in the messaging page
# 2021-10-04
  - Redesigned campaigns list
  - During dispatching: search tasks via address
# 2021-09-27
  - Spreadsheets now can be loaded via URL pointing to sheet
# 2021-09-26
  - Deploy via Fly.io (prod and staging environments)
  - New sidepanel for campaign messaging
  - The analytics dashboard (ty Serena)
  - Only assign existing tasks in the auto-assign feature
# 2021-09-16
  - Finish moving everything to Phoenix 1.6/LiveView 0.16/HEEX templates
# 2021-08-15
  - Fix bug with deleting items
# 2021-08-12
  - Items for programs/campaigns
  - Only upload photos and videos
  - List campaigns in program page
# 2021-07-29
  - Scheduled message indicator in campaign list
# 2021-07-22
 - Fix bug in stats where we don't sort anymore
# 2021-07-20
- Schedule messages
- Fix issues where message screen hit the db on every keypress
# 2021-07-11
 - Fix bug in stats where we weren't using delivery_start right
# 2021-07-07
  - Show when a campaign is last messaged
# 2021-06-30
  - Add message status indicator:
     … -> sending
     → -> sent
     ✓ -> delivered
     ! -> failed
# 2021-06-21
- Add Programs to Sidebar/change icons
- Make all Campaigns require a program, display them properly

# 2021-06-16
- Speed up campaign index page
- Speed up messaging index page

# 2021-06-15
- Switch off break-word on messages view (@Jenna)

# 2021-06-12
- Use date and time pickers to store campaign dates instead of string

# 2021-06-11
- Add a global `hidePII()` and `showPII()` function

# 2021-06-08
- Add links to google drive to all media in smses
- Upload all the photos we've gotten to the new drive
-
# 2021-06-08
- Updated the photo call out to "Pics or it didn't happen - send a selfie that we can share on social media!"
- Add rider pronouns to printable sheets

# 2021-06-07
- Added date picker to the rider safety check field
- Include person's name in delivery text: e.g. "Hi Florence, it's Baylee from the Bike Brigade delivering for Seeds of Hope! I'll be arriving shortly with a delivery for you! Are you available to receive it?"
# 2021-06-01
- Added better date pickers for all date fields
- Added a range date picker for the Stats/Leaderboard page
- Added a start_date / end_date to campaigns (not user visible yet)
- Set default delivery date to today for new campaigns
- Create a form for programs
- Change spacing on the safety check tracker
- Fix issue with importing spreadsheets numbers with spaces in the phone column

# 2021-05-31
- Placeholder text for the pickup window in add rider to campaign form matches the campaign's pickup window
- Added tracking for last safety check for riders
- Order riders by name in campaigns
- Printable form for safety checks
- Changed the Print/Download menus on campaigns to be two dropdowns
- Improved design of printable assignment sheet (got rid of an extra vertical line, improved position of the new rider badge)
