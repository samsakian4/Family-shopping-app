# Family Shopping Assistant

یک اپلیکیشن هوشمند مدیریت خرید و خانواده — Offline-First، Flutter + Supabase.

مشخصات کامل پروژه در پوشه `docs/` (مستندات اصلی که پروژه از روی آن‌ها
ساخته می‌شود) قرار دارد.

## وضعیت فعلی

**Milestone 1 — Foundation & MVP**

- [x] Phase 1 — Project Initialization ✅
- [x] Phase 2 — Authentication ✅
- [x] Phase 3 — User Profile ✅
- [x] Phase 4 — Family System ✅
- [x] Phase 5 — Shopping Lists ✅ (این فاز)
- [ ] Phase 6 — Shopping Items
- [ ] Phase 4 — Family System
- [ ] Phase 5 — Shopping Lists
- [ ] Phase 6 — Shopping Items
- [ ] Phase 7 — Local Database (Isar)
- [ ] Phase 8 — Synchronization
- [ ] Phase 9 — Basic Search
- [ ] Phase 10 — UI Polish
- [ ] Phase 11 — Testing
- [ ] Phase 12 — Documentation

## چیزی که در فاز ۱ ساخته شد

- ساختار پوشه‌بندی Feature-first / Clean Architecture کامل
  (`lib/core`, `lib/features/*`, `lib/shared`, `lib/services`, `lib/providers`)
- پیکربندی محیط بدون هاردکد (`lib/config/env_config.dart`)
- سیستم خطا (`Failure` / `Exception`) طبق معماری لایه‌ای
- Theme روشن/تاریک طبق Design System (رنگ، spacing، radius، انیمیشن)
- Router با GoRouter + Auth Guard (طبق 12_NAVIGATION.md)
- Dependency Injection با Riverpod (Supabase client, Secure Storage, Connectivity)
- CI اولیه (GitHub Actions: analyze + test)
- مستند راه‌اندازی محیط (`docs/ENVIRONMENT.md`)

## چیزی که در فاز ۲ (Authentication) ساخته شد

- مایگریشن `001_initial_auth_and_profiles.sql`: جدول `profiles` + RLS +
  تریگر ساخت خودکار پروفایل هنگام ثبت‌نام
- فیچر `auth` کامل طبق Clean Architecture:
  - Domain: `UserEntity`, `AuthRepository` (اینترفیس), Use Cases
    (SignUp/SignIn/SignOut/ResetPassword/GetCurrentUser) با اعتبارسنجی سمت کلاینت
  - Data: `UserModel`, `AuthRemoteDataSource` (Supabase Auth)،
    `AuthRepositoryImpl` با تبدیل خطاهای فنی به پیام‌های فارسی کاربرپسند
  - Presentation: `AuthController` (Riverpod AsyncNotifier)، صفحات
    Welcome / Login / Register / ForgotPassword
- Router: گارد احراز هویت واقعی وصل شد (دیگر placeholder نیست) — ورود
  موفق خودکار به `/home` هدایت می‌شود
- ویجت‌های مشترک پایه: `AppPrimaryButton`, `AppTextField`
- تست واحد برای اعتبارسنجی `SignUpUseCase`

هنوز خانواده و لیست خرید پیاده نشده — فاز بعد.

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

> ⚠️ این پروژه بدون یک پروژه Supabase واقعی (که خودتان می‌سازید) اجرا
> نمی‌شود — کلیدها هرگز داخل کد قرار داده نمی‌شوند.

## معماری

Clean Architecture / Feature-first، هر فیچر شامل:

```
features/<name>/
├── domain/         (entities, repository interfaces, usecases)
├── data/           (models, datasources, repository implementations)
├── application/    (orchestration، در صورت نیاز)
└── presentation/   (pages, widgets, providers)
```

جزئیات کامل در `docs/04_SYSTEM_ARCHITECTURE.md`.

## چیزی که در فاز ۳ (User Profile) ساخته شد

- مایگریشن `002_avatars_storage.sql`: باکت خصوصی `avatars` + Storage Policies
  (هر کاربر فقط پوشه خودش را می‌تواند آپلود/حذف کند)
- فیچر `settings` (بخش پروفایل):
  - Domain: `ProfileRepository`, `UpdateProfileUseCase`,
    `UploadAvatarUseCase` (با اعتبارسنجی حجم و فرمت فایل)
  - Data: `ProfileRemoteDataSource` (آپدیت جدول profiles + آپلود Storage)
  - Presentation: `ProfileController`, صفحات `SettingsPage` و
    `ProfileSettingsPage` (ویرایش نام، آپلود آواتار از گالری، خروج از حساب)
- Router: مسیرهای `/settings` و `/settings/profile` وصل شدند
- مقادیر واقعی پروژه Supabase در `scripts/run_dev.sh` / `scripts/build_web.sh`

## چیزی که در فاز ۴ (Family System) ساخته شد

- مایگریشن `003_family_system.sql`: جداول `families` / `family_members` /
  `invitations` + توابع RPC اتمیک (`create_family`, `join_family_by_code`,
  `leave_family`, `remove_family_member`, `regenerate_invite_code`) + RLS
  کامل (شامل گسترش پالیسی `profiles` برای دیدن پروفایل اعضای هم‌خانواده)
- فیچر `family` کامل: Domain (Entities, Repository, Use Cases)، Data
  (RPC calls + realtime stream اعضا)، Presentation
  (`FamilyController`, صفحات Family / Members / Invite)
- قانون نسخه ۱ اعمال شد: هر کاربر فقط عضو یک خانواده (constraint دیتابیس)
- Router: مسیرهای `/family`, `/family/members`, `/family/invite`

## چیزی که در فاز ۵ (Shopping Lists) ساخته شد

- مایگریشن `004_shopping_lists.sql`: جدول `shopping_lists` (شخصی/مشترک) +
  Soft Delete + توابع RPC (`soft_delete_shopping_list`,
  `restore_shopping_list`, `permanently_delete_shopping_list`,
  `purge_expired_trash`) + RLS
- فیچر `shopping` (بخش لیست‌ها): Domain/Data/Presentation کامل با realtime
- `ShoppingListsPage` با تب‌های شخصی/مشترک/آرشیو + دیالوگ ساخت لیست
  (انتخاب نوع فقط اگر عضو خانواده باشید)
- `TrashPage`: بازیابی/حذف دائم طبق قانون نگهداری ۳۰ روزه (FT-025)
- صفحه موقت جزئیات لیست (`/lists/detail/:id`) — آیتم‌های خرید در فاز بعد

## مرحله بعد

فاز ۶ (Shopping Items) — افزودن/ویرایش/حذف محصول، تیک خریداری‌شده،
دسته‌بندی، طبق `docs/03_FEATURE_LIST.md` (FT-023) و `docs/05_DATABASE_SCHEMA.md`.
