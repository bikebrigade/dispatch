# daisyUI migration

Moving the UI from a hand-ported Tailwind UI kit to daisyUI on Tailwind v4, so new features
(and `mix phx.gen.*` output) use a small, consistent component vocabulary and the design lives
in one theme instead of thousands of utility classes.

Conventions for new code are in `CLAUDE.md` (UI Conventions). `scripts/lint_ui` lists
remaining hard-coded palette colors (baseline before the migration: 766 lines in 61 files).

## Decisions

- Merge each phase / page group to `main` as it's done (staging deploy first), rather than a
  long-lived branch.
- Buttons move to Phoenix's `variant` attribute; `color` stays as an alias during the migration.
- Icons move to `<.icon name="hero-...">` (heroicons Tailwind plugin) in Phase 2.
- `bikebrigade-dark` is a QA tool until Phase 4 (anything not themed stands out in it); ship
  dark mode then if wanted.
- `space-*` isn't banned: convert it where it misbehaves (wrapping rows, direction changes at a
  breakpoint, children with their own margins or inline children).

## How each page is checked

1. Run `main` (port 4003) and the branch (port 4001); look at both at desktop and 390px wide.
2. Look for misaligned controls, inconsistent spacing, wrapping at narrow widths, mismatched
   control heights, truncation, broken native inputs.
3. Exercise states: open modals and slide-overs, submit invalid forms, select table rows,
   hover, empty states.
4. Switch to `bikebrigade-dark` (`document.documentElement.dataset.theme = "bikebrigade-dark"`)
   to spot hard-coded colors, and list leftover palette classes in the live DOM.
5. Run the tests; update any that assert on classes.

## Phase 0: Foundation

- [x] Vendor daisyUI 5.7.50; `bikebrigade` and `bikebrigade-dark` themes
- [x] UI conventions in `CLAUDE.md`
- [x] `scripts/lint_ui`
- [x] Dev-only component gallery at `/dev/components`
- [x] Confirm no visual change on existing pages (pixel-diffed 9 pages against main; removed a stray `btn` class on campaign show that daisyUI started styling)

## Phase 1: Core components (Phoenix 1.8 shape)

- [ ] Button: `variant` attr (keep `color`/`size` as aliases); today `clear` is invisible and `white`
      has no border (see the gallery)
- [ ] Input: fieldset/label structure, `hidden` type, `normalize_value`, `class`/`error_class`
      (replace `extra_class`), keep `help_text`; date/time inputs; default `id`/`errors` (it currently
      crashes without them outside a form field)
- [ ] Checkbox, radio group, toggle (real checkbox input)
- [ ] Table: `row_id`, `row_click`, `row_item`, streams; keep checkboxes/sort/stacking; the bulk-action
      bar currently covers the first column header
- [ ] Flash → `flash_group` with reconnect toasts
- [ ] Modal and slide-over on daisyUI modal/drawer styling (keep LiveView JS)
- [ ] New: `badge`, `card`, `stat`, `empty_state`, `dropdown`, `tooltip`; drop the app's custom
      `.dropdown`/`.tooltip`/`.link` CSS and the daisyUI excludes
- [ ] Acceptance: `mix phx.gen.live` output renders correctly unedited

## Phase 2: App shell

- [ ] Sidebar → daisyUI drawer + menu (incl. mobile menu)
- [ ] Root / public / fullscreen layouts, login page
- [ ] `<.icon name="hero-...">` replaces `<Heroicons.* />`

## Phase 3: Pages

### A. Campaigns
- [ ] Campaigns index
- [ ] Campaign show: tasks list, riders list, messaging form, message list
- [ ] Campaign new / edit, task form, duplicate, add rider
- [ ] Printable assignments, printable safety check

### B. Messaging
- [ ] Inbox (all / campaigns / bulk tabs), conversation, rider deliveries, presence
- [ ] SMS index (non-inbox users), SMS message list, bulk message form

### C. Riders
- [ ] Riders index (list + map), rider show, rider form, tags
- [ ] Rider / user selection components, location picker

### D. Admin
- [ ] Programs index / show / form / items
- [ ] Opportunities
- [ ] Banners
- [ ] Tags
- [ ] Users
- [ ] Delivery notes

### E. Stats
- [ ] Dashboard (Chart.js colors from the theme)
- [ ] Leaderboard, stats nav

### F. Rider-facing
- [ ] Rider home
- [ ] Delivery signup index / show
- [ ] Itinerary
- [ ] Profile
- [ ] Public delivery page (`/app/delivery/:token`)
- [ ] Calendar embed

## Phase 4: Cleanup

- [ ] Drop `@tailwindcss/forms` and the daisyUI excludes
- [ ] Delete dead custom CSS in `app.css`
- [ ] `scripts/lint_ui --strict` in CI
- [ ] Decide on shipping dark mode (theme toggle)
