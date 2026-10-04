# Web parity pass — Stage 1

This project is based on the user's current Web project, not the previous generated scaffold.

## Android reference
- Android `AttendanceViewModel.WorkerWeeklyData` is mirrored in `ProjectProvider.WorkerWeeklyData`.
- Android uses Sunday as the week start; Web does the same.
- Wage rules: Full/LEMBUR = 1.0 day, Half = 0.5 day, Lembur 1 = +Rp50.000, Lembur 2 = +Rp75.000.
- Salary net calculation: total wages - private weekly deduction - global kasbon.
- Paying salary creates the `Upah Gondes` transaction and resets attendance, weekly adjustments, and global kasbon for the paid week.

## Supabase contract
The Web reads/writes the same tables used by Android:
- `gondes_workers`
- `gondes_attendance`
- `gondes_adjustments`
- `gondes_kasbon_global`
- `gondes_kasbon_private`
- `transactions`

## Important
- Period definitions are intentionally kept as Android definitions. They are not fallback financial data.
- Financial totals are calculated from `transactions`.
- Firebase remains Firebase Hosting configuration only; no Firebase SDK was added because the Android project does not use Firebase as its application data backend.

## Next stage
After this foundation compiles in the user's Flutter environment, continue with visual/behavior parity for Dashboard, Attendance, Salary, Kasbon, Transactions, Material, and Reports.
