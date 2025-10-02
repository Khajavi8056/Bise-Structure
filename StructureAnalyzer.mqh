//+------------------------------------------------------------------+
//|                                           StructureAnalyzer.mqh |
//|                  Copyright 2025, xAI - Built by Grok             |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, khajavi - Built by hipoAlgoritm"
#property link      "hipoAlgoritm.com"
#property version   "1.20"
#property strict

// شامل فایل‌های لازم برای کار با اشیاء گرافیکی و توابع MQL5 - برای دسترسی به ثابت‌هایی مثل OBJPROP_CORNER
#include <Object.mqh>

// تعریف ساختار برای سطوح نوسان (Swing) - شامل قیمت و زمان سطح برای ذخیره‌سازی آسان و مقایسه
struct Swing
  {
   double            price;   // قیمت سطح (های یا لو)
   datetime          time;    // زمان سطح (زمان کندل مربوطه برای همگام‌سازی با چارت و چک تکراری)
  };

// تعریف ساختار برای FVG - شامل مرزها، EQ، زمان شروع و جهت برای نگهداری در حافظه
struct FVG
  {
   double            upperBoundary; // بالاترین قیمت FVG
   double            lowerBoundary; // پایین‌ترین قیمت FVG
   double            eqPrice;       // قیمت خط میانی (50% یا Equilibrium)
   datetime          startTime;     // زمان کندل اول FVG برای شروع رسم
   bool              isBullish;     // true اگر FVG صعودی (سبز)، false اگر نزولی (قرمز)
   string            objRectName;   // نام شیء مستطیل FVG برای پاک کردن
   string            objEqName;     // نام شیء خط EQ برای پاک کردن
   string            objFvgLabel;   // نام شیء لیبل FVG برای پاک کردن
   string            objEqLabel;    // نام شیء لیبل EQ برای پاک کردن
  };

