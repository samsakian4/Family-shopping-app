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
- ~~تشخیص تعارض واقعی پیاده نشده~~ → **رفع شد، به بخش «فاز ۸ (رفع تشخیص تعارض)» زیر نگاه کنید.**
- Exponential backoff تا ۱۵ دقیقه (طبق `07_SYNC_ENGINE.md`) پیاده نشده؛
  فعلاً فقط شمارش retry تا سقف `AppConstants.syncRetryDelays.length` و
  سپس علامت `failed` — تأخیر بین retry ها (۵/۱۵/۳۰/۶۰ ثانیه) هنوز زمان‌بندی نمی‌شود.

باقی‌مانده برای تست دستی روی محیط واقعی:

- [ ] تست دستی: آفلاین شدن → ساخت لیست/آیتم → آنلاین شدن → دیدن اینکه چیپ «در انتظار ارسال» صفر می‌شود و آیتم واقعاً روی سرور ساخته شده
- [ ] تست دستی: کشتن اپ وسط پردازش صف → باز کردن دوباره → صف باید از همان‌جا ادامه پیدا کند (چون در Isar پایدار ذخیره شده)
- [ ] تست دو دستگاه: هر دو آفلاین یک آیتم مشترک را ویرایش کنند → مشاهده رفتار Last-Write-Wins فعلی و مستندسازی برای پیاده‌سازی تشخیص تعارض واقعی

---

## فاز ۸ (رفع تشخیص تعارض) — قبل از فاز ۹

مشکل قبلی: `SyncEngine` صرفاً صف را بازپخش می‌کرد بدون مقایسه با نسخه فعلی
سرور — یعنی اگر دو دستگاه همزمان یک لیست/آیتم را (یکی آنلاین، یکی آفلاین)
ویرایش می‌کردند، تغییر دستگاه آفلاین بی‌سروصدا تغییر دستگاه دیگر را
Overwrite می‌کرد. این دقیقاً همان چیزی بود که `07_SYNC_ENGINE.md` به‌عنوان
"Conflict Detection" لازم می‌دانست و قبلاً پیاده نشده بود.

### راه‌حل پیاده‌شده

1. هر عملیات `update` صف‌شده حالا `base_updated_at` را هم حمل می‌کند —
   یعنی `updated_at` سرور در لحظه‌ای که ویرایش آفلاین شروع شد.
2. `SyncEngine` قبل از اعمال هر `update`، ردیف فعلی سرور را با `getById`
   می‌گیرد (متد جدید در هر دو RemoteDataSource) و `updated_at` آن را با
   `base_updated_at` مقایسه می‌کند.
3. اگر سرور جدیدتر بود → به‌جای اعمال خاموش، وضعیت صف `conflict` می‌شود
   و پردازش خودکار متوقف می‌شود (نه Retry بی‌پایان، نه از دست رفتن تغییر).
4. کاربر از صفحه‌ی جدید **تعارض‌های همگام‌سازی** (`/lists/conflicts`)
   بین دو گزینه انتخاب می‌کند: «تغییر من را اعمال کن» (`resolveKeepLocal`
   — بازپخش اجباری بدون بررسی مجدد) یا «نسخه سرور را نگه دار»
   (`resolveDiscardLocal` — کش محلی را با نسخه فعلی سرور جایگزین و
   ورودی صف را کنار می‌گذارد).
5. `create`/`delete`/`mark_purchased` عمداً از این بررسی معاف‌اند
   (دلیل هرکدام در docstring کلاس `SyncEngine` مستند شده) — این دقیقاً
   منطبق با استثنائات ذکرشده در خود سند (`07_SYNC_ENGINE.md` -
   "Purchased status ... merge logic should be applied when safe").

### تست‌های اضافه‌شده

در `test/unit/core/sync_engine_test.dart`:
- عدم تعارض (سرور جدیدتر نیست) → اعمال عادی و `markSynced`
- تعارض واقعی (سرور جدیدتر است) → عدم اعمال، `markConflict` به‌جای `markSynced`
- `resolveKeepLocal` → اعمال اجباری بدون بررسی مجدد نسخه
- `resolveDiscardLocal` → کش را از سرور بروزرسانی و ورودی صف را حذف می‌کند

### وضعیت باقی‌مانده (صادقانه)

- Merge خودکار فیلد به فیلد (مثلاً یکی `quantity` عوض کند و دیگری `notes`)
  هنوز پیاده نشده — در تعارض، کل تغییر یا اعمال می‌شود یا کنار گذاشته
  می‌شود، نه ادغام هوشمند. طبق سند این «Future Advanced Strategy» است.
