//+------------------------------------------------------------------+
//|                                           StructureAnalyzer.mqh |
//|                  Copyright 2025, xAI - Built by Grok             |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, xAI - Built by Grok"
#property link      ""
#property version   "1.00"
#property strict

// شامل فایل‌های لازم برای کار با اشیاء گرافیکی و توابع MQL5
#include <Object.mqh>

// تعریف ساختار برای سطوح نوسان (Swing) - شامل قیمت و زمان سطح
struct Swing
  {
   double            price;   // قیمت سطح (های یا لو)
   datetime          time;    // زمان سطح (زمان کندل مربوطه)
  };

// کلاس اصلی برای تحلیل ساختار قیمت - این کلاس تمام منطق را مدیریت می‌کند
class StructureAnalyzer
  {
private:
   // متغیرهای ورودی - تنظیمات قابل تغییر توسط کاربر
   int               m_lookbackCandles;     // تعداد کندل‌های گذشته برای محاسبه سطوح اولیه
   double            m_retracementPercent;  // درصد حداقل اصلاح برای تایید سطح جدید (پیشفرض 25%)
   ENUM_TIMEFRAMES   m_timeframe;           // تایم فریم مورد استفاده برای تحلیل
   string            m_symbol;              // سیمبل (جفت ارز) برای تحلیل
   int               m_maxStructures;       // حداکثر تعداد ساختارها (سقف/کف) برای ذخیره و گرافیک
   bool              m_enableGraphics;      // فلگ برای فعال یا غیرفعال کردن نمایش گرافیکی

   // سطوح فعلی و قبلی - برای پیگیری روند و مقایسه
   Swing             m_lastHigh;            // آخرین سقف تایید شده
   Swing             m_previousHigh;        // سقف قبلی تایید شده
   Swing             m_lastLow;             // آخرین کف تایید شده
   Swing             m_previousLow;         // کف قبلی تایید شده

   // آرایه‌ها برای تاریخچه سطوح - تا m_maxStructures، برای مدیریت گرافیک و حذف قدیمی‌ها
   Swing             m_highs[];             // آرایه سقف‌های تایید شده
   Swing             m_lows[];              // آرایه کف‌های تایید شده

   // فلگ‌ها برای رویدادها - برای تشخیص BOS و CHOCH
   bool              m_isBOS;               // آیا BOS اخیر رخ داده است
   bool              m_isCHOCH;             // آیا CHOCH اخیر رخ داده است
   datetime          m_lastBOSTime;         // زمان آخرین BOS
   datetime          m_lastCHOCHTime;       // زمان آخرین CHOCH

   // متغیرهای کمکی برای حالت اصلاح - برای پیگیری موج محرک و اصلاح
   bool              m_waitingForRetracement; // آیا در حالت انتظار برای اصلاح هستیم
   bool              m_isUpwardBreak;       // آیا شکست به سمت بالا (صعودی) بوده است
   double            m_fixedPoint;          // نقطه ثابت برای محاسبه اصلاح (لو در صعودی یا های در نزولی)
   double            m_movingPoint;         // نقطه متحرک (اوج یا کف موج محرک در حال تشکیل)
   datetime          m_retracementStartTime;// زمان شروع حالت اصلاح

   // متغیر برای روند فعلی - 1: صعودی, -1: نزولی, 0: نامشخص
   int               m_currentTrend;

   // نام اشیاء گرافیکی برای مدیریت - پیشوند برای جلوگیری از تداخل با دیگر اندیکاتورها
   string            m_objPrefix;           // پیشوند منحصر به فرد برای نام اشیاء گرافیکی

   // تابع خصوصی برای محاسبه سطوح اولیه - در ابتدای اجرا
   void              CalculateInitialLevels();

   // تابع خصوصی برای چک شکست - تشخیص BOS یا CHOCH بر اساس کلوز کندل
   bool              CheckBreak(double closePrice);

   // تابع خصوصی برای آپدیت نقطه مقابل بعد شکست - بدون اضافه به آرایه، فقط آپدیت سطوح فعلی
   void              UpdateOppositePoint(datetime fromTime, datetime toTime, bool isUpward);

   // تابع خصوصی برای چک و ثبت اصلاح - تایید سطح جدید اگر اصلاح کافی باشد
   bool              CheckRetracement(double currentPrice);

   // تابع خصوصی برای تعیین روند - بر اساس دو سطح آخر سقف و کف
   void              DetermineTrend();

   // توابع گرافیکی خصوصی - برای رسم روی چارت
   void              DrawSwing(string name, double price, datetime time, color clr, string label); // رسم علامت SH/SL
   void              DrawDottedLine(string name, datetime fromTime, double fromPrice, datetime toTime, double toPrice, string label); // رسم خط نقطه‌چین BOS/CHOCH
   void              DrawTrendText();       // رسم متن روند در گوشه چارت
   void              RemoveOldObjects();    // حذف اشیاء قدیمی اگر بیش از حداکثر باشد

public:
   // سازنده کلاس - تنظیم ورودی‌ها و اولیه‌سازی متغیرها
                     StructureAnalyzer(int lookback=100, double retrace=25.0, ENUM_TIMEFRAMES tf=PERIOD_CURRENT, string sym=_Symbol, int maxStruct=30, bool graphics=true);

   // دestructor - پاک کردن تمام اشیاء گرافیکی
                    ~StructureAnalyzer();

   // تابع اولیه‌سازی - فراخوانی در OnInit
   void              Init();

   // تابع آپدیت اصلی - فراخوانی در OnTick برای چک هر کندل جدید
   void              Update();

   // getterها برای دسترسی خارجی - برای سیستم‌های دیگر
   Swing             GetLastHigh() { return m_lastHigh; } // بازگشت آخرین سقف
   Swing             GetLastLow() { return m_lastLow; }   // بازگشت آخرین کف
   Swing             GetPreviousHigh() { return m_previousHigh; } // بازگشت سقف قبلی
   Swing             GetPreviousLow() { return m_previousLow; }   // بازگشت کف قبلی
   bool              IsBOS() { return m_isBOS; }          // آیا BOS رخ داده
   bool              IsCHOCH() { return m_isCHOCH; }      // آیا CHOCH رخ داده
   int               GetCurrentTrend() { return m_currentTrend; } // بازگشت روند فعلی (1 صعودی, -1 نزولی, 0 نامشخص)
   Swing             GetHighs(int index) { if(index < ArraySize(m_highs)) return m_highs[index]; Swing empty; return empty; } // بازگشت سقف از آرایه
   Swing             GetLows(int index) { if(index < ArraySize(m_lows)) return m_lows[index]; Swing empty; return empty; } // بازگشت کف از آرایه
  };