// کلاس اصلی برای تحلیل ساختار قیمت - این کلاس تمام منطق تحلیل BOS، CHOCH، روند، FVG و نمایش گرافیکی را مدیریت می‌کند
class StructureAnalyzer
  {
private:
   // متغیرهای ورودی - تنظیمات قابل تغییر توسط کاربر برای سفارشی‌سازی رفتار کتابخانه
   int               m_lookbackCandles;     // تعداد کندل‌های گذشته برای محاسبه سطوح اولیه (پیشفرض 100)
   double            m_retracementPercent;  // درصد حداقل اصلاح برای تایید سطح جدید (پیشفرض 25.0)
   ENUM_TIMEFRAMES   m_timeframe;           // تایم فریم مورد استفاده برای تحلیل (پیشفرض فعلی چارت)
   string            m_symbol;              // سیمبل (جفت ارز) برای تحلیل (پیشفرض سیمبل فعلی)
   int               m_maxStructures;       // حداکثر تعداد ساختارها (سقف/کف/FVG) برای ذخیره و گرافیک (پیشفرض 30)
   bool              m_enableGraphics;      // فلگ برای فعال یا غیرفعال کردن نمایش گرافیکی (پیشفرض true)

   // سطوح فعلی و قبلی - برای پیگیری روند و مقایسه سطوح برای تعیین صعودی/نزولی
   Swing             m_lastHigh;            // آخرین سقف تایید شده
   Swing             m_previousHigh;        // سقف قبلی تایید شده برای مقایسه
   Swing             m_lastLow;             // آخرین کف تایید شده
   Swing             m_previousLow;         // کف قبلی تایید شده برای مقایسه

   // آرایه‌ها برای تاریخچه سطوح - تا m_maxStructures، برای مدیریت گرافیک و حذف قدیمی‌ها اگر بیش از حد شوند
   Swing             m_highs[];             // آرایه سقف‌های تایید شده (FIFO برای حذف قدیمی‌ها)
   Swing             m_lows[];              // آرایه کف‌های تایید شده (FIFO برای حذف قدیمی‌ها)

   // آرایه برای FVGهای فعال - تا m_maxStructures، برای مدیریت مصرف و پاکسازی
   FVG               m_fvgs[];              // آرایه FVGهای مصرف نشده (FIFO برای حذف قدیمی‌ها اگر بیش از 30)

   // ثابت‌ها برای فیلتر FVG - حداقل نسبت‌ها برای اعتبار
   const double      FVG_MIN_BODY_RATIO = 0.40; // حداقل ۴۰% ارتفاع FVG نسبت به بادی کندل ۲
   const double      CANDLE_BODY_MIN_RATIO = 0.50; // حداقل ۵۰% بادی کندل ۲ نسبت به طول کلی آن

   // فلگ‌ها برای رویدادها - برای تشخیص و ذخیره وضعیت BOS و CHOCH
   bool              m_isBOS;               // آیا BOS اخیر رخ داده است (شکست در جهت روند)
   bool              m_isCHOCH;             // آیا CHOCH اخیر رخ داده است (شکست مخالف روند)
   datetime          m_lastBOSTime;         // زمان آخرین BOS برای پیگیری
   datetime          m_lastCHOCHTime;       // زمان آخرین CHOCH برای پیگیری

   // متغیرهای کمکی برای حالت اصلاح - برای پیگیری موج محرک و محاسبه اصلاح
   bool              m_waitingForRetracement; // آیا در حالت انتظار برای اصلاح هستیم (پس از شکست)
   bool              m_isUpwardBreak;       // آیا شکست به سمت بالا (صعودی) بوده است
   double            m_fixedPoint;          // نقطه ثابت برای محاسبه اصلاح (لو در صعودی یا های در نزولی)
   double            m_movingPoint;         // نقطه متحرک (اوج یا کف موج محرک در حال تشکیل)
   datetime          m_retracementStartTime;// زمان شروع حالت اصلاح برای محدود کردن بازه

   // متغیر برای روند فعلی - 1: صعودی, -1: نزولی, 0: نامشخص بر اساس مقایسه دو سطح آخر
   int               m_currentTrend;

   // نام اشیاء گرافیکی برای مدیریت - پیشوند برای جلوگیری از تداخل با دیگر اندیکاتورها یا اکسپرت‌ها
   string            m_objPrefix;           // پیشوند منحصر به فرد برای نام اشیاء گرافیکی (با رندوم برای uniqueness)

   // تابع خصوصی برای محاسبه سطوح اولیه - در ابتدای اجرا برای تنظیم پایه تحلیل
   void              CalculateInitialLevels();

   // تابع خصوصی برای چک شکست - تشخیص BOS یا CHOCH بر اساس کلوز کندل و روند فعلی
   bool              CheckBreak(double closePrice);

   // تابع خصوصی برای آپدیت و ثبت نقطه مقابل بعد شکست - ثبت فوری به عنوان سطح نهایی، اضافه به آرایه اگر تکراری نباشد، و رسم گرافیکی
   void              UpdateAndRegisterOppositePoint(datetime fromTime, datetime toTime, bool isUpward);

   // تابع خصوصی برای چک و ثبت اصلاح - تایید سطح جدید اگر اصلاح کافی (حداقل درصد) باشد
   bool              CheckRetracement(double currentPrice);

   // تابع خصوصی برای تعیین روند - بر اساس دو سطح آخر سقف و کف برای تصمیم‌گیری صعودی/نزولی
   void              DetermineTrend();

   // تابع خصوصی برای چک تکراری بودن نقطه - مقایسه قیمت و زمان با آخرین در آرایه برای جلوگیری از ثبت دوباره
   bool              IsDuplicateSwing(const Swing &newSwing, const Swing &lastSwing, double priceTolerance = 0.00001);

   // تابع خصوصی برای تشخیص و ثبت FVG - بررسی ۳ کندل، فیلتر قدرت و اندازه، اضافه به حافظه اگر معتبر
   void              DetectAndRegisterFVG();

   // تابع خصوصی برای چک مصرف FVGها - بررسی تمام FVGهای فعال و پاک کردن مصرف‌شده‌ها (با حذف گرافیک)
   void              CheckFVGConsumption();

   // توابع گرافیکی خصوصی - برای رسم روی چارت اگر m_enableGraphics فعال باشد
   void              DrawSwing(string name, double price, datetime time, color clr, bool isHigh); // رسم فلش Wingdings با فاصله هوشمند (بر اساس ATR داخلی)
   void              DrawDottedLine(string name, datetime fromTime, double fromPrice, datetime toTime, double toPrice, string label); // رسم خط نقطه‌چین BOS/CHOCH با رنگ پویا و فونت سایز هوشمند
   void              DrawTrendText();       // رسم متن روند در گوشه بالا راست چارت با رنگ مناسب
   void              DrawFVG(FVG &fvg);     // رسم مستطیل شفاف FVG، خط EQ نقطه‌چین، و لیبل‌های FVG/EQ در سمت راست
   void              RemoveOldObjects();    // حذف اشیاء قدیمی اگر تعداد ساختارها بیش از حداکثر باشد

public:
   // سازنده کلاس - تنظیم ورودی‌ها و اولیه‌سازی متغیرها برای شروع کار
                     StructureAnalyzer(int lookback=100, double retrace=25.0, ENUM_TIMEFRAMES tf=PERIOD_CURRENT, string sym="", int maxStruct=30, bool graphics=true);

   // دestructor - پاک کردن تمام اشیاء گرافیکی برای جلوگیری از نشت حافظه و تمیز کردن چارت
                    ~StructureAnalyzer();

   // تابع اولیه‌سازی - فراخوانی در OnInit برای تنظیم سطوح اولیه و گرافیک (و فعال کردن شیفت راست چارت اگر گرافیک فعال)
   void              Init();

   // تابع آپدیت اصلی - فراخوانی در OnTick برای چک هر کندل جدید و اجرای منطق (شامل FVG)
   void              Update();

   // getterها برای دسترسی خارجی - برای سیستم‌های دیگر که بخواهند از کتابخانه استفاده کنند
   Swing             GetLastHigh() { return m_lastHigh; } // بازگشت آخرین سقف تایید شده
   Swing             GetLastLow() { return m_lastLow; }   // بازگشت آخرین کف تایید شده
   Swing             GetPreviousHigh() { return m_previousHigh; } // بازگشت سقف قبلی
   Swing             GetPreviousLow() { return m_previousLow; }   // بازگشت کف قبلی
   bool              IsBOS() { return m_isBOS; }          // آیا BOS رخ داده
   bool              IsCHOCH() { return m_isCHOCH; }      // آیا CHOCH رخ داده
   int               GetCurrentTrend() { return m_currentTrend; } // بازگشت روند فعلی (1 صعودی, -1 نزولی, 0 نامشخص)
   Swing             GetHighs(int index) { if(index < ArraySize(m_highs) && index >= 0) return m_highs[index]; Swing empty; return empty; } // بازگشت سقف از آرایه تاریخچه
   Swing             GetLows(int index) { if(index < ArraySize(m_lows) && index >= 0) return m_lows[index]; Swing empty; return empty; } // بازگشت کف از آرایه تاریخچه
   FVG               GetFVG(int index) { if(index < ArraySize(m_fvgs) && index >= 0) return m_fvgs[index]; FVG empty; return empty; } // بازگشت FVG از آرایه فعال
  };