- تشخیص تعارض فقط برای `shopping_list`/`shopping_item` عملیات `update`
  پیاده شده، نه برای family/profile (که اصلاً نوشتن آفلاین ندارند).

---

## فاز ۹ — Basic Search

محدوده انتخابی (مطابق با scope واقعی MVP در `35_MILESTONE_1.md`، نه نسخه
کامل AI-assisted در `17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md`): جستجوی محلی
Level 1 (Local Cache) روی نام محصولاتی که کاربر قبلاً در هر یک از
لیست‌های خودش وارد کرده — بدون نیاز به کاتالوگ محصول یا AI. کاملاً آفلاین
کار می‌کند (`17_PRODUCT_SEARCH...md` - Offline Behavior: "Available:
Local products").

| # | بررسی | نتیجه |
|---|--------|--------|
| 1 | همه import های داخلی سالم | ✅ |
| 2 | هر `@riverpod` دارای `part` صحیح | ✅ |
| 3 | `searchProductNamesUseCaseProvider` در UI با نام دقیق تولیدشده توسط generator فراخوانی شده | ✅ |
| 4 | Debounce واقعاً از `AppConstants.searchDebounce` (۳۰۰ میلی‌ثانیه طبق سند) استفاده می‌کند، نه عدد هاردکد جدید | ✅ |
| 5 | تست واحد `SearchProductNamesUseCase` (تفویض صحیح query، رفتار با ورودی خالی) | ✅ اضافه شد در `test/unit/features/shopping/search_product_names_usecase_test.dart` |

نکته طراحی: چون `ShoppingItemLocalCache.searchItemNames` مستقیماً روی
Isar کار می‌کند (بدون واسطه قابل mock کردن ساده)، تست واحد آن اینجا
نوشته نشد — پوشش آن بخشی از تست دستی/Widget Test در محیط واقعی خواهد
بود، نه اینجا.

باقی‌مانده برای تست دستی روی محیط واقعی:

- [ ] تایپ نام محصولی که قبلاً در لیست دیگری اضافه شده → باید به‌عنوان چیپ پیشنهاد ظاهر شود
- [ ] بررسی زمان پاسخ جستجو زیر ۱۰۰ میلی‌ثانیه طبق هدف عملکردی `04_SYSTEM_ARCHITECTURE.md`
- [ ] تست آفلاین: جستجو باید بدون اینترنت هم کار کند (چون کاملاً محلی است)

---

## فاز ۱۰ — UI Polish

| # | بررسی | نتیجه |
|---|--------|--------|
| 1 | همه import های داخلی سالم | ✅ |
| 2 | هیچ رفرنسی به `HomePagePlaceholder` باقی نمانده (فایل حذف و همه‌جا با `DashboardPage` جایگزین شد) | ✅ |
| 3 | هر `@riverpod` دارای `part` صحیح | ✅ |
| 4 | بدون import تکراری در فایل‌های ویرایش‌شده | ✅ |
| 5 | تست ویجت برای `AppEmptyState`/`AppErrorView` (نمایش پیام، دکمه اکشن فقط وقتی هر دو پارامتر داده شده، callback ها فراخوانی می‌شوند) | ✅ اضافه شد در `test/widget/shared/error_and_empty_state_test.dart` — **اولین Widget Test پروژه** (تا این فاز همه تست‌ها Unit Test بودند) |

کارهای انجام‌شده:
- `DashboardPage` واقعی (خلاصه لیست‌ها، وضعیت خانواده، دسترسی سریع) جایگزین placeholder داشبورد شد
- دو ویجت مشترک جدید طبق `11_COMPONENT_LIBRARY.md`: `AppEmptyState`, `AppErrorView`
  — و در ۳ صفحه (لیست‌ها، جزئیات لیست، سطل زباله) به‌جای `Text` خام جایگزین شدند
- ضمناً یک باگ مستندسازی (چک‌لیست فازهای تکراری در README از ویرایش‌های قبلی) پیدا و پاک شد

**آنچه عمداً در این فاز انجام نشد** (صادقانه، برای فاز ۱۱/۱۲ یا فراتر از Milestone 1):
- Bottom Navigation واقعی طبق `12_NAVIGATION.md` (Home/Lists/Shopping/Reports/Settings)
  پیاده نشد — ناوبری فعلی هنوز مبتنی بر دکمه‌های AppBar + `context.push` است،
  نه `StatefulShellRoute` با حفظ pile ناوبری هر تب. این یک بازسازی معماری
  routing واقعی است که باید جداگانه و با دقت انجام شود.
- انیمیشن‌های حرفه‌ای (Shared transitions، Skeleton loading سراسری) طبق
  `09_DESIGN_SYSTEM.md` هنوز پیاده نشده — فقط `CircularProgressIndicator` ساده.
- فونت فارسی Vazirmatn هنوز به پروژه اضافه نشده (نیاز به فایل فونت واقعی دارد
  که این محیط نمی‌تواند دانلود کند — در `pubspec.yaml` و `AppTheme` جای آن
  رزرو شده، کامنت TODO موجود است).

---

## فاز ۱۱ — Testing

طبق `28_TEST_PLAN.md` و `20_TESTING_STRATEGY.md`. این فاز عمدتاً «تکمیل
پوشش تست‌های واحد/ویجت» بود، نه نوشتن از صفر — چون طبق رویه Loop
Engineering در تمام فازهای قبل، هر فاز حداقل یک تست واحد گرفته بود.

### پوشش نهایی (۱۲ فایل، ۴۶ کیس تست)

| حوزه | فایل | چه چیزی پوشش داده می‌شود |
|---|---|---|
| Auth | `sign_up_usecase_test.dart` | اعتبارسنجی ایمیل/رمز/نام، نرمال‌سازی، تحویل به Repository |
| Auth | `sign_in_usecase_test.dart` | رد ورودی خالی، نرمال‌سازی ایمیل |
| Auth | `reset_password_usecase_test.dart` | رد ایمیل نامعتبر، نرمال‌سازی |
| Family | `family_usecases_test.dart` | ساخت/پیوستن خانواده — رد ورودی نامعتبر، trim |
| Settings | `upload_avatar_usecase_test.dart` | رد حجم >۵MB، رد فرمت نامعتبر، مسیر موفق |
| Shopping | `shopping_list_usecases_test.dart` | ساخت/تغییرنام لیست — قوانین اعتبارسنجی |
| Shopping | `shopping_item_usecases_test.dart` | افزودن/ویرایش آیتم — قوانین اعتبارسنجی |
| Shopping | `search_product_names_usecase_test.dart` | تفویض query، ورودی خالی |
| Core/Local | `local_cache_mapping_test.dart` | رفت‌وبرگشت Entity↔Isar Model بدون از دست دادن داده |
| Core/Sync | `sync_engine_test.dart` | مسیریابی create/update/delete/mark_purchased، **تشخیص تعارض**، `resolveKeepLocal`/`resolveDiscardLocal`، رفتار آفلاین |
| Widget | `error_and_empty_state_test.dart` | `AppEmptyState`/`AppErrorView` — نمایش صحیح، اکشن اختیاری |
| Widget | `app_primary_button_test.dart` | حالت loading دکمه را غیرفعال می‌کند و اسپینر نشان می‌دهد |

### آنچه عمداً پوشش داده نشد (و چرا)

- **Integration Tests واقعی** (طبق `28_TEST_PLAN.md` بخش Integration Testing)
  نیاز به یک پروژه Supabase تست واقعی + اجرای `flutter test integration_test`
  دارند — این محیط نه SDK فلاتر دارد نه دسترسی شبکه به Supabase، پس این‌ها
  در CI شما (`ci.yml`) باید فعال شوند، نه اینجا.
- Repository ها (لایه Data) مستقیماً تست نشدند — چون DataSource های واقعی‌شان
  به Supabase وصل می‌شوند؛ رفتارشان از طریق Use Case ها (که Repository را
  Mock می‌کنند) و از طریق منطق داخلی `SyncEngine`/`LocalCache` که Mock/Fake
  قابل تست دارند پوشش داده شده.
- Family/Auth usecase های کمتر حیاتی (`LeaveFamilyUseCase`,
  `RemoveMemberUseCase`, `UpdateProfileUseCase`) تست مستقیم ندارند —
  منطق‌شان trivial pass-through است (بدون اعتبارسنجی خاص)، ریسک کمی دارند.
- `flutter analyze` / `flutter test` واقعی هرگز در این محیط اجرا نشد
  (نبود SDK) — تنها راه تأیید قطعی، اجرای CI شماست.

---

## فاز ۱–۳ (بازبینی گذشته‌نگر خلاصه)

در زمان ساخت فازهای ۱ تا ۳ این لاگ هنوز وجود نداشت. بازبینی خلاصه انجام‌شده:
- ساختار پوشه‌ها و pubspec با معماری مستندشده مطابقت دارد.
- تست واحد `SignUpUseCase` در فاز ۲ نوشته شد.
- تست دستی end-to-end (ثبت‌نام/ورود/آپلود آواتار واقعی) هنوز روی پروژه
  Supabase واقعی انجام نشده — در فهرست "باقی‌مانده" فاز بعد قرار می‌گیرد.