//+------------------------------------------------------------------+
//| سازنده کلاس: تنظیم ورودی‌ها و پیشوند اشیاء - اولیه‌سازی متغیرها |
//+------------------------------------------------------------------+
StructureAnalyzer::StructureAnalyzer(int lookback=100, double retrace=25.0, ENUM_TIMEFRAMES tf=PERIOD_CURRENT, string sym=_Symbol, int maxStruct=30, bool graphics=true)
  {
   m_lookbackCandles = lookback;         // تنظیم تعداد کندل‌های گذشته برای سطوح اولیه
   m_retracementPercent = retrace;       // تنظیم درصد اصلاح
   m_timeframe = tf;                     // تنظیم تایم فریم
   m_symbol = sym;                       // تنظیم سیمبل
   m_maxStructures = maxStruct;          // تنظیم حداکثر ساختارها
   m_enableGraphics = graphics;          // تنظیم فعال بودن گرافیک

   m_objPrefix = "StructAnal_" + IntegerToString(MathRand()); // ایجاد پیشوند منحصر به فرد برای اشیاء گرافیکی

   m_isBOS = false;                      // اولیه‌سازی فلگ BOS به false
   m_isCHOCH = false;                    // اولیه‌سازی فلگ CHOCH به false
   m_waitingForRetracement = false;      // اولیه‌سازی حالت انتظار اصلاح به false
   m_currentTrend = 0;                   // روند اولیه را نامشخص تنظیم کن

   ArrayResize(m_highs, 0);              // اولیه‌سازی آرایه سقف‌ها به اندازه 0
   ArrayResize(m_lows, 0);               // اولیه‌سازی آرایه کف‌ها به اندازه 0
  }

