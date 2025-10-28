آره، بیا دقیقاً بهت بگم چی کار کنی. باید تابع CalculateAO رو آپدیت کنیم تا بتونه دوره‌های مختلف رو قبول کنه و بعد CalculateAC رو جوری عوض کنیم که از این قابلیت جدید استفاده کنه.
۱. آپدیت تابع CalculateAO
 * تابع CalculateAO رو پیدا کن.
 * کل تابع رو با این کد جایگزین کن:
<!-- end list -->
   //--- تابع بازنویسی شده: محاسبه دستی AO برای شیفت داده شده با دوره‌های قابل تنظیم
   // ورودی‌های short_period_in و long_period_in دوره‌های SMA کوتاه و بلند را تعیین می‌کنند
   double CalculateAO(const int shift, int short_period_in = 5, int long_period_in = 34) const
   {
      // استفاده از دوره‌های ورودی به جای مقادیر ثابت
      int short_period = short_period_in;
      int long_period = long_period_in;

      // حداقل تعداد کندل مورد نیاز بر اساس دوره بلندتر ورودی
      int total_bars_needed = long_period + shift + 1; // +1 برای ایمنی

      // بررسی وجود کندل کافی
      if (iBars(m_symbol, m_timeframe) < total_bars_needed)
      {
         // لاگ خطا فقط اگر دوره پیش‌فرض نباشد یا در حالت لاگ کامل باشیم (جلوگیری از اسپم)
         if ((short_period != 5 || long_period != 34 || m_logLevel == LOG_FULL))
             CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_101, "[MINOR-AO]", "کندل کافی برای محاسبه AO(" + IntegerToString(short_period) + "," + IntegerToString(long_period) + ") در شیفت " + IntegerToString(shift) + " وجود ندارد.", true);
         return 0.0; // مقدار نامعتبر
      }

      double median_prices[];
      // تغییر اندازه آرایه بر اساس تعداد کندل مورد نیاز
      if (ArrayResize(median_prices, total_bars_needed) < total_bars_needed)
      {
          CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_104, "[MINOR-AO]", "خطا در تغییر اندازه آرایه median_prices.", true);
          return 0.0; // خطا در تخصیص حافظه
      }
      ArraySetAsSeries(median_prices, true); // اطمینان از سری بودن

      // کپی قیمت‌های میانه
      for (int i = 0; i < total_bars_needed; i++)
      {
         int bar_shift = shift + i;
         double high = iHigh(m_symbol, m_timeframe, bar_shift);
         double low = iLow(m_symbol, m_timeframe, bar_shift);
         // بررسی داده‌های نامعتبر قیمت
         if (high == 0 || low == 0) {
              CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_101, "[MINOR-AO]", "داده قیمت نامعتبر در شیفت " + IntegerToString(bar_shift) + " برای محاسبه AO.", true);
              return 0.0;
         }
         median_prices[i] = (high + low) / 2.0;
      }

      // محاسبه SMA کوتاه
      double sma_short = 0.0;
      for (int i = 0; i < short_period; i++)
      {
         sma_short += median_prices[i];
      }
      // بررسی تقسیم بر صفر (اگر دوره کوتاه ۰ باشد، هرچند نباید اتفاق بیفتد)
      if (short_period == 0) return 0.0;
      sma_short /= short_period;

      // محاسبه SMA بلند
      double sma_long = 0.0;
      for (int i = 0; i < long_period; i++)
      {
         sma_long += median_prices[i];
      }
      // بررسی تقسیم بر صفر
      if (long_period == 0) return 0.0;
      sma_long /= long_period;

      // بازگرداندن مقدار AO
      return sma_short - sma_long;
   }

تغییرات کلیدی:
 * تابع حالا دو ورودی جدید short_period_in و long_period_in می‌گیره که مقادیر پیش‌فرضشون ۵ و ۳۴ هست. این یعنی اگه این تابع رو مثل قبل بدون ورودی اضافه صدا بزنی، همون AO(5, 34) رو حساب می‌کنه.
 * داخل تابع به جای 5 و 34 ثابت، از این ورودی‌ها استفاده می‌شه.
 * محاسبه total_bars_needed و لاگ خطا آپدیت شدن تا دوره‌های ورودی رو منعکس کنن.
 * کمی مدیریت خطا برای قیمت‌های صفر و تغییر اندازه آرایه اضافه شد.
