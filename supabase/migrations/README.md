# Migrations

Naming convention (26_DATABASE_MIGRATION_STRATEGY.md):

```
[number]_[description].sql
```

Migrations are added feature-by-feature, in the order features are built
(matching 35_MILESTONE_1.md phases), not all up front. The first migration
(`001_initial_auth_and_profiles.sql`) is added in the **Auth** phase.

Rules:
- Never edit an already-applied migration; add a new one.
- Every migration that creates a user-data table must enable RLS in the
  same migration (08_SECURITY.md).
- Apply via `supabase db push` or the SQL editor, in numeric order.