//+------------------------------------------------------------------+
//| سازنده کلاس: تنظیم ورودی‌ها و پیشوند اشیاء - اولیه‌سازی متغیرها برای جلوگیری از تداخل |
//+------------------------------------------------------------------+
StructureAnalyzer::StructureAnalyzer(int lookback=100, double retrace=25.0, ENUM_TIMEFRAMES tf=PERIOD_CURRENT, string sym="", int maxStruct=30, bool graphics=true)
  {
   m_lookbackCandles = lookback;         // تنظیم تعداد کندل‌های گذشته برای سطوح اولیه
   m_retracementPercent = retrace;       // تنظیم درصد اصلاح
   m_timeframe = tf;                     // تنظیم تایم فریم
   m_symbol = (sym == "") ? _Symbol : sym; // تنظیم سیمبل - اگر خالی باشد، از _Symbol استفاده کن
   m_maxStructures = maxStruct;          // تنظیم حداکثر ساختارها
   m_enableGraphics = graphics;          // تنظیم فعال بودن گرافیک

   m_objPrefix = "StructAnal_" + IntegerToString((int)MathRand()); // ایجاد پیشوند منحصر به فرد با رندوم برای اشیاء

   m_isBOS = false;                      // اولیه‌سازی فلگ BOS به false
   m_isCHOCH = false;                    // اولیه‌سازی فلگ CHOCH به false
   m_waitingForRetracement = false;      // اولیه‌سازی حالت انتظار اصلاح به false
   m_currentTrend = 0;                   // روند اولیه را نامشخص تنظیم کن

   ArrayResize(m_highs, 0);              // اولیه‌سازی آرایه سقف‌ها به اندازه 0
   ArrayResize(m_lows, 0);               // اولیه‌سازی آرایه کف‌ها به اندازه 0
   ArrayResize(m_fvgs, 0);               // اولیه‌سازی آرایه FVGها به اندازه 0
  }

//+------------------------------------------------------------------+
//| دestructor: پاک کردن تمام اشیاء گرافیکی برای تمیز کردن چارت |
//+------------------------------------------------------------------+
StructureAnalyzer::~StructureAnalyzer()
  {
   //循環 بر روی تمام اشیاء چارت فعلی (chart_id = 0) و پاک کردن آن‌هایی که با پیشوند شروع می‌شوند
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);    // گرفتن نام شیء در اندیس i از چارت 0
      if(StringFind(name, m_objPrefix) == 0) ObjectDelete(0, name); // اگر با پیشوند مطابقت داشت، پاک کردن شیء
     }
  }

//+------------------------------------------------------------------+
//| تابع اولیه‌سازی: محاسبه سطوح اولیه و تنظیم روند اولیه با گرافیک اگر فعال باشد، و فعال کردن شیفت راست چارت |
//+------------------------------------------------------------------+
void StructureAnalyzer::Init()
  {
   CalculateInitialLevels();             // فراخوانی محاسبه سطوح اولیه از N کندل گذشته
   DetermineTrend();                     // تعیین روند اولیه بر اساس سطوح (احتمالاً نامشخص)
   if(m_enableGraphics)                  // اگر نمایش گرافیکی فعال باشد
     {
      ChartSetInteger(0, CHART_SHIFT, true); // فعال کردن شیفت راست چارت برای فضای لیبل‌ها در سمت راست
      DrawSwing(m_objPrefix + "InitHigh", m_lastHigh.price, m_lastHigh.time, clrGreen, true); // رسم سقف اولیه با فلش رو به پایین سبز
      DrawSwing(m_objPrefix + "InitLow", m_lastLow.price, m_lastLow.time, clrRed, false);     // رسم کف اولیه با فلش رو به بالا قرمز
      DrawTrendText();                    // رسم متن روند اولیه در گوشه چارت
     }
  }

