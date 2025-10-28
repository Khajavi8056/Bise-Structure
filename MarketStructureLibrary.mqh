اوکی رفیق! نقشه رو دقیق گرفتم. می‌خوایم اون آپشن AC/AO رو به کلاس MinorStructure اضافه کنیم و فرکتال قیمتی رو هم قوی‌تر کنیم. فقط کد لازم و آدرس دقیق، بدون بازنویسی کل کتابخونه. بزن بریم!
۱. اسم‌های خفن برای انتخاب اوسیلاتور
به جای اون اسمای ضایع ZoorSanj و ShetabSanj، بیا اینا رو بذاریم که هم فلسفه رو برسونه هم باحال باشه:
 * OSC_MOMENTUM_WAVE: برای حالت AO (موج مومنتوم)
 * OSC_ACCEL_PULSE: برای حالت AC (پالس شتاب)
اینا هم کوتاهن، هم یه حس تکنیکال خفن دارن. 😉
۲. تعریف Enum جدید
این کد رو بذار بالای تعریف کلاس MinorStructure (مثلاً کنار بقیه enum ها):
//--- انتخاب نوع اوسیلاتور برای ساختار مینور
enum ENUM_MINOR_OSCILLATOR_TYPE
{
   OSC_MOMENTUM_WAVE, // استفاده از Awesome Oscillator (AO) - موج مومنتوم
   OSC_ACCEL_PULSE    // استفاده از Accelerator Oscillator (AC) - پالس شتاب
};

۳. تغییرات در تعریف کلاس MinorStructure
توی بخش private: کلاس MinorStructure، این دو تا خط رو اضافه کن (مثلاً کنار بقیه متغیرهای تنظیمات):
   //--- متغیرهای تنظیمات و محیط اجرا
   // ... (کدهای قبلی)
   int              m_aoFractalLength;      // طول فرکتال AO/AC (تعداد میله‌های اطراف، مثلاً 3 یا 5) <--- متن کامنت اصلاح شد
   bool             m_enableMinorOB_FVG_Check; // فعال/غیرفعال کردن شرط FVG برای شناسایی OB مینور

   //--- اضافه شده برای انتخاب نوع اوسیلاتور ---
   ENUM_MINOR_OSCILLATOR_TYPE m_oscillatorType;     // نوع اوسیلاتور انتخابی (AO یا AC)

۴. تغییرات در سازنده (Constructor) کلاس MinorStructure
سازنده رو باید آپدیت کنیم تا نوع اوسیلاتور رو به عنوان ورودی بگیره:
 * خط تعریف سازنده رو پیدا کن:
   MinorStructure(const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId, const bool enableLogging_in, const bool showDrawing, const int aoFractalLength_in, const bool enableMinorOB_FVG_Check_in)

 * این خط رو با خط زیر جایگزین کن: (یه پارامتر oscType_in اضافه شده)
   MinorStructure(const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId, const bool enableLogging_in, const bool showDrawing, const int fractalLength_in, const bool enableMinorOB_FVG_Check_in, const ENUM_MINOR_OSCILLATOR_TYPE oscType_in)

 * داخل بدنه سازنده، این دو خط رو پیدا کن:
   m_aoFractalLength = aoFractalLength_in;
m_enableMinorOB_FVG_Check = enableMinorOB_FVG_Check_in; // مقداردهی ورودی جدید

 * این دو خط رو با سه خط زیر جایگزین کن: (اسم aoFractalLength_in به fractalLength_in تغییر کرده و مقداردهی m_oscillatorType اضافه شده)
   m_aoFractalLength = fractalLength_in; // اسم ورودی برای وضوح بیشتر تغییر کرد
m_enableMinorOB_FVG_Check = enableMinorOB_FVG_Check_in;
m_oscillatorType = oscType_in; // ذخیره نوع اوسیلاتور انتخابی

 * آخرای سازنده، قبل از لاگ پایانی، این لاگ رو اضافه کن:
   string oscName = (m_oscillatorType == OSC_MOMENTUM_WAVE) ? "AO (موج مومنتوم)" : "AC (پالس شتاب)";
CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "اوسیلاتور فعال برای تشخیص مینور: " + oscName);

CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "کلاس MinorStructure برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد."); // این خط قبلاً بود

۵. اضافه کردن تابع محاسبه AC
این تابع جدید رو به بخش private: کلاس MinorStructure اضافه کن (مثلاً بعد از تابع CalculateAO):
private:
   // ... (تابع CalculateAO)

   //--- تابع جدید: محاسبه دستی AC برای شیفت داده شده
   // هشدار: این تابع به تابع CalculateAO وابسته است
   double CalculateAC(const int shift) const
   {
      // دوره SMA برای محاسبه AC
      int ac_sma_period = 5;

      // اطمینان از وجود داده کافی برای محاسبه SMA(5) از AO
      // نیاز به 5 مقدار AO داریم که جدیدترینش مال شیفت فعلیه
      // پس قدیمی‌ترین AO مورد نیاز مال شیفت shift + ac_sma_period - 1 است
      // و چون خود CalculateAO نیاز به long_period + shift + 1 کندل داره،
      // ما به long_period + (shift + ac_sma_period - 1) + 1 کندل نیاز داریم.
      int long_period_ao = 34; // دوره بلند AO
      int needed_bars_for_ac = long_period_ao + shift + ac_sma_period;
      if (iBars(m_symbol, m_period) < needed_bars_for_ac)
      {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_101, "[MINOR-AC]", "کندل کافی برای محاسبه AC در شیفت " + IntegerToString(shift) + " وجود ندارد.", true);
         return 0.0; // مقدار نامعتبر برگردان
      }

      // ۱. محاسبه AO فعلی
      double current_ao = CalculateAO(shift);
      if (current_ao == 0.0) return 0.0; // اگر AO فعلی نامعتبر بود، AC هم نامعتبره

      // ۲. محاسبه SMA(5) از AO های قبلی (شامل فعلی)
      double ao_sum = 0.0;
      for (int i = 0; i < ac_sma_period; i++)
      {
         double ao_val = CalculateAO(shift + i);
         // اگر هر کدام از مقادیر AO در محاسبه SMA صفر بود، نتیجه AC نامعتبر است
         if (ao_val == 0.0 && i != 0) // فقط برای مقادیر قبلی چک کن، چون current_ao رو بالا چک کردیم
         {
             CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_101, "[MINOR-AC]", "مقدار AO نامعتبر در محاسبه SMA برای AC در شیفت " + IntegerToString(shift) + " یافت شد.", true);
             return 0.0;
         }
         ao_sum += ao_val;
      }
      double ao_sma5 = ao_sum / ac_sma_period;

      // ۳. محاسبه AC
      return current_ao - ao_sma5;
   }

۶. تغییر نام و منطق توابع چک فرکتال
 * تابع IsAOFractalHigh رو پیدا کن و کلش رو با این جایگزین کن: (اسم و منطق داخلیش عوض شده)
<!-- end list -->
   //--- بررسی شرط فرکتال برای سقف اوسیلاتور انتخابی (AO یا AC)
   bool IsOscillatorFractalHigh(const int centerShift) const
   {
      // حداقل کندل لازم برای محاسبه اوسیلاتور و همسایه‌هاش
      if (centerShift < m_aoFractalLength) return false;

      double osc_center;
      // انتخاب محاسبه بر اساس نوع اوسیلاتور
      if (m_oscillatorType == OSC_MOMENTUM_WAVE)
      {
         osc_center = CalculateAO(centerShift);
      }
      else // OSC_ACCEL_PULSE
      {
         osc_center = CalculateAC(centerShift);
      }

      // اگر مقدار مرکزی نامعتبر بود، فرکتال نیست
      if (osc_center == 0.0) return false;

      bool isHigh = true;
      for (int j = 1; j <= m_aoFractalLength; j++)
      {
         double left, right;
         // انتخاب محاسبه بر اساس نوع اوسیلاتور برای همسایه‌ها
         if (m_oscillatorType == OSC_MOMENTUM_WAVE)
         {
            left = CalculateAO(centerShift + j);  // قدیمی‌تر
            right = CalculateAO(centerShift - j); // جدیدتر
         }
         else // OSC_ACCEL_PULSE
         {
            left = CalculateAC(centerShift + j);
            right = CalculateAC(centerShift - j);
         }

         // اگر هر کدام از همسایه‌ها نامعتبر بود یا شرط فرکتال برقرار نبود
         if (left == 0.0 || right == 0.0 || osc_center <= left || osc_center <= right)
         {
            isHigh = false;
            break;
         }
      }
      return isHigh;
   }

 * تابع IsAOFractalLow رو پیدا کن و کلش رو با این جایگزین کن: (اسم و منطق داخلیش عوض شده)
