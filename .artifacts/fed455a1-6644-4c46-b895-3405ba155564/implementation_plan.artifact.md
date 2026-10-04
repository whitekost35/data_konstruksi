# Implementation Plan - Fix Tagihan Koko Functionality

I will fix the non-functional buttons in the "Tagihan Koko" dialog. The root cause is likely an invalid UUID format being sent to Supabase, causing database operations to crash silently. I will also improve error handling and row management.

## User Review Required

> [!IMPORTANT]
> I will update the database interaction logic to let Supabase generate unique IDs (UUIDs) automatically. This ensures compatibility with the database schema you just initialized.

## Proposed Changes

### Models
#### [MODIFY] [koko_bill.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/models/koko_bill.dart)
- Update `toMap()` methods to exclude the `id` field if it is empty or doesn't follow the UUID format. This allows Supabase's `uuid_generate_v4()` to take over for new entries.

### Services
#### [MODIFY] [supabase_service.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/services/supabase_service.dart)
- Refactor `upsertKokoPeriod` and `upsertKokoEntry` to handle new inserts properly.

#### [MODIFY] [project_provider.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/services/project_provider.dart)
- Wrap all Koko-related methods in the `_run` helper to ensure proper state management (`isSyncing`) and error reporting.
- Ensure `refreshData` is called after every Koko operation to keep the UI in sync.

### UI Components
#### [MODIFY] [tagihan_koko_dialog.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/widgets/tagihan_koko_dialog.dart)
- Add a loading overlay that triggers when `p.isSyncing` is true, providing visual feedback during database operations.
- Display error messages if `p.lastError` is not null.
- Fix row addition logic to ensure a clean state for new rows.

## Verification Plan

### Manual Verification
- **Add Row:** Open the dialog and click the **(+)** button. Verify that a new row appears immediately.
- **Edit Data:** Type a transaction name and price. Verify that it persists after closing and reopening the dialog.
- **Delete Row:** Click the **(-)** button. Verify the last row is removed.
- **Date Sync:** Change the "Dari" or "Sampai" dates. Verify the sidebar updates its "Rentang Waktu" label.
- **Numbering:** Verify that "Mykost 179" numbering starts exactly after "White Kost 35".

### Automated Tests
- Ran `flutter analyze`: Success.