//+------------------------------------------------------------------+
//| محاسبه سطوح اولیه از N کندل گذشته - با استفاده از iHighest و iLowest برای پیدا کردن max/min |
//+------------------------------------------------------------------+
void StructureAnalyzer::CalculateInitialLevels()
  {
   int highest = iHighest(m_symbol, m_timeframe, MODE_HIGH, m_lookbackCandles, 1); // پیدا کردن اندیس بالاترین قیمت در N کندل گذشته (شیفت 1 برای گذشته)
   int lowest = iLowest(m_symbol, m_timeframe, MODE_LOW, m_lookbackCandles, 1);    // پیدا کردن اندیس پایین‌ترین قیمت در N کندل گذشته

   m_lastHigh.price = iHigh(m_symbol, m_timeframe, highest); // تنظیم قیمت سقف اولیه
   m_lastHigh.time = iTime(m_symbol, m_timeframe, highest);  // تنظیم زمان سقف اولیه
   m_lastLow.price = iLow(m_symbol, m_timeframe, lowest);    // تنظیم قیمت کف اولیه
   m_lastLow.time = iTime(m_symbol, m_timeframe, lowest);    // تنظیم زمان کف اولیه

   // اضافه کردن سطوح اولیه به آرایه‌های تاریخچه برای مدیریت گرافیک
   ArrayResize(m_highs, 1);              // تغییر اندازه آرایه سقف‌ها به 1
   m_highs[0] = m_lastHigh;              // ذخیره سقف اولیه در آرایه
   ArrayResize(m_lows, 1);               // تغییر اندازه آرایه کف‌ها به 1
   m_lows[0] = m_lastLow;                // ذخیره کف اولیه در آرایه

   // سطوح قبلی را خالی نگه دار برای روند اولیه (نامشخص در ابتدای کار)
   m_previousHigh.price = 0;             // سقف قبلی را 0 تنظیم کن (نامعتبر)
   m_previousLow.price = 0;              // کف قبلی را 0 تنظیم کن (نامعتبر)
  }

