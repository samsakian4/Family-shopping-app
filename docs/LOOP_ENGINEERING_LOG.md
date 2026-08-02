# Loop Engineering Log

هر فاز، در پایان، یک دور بازبینی/تست می‌شود. چون این محیط به Flutter/Dart
SDK و pub.dev دسترسی ندارد، `flutter analyze` / `flutter test` واقعی اینجا
اجرا نمی‌شود — این بازبینی جایگزین آن با ابزارهای موجود (grep/python) است.
تأیید نهایی هر فاز را باید CI روی گیت‌هاب (`.github/workflows/ci.yml`) یا
اجرای محلی شما انجام بدهد.

---

## فاز ۴ — Family System

بررسی‌های انجام‌شده:

| # | بررسی | نتیجه |
|---|--------|--------|
| 1 | همه‌ی `import 'package:family_shopping_app/...'` به فایل موجود اشاره می‌کنند | ✅ |
| 2 | همه‌ی کلاس/تابع‌های `@riverpod` دارای `part '*.g.dart'` هستند | ✅ |
| 3 | نام توابع RPC فراخوانی‌شده در Dart (`create_family`, `join_family_by_code`, `leave_family`, `remove_family_member`, `regenerate_invite_code`) دقیقاً با نام توابع تعریف‌شده در `003_family_system.sql` یکی است | ✅ |
| 4 | پکیج‌های import‌شده در `lib/` همگی در `pubspec.yaml` تعریف شده‌اند | ✅ |
| 5 | مقادیر `enum FamilyRole` (owner/admin/member) با `CHECK` constraint جدول `family_members` یکی است | ✅ |
| 6 | بلوک‌های `$$ ... $$` در هر سه فایل مایگریشن زوج‌اند (نشانه‌ی عدم break شدن یک تابع PL/pgSQL) | ✅ |
| 7 | تست واحد برای `CreateFamilyUseCase` و `JoinFamilyUseCase` (اعتبارسنجی ورودی خالی + تحویل صحیح به Repository) نوشته شد | ✅ اضافه شد در `test/unit/features/family/family_usecases_test.dart` |

باقی‌مانده برای تست دستی روی محیط واقعی (چون اینجا اجرا نمی‌شود):

- [ ] اجرای واقعی مایگریشن‌ها روی پروژه Supabase (`supabase db push` یا SQL Editor)
- [ ] تست دستی: ساخت خانواده → دیدن کد دعوت → پیوستن با یوزر دوم → دیدن realtime در لیست اعضا
- [ ] تست RLS: کاربر خارج از خانواده نباید بتواند `family_members` یا `profiles` اعضای آن خانواده را بخواند
- [ ] `flutter analyze` و `flutter test` روی CI پس از اولین push

---

## فاز ۱–۳ (بازبینی گذشته‌نگر خلاصه)

در زمان ساخت فازهای ۱ تا ۳ این لاگ هنوز وجود نداشت. بازبینی خلاصه انجام‌شده:
- ساختار پوشه‌ها و pubspec با معماری مستندشده مطابقت دارد.
- تست واحد `SignUpUseCase` در فاز ۲ نوشته شد.
- تست دستی end-to-end (ثبت‌نام/ورود/آپلود آواتار واقعی) هنوز روی پروژه
  Supabase واقعی انجام نشده — در فهرست "باقی‌مانده" فاز بعد قرار می‌گیرد.
