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

## فاز ۵ — Shopping Lists

| # | بررسی | نتیجه |
|---|--------|--------|
| 1 | همه import های داخلی سالم | ✅ |
| 2 | نام توابع RPC (`soft_delete_shopping_list`, `restore_shopping_list`, `permanently_delete_shopping_list`) در Dart دقیقاً یک بار هرکدام فراخوانی شده و با SQL یکی است؛ `purge_expired_trash` عمداً از کلاینت صدا زده نمی‌شود (برای Edge Function/cron آینده رزرو شده) | ✅ |
| 3 | همه‌ی provider های `@riverpod` دارای `part` صحیح | ✅ |
| 4 | بلوک‌های `$$` در مایگریشن ۰۰۴ زوج (۸ عدد = ۴ تابع سالم) | ✅ |
| 5 | تست واحد برای `CreateListUseCase` (رد عنوان خالی، رد لیست مشترک بدون خانواده، ساخت موفق لیست شخصی) و `RenameListUseCase` (رد نام خالی) | ✅ اضافه شد در `test/unit/features/shopping/shopping_list_usecases_test.dart` |

باقی‌مانده برای تست دستی روی محیط واقعی:

- [ ] اجرای مایگریشن `004_shopping_lists.sql` روی Supabase واقعی
- [ ] تست دستی: ساخت لیست شخصی + مشترک، آرشیو/خروج از آرشیو، حذف → دیدن در سطل زباله → بازیابی → دیدن دوباره در تب مربوطه
- [ ] تست RLS: کاربر خارج از خانواده نباید لیست مشترک آن خانواده را ببیند یا بتواند در آن insert کند
- [ ] تست realtime: کاربر دوم هم‌خانواده باید لیست مشترک جدید را بدون رفرش ببیند

---

## فاز ۶ — Shopping Items

| # | بررسی | نتیجه |
|---|--------|--------|
| 1 | همه import های داخلی سالم | ✅ |
| 2 | فایل placeholder جزئیات لیست پاک شد و هیچ رفرنسی به آن نمانده | ✅ |
| 3 | `mark_item_purchased` در Dart دقیقاً با امضای تابع SQL منطبق (۳ پارامتر) | ✅ |
| 4 | همه‌ی provider های `@riverpod` دارای `part` صحیح | ✅ |
| 5 | بلوک‌های `$$` در مایگریشن ۰۰۵ زوج (۴ = ۲ تابع) | ✅ |
| 6 | پکیج‌های خارجی استفاده‌شده در فیچر همگی در pubspec تعریف شده‌اند | ✅ |
| 7 | تست واحد `AddItemUseCase` (رد نام خالی، رد تعداد صفر/منفی، تحویل صحیح) و `UpdateItemUseCase` (رد نام خالی و تعداد نامعتبر هنگام ارائه) | ✅ اضافه شد در `test/unit/features/shopping/shopping_item_usecases_test.dart` |

نکته طراحی: تریگر SQL `recalc_list_estimated_total` مجموع `estimated_price × quantity`
را در هر insert/update/delete آیتم دوباره محاسبه و در `shopping_lists.estimated_total`
ذخیره می‌کند — این خودِ منطق `18_PRICE_ESTIMATION_SYSTEM.md` است، نه چیزی که کلاینت
باید حساب کند.

باقی‌مانده برای تست دستی روی محیط واقعی:

- [ ] اجرای مایگریشن `005_shopping_items.sql` (شامل seed دسته‌بندی‌های پیش‌فرض)
- [ ] تست دستی: افزودن آیتم → دیدن realtime در دستگاه دوم → تیک خریداری‌شده →
      دیدن بروزرسانی خودکار `estimated_total` در صفحه لیست‌ها
- [ ] تست RLS: کاربر خارج از لیست/خانواده نباید بتواند آیتم آن لیست را ببیند یا ویرایش کند

---

## فاز ۷ — Local Database (Isar)

