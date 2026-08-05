# Family Shopping Assistant

یک اپلیکیشن هوشمند مدیریت خرید و خانواده — Offline-First، Flutter + Supabase.

مشخصات کامل پروژه (۳۸ سند اصلی که این کد از روی آن‌ها ساخته شده) در
پوشه [`docs/`](docs/) قرار دارد.

## وضعیت فعلی

**✅ Milestone 1 — Foundation & MVP: کامل شد (۱۲ فاز، ۱۳ کامیت)**

| فاز | وضعیت |
|---|---|
| 1. Project Initialization | ✅ |
| 2. Authentication | ✅ |
| 3. User Profile | ✅ |
| 4. Family System | ✅ |
| 5. Shopping Lists | ✅ |
| 6. Shopping Items | ✅ |
| 7. Local Database (Isar) | ✅ |
| 8. Synchronization (شامل تشخیص تعارض واقعی) | ✅ |
| 9. Basic Search | ✅ |
| 10. UI Polish | ✅ |
| 11. Testing (۴۶ کیس تست) | ✅ |
| 12. Documentation | ✅ (همین سند) |

قدم بعدی طبق روادمپ خود پروژه: [`docs/36_MILESTONE_2.md`](docs/36_MILESTONE_2.md)
(Smart Shopping & Intelligence — قیمت‌گذاری، AI، جستجوی هوشمند).

**برای جزئیات فنی:**
- چه چیزی واقعاً ساخته شد، تفاوت با طرح اولیه، محدودیت‌های شناخته‌شده →
  [`docs/IMPLEMENTATION_SUMMARY.md`](docs/IMPLEMENTATION_SUMMARY.md)
- تاریخچه گام‌به‌گام هر فاز + نتایج بازبینی فنی (Loop Engineering) →
  [`docs/LOOP_ENGINEERING_LOG.md`](docs/LOOP_ENGINEERING_LOG.md)

## راه‌اندازی

ببینید [`docs/ENVIRONMENT.md`](docs/ENVIRONMENT.md).

خلاصه:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

یا برای این پروژه مشخص (مقادیر واقعی از قبل در اسکریپت‌ها هست):

```bash
./scripts/run_dev.sh
```

> ⚠️ قبل از اولین اجرا، مایگریشن‌های `supabase/migrations/*.sql` را به
> ترتیب شماره روی پروژه Supabase‌تان اجرا کنید (SQL Editor یا
> `supabase db push`).

## معماری

Clean Architecture / Feature-first، هر فیچر شامل:

```
features/<name>/
├── domain/         (entities, repository interfaces, usecases)
├── data/           (models, datasources, repository implementations)
├── application/    (orchestration، در صورت نیاز)
└── presentation/   (pages, widgets, providers)
```

نکته‌ی مهم: لایه‌ی Data از فاز ۸ به بعد **cache-centric** است — یعنی
واسط کاربری همیشه از Isar می‌خواند، نه مستقیم از Supabase. جزئیات کامل
در `docs/IMPLEMENTATION_SUMMARY.md`.

معماری طرح اولیه در `docs/04_SYSTEM_ARCHITECTURE.md`.

## تست

```bash
flutter test
```

۱۲ فایل، ۴۶ کیس تست واحد/ویجت. فهرست کامل پوشش در
`docs/LOOP_ENGINEERING_LOG.md` (بخش فاز ۱۱).

## ساختار پروژه

```
lib/
├── core/         تنظیمات مشترک: theme, router, errors, local db, sync engine
├── config/       env_config.dart (بدون هاردکد سکرت)
├── providers/    DI مشترک (Supabase client, Isar, network info, sync queue)
├── shared/       ویجت‌های مشترک (AppButton, AppTextField, AppEmptyState, ...)
└── features/     auth, settings, family, shopping (هر کدام Clean Architecture کامل)

supabase/
├── migrations/   ۵ فایل SQL به ترتیب اجرا
└── functions/    (خالی — فاز بعدی Milestone که Edge Function لازم دارد)

docs/             مستندات اصلی پروژه (۰۰-۳۸) + مستندات تولیدشده حین ساخت
test/             unit/ و widget/
```