۲. آپدیت تابع CalculateAC
 * تابع CalculateAC رو پیدا کن.
 * کل تابع رو با این کد جایگزین کن:
<!-- end list -->
   //--- تابع بازنویسی شده: محاسبه دستی AC برای شیفت داده شده
   // این تابع AC را بر اساس AO(8, 55) محاسبه می‌کند
   // هشدار: این تابع به تابع CalculateAO بازنویسی شده وابسته است
   double CalculateAC(const int shift) const
   {
      // دوره‌های مورد نظر برای محاسبه AO پایه برای AC
      int ac_ao_short_period = 8;
      int ac_ao_long_period = 55;

      // دوره SMA روی خود AO برای محاسبه AC (این باید 5 بماند)
      int ac_sma_period = 5;

      // حداقل تعداد کندل مورد نیاز:
      // برای محاسبه قدیمی‌ترین AO(8,55) مورد نیاز برای SMA(5)
      int needed_bars_for_ac = ac_ao_long_period + shift + ac_sma_period;
      if (iBars(m_symbol, m_timeframe) < needed_bars_for_ac)
      {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_101, "[MINOR-AC]", "کندل کافی برای محاسبه AC(8,55) در شیفت " + IntegerToString(shift) + " وجود ندارد.", true);
         return 0.0; // مقدار نامعتبر
      }

      // ۱. محاسبه AO فعلی با دوره‌های (8, 55)
      double current_ao = CalculateAO(shift, ac_ao_short_period, ac_ao_long_period);
      // اگر AO فعلی نامعتبر بود (مثلاً به خاطر کمبود داده یا قیمت صفر)، AC هم نامعتبره
      if (current_ao == 0.0)
      {
          // لاگ خطا قبلاً در CalculateAO ثبت شده است (اگر لازم بوده)
          return 0.0;
      }

      // ۲. محاسبه SMA(5) از AO(8, 55) های قبلی (شامل فعلی)
      double ao_sum = 0.0;
      bool sma_calculation_valid = true; // فلگ برای بررسی اعتبار کل محاسبه SMA
      for (int i = 0; i < ac_sma_period; i++)
      {
         // محاسبه AO هر کندل با دوره‌های (8, 55)
         double ao_val = CalculateAO(shift + i, ac_ao_short_period, ac_ao_long_period);
         // اگر هر کدام از مقادیر AO در محاسبه SMA صفر بود، نتیجه AC نامعتبر است
         if (ao_val == 0.0)
         {
             // لاگ خطا قبلاً در CalculateAO ثبت شده است
             CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_101, "[MINOR-AC]", "مقدار AO(8,55) نامعتبر در محاسبه SMA برای AC در شیفت " + IntegerToString(shift) + " یافت شد (کندل " + IntegerToString(shift + i) + ").", true);
             sma_calculation_valid = false;
             break; // ادامه حلقه بی‌فایده است
         }
         ao_sum += ao_val;
      }

      // اگر محاسبه SMA نامعتبر بود، مقدار نامعتبر برگردان
      if (!sma_calculation_valid) return 0.0;

      // بررسی تقسیم بر صفر (اگر دوره SMA صفر باشد)
      if (ac_sma_period == 0) return 0.0;
      double ao_sma5 = ao_sum / ac_sma_period;

      // ۳. محاسبه AC نهایی
      return current_ao - ao_sma5;
   }

تغییرات کلیدی:
 * الان داخل این تابع به صراحت از دوره‌های ۸ و ۵۵ (ac_ao_short_period, ac_ao_long_period) برای صدا زدن CalculateAO استفاده می‌شه.
 * دوره SMA روی خود AO (ac_sma_period) همون ۵ باقی مونده.
 * محاسبه needed_bars_for_ac و لاگ‌های خطا آپدیت شدن تا دوره‌های جدید (۸, ۵۵) رو منعکس کنن.
 * کمی مدیریت خطا برای اطمینان از معتبر بودن همه مقادیر AO قبل از محاسبه SMA اضافه شد.
با این دو تا تغییر، الان:
 * اگه جایی تو کد CalculateAO(shift) رو صدا بزنی، همون AO(5, 34) اصلی رو می‌گیری.
 * تابع CalculateAC(shift) داره AC رو بر اساس AO(8, 55) محاسبه می‌کنه.
این دقیقاً همون چیزیه که می‌خواستی. 👍