//+------------------------------------------------------------------+
//| تابع آپدیت اصلی: چک هر کندل جدید و اجرای منطق تحلیل با داده‌های کندل بسته‌شده، شامل FVG |
//+------------------------------------------------------------------+
void StructureAnalyzer::Update()
  {
   // چک اگر کندل جدید بسته شده - برای جلوگیری از اجرای چندباره در یک کندل (stateful با static)
   static datetime lastTime = 0;         // زمان آخرین آپدیت ذخیره‌شده برای مقایسه
   datetime currentTime = iTime(m_symbol, m_timeframe, 0); // زمان کندل فعلی (باز)
   if(currentTime == lastTime) return;   // اگر کندل جدید بسته نشده، خارج شو و منتظر بمان
   lastTime = currentTime;               // آپدیت زمان آخرین کندل بسته‌شده

   // گرفتن قیمت‌های کندل بسته‌شده (شیفت 1) برای تصمیم‌گیری دقیق
   double closePrice = iClose(m_symbol, m_timeframe, 1); // کلوز کندل بسته‌شده برای چک شکست
   double highPrice = iHigh(m_symbol, m_timeframe, 1);   // های کندل بسته‌شده برای آپدیت اوج موج
   double lowPrice = iLow(m_symbol, m_timeframe, 1);     // لو کندل بسته‌شده برای آپدیت کف موج

   // گام 1: چک شکست (BOS یا CHOCH) بر اساس کلوز کندل
   if(CheckBreak(closePrice))            // اگر شکست رخ داده باشد (بازگشت true)
     {
      // تعیین زمان بازه برای آپدیت و ثبت نقطه مقابل (از سطح شکسته تا کندل فعلی)
      datetime fromTime = m_isUpwardBreak ? m_lastHigh.time : m_lastLow.time; // زمان سطح شکسته‌شده
      datetime toTime = iTime(m_symbol, m_timeframe, 1); // زمان کندل بسته‌شده فعلی

      // آپدیت و ثبت فوری نقطه مقابل به عنوان سطح نهایی (اضافه به آرایه اگر تکراری نباشد و رسم گرافیکی)
      UpdateAndRegisterOppositePoint(fromTime, toTime, m_isUpwardBreak);

      // تنظیم حالت انتظار برای اصلاح بعد از شکست با نقطه متحرک اولیه
      m_waitingForRetracement = true;    // فعال کردن حالت انتظار اصلاح
      m_fixedPoint = m_isUpwardBreak ? m_lastLow.price : m_lastHigh.price; // تنظیم نقطه ثابت (لو در صعودی، های در نزولی)
      m_movingPoint = m_isUpwardBreak ? highPrice : lowPrice; // تنظیم نقطه متحرک اولیه با های/لو کندل بسته‌شده
      m_retracementStartTime = toTime;   // ذخیره زمان شروع اصلاح برای محدود کردن

      if(m_enableGraphics)               // اگر گرافیک فعال باشد، رسم خط شکست با رنگ پویا
        {
         string label = m_isBOS ? "BOS" : "CHOCH"; // انتخاب لیبل بر اساس نوع شکست (BOS یا CHOCH)
         DrawDottedLine(m_objPrefix + "Break_" + TimeToString(toTime), fromTime, m_isUpwardBreak ? m_lastHigh.price : m_lastLow.price, toTime, closePrice, label); // رسم خط نقطه‌چین با متن
        }
     }

   // گام 2: اگر در حالت انتظار اصلاح باشیم، چک آپدیت نقطه متحرک و اصلاح
   if(m_waitingForRetracement)
     {
      // آپدیت نقطه متحرک با های یا لو واقعی کندل بسته‌شده (اصلاح برای استفاده از اوج واقعی موج)
      if(m_isUpwardBreak && highPrice > m_movingPoint) m_movingPoint = highPrice; // برای صعودی، از های استفاده کن برای اوج دقیق
      else if(!m_isUpwardBreak && lowPrice < m_movingPoint) m_movingPoint = lowPrice; // برای نزولی، از لو استفاده کن برای کف دقیق

      // چک اگر اصلاح کافی رخ داده (با کلوز کندل برای تصمیم‌گیری نهایی بازگشت قیمت)
      if(CheckRetracement(closePrice))
        {
         // ثبت سطح جدید بعد از تایید اصلاح (اضافه به آرایه و آپدیت قبلی/آخرین، با چک تکراری)
         Swing newSwing;
         newSwing.price = m_movingPoint; // قیمت سطح جدید
         newSwing.time = iTime(m_symbol, m_timeframe, 1); // زمان کندل فعلی برای سطح جدید

         if(m_isUpwardBreak)             // اگر شکست صعودی بوده، ثبت سقف جدید (SH)
           {
            // چک تکراری با آخرین سقف
            if(ArraySize(m_highs) > 0 && !IsDuplicateSwing(newSwing, m_highs[ArraySize(m_highs)-1]))
              {
               m_previousHigh = m_lastHigh; // آپدیت سقف قبلی با آخرین سقف
               m_lastHigh = newSwing;       // ثبت سقف جدید
               ArrayResize(m_highs, ArraySize(m_highs) + 1); // افزایش اندازه آرایه سقف‌ها
               m_highs[ArraySize(m_highs)-1] = m_lastHigh;   // اضافه سقف جدید به انتهای آرایه
               if(m_enableGraphics) DrawSwing(m_objPrefix + "High_" + TimeToString(m_lastHigh.time), m_lastHigh.price, m_lastHigh.time, clrGreen, true); // رسم فلش رو به پایین سبز برای SH
              }
           }
         else                            // اگر شکست نزولی بوده، ثبت کف جدید (SL)
           {
            // چک تکراری با آخرین کف
            if(ArraySize(m_lows) > 0 && !IsDuplicateSwing(newSwing, m_lows[ArraySize(m_lows)-1]))
              {
               m_previousLow = m_lastLow;   // آپدیت کف قبلی با آخرین کف
               m_lastLow = newSwing;        // ثبت کف جدید
               ArrayResize(m_lows, ArraySize(m_lows) + 1); // افزایش اندازه آرایه کف‌ها
               m_lows[ArraySize(m_lows)-1] = m_lastLow;    // اضافه کف جدید به انتهای آرایه
               if(m_enableGraphics) DrawSwing(m_objPrefix + "Low_" + TimeToString(m_lastLow.time), m_lastLow.price, m_lastLow.time, clrRed, false); // رسم فلش رو به بالا قرمز برای SL
              }
           }

         m_waitingForRetracement = false; // پایان حالت انتظار اصلاح پس از ثبت
         DetermineTrend();                // تعیین روند جدید بعد از ثبت سطح جدید
         if(m_enableGraphics)             // اگر گرافیک فعال باشد، آپدیت نمایش
           {
            DrawTrendText();               // آپدیت متن روند در چارت
            RemoveOldObjects();            // حذف ساختارهای قدیمی اگر بیش از حداکثر باشد برای جلوگیری از شلوغی
           }
        }
     }

   // گام 3: تشخیص و ثبت FVG جدید پس از بسته شدن کندل (بر اساس 3 کندل گذشته)
   DetectAndRegisterFVG();

   // گام 4: چک مصرف FVGهای فعال و پاک کردن مصرف‌شده‌ها
   CheckFVGConsumption();
  }