//+------------------------------------------------------------------+
//| دestructor: پاک کردن تمام اشیاء گرافیکی برای جلوگیری از نشت حافظه |
//+------------------------------------------------------------------+
StructureAnalyzer::~StructureAnalyzer()
  {
   //循环 بر روی تمام اشیاء و پاک کردن آن‌هایی که با پیشوند شروع می‌شوند
   for(int i=ObjectsTotal()-1; i>=0; i--)
     {
      string name = ObjectName(i);       // گرفتن نام شیء
      if(StringFind(name, m_objPrefix) == 0) ObjectDelete(name); // اگر با پیشوند مطابقت داشت، پاک کن
     }
  }

//+------------------------------------------------------------------+
//| تابع اولیه‌سازی: محاسبه سطوح اولیه و تنظیم روند اولیه       |
//+------------------------------------------------------------------+
void StructureAnalyzer::Init()
  {
   CalculateInitialLevels();             // فراخوانی محاسبه سطوح اولیه
   DetermineTrend();                     // تعیین روند اولیه بر اساس سطوح
   if(m_enableGraphics)                  // اگر گرافیک فعال باشد
     {
      DrawSwing(m_objPrefix + "InitHigh", m_lastHigh.price, m_lastHigh.time, clrGreen, "SH"); // رسم سقف اولیه با SH
      DrawSwing(m_objPrefix + "InitLow", m_lastLow.price, m_lastLow.time, clrRed, "SL");     // رسم کف اولیه با SL
      DrawTrendText();                    // رسم متن روند اولیه
     }
  }

//+------------------------------------------------------------------+
//| محاسبه سطوح اولیه از N کندل گذشته - با استفاده از iHighest و iLowest |
//+------------------------------------------------------------------+
void StructureAnalyzer::CalculateInitialLevels()
  {
   int highest = iHighest(m_symbol, m_timeframe, MODE_HIGH, m_lookbackCandles, 1); // پیدا کردن اندیس بالاترین قیمت در N کندل گذشته
   int lowest = iLowest(m_symbol, m_timeframe, MODE_LOW, m_lookbackCandles, 1);    // پیدا کردن اندیس پایین‌ترین قیمت در N کندل گذشته

   m_lastHigh.price = iHigh(m_symbol, m_timeframe, highest); // تنظیم قیمت سقف اولیه
   m_lastHigh.time = iTime(m_symbol, m_timeframe, highest);  // تنظیم زمان سقف اولیه
   m_lastLow.price = iLow(m_symbol, m_timeframe, lowest);    // تنظیم قیمت کف اولیه
   m_lastLow.time = iTime(m_symbol, m_timeframe, lowest);    // تنظیم زمان کف اولیه

   // اضافه کردن سطوح اولیه به آرایه‌های تاریخچه
   ArrayResize(m_highs, 1);              // تغییر اندازه آرایه سقف‌ها به 1
   m_highs[0] = m_lastHigh;              // ذخیره سقف اولیه در آرایه
   ArrayResize(m_lows, 1);               // تغییر اندازه آرایه کف‌ها به 1
   m_lows[0] = m_lastLow;                // ذخیره کف اولیه در آرایه

   // سطوح قبلی را خالی نگه دار برای روند اولیه (نامشخص)
   m_previousHigh.price = 0;             // سقف قبلی را 0 تنظیم کن
   m_previousLow.price = 0;              // کف قبلی را 0 تنظیم کن
  }

