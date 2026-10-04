# Implementation Plan - Connect Role to User Profile

I will modify the application to fetch and display the specific user profile associated with the logged-in role ('admin' or 'owner'). Currently, the application fetches a generic profile; this change will ensure that when "Aidan" logs in as Admin, he sees his profile, and when "Boi Khian" logs in as Owner, he sees his.

## Proposed Changes

### Supabase Service
#### [MODIFY] [supabase_service.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/services/supabase_service.dart)
- Update `getUserProfile` to accept a `String id` parameter.
- Change the query to `.eq('id', id).maybeSingle()` to fetch the profile matching the role ID.

### Project Provider
#### [MODIFY] [project_provider.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/services/project_provider.dart)
- Update `refreshData` to accept an optional `String? profileId`.
- Pass this `profileId` to `_service.getUserProfile`.

### Authentication Flow
#### [MODIFY] [login_screen.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/screens/login_screen.dart)
- After a successful login, call `provider.refreshData(profileId: role)` to load the correct user data immediately.

#### [MODIFY] [main.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/main.dart)
- When the app starts and `AuthProvider` confirms the user is authenticated, we need a way to ensure the profile is loaded. I'll modify `DataKonstruksiApp` to trigger a data refresh when authentication state is confirmed.

## Verification Plan

### Manual Verification
1. **Login as Admin**: Verify the dashboard shows "Aidan Suhendy" and "Manager".
2. **Login as Owner**: Verify the dashboard shows "BOI KHIAN" and "Owner".
3. **Logout/Login Swap**: Switch between accounts and ensure the profile updates instantly without a full app restart.