| # | بررسی | نتیجه |
|---|--------|--------|
| 1 | همه import های داخلی سالم | ✅ |
| 2 | هر ۴ کالکشن (`ShoppingListLocal`, `ShoppingItemLocal`, `CategoryLocal`, `SyncQueueEntry`) در `AppDatabase.open()` ثبت شده‌اند | ✅ |
| 3 | `isarProvider` دقیقاً یک‌بار در `main.dart` با `overrideWithValue` مقداردهی می‌شود، قبل از `runApp` | ✅ |
| 4 | سازنده‌ی هر سه Repository (List/Item/Category) با امضای جدید (remote + networkInfo + cache) در پروایدرهای مربوطه فراخوانی شده | ✅ |
| 5 | تست واحد رفت‌وبرگشت نگاشت `Entity <-> Local` برای لیست و آیتم (بدون نیاز به باز کردن دیتابیس واقعی) | ✅ اضافه شد در `test/unit/core/local_cache_mapping_test.dart` |

نکات طراحی مهم:
- خواندن اکنون offline-first است: `watchMyLists()`/`watchItems()`/`getCategories()`
  ابتدا از کش Isar می‌خوانند، سپس اگر آنلاین باشد جریان realtime سرور را
  دنبال کرده و کش را write-through بروزرسانی می‌کنند.
- **نوشتن هنوز offline-first نیست** — `create/update/delete` مستقیماً به
  Supabase می‌روند و اگر آفلاین باشید خطا می‌گیرید. صف `SyncQueueEntry`
  فقط تعریف شده؛ منطق enqueue/retry/conflict resolution در **فاز ۸
  (Synchronization)** پیاده می‌شود — این تفکیک عمداً همان چیزی است که
  `35_MILESTONE_1.md` بین Phase 7 و Phase 8 قائل شده.

باقی‌مانده برای تست دستی روی محیط واقعی:

- [ ] اجرای `dart run build_runner build` برای تولید `*.g.dart` مربوط به Isar (اینجا در دسترس نیست)
- [ ] تست دستی: باز کردن اپ آفلاین بعد از یک بار آنلاین بودن → دیدن لیست‌ها/آیتم‌های کش‌شده
- [ ] تست دستی: تلاش برای ساخت لیست در حالت آفلاین → باید خطای «اتصال اینترنت برقرار نیست» نمایش داده شود (چون نوشتن هنوز صف نمی‌شود)

---

## فاز ۸ — Synchronization

| # | بررسی | نتیجه |
|---|--------|--------|
| 1 | همه import های داخلی سالم | ✅ |
| 2 | امضای `createList`/`addItem` (با پارامتر `id` صریح) در Interface، پیاده‌سازی Remote، Repository (هر دو مسیر آنلاین/آفلاین)، و `SyncEngine` دقیقاً یکسان است — این نکته حیاتی بود چون قبلاً سرور خودش UUID می‌ساخت و شناسه محلی/سرور مچ نمی‌شدند | ✅ |
| 3 | سازنده‌های `ShoppingListRepositoryImpl` (۵ آرگومان) و `ShoppingItemRepositoryImpl` (۴ آرگومان) با فراخوانی در پروایدرها مطابقت دارند | ✅ |
| 4 | همه‌ی `@riverpod` دارای `part` صحیح (شامل `sync_engine_provider.dart` که در نگارش اول اسم فایل `part` اشتباه تایپ شده بود و اصلاح شد) | ✅ |
| 5 | پکیج `uuid` که برای تولید شناسه محلی استفاده می‌شود در pubspec موجود است | ✅ |
| 6 | تست واحد `SyncEngine`: مسیریابی صحیح `create`/`mark_purchased`/`delete` به متد Remote درست با همان id، رفتار صحیح هنگام شکست (failed attempt نه synced)، و توقف کامل پردازش وقتی آفلاین است | ✅ اضافه شد در `test/unit/core/sync_engine_test.dart` |