//+------------------------------------------------------------------+
//| تابع خصوصی برای تشخیص و ثبت FVG - بررسی 3 کندل، فیلتر قدرت و اندازه، اضافه به حافظه اگر معتبر |
//+------------------------------------------------------------------+
void StructureAnalyzer::DetectAndRegisterFVG()
  {
   // مطمئن می‌شویم حداقل 3 کندل برای بررسی الگو در دسترس باشد (اندیس 1، 2، 3)
   if(Bars(m_symbol, m_timeframe) < 4) return;
   
   // گرفتن قیمت‌های کندل‌های 1 (جدید بسته‌شده)، 2 و 3
   double high1 = iHigh(m_symbol, m_timeframe, 1); 
   double low1 = iLow(m_symbol, m_timeframe, 1);   
   // double open1 = iOpen(m_symbol, m_timeframe, 1); 
   // double close1 = iClose(m_symbol, m_timeframe, 1); 

   double high2 = iHigh(m_symbol, m_timeframe, 2); 
   double low2 = iLow(m_symbol, m_timeframe, 2);   
   double open2 = iOpen(m_symbol, m_timeframe, 2); 
   double close2 = iClose(m_symbol, m_timeframe, 2); 

   double high3 = iHigh(m_symbol, m_timeframe, 3); 
   double low3 = iLow(m_symbol, m_timeframe, 3);   
   
   // --- فیلتر قدرت کندل 2: بادی > شدوها (بادی / طول کلی > 0.50) ---
   double total2 = high2 - low2;
   double body2 = MathAbs(close2 - open2);
   double wicks2 = total2 - body2;
   
   // اگر کندل 2 خیلی ضعیف باشد (مثلا دوجی یا پین‌بار بلند)، منطق FVG را نادیده بگیر
   if(body2 <= wicks2) return; 
   
   // --- تشخیص FVG صعودی: Low[1] > High[3] ---
   if(low1 > high3)
     {
      double upper = low1;
      double lower = high3;
      double height = upper - lower;
      
      // فیلتر اندازه 40%: ارتفاع FVG باید حداقل 40% از بادی کندل 2 باشد
      if(height / body2 >= FVG_MIN_BODY_RATIO) 
        {
         FVG newFvg;
         newFvg.upperBoundary = upper;
         newFvg.lowerBoundary = lower;
         newFvg.eqPrice = lower + height * 0.5;
         newFvg.startTime = iTime(m_symbol, m_timeframe, 3); // <<-- اصلاح شد: زمان کندل 3 (شروع الگو)
         newFvg.isBullish = true;

         // اگر آرایه پر باشد، قدیمی‌ترین را پاک کن (FIFO)
         if(ArraySize(m_fvgs) >= m_maxStructures)
           {
            FVG old = m_fvgs[0];
            ObjectDelete(0, old.objRectName);
            ObjectDelete(0, old.objEqName);
            ObjectDelete(0, old.objFvgLabel);
            ObjectDelete(0, old.objEqLabel);
            ArrayCopy(m_fvgs, m_fvgs, 0, 1); // شیفت آرایه برای حذف عنصر اول
            ArrayResize(m_fvgs, m_maxStructures - 1); // کاهش اندازه
           }

         // اضافه FVG جدید به انتهای آرایه
         ArrayResize(m_fvgs, ArraySize(m_fvgs) + 1);
         m_fvgs[ArraySize(m_fvgs)-1] = newFvg;

         // رسم اگر گرافیک فعال باشد - با ارجاع به عنصری که تازه اضافه شده
         if(m_enableGraphics) DrawFVG(m_fvgs[ArraySize(m_fvgs)-1]);
        }
     }

   // --- تشخیص FVG نزولی: High[1] < Low[3] ---
   if(high1 < low3)
     {
      double upper = low3;
      double lower = high1;
      double height = upper - lower;
      
      // فیلتر اندازه 40%: ارتفاع FVG باید حداقل 40% از بادی کندل 2 باشد
      if(height / body2 >= FVG_MIN_BODY_RATIO) 
        {
         FVG newFvg;
         newFvg.upperBoundary = upper;
         newFvg.lowerBoundary = lower;
         newFvg.eqPrice = lower + height * 0.5;
         newFvg.startTime = iTime(m_symbol, m_timeframe, 3); // <<-- اصلاح شد: زمان کندل 3 (شروع الگو)
         newFvg.isBullish = false;

         // اگر آرایه پر باشد، قدیمی‌ترین را پاک کن (FIFO)
         if(ArraySize(m_fvgs) >= m_maxStructures)
           {
            FVG old = m_fvgs[0];
            ObjectDelete(0, old.objRectName);
            ObjectDelete(0, old.objEqName);
            ObjectDelete(0, old.objFvgLabel);
            ObjectDelete(0, old.objEqLabel);
            ArrayCopy(m_fvgs, m_fvgs, 0, 1); // شیفت آرایه برای حذف عنصر اول
            ArrayResize(m_fvgs, m_maxStructures - 1); // کاهش اندازه
           }

         // اضافه FVG جدید به انتهای آرایه
         ArrayResize(m_fvgs, ArraySize(m_fvgs) + 1);
         m_fvgs[ArraySize(m_fvgs)-1] = newFvg;

         // رسم اگر گرافیک فعال باشد - با ارجاع به عنصری که تازه اضافه شده
         if(m_enableGraphics) DrawFVG(m_fvgs[ArraySize(m_fvgs)-1]);
        }
     }
  }