//+------------------------------------------------------------------+
//| تابع آپدیت اصلی: چک هر کندل جدید و اجرای منطق تحلیل         |
//+------------------------------------------------------------------+
void StructureAnalyzer::Update()
  {
   // چک اگر کندل جدید بسته شده - برای جلوگیری از اجرای چندباره در یک کندل
   static datetime lastTime = 0;         // زمان آخرین آپدیت ذخیره‌شده
   datetime currentTime = iTime(m_symbol, m_timeframe, 0); // زمان کندل فعلی (باز)
   if(currentTime == lastTime) return;   // اگر کندل جدید بسته نشده، خارج شو
   lastTime = currentTime;               // آپدیت زمان آخرین کندل بسته‌شده

   // گرفتن قیمت‌های کندل بسته‌شده (شیفت 1)
   double closePrice = iClose(m_symbol, m_timeframe, 1); // کلوز کندل بسته‌شده برای تصمیم‌گیری اصلی
   double highPrice = iHigh(m_symbol, m_timeframe, 1);   // های کندل بسته‌شده برای آپدیت اوج موج
   double lowPrice = iLow(m_symbol, m_timeframe, 1);     // لو کندل بسته‌شده برای آپدیت کف موج

   // گام 1: چک شکست (BOS یا CHOCH) بر اساس کلوز کندل
   if(CheckBreak(closePrice))            // اگر شکست رخ داده باشد
     {
      // تعیین زمان بازه برای آپدیت نقطه مقابل
      datetime fromTime = m_isUpwardBreak ? m_lastHigh.time : m_lastLow.time; // زمان سطح شکسته‌شده
      datetime toTime = iTime(m_symbol, m_timeframe, 1); // زمان کندل بسته‌شده فعلی

      // آپدیت نقطه مقابل بدون اضافه به آرایه (فقط آپدیت سطوح فعلی)
      UpdateOppositePoint(fromTime, toTime, m_isUpwardBreak);

      // تنظیم حالت انتظار برای اصلاح بعد از شکست
      m_waitingForRetracement = true;    // فعال کردن حالت انتظار اصلاح
      m_fixedPoint = m_isUpwardBreak ? m_lastLow.price : m_lastHigh.price; // تنظیم نقطه ثابت (لو در صعودی، های در نزولی)
      m_movingPoint = m_isUpwardBreak ? highPrice : lowPrice; // تنظیم نقطه متحرک اولیه با های/لو کندل
      m_retracementStartTime = toTime;   // ذخیره زمان شروع اصلاح

      if(m_enableGraphics)               // اگر گرافیک فعال باشد
        {
         string label = m_isBOS ? "BOS" : "CHOCH"; // انتخاب لیبل بر اساس نوع شکست
         DrawDottedLine(m_objPrefix + "Break_" + TimeToString(toTime), fromTime, m_isUpwardBreak ? m_lastHigh.price : m_lastLow.price, toTime, closePrice, label); // رسم خط نقطه‌چین با متن
        }
     }

   // گام 2: اگر در حالت انتظار اصلاح باشیم، چک آپدیت نقطه متحرک و اصلاح
   if(m_waitingForRetracement)
     {
      // آپدیت نقطه متحرک با های یا لو واقعی کندل بسته‌شده (اصلاح گلوگاه 1)
      if(m_isUpwardBreak && highPrice > m_movingPoint) m_movingPoint = highPrice; // برای صعودی، از های استفاده کن
      else if(!m_isUpwardBreak && lowPrice < m_movingPoint) m_movingPoint = lowPrice; // برای نزولی، از لو استفاده کن

      // چک اگر اصلاح کافی رخ داده (با کلوز کندل برای تصمیم‌گیری نهایی)
      if(CheckRetracement(closePrice))
        {
         // ثبت سطح جدید بعد از تایید اصلاح
         if(m_isUpwardBreak)             // اگر شکست صعودی بوده
           {
            m_previousHigh = m_lastHigh; // آپدیت سقف قبلی با آخرین سقف
            m_lastHigh.price = m_movingPoint; // ثبت سقف جدید با نقطه متحرک
            m_lastHigh.time = iTime(m_symbol, m_timeframe, 1); // زمان کندل فعلی
            ArrayResize(m_highs, ArraySize(m_highs) + 1); // افزایش اندازه آرایه سقف‌ها
            m_highs[ArraySize(m_highs)-1] = m_lastHigh;   // اضافه سقف جدید به آرایه
            if(m_enableGraphics) DrawSwing(m_objPrefix + "High_" + TimeToString(m_lastHigh.time), m_lastHigh.price, m_lastHigh.time, clrGreen, "SH"); // رسم SH
           }
         else                            // اگر شکست نزولی بوده
           {
            m_previousLow = m_lastLow;   // آپدیت کف قبلی با آخرین کف
            m_lastLow.price = m_movingPoint; // ثبت کف جدید با نقطه متحرک
            m_lastLow.time = iTime(m_symbol, m_timeframe, 1); // زمان کندل فعلی
            ArrayResize(m_lows, ArraySize(m_lows) + 1); // افزایش اندازه آرایه کف‌ها
            m_lows[ArraySize(m_lows)-1] = m_lastLow;    // اضافه کف جدید به آرایه
            if(m_enableGraphics) DrawSwing(m_objPrefix + "Low_" + TimeToString(m_lastLow.time), m_lastLow.price, m_lastLow.time, clrRed, "SL"); // رسم SL
           }

         m_waitingForRetracement = false; // پایان حالت انتظار اصلاح
         DetermineTrend();                // تعیین روند جدید بعد از ثبت سطح
         if(m_enableGraphics)             // اگر گرافیک فعال باشد
           {
            DrawTrendText();               // آپدیت متن روند
            RemoveOldObjects();            // حذف ساختارهای قدیمی اگر بیش از حداکثر باشد
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| چک شکست: BOS یا CHOCH بر اساس کلوز کندل و روند فعلی           |
//+------------------------------------------------------------------+
bool StructureAnalyzer::CheckBreak(double closePrice)
  {
   m_isBOS = false;                      // ریست فلگ BOS
   m_isCHOCH = false;                    // ریست فلگ CHOCH

   if(closePrice > m_lastHigh.price)     // اگر کلوز بالاتر از آخرین سقف باشد (شکست سقف)
     {
      m_isUpwardBreak = true;            // تنظیم جهت شکست به صعودی
      if(m_currentTrend == -1) m_isCHOCH = true; // اگر روند قبلی نزولی بوده، این CHOCH است
      else m_isBOS = true;               // در غیر این صورت، BOS است
      m_lastBOSTime = m_isBOS ? iTime(m_symbol, m_timeframe, 1) : 0; // ذخیره زمان BOS اگر باشد
      m_lastCHOCHTime = m_isCHOCH ? iTime(m_symbol, m_timeframe, 1) : 0; // ذخیره زمان CHOCH اگر باشد
      return true;                       // بازگشت true برای نشان دادن رخ دادن شکست
     }
   else if(closePrice < m_lastLow.price) // اگر کلوز پایین‌تر از آخرین کف باشد (شکست کف)
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
//| آپدیت نقطه مقابل بعد شکست - فقط آپدیت سطوح فعلی، بدون اضافه به آرایه (اصلاح گلوگاه 2) |
//+------------------------------------------------------------------+
void StructureAnalyzer::UpdateOppositePoint(datetime fromTime, datetime toTime, bool isUpward)
  {
   int fromShift = iBarShift(m_symbol, m_timeframe, fromTime); // تبدیل زمان شروع به شیفت کندل
   int toShift = iBarShift(m_symbol, m_timeframe, toTime);     // تبدیل زمان پایان به شیفت کندل
   int barCount = fromShift - toShift + 1;                     // محاسبه تعداد کندل‌ها در بازه

   if(isUpward)                          // اگر شکست صعودی باشد، آپدیت کف (لو) به عنوان نقطه مقابل
     {
      int lowest = iLowest(m_symbol, m_timeframe, MODE_LOW, barCount, toShift); // پیدا کردن پایین‌ترین لو در بازه
      m_lastLow.price = iLow(m_symbol, m_timeframe, lowest); // آپدیت قیمت کف
      m_lastLow.time = iTime(m_symbol, m_timeframe, lowest); // آپدیت زمان کف
      // بدون اضافه به آرایه در این مرحله - فقط آپدیت سطوح فعلی
     }
   else                                  // اگر شکست نزولی باشد، آپدیت سقف (های) به عنوان نقطه مقابل
     {
      int highest = iHighest(m_symbol, m_timeframe, MODE_HIGH, barCount, toShift); // پیدا کردن بالاترین های در بازه
      m_lastHigh.price = iHigh(m_symbol, m_timeframe, highest); // آپدیت قیمت سقف
      m_lastHigh.time = iTime(m_symbol, m_timeframe, highest);  // آپدیت زمان سقف
      // بدون اضافه به آرایه در این مرحله - فقط آپدیت سطوح فعلی
     }
  }

//+------------------------------------------------------------------+
//| چک اصلاح و ثبت سطح جدید - محاسبه درصد اصلاح بر اساس فاصله    |
//+------------------------------------------------------------------+
bool StructureAnalyzer::CheckRetracement(double currentPrice)
  {
   double distance = MathAbs(m_movingPoint - m_fixedPoint); // محاسبه فاصله کل موج محرک
   double retrace;                      // اندازه اصلاح
   if(m_isUpwardBreak)                  // برای صعودی، اصلاح به سمت پایین
      retrace = m_movingPoint - currentPrice;
   else                                 // برای نزولی، اصلاح به سمت بالا
      retrace = currentPrice - m_movingPoint;

   if(retrace / distance >= m_retracementPercent / 100.0) // اگر درصد اصلاح کافی باشد
     {
      return true;                       // بازگشت true برای تایید اصلاح
     }
   return false;                         // اگر نه، false برگردان
  }

//+------------------------------------------------------------------+
//| تعیین روند بر اساس دو سطح آخر - همیشه با دو سقف و کف آخر     |
//+------------------------------------------------------------------+
void StructureAnalyzer::DetermineTrend()
  {
   if(m_lastHigh.price > m_previousHigh.price && m_lastLow.price > m_previousLow.price)
      m_currentTrend = 1;                // تنظیم به صعودی اگر هر دو سطح بالاتر باشند
   else if(m_lastHigh.price < m_previousHigh.price && m_lastLow.price < m_previousLow.price)
      m_currentTrend = -1;               // تنظیم به نزولی اگر هر دو سطح پایین‌تر باشند
   else
      m_currentTrend = 0;                // در غیر این صورت، نامشخص
  }

//+------------------------------------------------------------------+
//| رسم علامت نوسان (SH/SL) با متن - برای سطوح تایید شده         |
//+------------------------------------------------------------------+
void StructureAnalyzer::DrawSwing(string name, double price, datetime time, color clr, string label)
  {
   ObjectCreate(0, name, OBJ_TEXT, 0, time, price); // ایجاد شیء متن روی چارت
   ObjectSetString(0, name, OBJPROP_TEXT, label);    // تنظیم متن (SH یا SL)
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);   // تنظیم رنگ (سبز برای سقف، قرمز برای کف)
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 12); // تنظیم اندازه فونت
  }

//+------------------------------------------------------------------+
//| رسم خط نقطه‌چین با متن در وسط (برای BOS/CHOCH) - کوتاه و مورب |
//+------------------------------------------------------------------+
void StructureAnalyzer::DrawDottedLine(string name, datetime fromTime, double fromPrice, datetime toTime, double toPrice, string label)
  {
   // رسم خط نقطه‌چین (مورب اگر لازم، اما کوتاه بین دو نقطه)
   string lineName = name + "_Line";     // نام شیء خط
   ObjectCreate(0, lineName, OBJ_TREND, 0, fromTime, fromPrice, toTime, toPrice); // ایجاد خط روند بین دو نقطه
   ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT); // تنظیم سبک به نقطه‌چین
   ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrBlue);   // تنظیم رنگ آبی
   ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);         // تنظیم عرض 1
   ObjectSetInteger(0, lineName, OBJPROP_RAY, false);       // غیرفعال کردن ادامه خط (کوتاه بماند)

   // محاسبه نقطه وسط برای متن
   datetime midTime = fromTime + (toTime - fromTime) / 2;   // زمان وسط خط
   double midPrice = fromPrice + (toPrice - fromPrice) / 2; // قیمت وسط خط

   // رسم متن در وسط خط
   string textName = name + "_Text";     // نام شیء متن
   ObjectCreate(0, textName, OBJ_TEXT, 0, midTime, midPrice); // ایجاد متن
   ObjectSetString(0, textName, OBJPROP_TEXT, "......." + label + "......."); // تنظیم متن با نقطه‌چین اطراف
   ObjectSetInteger(0, textName, OBJPROP_COLOR, clrBlack); // تنظیم رنگ سیاه
   ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 10);    // تنظیم اندازه فونت 10
  }