نکات معماری مهم این فاز:
- معماری از حالت "remote-stream-is-truth" به **"cache-is-truth، remote فقط پرکننده کش است"** تغییر کرد:
  `watchMyLists()`/`watchItems()` اکنون همیشه از Isar واکنش‌پذیر (`watch()`) می‌خوانند؛
  یک subscription پس‌زمینه (idempotent) جریان realtime سرور را به کش merge می‌کند.
  این باعث می‌شود نوشتن آفلاین بلافاصله در UI دیده شود.
- `mergeFromRemote`/`mergeForList` رکوردهای `pending`/`failed` محلی را که هنوز
  به سرور نرسیده‌اند حذف نمی‌کنند — فقط رکوردهای `synced` که دیگر روی سرور
  نیستند پاک می‌شوند. این از گم‌شدن تغییرات آفلاین توسط یک رفرش remote جلوگیری می‌کند.
- `SyncEngine.processQueue()` روی رویداد اتصال مجدد و هنگام باز شدن اپ (از `SplashPage`) اجرا می‌شود.
- نشانگر «N در انتظار ارسال» به AppBar صفحه لیست‌ها اضافه شد (`10_UI_UX.md` - Sync Indicator).

**محدودیت‌های شناخته‌شده و آگاهانه این فاز** (مستند برای فازهای بعد):
- فقط `shopping_list` و `shopping_item` نوشتن آفلاین دارند؛ خانواده/پروفایل هنوز online-only.
- بازیابی/حذف دائم از سطل زباله و Regenerate کد دعوت عمداً online-only ماندند.
- **تشخیص تعارض واقعی (Conflict Detection) پیاده نشده** — استراتژی فعلی صرفاً
  "بازپخش صف پس از اتصال مجدد" است، نه مقایسه‌ی `updated_at` محلی در برابر سرور
  قبل از اعمال. اگر دو دستگاه همزمان یک آیتم را آفلاین ویرایش کنند، آخرین
  entryای که صف آن پردازش می‌شود می‌برد (شبیه Last-Write-Wins ساده، بدون
  تشخیص/هشدار تعارض به کاربر). پیاده‌سازی کامل طبق `07_SYNC_ENGINE.md`
  (ستون `version`، مقایسه قبل از اعمال، حالت `conflict`) به یک فاز
  تکمیلی موکول شد.
- Exponential backoff تا ۱۵ دقیقه (طبق `07_SYNC_ENGINE.md`) پیاده نشده؛
  فعلاً فقط شمارش retry تا سقف `AppConstants.syncRetryDelays.length` و
  سپس علامت `failed` — تأخیر بین retry ها (۵/۱۵/۳۰/۶۰ ثانیه) هنوز زمان‌بندی نمی‌شود.

باقی‌مانده برای تست دستی روی محیط واقعی:

- [ ] تست دستی: آفلاین شدن → ساخت لیست/آیتم → آنلاین شدن → دیدن اینکه چیپ «در انتظار ارسال» صفر می‌شود و آیتم واقعاً روی سرور ساخته شده
- [ ] تست دستی: کشتن اپ وسط پردازش صف → باز کردن دوباره → صف باید از همان‌جا ادامه پیدا کند (چون در Isar پایدار ذخیره شده)
- [ ] تست دو دستگاه: هر دو آفلاین یک آیتم مشترک را ویرایش کنند → مشاهده رفتار Last-Write-Wins فعلی و مستندسازی برای پیاده‌سازی تشخیص تعارض واقعی

---

## فاز ۱–۳ (بازبینی گذشته‌نگر خلاصه)

در زمان ساخت فازهای ۱ تا ۳ این لاگ هنوز وجود نداشت. بازبینی خلاصه انجام‌شده:
- ساختار پوشه‌ها و pubspec با معماری مستندشده مطابقت دارد.
- تست واحد `SignUpUseCase` در فاز ۲ نوشته شد.
- تست دستی end-to-end (ثبت‌نام/ورود/آپلود آواتار واقعی) هنوز روی پروژه
  Supabase واقعی انجام نشده — در فهرست "باقی‌مانده" فاز بعد قرار می‌گیرد.
