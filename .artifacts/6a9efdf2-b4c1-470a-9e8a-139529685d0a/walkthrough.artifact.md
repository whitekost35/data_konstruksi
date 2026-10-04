# Walkthrough - Role-Based User Profiles

I have successfully connected the login roles to specific user profiles. Now, the application automatically displays the correct identity (Aidan Suhendy or Boi Khian) based on the PIN entered.

## Key Changes

### 1. Dynamic Profile Fetching
- **[SupabaseService](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/services/supabase_service.dart):** Updated `getUserProfile` to accept an `id` parameter. It now queries the `app_profiles` table specifically for the profile matching the user's role.
- **[ProjectProvider](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/services/project_provider.dart):** Added `_lastProfileId` state to remember who is logged in. This ensures that even when data is refreshed (e.g., after adding a transaction), the profile remains correctly loaded.

### 2. Authentication Integration
- **Immediate Load:** When a user enters their PIN on the [Login Screen](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/screens/login_screen.dart), the application immediately triggers a data sync for that specific role.
- **Startup Sync:** Added logic to `MainShell` and `MobileMainShell` to ensure the profile is fetched correctly if the user was already logged in (auto-login).
- **Session Cleanup:** Implemented `clearProfile()` which is called during logout to reset the identity state for the next login.

## Verification
- [x] **Login as Admin (`060896`):** Dashboard displays **"Aidan Suhendy"** with status **"Manager"**.
- [x] **Login as Owner (`010735`):** Dashboard displays **"BOI KHIAN"** with status **"Owner"**.
- [x] **Persistence:** Closing and reopening the app keeps the correct profile visible.
- [x] **Logout:** Switching roles correctly swaps the profile data.

> [!NOTE]
> The profile data is pulled directly from your Supabase `app_profiles` table. Any changes you make to the names, status, or photo URLs in that table will reflect in the app upon the next login or refresh.
