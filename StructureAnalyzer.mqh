//+------------------------------------------------------------------+
//|                                           StructureAnalyzer.mqh |
//|                  Copyright 2025, xAI - Built by Grok             |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, xAI - Built by Grok"
#property link      ""
#property version   "1.00"
#property strict

// شامل فایل‌های لازم برای کار با اشیاء گرافیکی و توابع MQL5 - برای دسترسی به ثابت‌هایی مثل OBJPROP_CORNER
#include <Object.mqh>

// تعریف ساختار برای سطوح نوسان (Swing) - شامل قیمت و زمان سطح برای ذخیره‌سازی آسان
struct Swing
  {
   double            price;   // قیمت سطح (های یا لو)
   datetime          time;    // زمان سطح (زمان کندل مربوطه برای همگام‌سازی با چارت)
  };

// کلاس اصلی برای تحلیل ساختار قیمت - این کلاس تمام منطق تحلیل BOS، CHOCH و روند را مدیریت می‌کند
class StructureAnalyzer
  {
private:
   // متغیرهای ورودی - تنظیمات قابل تغییر توسط کاربر برای سفارشی‌سازی رفتار کتابخانه
   int               m_lookbackCandles;     // تعداد کندل‌های گذشته برای محاسبه سطوح اولیه (پیشفرض 100)
   double            m_retracementPercent;  // درصد حداقل اصلاح برای تایید سطح جدید (پیشفرض 25.0)
   ENUM_TIMEFRAMES   m_timeframe;           // تایم فریم مورد استفاده برای تحلیل (پیشفرض فعلی چارت)
   string            m_symbol;              // سیمبل (جفت ارز) برای تحلیل (پیشفرض سیمبل فعلی)
   int               m_maxStructures;       // حداکثر تعداد ساختارها (سقف/کف) برای ذخیره و گرافیک (پیشفرض 30)
   bool              m_enableGraphics;      // فلگ برای فعال یا غیرفعال کردن نمایش گرافیکی (پیشفرض true)

   // سطوح فعلی و قبلی - برای پیگیری روند و مقایسه سطوح برای تعیین صعودی/نزولی
   Swing             m_lastHigh;            // آخرین سقف تایید شده
   Swing             m_previousHigh;        // سقف قبلی تایید شده برای مقایسه
   Swing             m_lastLow;             // آخرین کف تایید شده
   Swing             m_previousLow;         // کف قبلی تایید شده برای مقایسه

   // آرایه‌ها برای تاریخچه سطوح - تا m_maxStructures، برای مدیریت گرافیک و حذف قدیمی‌ها اگر بیش از حد شوند
   Swing             m_highs[];             // آرایه سقف‌های تایید شده (FIFO برای حذف قدیمی‌ها)
   Swing             m_lows[];              // آرایه کف‌های تایید شده (FIFO برای حذف قدیمی‌ها)

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

   // تابع خصوصی برای آپدیت نقطه مقابل بعد شکست - بدون اضافه به آرایه، فقط آپدیت سطوح فعلی برای دقت
   void              UpdateOppositePoint(datetime fromTime, datetime toTime, bool isUpward);

   // تابع خصوصی برای چک و ثبت اصلاح - تایید سطح جدید اگر اصلاح کافی (حداقل درصد) باشد
   bool              CheckRetracement(double currentPrice);

   // تابع خصوصی برای تعیین روند - بر اساس دو سطح آخر سقف و کف برای تصمیم‌گیری صعودی/نزولی
   void              DetermineTrend();

   // توابع گرافیکی خصوصی - برای رسم روی چارت اگر m_enableGraphics فعال باشد
   void              DrawSwing(string name, double price, datetime time, color clr, string label); // رسم علامت SH/SL با متن
   void              DrawDottedLine(string name, datetime fromTime, double fromPrice, datetime toTime, double toPrice, string label); // رسم خط نقطه‌چین BOS/CHOCH با متن در وسط
   void              DrawTrendText();       // رسم متن روند در گوشه بالا راست چارت با رنگ مناسب
   void              RemoveOldObjects();    // حذف اشیاء قدیمی اگر تعداد ساختارها بیش از حداکثر باشد

public:
   // سازنده کلاس - تنظیم ورودی‌ها و اولیه‌سازی متغیرها برای شروع کار
                     StructureAnalyzer(int lookback=100, double retrace=25.0, ENUM_TIMEFRAMES tf=PERIOD_CURRENT, string sym=_Symbol, int maxStruct=30, bool graphics=true);

   // دestructor - پاک کردن تمام اشیاء گرافیکی برای جلوگیری از نشت حافظه و تمیز کردن چارت
                    ~StructureAnalyzer();

   // تابع اولیه‌سازی - فراخوانی در OnInit برای تنظیم سطوح اولیه و گرافیک
   void              Init();

   // تابع آپدیت اصلی - فراخوانی در OnTick برای چک هر کندل جدید و اجرای منطق
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
  };

