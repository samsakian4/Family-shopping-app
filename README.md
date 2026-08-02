# Family Shopping Assistant

یک اپلیکیشن هوشمند مدیریت خرید و خانواده — Offline-First، Flutter + Supabase.

مشخصات کامل پروژه در پوشه `docs/` (مستندات اصلی که پروژه از روی آن‌ها
ساخته می‌شود) قرار دارد.

## وضعیت فعلی

**Milestone 1 — Foundation & MVP**

- [x] Phase 1 — Project Initialization ✅
- [x] Phase 2 — Authentication ✅
- [x] Phase 3 — User Profile ✅ (این فاز)
- [ ] Phase 4 — Family System
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

## مرحله بعد

فاز ۴ (Family System) — ساخت خانواده، کد دعوت، مدیریت اعضا، طبق
`docs/16_AUTH.md`، `docs/03_FEATURE_LIST.md` (FT-010 تا FT-013).
