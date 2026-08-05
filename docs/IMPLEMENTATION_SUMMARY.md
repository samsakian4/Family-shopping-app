# Implementation Summary (Milestone 1)

این سند خلاصه‌ی **آنچه واقعاً ساخته شد** است — برای وقتی که مستندات
اصلی پروژه (۰۰ تا ۳۸) طرح اولیه را توصیف می‌کنند اما پیاده‌سازی واقعی
جزئیاتی دارد که فقط حین ساخت مشخص شدند. برای تاریخچه‌ی گام‌به‌گام هر
فاز (شامل چیزهایی که عمداً کم‌وکم گذاشته شدند)، `LOOP_ENGINEERING_LOG.md`
را ببینید.

## پایگاه داده (واقعی، نه فقط طرح)

۵ فایل مایگریشن به ترتیب اجرا می‌شوند (`supabase/migrations/`):

| فایل | چه چیزی می‌سازد |
|---|---|
| `001_initial_auth_and_profiles.sql` | `profiles` + RLS + تریگر ساخت خودکار پروفایل |
| `002_avatars_storage.sql` | باکت خصوصی `avatars` + Storage Policies |
| `003_family_system.sql` | `families`/`family_members`/`invitations` + توابع RPC اتمیک (`create_family`, `join_family_by_code`, `leave_family`, `remove_family_member`, `regenerate_invite_code`) + گسترش RLS پروفایل برای دیدن اعضای هم‌خانواده |
| `004_shopping_lists.sql` | `shopping_lists` (شخصی/مشترک) + Soft Delete + RPC های Trash (`soft_delete_shopping_list`, `restore_shopping_list`, `permanently_delete_shopping_list`, `purge_expired_trash`) |
| `005_shopping_items.sql` | `categories` (با seed پیش‌فرض) + `shopping_items` + RPC `mark_item_purchased` + تریگر خودکار `recalc_list_estimated_total` |

نکته‌ی مهم غیر بدیهی: خیلی از عملیات‌های نوشتنی به‌جای `insert`/`update`
مستقیم از کلاینت، از طریق **توابع RPC با `security definer`** انجام
می‌شوند (مثلاً `create_family`, `soft_delete_shopping_list`). دلیل: این
عملیات‌ها چند جدول را با هم دست می‌زنند یا قوانین کسب‌وکاری دارند
(مثلاً «هر کاربر فقط عضو یک خانواده») که با RLS تنها به‌سختی و با ریسک
race condition قابل تضمین‌اند. تابع RPC این منطق را در یک تراکنش اتمیک
نگه می‌دارد.

## معماری کلاینت (تفاوت با طرح اولیه)

طرح اولیه (`04_SYSTEM_ARCHITECTURE.md`) یک لایه Repository ساده با
Isar-به‌عنوان-کش را توصیف می‌کند. آنچه واقعاً از فاز ۸ به بعد پیاده شد
دقیق‌تر است:

- **UI هرگز مستقیماً استریم Supabase Realtime را نمی‌خواند.** فقط
  `Isar.watch()` را می‌خواند. یک subscription پس‌زمینه‌ی idempotent
  (در خود Repository) استریم realtime را به کش merge می‌کند.
- نوشتن‌ها (`create`/`update`/`delete`) همیشه اول در کش اعمال می‌شوند
  (optimistic)، بعد یا مستقیم به Supabase می‌روند (اگر آنلاین) یا در
  `SyncQueueEntry` صف می‌شوند (اگر آفلاین).
- شناسه‌ی هر رکورد **همیشه** سمت کلاینت با UUID تولید می‌شود (چه آنلاین
  چه آفلاین) — نه با `default uuid_generate_v4()` سمت دیتابیس — تا هیچ‌وقت
  دو شناسه‌ی متفاوت برای یک رکورد منطقی به وجود نیاید.
- **تشخیص تعارض واقعی**: هر ویرایش صف‌شده `base_updated_at` حمل می‌کند؛
  `SyncEngine` قبل از اعمال، نسخه فعلی سرور را می‌گیرد و مقایسه می‌کند.

جزئیات کامل و تصمیم‌های رد شده در بخش «فاز ۸» و «فاز ۸ (رفع تشخیص
تعارض)» در `LOOP_ENGINEERING_LOG.md`.

## فیچرهای کامل (Milestone 1)

- Auth: ثبت‌نام، ورود، خروج، فراموشی رمز، پایداری نشست
- Profile: ویرایش نام، آپلود آواتار، (زبان/تم در دیتابیس رزرو شده، UI انتخاب هنوز ساخته نشده)
- Family: ساخت/پیوستن با کد دعوت/مدیریت اعضا/نقش‌ها/ترک خانواده
- Shopping Lists: شخصی/مشترک/آرشیو/سطل زباله (نگهداری ۳۰ روزه)
- Shopping Items: افزودن/ویرایش/حذف/تیک خریداری‌شده/دسته‌بندی
- Offline: خواندن کاملاً آفلاین‌محور؛ نوشتن آفلاین برای لیست‌ها و آیتم‌ها
  با صف Sync و تشخیص تعارض
- Search: Autocomplete محلی (بدون کاتالوگ محصول یا AI)
- Dashboard واقعی با خلاصه وضعیت

## فیچرهای این مستندات که در Milestone 1 نیستند (طبق روادمپ خودشان)

طبق `23_DEVELOPMENT_ROADMAP.md` و `35/36/37_MILESTONE_*.md`، این‌ها عمداً
خارج از این Milestone‌اند: AI Assistant، Price Estimation از منابع
خارجی (فعلاً فقط دستی)، Barcode/OCR، Pantry، Budget Management،
Push Notifications، Reports/Analytics. اگر می‌خواهید ادامه بدهید،
`35_MILESTONE_1.md` تمام شده — قدم بعد `36_MILESTONE_2.md` است.

## چیزهایی که این محیط نمی‌توانست انجام بدهد

- اجرای واقعی `flutter analyze` / `flutter test` / `flutter build` —
  بدون SDK فلاتر و بدون دسترسی شبکه به pub.dev
- اجرای مایگریشن‌ها روی یک پروژه Supabase واقعی
- تولید فایل‌های `*.g.dart` (Riverpod/Isar code generation) —
  باید با `dart run build_runner build --delete-conflicting-outputs`
  روی سیستم خودتان انجام شود (دستور کامل در `ENVIRONMENT.md`)
- دانلود و افزودن فونت فارسی Vazirmatn

همه‌ی این‌ها با بازبینی استاتیک دستی (import ها، تطبیق امضای توابع،
تعادل بلوک‌های SQL) و تست واحد/ویجت جبران شدند — نه با اجرای واقعی.
تأیید نهایی روی محیط واقعی برعهده‌ی شماست؛ چک‌لیست دقیق «باقی‌مانده
برای تست دستی» در انتهای هر بخش `LOOP_ENGINEERING_LOG.md` آمده.