//+------------------------------------------------------------------+
//| سازنده کلاس: تنظیم ورودی‌ها و پیشوند اشیاء - اولیه‌سازی متغیرها برای جلوگیری از تداخل |
//+------------------------------------------------------------------+
StructureAnalyzer::StructureAnalyzer(int lookback=100, double retrace=25.0, ENUM_TIMEFRAMES tf=PERIOD_CURRENT, string sym=_Symbol, int maxStruct=30, bool graphics=true)
  {
   m_lookbackCandles = lookback;         // تنظیم تعداد کندل‌های گذشته برای سطوح اولیه
   m_retracementPercent = retrace;       // تنظیم درصد اصلاح
   m_timeframe = tf;                     // تنظیم تایم فریم
   m_symbol = sym;                       // تنظیم سیمبل
   m_maxStructures = maxStruct;          // تنظیم حداکثر ساختارها
   m_enableGraphics = graphics;          // تنظیم فعال بودن گرافیک

   m_objPrefix = "StructAnal_" + IntegerToString((int)MathRand()); // ایجاد پیشوند منحصر به فرد با رندوم برای اشیاء

   m_isBOS = false;                      // اولیه‌سازی فلگ BOS به false
   m_isCHOCH = false;                    // اولیه‌سازی فلگ CHOCH به false
   m_waitingForRetracement = false;      // اولیه‌سازی حالت انتظار اصلاح به false
   m_currentTrend = 0;                   // روند اولیه را نامشخص تنظیم کن

   ArrayResize(m_highs, 0);              // اولیه‌سازی آرایه سقف‌ها به اندازه 0
   ArrayResize(m_lows, 0);               // اولیه‌سازی آرایه کف‌ها به اندازه 0
  }

//+------------------------------------------------------------------+
//| دestructor: پاک کردن تمام اشیاء گرافیکی برای تمیز کردن چارت |
//+------------------------------------------------------------------+
StructureAnalyzer::~StructureAnalyzer()
  {
   //循环 بر روی تمام اشیاء چارت فعلی (chart_id = 0) و پاک کردن آن‌هایی که با پیشوند شروع می‌شوند
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);    // گرفتن نام شیء در اندیس i از چارت 0
      if(StringFind(name, m_objPrefix) == 0) ObjectDelete(0, name); // اگر با پیشوند مطابقت داشت، پاک کردن شیء
     }
  }