//+------------------------------------------------------------------+
//| تابع خصوصی برای چک مصرف FVGها - بررسی تمام FVGهای فعال و پاک کردن مصرف‌شده‌ها با حذف گرافیک |
//+------------------------------------------------------------------+
void StructureAnalyzer::CheckFVGConsumption()
  {
   double currentLow = iLow(m_symbol, m_timeframe, 0); // Low کندل فعلی (برای چک مصرف)
   double currentHigh = iHigh(m_symbol, m_timeframe, 0); // High کندل فعلی (برای چک مصرف)

   for(int i = ArraySize(m_fvgs) - 1; i >= 0; i--) // از جدیدترین به قدیمی‌ترین برای جلوگیری از شیفت اشتباه
     {
      FVG fvg = m_fvgs[i];
      bool consumed = false;

      if(fvg.isBullish)                   // برای FVG صعودی: چک مصرف پایین مرز پایین
        {
         if(currentLow <= fvg.lowerBoundary) consumed = true;
        }
      else                                // برای FVG نزولی: چک مصرف بالای مرز بالا
        {
         if(currentHigh >= fvg.upperBoundary) consumed = true;
        }

      if(consumed)                        // اگر مصرف شده، حذف گرافیک و از آرایه
        {
         ObjectDelete(0, fvg.objRectName);
         ObjectDelete(0, fvg.objEqName);
         ObjectDelete(0, fvg.objFvgLabel);
         ObjectDelete(0, fvg.objEqLabel);

         // حذف از آرایه با شیفت
         ArrayCopy(m_fvgs, m_fvgs, i, i+1);
         ArrayResize(m_fvgs, ArraySize(m_fvgs) - 1);
        }
     }
  }

//+------------------------------------------------------------------+
//| رسم FVG با مستطیل شفاف، خط EQ نقطه‌چین، و لیبل‌های FVG/EQ در سمت راست با شفافیت شیشه‌ای |
//+------------------------------------------------------------------+
void StructureAnalyzer::DrawFVG(FVG &fvg)
  {
   // زمان دور در آینده برای امتداد راست اشیاء گرافیکی (تقریباً تا 1000 کندل جلوتر)
   datetime farTime = TimeCurrent() + PeriodSeconds(m_timeframe) * 1000; 

   // رنگ FVG بر اساس جهت: سبز برای صعودی، قرمز برای نزولی
   color zoneColor = fvg.isBullish ? clrGreen : clrRed;
   
   // --- 1. رسم مستطیل FVG با شفافیت (شیشه‌ای) ---
   fvg.objRectName = m_objPrefix + "FVG_Rect_" + TimeToString(fvg.startTime);
   ObjectCreate(0, fvg.objRectName, OBJ_RECTANGLE, 0, fvg.startTime, fvg.upperBoundary, farTime, fvg.lowerBoundary);
   
   // آلفا 128 برای شفافیت 50% (شیشه‌ای) - رنگ‌ها به صورت ARGB تنظیم می‌شوند
   ObjectSetInteger(0, fvg.objRectName, OBJPROP_COLOR, ColorToARGB(zoneColor, 128)); 
   ObjectSetInteger(0, fvg.objRectName, OBJPROP_FILL, true);       // پر کردن مستطیل
   ObjectSetInteger(0, fvg.objRectName, OBJPROP_BACK, true);       // پشت کندل‌ها برای شیشه‌ای بودن
   
   // --- 2. رسم خط EQ نقطه‌چین (خط 50 درصد) ---
   fvg.objEqName = m_objPrefix + "FVG_Eq_" + TimeToString(fvg.startTime);
   ObjectCreate(0, fvg.objEqName, OBJ_TREND, 0, fvg.startTime, fvg.eqPrice, farTime, fvg.eqPrice);
   ObjectSetInteger(0, fvg.objEqName, OBJPROP_STYLE, STYLE_DOT); // نقطه‌چین
   ObjectSetInteger(0, fvg.objEqName, OBJPROP_COLOR, zoneColor); // رنگ همان FVG
   ObjectSetInteger(0, fvg.objEqName, OBJPROP_RAY, true);       // امتداد به راست

   // --- 3. رسم لیبل FVG در سمت راست چارت ---
   // <<-- اصلاح شد: تخصیص نام به متغیر fvg.objFvgLabel
   fvg.objFvgLabel = m_objPrefix + "FVG_Label_" + TimeToString(fvg.startTime); 
   double fvgLabelPrice = fvg.isBullish ? fvg.lowerBoundary : fvg.upperBoundary; // پایین برای صعودی، بالا برای نزولی
   ObjectCreate(0, fvg.objFvgLabel, OBJ_TEXT, 0, farTime, fvgLabelPrice);
   
   ObjectSetString(0, fvg.objFvgLabel, OBJPROP_TEXT, "FVG");
   ObjectSetInteger(0, fvg.objFvgLabel, OBJPROP_COLOR, clrBlack); // رنگ متن لیبل
   ObjectSetInteger(0, fvg.objFvgLabel, OBJPROP_FONTSIZE, 10);

   // --- 4. رسم لیبل EQ در سمت راست چارت ---
   // <<-- اصلاح شد: تخصیص نام به متغیر fvg.objEqLabel
   fvg.objEqLabel = m_objPrefix + "EQ_Label_" + TimeToString(fvg.startTime);
   ObjectCreate(0, fvg.objEqLabel, OBJ_TEXT, 0, farTime, fvg.eqPrice);
   
   ObjectSetString(0, fvg.objEqLabel, OBJPROP_TEXT, "EQ");
   ObjectSetInteger(0, fvg.objEqLabel, OBJPROP_COLOR, clrBlack); // رنگ متن لیبل
   ObjectSetInteger(0, fvg.objEqLabel, OBJPROP_FONTSIZE, 10);
  }