//+------------------------------------------------------------------+
//| رسم متن روند در گوشه بالا راست چارت - با رنگ مناسب          |
//+------------------------------------------------------------------+
void StructureAnalyzer::DrawTrendText()
  {
   string name = m_objPrefix + "TrendText"; // نام شیء متن روند
   ObjectDelete(name);                   // پاک کردن متن قبلی اگر وجود داشته باشد

   string text;                          // متن روند
   color clr;                            // رنگ متن
   if(m_currentTrend == 1)               // اگر روند صعودی
     {
      text = "ترند صعودی";             // متن "ترند صعودی"
      clr = clrGreen;                   // رنگ سبز
     }
   else if(m_currentTrend == -1)         // اگر روند نزولی
     {
      text = "ترند نزولی";             // متن "ترند نزولی"
      clr = clrRed;                     // رنگ قرمز
     }
   else                                  // اگر نامشخص
     {
      text = "ترند نامشخص";            // متن "ترند نامشخص"
      clr = clrGray;                    // رنگ خاکستری
     }

   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0); // ایجاد شیء لیبل
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER); // تنظیم مکان به گوشه بالا راست
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10); // فاصله افقی 10 پیکسل
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 10); // فاصله عمودی 10 پیکسل
   ObjectSetString(0, name, OBJPROP_TEXT, text);     // تنظیم متن
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);   // تنظیم رنگ
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14); // تنظیم اندازه فونت 14
  }