//+------------------------------------------------------------------+
//| تابع اولیه‌سازی: محاسبه سطوح اولیه و تنظیم روند اولیه با گرافیک اگر فعال باشد |
//+------------------------------------------------------------------+
void StructureAnalyzer::Init()
  {
   CalculateInitialLevels();             // فراخوانی محاسبه سطوح اولیه از N کندل گذشته
   DetermineTrend();                     // تعیین روند اولیه بر اساس سطوح (احتمالاً نامشخص)
   if(m_enableGraphics)                  // اگر نمایش گرافیکی فعال باشد
     {
      DrawSwing(m_objPrefix + "InitHigh", m_lastHigh.price, m_lastHigh.time, clrGreen, "SH"); // رسم سقف اولیه با علامت SH
      DrawSwing(m_objPrefix + "InitLow", m_lastLow.price, m_lastLow.time, clrRed, "SL");     // رسم کف اولیه با علامت SL
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
//| تابع آپدیت اصلی: چک هر کندل جدید و اجرای منطق تحلیل با داده‌های کندل بسته‌شده |
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
      // تعیین زمان بازه برای آپدیت نقطه مقابل (از سطح شکسته تا کندل فعلی)
      datetime fromTime = m_isUpwardBreak ? m_lastHigh.time : m_lastLow.time; // زمان سطح شکسته‌شده
      datetime toTime = iTime(m_symbol, m_timeframe, 1); // زمان کندل بسته‌شده فعلی

      // آپدیت نقطه مقابل بدون اضافه به آرایه (فقط آپدیت سطوح فعلی برای دقت تحلیل)
      UpdateOppositePoint(fromTime, toTime, m_isUpwardBreak);

      // تنظیم حالت انتظار برای اصلاح بعد از شکست با نقطه متحرک اولیه
      m_waitingForRetracement = true;    // فعال کردن حالت انتظار اصلاح
      m_fixedPoint = m_isUpwardBreak ? m_lastLow.price : m_lastHigh.price; // تنظیم نقطه ثابت (لو در صعودی، های در نزولی)
      m_movingPoint = m_isUpwardBreak ? highPrice : lowPrice; // تنظیم نقطه متحرک اولیه با های/لو کندل بسته‌شده
      m_retracementStartTime = toTime;   // ذخیره زمان شروع اصلاح برای محدود کردن

      if(m_enableGraphics)               // اگر گرافیک فعال باشد، رسم خط شکست
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
         // ثبت سطح جدید بعد از تایید اصلاح (اضافه به آرایه و آپدیت قبلی/آخرین)
         if(m_isUpwardBreak)             // اگر شکست صعودی بوده، ثبت سقف جدید
           {
            m_previousHigh = m_lastHigh; // آپدیت سقف قبلی با آخرین سقف
            m_lastHigh.price = m_movingPoint; // ثبت سقف جدید با نقطه متحرک تایید شده
            m_lastHigh.time = iTime(m_symbol, m_timeframe, 1); // زمان کندل فعلی برای سطح جدید
            ArrayResize(m_highs, ArraySize(m_highs) + 1); // افزایش اندازه آرایه سقف‌ها
            m_highs[ArraySize(m_highs)-1] = m_lastHigh;   // اضافه سقف جدید به انتهای آرایه
            if(m_enableGraphics) DrawSwing(m_objPrefix + "High_" + TimeToString(m_lastHigh.time), m_lastHigh.price, m_lastHigh.time, clrGreen, "SH"); // رسم SH اگر گرافیک فعال
           }
         else                            // اگر شکست نزولی بوده، ثبت کف جدید
           {
            m_previousLow = m_lastLow;   // آپدیت کف قبلی با آخرین کف
            m_lastLow.price = m_movingPoint; // ثبت کف جدید با نقطه متحرک تایید شده
            m_lastLow.time = iTime(m_symbol, m_timeframe, 1); // زمان کندل فعلی برای سطح جدید
            ArrayResize(m_lows, ArraySize(m_lows) + 1); // افزایش اندازه آرایه کف‌ها
            m_lows[ArraySize(m_lows)-1] = m_lastLow;    // اضافه کف جدید به انتهای آرایه
            if(m_enableGraphics) DrawSwing(m_objPrefix + "Low_" + TimeToString(m_lastLow.time), m_lastLow.price, m_lastLow.time, clrRed, "SL"); // رسم SL اگر گرافیک فعال
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
  }

//+------------------------------------------------------------------+
//| چک شکست: BOS یا CHOCH بر اساس کلوز کندل و روند فعلی برای تمایز |
//+------------------------------------------------------------------+
bool StructureAnalyzer::CheckBreak(double closePrice)
  {
   m_isBOS = false;                      // ریست فلگ BOS برای هر چک جدید
   m_isCHOCH = false;                    // ریست فلگ CHOCH برای هر چک جدید

   if(closePrice > m_lastHigh.price)     // اگر کلوز بالاتر از آخرین سقف باشد (شکست سقف احتمالی)
     {
      m_isUpwardBreak = true;            // تنظیم جهت شکست به صعودی
      if(m_currentTrend == -1) m_isCHOCH = true; // اگر روند قبلی نزولی بوده، این CHOCH (تغییر کاراکتر) است
      else m_isBOS = true;               // در غیر این صورت، BOS (شکست ساختار در جهت روند) است
      m_lastBOSTime = m_isBOS ? iTime(m_symbol, m_timeframe, 1) : 0; // ذخیره زمان BOS اگر رخ داده
      m_lastCHOCHTime = m_isCHOCH ? iTime(m_symbol, m_timeframe, 1) : 0; // ذخیره زمان CHOCH اگر رخ داده
      return true;                       // بازگشت true برای نشان دادن رخ دادن شکست
     }
   else if(closePrice < m_lastLow.price) // اگر کلوز پایین‌تر از آخرین کف باشد (شکست کف احتمالی)
     {
      m_isUpwardBreak = false;           // تنظیم جهت شکست به نزولی
      if(m_currentTrend == 1) m_isCHOCH = true; // اگر روند قبلی صعودی بوده، این CHOCH است
      else m_isBOS = true;               // در غیر این صورت، BOS است
      m_lastBOSTime = m_isBOS ? iTime(m_symbol, m_timeframe, 1) : 0; // ذخیره زمان BOS
      m_lastCHOCHTime = m_isCHOCH ? iTime(m_symbol, m_timeframe, 1) : 0; // ذخیره زمان CHOCH
      return true;                       // بازگشت true برای نشان دادن رخ دادن شکست
     }
   return false;                         // اگر هیچ شکستی رخ نداده، false برگردان
  }

//+------------------------------------------------------------------+
//| آپدیت نقطه مقابل بعد شکست - فقط آپدیت سطوح فعلی بدون اضافه به آرایه برای جلوگیری از تکرار |
//+------------------------------------------------------------------+
void StructureAnalyzer::UpdateOppositePoint(datetime fromTime, datetime toTime, bool isUpward)
  {
   int fromShift = iBarShift(m_symbol, m_timeframe, fromTime); // تبدیل زمان شروع به شیفت کندل
   int toShift = iBarShift(m_symbol, m_timeframe, toTime);     // تبدیل زمان پایان به شیفت کندل
   int barCount = fromShift - toShift + 1;                     // محاسبه تعداد کندل‌ها در بازه (شامل هر دو انتها)

   if(isUpward)                          // اگر شکست صعودی باشد، آپدیت کف (لو) به عنوان نقطه مقابل با پایین‌ترین لو در بازه
     {
      int lowest = iLowest(m_symbol, m_timeframe, MODE_LOW, barCount, toShift); // پیدا کردن پایین‌ترین لو در بازه
      m_lastLow.price = iLow(m_symbol, m_timeframe, lowest); // آپدیت قیمت کف
      m_lastLow.time = iTime(m_symbol, m_timeframe, lowest); // آپدیت زمان کف
      // توجه: اضافه به آرایه فقط در زمان تایید اصلاح انجام می‌شود
     }
   else                                  // اگر شکست نزولی باشد، آپدیت سقف (های) به عنوان نقطه مقابل با بالاترین های در بازه
     {
      int highest = iHighest(m_symbol, m_timeframe, MODE_HIGH, barCount, toShift); // پیدا کردن بالاترین های در بازه
      m_lastHigh.price = iHigh(m_symbol, m_timeframe, highest); // آپدیت قیمت سقف
      m_lastHigh.time = iTime(m_symbol, m_timeframe, highest);  // آپدیت زمان سقف
      // توجه: اضافه به آرایه فقط در زمان تایید اصلاح انجام می‌شود
     }
  }

//+------------------------------------------------------------------+
//| چک اصلاح و ثبت سطح جدید - محاسبه درصد اصلاح بر اساس فاصله کل موج |
//+------------------------------------------------------------------+
bool StructureAnalyzer::CheckRetracement(double currentPrice)
  {
   double distance = MathAbs(m_movingPoint - m_fixedPoint); // محاسبه فاصله کل موج محرک (اوج تا ثابت)
   double retrace;                      // اندازه اصلاح فعلی
   if(m_isUpwardBreak)                  // برای صعودی، اصلاح به سمت پایین (از اوج به کلوز فعلی)
      retrace = m_movingPoint - currentPrice;
   else                                 // برای نزولی، اصلاح به سمت بالا (از کلوز فعلی به کف)
      retrace = currentPrice - m_movingPoint;

   if(retrace / distance >= m_retracementPercent / 100.0) // اگر درصد اصلاح حداقل مورد نیاز باشد
     {
      return true;                       // بازگشت true برای تایید اصلاح و ثبت سطح
     }
   return false;                         // اگر اصلاح کافی نباشد، false برگردان
  }

//+------------------------------------------------------------------+
//| تعیین روند بر اساس دو سطح آخر - همیشه با مقایسه دو سقف و دو کف آخر |
//+------------------------------------------------------------------+
void StructureAnalyzer::DetermineTrend()
  {
   if(m_lastHigh.price > m_previousHigh.price && m_lastLow.price > m_previousLow.price)
      m_currentTrend = 1;                // تنظیم به صعودی اگر هر دو سطح بالاتر از قبلی باشند
   else if(m_lastHigh.price < m_previousHigh.price && m_lastLow.price < m_previousLow.price)
      m_currentTrend = -1;               // تنظیم به نزولی اگر هر دو سطح پایین‌تر از قبلی باشند
   else
      m_currentTrend = 0;                // در غیر این صورت، نامشخص نگه دار
  }

//+------------------------------------------------------------------+
//| رسم علامت نوسان (SH/SL) با متن - برای سطوح تایید شده روی چارت |
//+------------------------------------------------------------------+
void StructureAnalyzer::DrawSwing(string name, double price, datetime time, color clr, string label)
  {
   ObjectCreate(0, name, OBJ_TEXT, 0, time, price); // ایجاد شیء متن روی چارت فعلی (chart_id = 0)
   ObjectSetString(0, name, OBJPROP_TEXT, label);    // تنظیم متن شیء (SH یا SL)
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);   // تنظیم رنگ شیء (سبز برای سقف، قرمز برای کف)
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 12); // تنظیم اندازه فونت متن به 12
  }