//+------------------------------------------------------------------+
//| رسم متن روند در گوشه بالا راست چارت - با رنگ مناسب بر اساس روند |
//+------------------------------------------------------------------+
void StructureAnalyzer::DrawTrendText()
  {
   string name = m_objPrefix + "TrendText"; // نام شیء متن روند برای مدیریت
   ObjectDelete(0, name);                   // پاک کردن متن قبلی اگر وجود داشته باشد برای آپدیت

   string text;                          // متن روند بر اساس وضعیت فعلی
   color clr;                            // رنگ متن بر اساس روند
   if(m_currentTrend == 1)               // اگر روند صعودی تشخیص داده شود
     {
      text = "ترند صعودی";             // متن "ترند صعودی" تنظیم کن
      clr = clrGreen;                   // رنگ سبز برای صعودی
     }
   else if(m_currentTrend == -1)         // اگر روند نزولی تشخیص داده شود
     {
      text = "ترند نزولی";             // متن "ترند نزولی" تنظیم کن
      clr = clrRed;                     // رنگ قرمز برای نزولی
     }
   else                                  // اگر روند نامشخص باشد
     {
      text = "ترند نامشخص";            // متن "ترند نامشخص" تنظیم کن
      clr = clrGray;                    // رنگ خاکستری برای نامشخص
     }

   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0); // ایجاد شیء لیبل روی چارت 0
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER); // تنظیم مکان به گوشه بالا راست با ثابت داخلی
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10); // فاصله افقی از گوشه 10 پیکسل
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 10); // فاصله عمودی از گوشه 10 پیکسل
   ObjectSetString(0, name, OBJPROP_TEXT, text);     // تنظیم متن لیبل
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);   // تنظیم رنگ متن
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14); // تنظیم اندازه فونت به 14 برای خوانایی
  }

//+------------------------------------------------------------------+
//| حذف اشیاء قدیمی اگر بیش از حداکثر - برای جلوگیری از شلوغی چارت و مدیریت حافظه |
//+------------------------------------------------------------------+
void StructureAnalyzer::RemoveOldObjects()
  {
   // چک و حذف از آرایه سقف‌ها اگر بیش از حداکثر باشد (FIFO: حذف از ابتدای آرایه)
   while(ArraySize(m_highs) > m_maxStructures)
     {
      string oldName = m_objPrefix + "High_" + TimeToString(m_highs[0].time); // نام شیء قدیمی سقف بر اساس زمان با TimeToString
      ObjectDelete(0, oldName);             // پاک کردن شیء قدیمی از چارت 0
      ArrayCopy(m_highs, m_highs, 0, 1); // شیفت آرایه به سمت چپ برای حذف اولین عنصر
      ArrayResize(m_highs, ArraySize(m_highs) - 1); // کاهش اندازه آرایه پس از حذف
     }

   // چک و حذف از آرایه کف‌ها اگر بیش از حداکثر باشد (FIFO: حذف از ابتدای آرایه)
   while(ArraySize(m_lows) > m_maxStructures)
     {
      string oldName = m_objPrefix + "Low_" + TimeToString(m_lows[0].time); // نام شیء قدیمی کف بر اساس زمان با TimeToString
      ObjectDelete(0, oldName);             // پاک کردن شیء قدیمی از چارت 0
      ArrayCopy(m_lows, m_lows, 0, 1);   // شیفت آرایه به سمت چپ برای حذف اولین عنصر
      ArrayResize(m_lows, ArraySize(m_lows) - 1); // کاهش اندازه آرایه پس از حذف
     }

   // چک و حذف از آرایه FVGها اگر بیش از حداکثر باشد (FIFO: حذف از ابتدای آرایه با حذف گرافیک)
   while(ArraySize(m_fvgs) > m_maxStructures)
     {
      FVG old = m_fvgs[0];
      ObjectDelete(0, old.objRectName);
      ObjectDelete(0, old.objEqName);
      ObjectDelete(0, old.objFvgLabel);
      ObjectDelete(0, old.objEqLabel);
      ArrayCopy(m_fvgs, m_fvgs, 0, 1);   // شیفت آرایه به سمت چپ برای حذف اولین عنصر
      ArrayResize(m_fvgs, ArraySize(m_fvgs) - 1); // کاهش اندازه آرایه پس از حذف
     }
  }