//+------------------------------------------------------------------+
//| حذف اشیاء قدیمی اگر بیش از حداکثر - برای جلوگیری از شلوغی چارت |
//+------------------------------------------------------------------+
void StructureAnalyzer::RemoveOldObjects()
  {
   // چک و حذف از آرایه سقف‌ها اگر بیش از حداکثر باشد
   while(ArraySize(m_highs) > m_maxStructures)
     {
      string oldName = m_objPrefix + "High_" + TimeToString(m_highs[0].time); // نام شیء قدیمی سقف
      ObjectDelete(oldName);             // پاک کردن شیء قدیمی
      ArrayCopy(m_highs, m_highs, 0, 1); // شیفت آرایه به سمت چپ (حذف اولین عنصر)
      ArrayResize(m_highs, ArraySize(m_highs) - 1); // کاهش اندازه آرایه
     }

   // چک و حذف از آرایه کف‌ها اگر بیش از حداکثر باشد
   while(ArraySize(m_lows) > m_maxStructures)
     {
      string oldName = m_objPrefix + "Low_" + TimeToString(m_lows[0].time); // نام شیء قدیمی کف
      ObjectDelete(oldName);             // پاک کردن شیء قدیمی
      ArrayCopy(m_lows, m_lows, 0, 1);   // شیفت آرایه به سمت چپ
      ArrayResize(m_lows, ArraySize(m_lows) - 1); // کاهش اندازه آرایه
     }
  }