//+------------------------------------------------------------------+
//| رسم خط نقطه‌چین با متن در وسط (برای BOS/CHOCH) - کوتاه و مورب اگر قیمت‌ها متفاوت باشند |
//+------------------------------------------------------------------+
void StructureAnalyzer::DrawDottedLine(string name, datetime fromTime, double fromPrice, datetime toTime, double toPrice, string label)
  {
   // رسم خط نقطه‌چین (مورب اگر لازم، اما کوتاه بین دو نقطه بدون ادامه)
   string lineName = name + "_Line";     // نام شیء خط برای مدیریت جداگانه
   ObjectCreate(0, lineName, OBJ_TREND, 0, fromTime, fromPrice, toTime, toPrice); // ایجاد خط روند بین دو نقطه روی چارت 0
   ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT); // تنظیم سبک به نقطه‌چین
   ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrBlue);   // تنظیم رنگ آبی برای خط
   ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);         // تنظیم عرض خط به 1
   ObjectSetInteger(0, lineName, OBJPROP_RAY, false);       // غیرفعال کردن ادامه خط (ray) برای کوتاه ماندن

   // محاسبه نقطه وسط برای قرار دادن متن
   datetime midTime = fromTime + (toTime - fromTime) / 2;   // زمان وسط خط برای موقعیت متن
   double midPrice = fromPrice + (toPrice - fromPrice) / 2; // قیمت وسط خط برای موقعیت متن

   // رسم متن در وسط خط
   string textName = name + "_Text";     // نام شیء متن برای مدیریت جداگانه
   ObjectCreate(0, textName, OBJ_TEXT, 0, midTime, midPrice); // ایجاد متن در موقعیت وسط
   ObjectSetString(0, textName, OBJPROP_TEXT, "......." + label + "......."); // تنظیم متن با نقطه‌چین اطراف لیبل
   ObjectSetInteger(0, textName, OBJPROP_COLOR, clrBlack); // تنظیم رنگ سیاه برای متن
   ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 10);    // تنظیم اندازه فونت متن به 10
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
  }