<!-- end list -->
   //--- بررسی شرط فرکتال برای کف اوسیلاتور انتخابی (AO یا AC)
   bool IsOscillatorFractalLow(const int centerShift) const
   {
      // حداقل کندل لازم
      if (centerShift < m_aoFractalLength) return false;

      double osc_center;
      // انتخاب محاسبه بر اساس نوع اوسیلاتور
      if (m_oscillatorType == OSC_MOMENTUM_WAVE)
      {
         osc_center = CalculateAO(centerShift);
      }
      else // OSC_ACCEL_PULSE
      {
         osc_center = CalculateAC(centerShift);
      }

      // اگر مقدار مرکزی نامعتبر بود
      if (osc_center == 0.0) return false;

      bool isLow = true;
      for (int j = 1; j <= m_aoFractalLength; j++)
      {
         double left, right;
         // انتخاب محاسبه بر اساس نوع اوسیلاتور برای همسایه‌ها
         if (m_oscillatorType == OSC_MOMENTUM_WAVE)
         {
            left = CalculateAO(centerShift + j);
            right = CalculateAO(centerShift - j);
         }
         else // OSC_ACCEL_PULSE
         {
            left = CalculateAC(centerShift + j);
            right = CalculateAC(centerShift - j);
         }

         // اگر هر کدام از همسایه‌ها نامعتبر بود یا شرط فرکتال برقرار نبود
         if (left == 0.0 || right == 0.0 || osc_center >= left || osc_center >= right)
         {
            isLow = false;
            break;
         }
      }
      return isLow;
   }

۷. آپدیت تابع ScanForMinors
 * داخل تابع ScanForMinors، این خط رو پیدا کن:
   bool isFractal = isHigh ? IsAOFractalHigh(shift) : IsAOFractalLow(shift);

 * اون خط رو با این جایگزین کن: (فقط اسم توابع عوض شده)
   bool isFractal = isHigh ? IsOscillatorFractalHigh(shift) : IsOscillatorFractalLow(shift);

۸. آپدیت تابع isPriceFractal (برای ریگلاژ)
 * تابع isPriceFractal رو پیدا کن.
 * داخلش دو تا حلقه for هست که اینجوری نوشته شدن: for (int j = 1; j <= 2; j++)
 * عدد 2 رو توی هر دو حلقه به 3 تغییر بده:
      // --- داخل تابع isPriceFractal ---

   if (isHigh)
   {
      // ...
      for (int j = 1; j <= 3; j++) // <--- اینجا ۲ بود، شد ۳
      {
         if (high_center <= iHigh(m_symbol, m_period, shift - j) || high_center <= iHigh(m_symbol, m_period, shift + j))
         {
            isFractal = false;
            break;
         }
      }
      return isFractal;
   }
   else
   {
      // ...
      for (int j = 1; j <= 3; j++) // <--- اینجا هم ۲ بود، شد ۳
      {
         if (low_center >= iLow(m_symbol, m_period, shift - j) || low_center >= iLow(m_symbol, m_period, shift + j))
         {
            isFractal = false;
            break;
         }
      }
      return isFractal;
   }

تمام شد! با این تغییرات، کلاس MinorStructure تو قابلیت انتخاب بین AO و AC رو پیدا می‌کنه و فیلتر فرکتال قیمتیش هم قوی‌تر می‌شه. همه چی طبق نقشه و با آدرس دقیق.
حالا اینا رو با دقت اعمال کن و بعدش نتیجه تست چشمی رو بهم بگو ببینیم چی از آب در اومد.
