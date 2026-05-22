# JobTracker — User Guide

This guide explains how to use JobTracker day-to-day to keep your job search organized.

---

## Overview of the window

When you open JobTracker you see a single window divided into three areas:

- **Toolbar** (top) — buttons to add a new application, export to CSV, and delete the selected one.
- **Search & Filter bar** — a text field for searching by company or title, and a status filter picker.
- **Application table** (main area) — a list of all your applications, one row per application, sorted with the most recently added at the top.
- **Detail panel** (right side) — shows full details of the selected application including description, salary, URL, and contact info.

Each row shows:

| Column | What it contains |
|---|---|
| Company | The name of the company (with a red dot if overdue for follow-up) |
| Job Title | The role you applied or are interested in |
| Status | A colour-coded badge showing where things stand |
| Date Applied | The date you recorded for this application |

If you have not added any applications yet, the table area shows a tray icon and the message "No applications yet. Click + to add one."

---

## Adding a job application

1. Click the **+** button in the top-right corner of the toolbar (or press **Cmd+N**). The Add Application sheet slides open.
2. Fill in the fields:
   - **Company Name** (required) — the name of the employer.
   - **Job Title** (required) — the role title.
   - **Description** (optional) — any notes you want to keep, up to 50,000 characters.
   - **Status** — choose the starting status from the picker (defaults to Pending).
   - **Date Applied** — the date you applied or first engaged with the role (defaults to today).
   - **Follow-up Date** (optional) — toggle the checkbox and pick a date to set a reminder. If the date passes without the application reaching a terminal state, a red overdue indicator appears on the row.
   - **Salary** (optional) — hidden by default; click the eye icon to reveal while typing.
   - **Job URL** (optional) — a link to the job posting.
   - **Contact Name** (optional) — the name of your recruiter or hiring manager.
   - **Contact Email** (optional) — their email address.
3. Click **Save** (or press Return). The sheet closes and the new application appears at the top of the list.

If either the Company Name or Job Title is empty, the Save button is disabled and an error message appears below the relevant field. Fill in both required fields to enable saving.

To close the sheet without saving, click **Cancel** or press Escape.

---

## Editing an application

All fields are editable inline directly in the list row:

- **Company Name, Job Title**: click the cell and type. Press Return to save.
- **Status**: click the status badge to open the dropdown picker. Selecting a new status saves immediately.
- **Date Applied**: click the date text and type a new date in MM/DD/YYYY format. Press Return to save.

To edit additional fields (description, follow-up date, salary, URL, contacts), right-click the row and choose **Edit** from the context menu. The Edit Application sheet opens with all fields pre-populated.

---

## Detail panel

Selecting any row shows a detail panel on the right side of the window. The panel displays:

- **Company name and job title** (header)
- **Follow-up date** — shown with a bell icon; turns red when overdue
- **Salary** — hidden by default with a reveal toggle (eye icon)
- **Job URL** — displayed as a clickable link
- **Contact name and email**
- **Full description** — with text selection enabled

The bottom of the panel has **Clear** (removes the description) and **Copy** (copies description to clipboard) buttons.

---

## Search and filter

The search/filter bar appears above the application list:

- **Search field** — type to filter by company name or job title. The filter is live (updates as you type). Press **Cmd+F** to focus the search field. Click the X button to clear.
- **Status filter** — use the dropdown to show only applications with a specific status. Select "All Statuses" to clear the filter.

When filters are active and no results match, the message "No applications match your search." is displayed.

---

## Follow-up date and overdue indicator

When you set a follow-up date on an application:

- A small **red dot** appears before the company name in the list row when the follow-up date has passed and the application is not in a terminal state (Hired or Ghosted).
- The detail panel shows the follow-up date with a bell icon; the text turns **red** when overdue.

This helps you identify applications that need your attention.

---

## Salary, URL, and contact fields

- **Salary**: hidden by default in both the form and the detail panel. Use the eye icon to toggle visibility. This prevents shoulder-surfing when sharing your screen.
- **Job URL**: shown as a clickable link in the detail panel.
- **Contact Name / Email**: displayed in the detail panel for quick reference.

---

## Updating the status of an application

Status can be changed directly in the list row by clicking the status badge and selecting a new value from the dropdown. The change is saved immediately.

Alternatively, right-click the row > Edit, and change the status in the form.

---

## Deleting an application

### Using the toolbar

1. Click the row you want to delete to select it (the row highlights).
2. Click the **trash icon** in the toolbar (or press the **Delete** key).
3. A confirmation dialog appears: "Delete Application — This action cannot be undone."
4. Click **Delete** to confirm, or **Cancel** to keep the application.

### Using the context menu

1. Right-click the row you want to delete.
2. Choose **Delete** from the context menu.
3. Confirm in the dialog that appears.

Deletion is permanent. There is no undo.

---

## CSV export

Click the **export button** (square with up-arrow icon) in the toolbar to export all your applications to a CSV file. A save dialog will appear where you can choose the file name and location.

The CSV includes all fields: Company, Job Title, Status, Date Applied, Follow-Up Date, Salary, URL, Contact Name, Contact Email, and Description. The export button is disabled when you have no applications.

---

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| Cmd+N | Open the Add Application form |
| Delete | Delete the selected application (shows confirmation) |
| Cmd+F | Focus the search field |
| Escape | Close the form sheet / cancel |
| Return | Save (when form is focused) |

---

## Understanding status colours and meanings

Each application has a status that reflects where it is in your job search process. The status is displayed as a colour-coded pill badge in the Status column.

| Badge | Colour | Meaning |
|---|---|---|
| Pending | Orange | You have noted this opportunity but have not yet submitted an application. |
| Applied | Blue | You have submitted an application and are waiting to hear back. |
| In Process | Purple | Active engagement is happening — for example, you have had an initial screen, are in interviews, or have a take-home task underway. |
| Waiting | Cyan-teal | You have completed a round of interviews and are waiting for a decision or next step. |
| Hired | Green | You received and accepted an offer. This is a final state — no further updates are expected. |
| Ghosted | Red | The employer stopped responding. This is a final state — no further updates are expected. |

**Terminal statuses** (Hired and Ghosted) use a slightly bolder font weight in the badge to make them easier to distinguish from active statuses at a glance. Once an application reaches a terminal status, it represents a closed chapter — you may keep the record for reference or delete it.

**Colour logic at a glance:**
- Warm colours (orange) signal items that need your attention.
- Cool colours (blue, purple, cyan-teal) signal active progress or waiting.
- Green means a successful outcome.
- Red means the process ended without a response.

---

## Tips for keeping your list useful

- **Add applications early.** Create a Pending record the moment you identify a role worth pursuing, even before you apply. This ensures nothing slips through.
- **Update status promptly.** After every meaningful event (submitted application, interview, offer), update the status so the table always reflects reality.
- **Set follow-up dates.** Use the follow-up date to remind yourself to check in. The overdue indicator makes stale applications easy to spot.
- **Use the salary field.** Record offered or expected salary with the eye-toggle for privacy.
- **Paste the job URL.** Having the link in the detail panel saves time when you need to reference the posting.
- **Delete closed applications periodically.** Hired and Ghosted applications are terminal. Once you no longer need them for reference, deleting them keeps the active list shorter and easier to scan.
- **Use search and filter.** As your list grows, use Cmd+F to quickly find applications by company or title, or filter by status to focus on active opportunities.
- **Export before cleanup.** Use CSV export to back up your data before bulk-deleting old applications.
- **The newest-first sort is automatic.** New applications always appear at the top, so you do not need to scroll to find recent additions.
