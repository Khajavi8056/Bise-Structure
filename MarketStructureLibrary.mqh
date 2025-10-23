//+------------------------------------------------------------------+
//|                                MarketStructureLibrary.mqh         |
//|                              Copyright 2025, Khajavi - HipoAlgoritm|
//|                                                                  |
//| راهنمای اجرا و استفاده (Blueprint for Memento Project):          |
//| این کتابخانه شامل چهار کلاس مستقل 'MarketStructure'، 'FVGManager'،|
//| 'MinorStructure' و 'CLiquidityManager' است که قابلیت اجرای چندگانه (Multi-Timeframe/Multi-Symbol) را فراهم می کنند.|
//|                                                                  |
//| ۱. ایجاد آبجکت: در تابع OnInit() اکسپرت، نمونه‌هایی از این کلاس‌ها را ایجاد کنید. برای هر تایم فریم/نماد مورد نیاز، یک آبجکت جدید بسازید.|
//|    مثال: MarketStructure *H1_Struct = new MarketStructure(...);  |
//|          MinorStructure *H1_Minor = new MinorStructure(...);     |
//|          CLiquidityManager *H1_Liq = new CLiquidityManager(H1_Struct, H1_Minor, ...); // تزریق وابستگی به کلاس‌های MarketStructure و MinorStructure الزامی است.|
//|                                                                  |
//| ۲. پردازش داده: در OnTick() یا OnTimer() اکسپرت:                  |
//|    - متد ProcessNewTick() را برای مدیریت FVG (ابطال لحظه‌ای) و OB (میتگیشن لحظه‌ای) و نقدینگی (ProcessNewTick() کلاس CLiquidityManager) فراخوانی کنید.|
//|    - متد ProcessNewBar() را فقط در هنگام کلوز کندل جدید تایم فریم مربوطه فراخوانی کنید (برای شناسایی ساختار، FVG جدید، مینور، EQ و نقدینگی).|
//|                                                                  |
//| ۳. دسترسی به داده: از توابع Get... مانند GetLastSwingHigh()، GetFVGCount()، GetMajorEQPattern()، GetLiquidityEvent() و ... برای استخراج داده‌های لازم برای ترید استفاده کنید.|
//|                                                                  |
//| ۴. مدیریت نمایش: با پارامتر 'showDrawing' در سازنده، می توانید نمایش ترسیمات کلاس را روی چارت خاموش یا روشن کنید. برای CLiquidityManager، ورودی‌های جداگانه برای هر نوع نقدینگی (drawEQ, drawTraps و ...) وجود دارد.|
//|                                                                  |
//| نکته: کلاس CLiquidityManager وابسته به MarketStructure و MinorStructure است و باید پس از ایجاد آن‌ها ساخته شود. پوینترها را به سازنده آن پاس دهید.|
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi - HipoAlgoritm"
#property link      "https://github.com/Khajavi8056/"
#property version   "3.00" // نسخه با اضافه کردن قابلیت نقدینگی یکپارچه و EQ ماژور

//+------------------------------------------------------------------+
//| تعاریف سراسری برای عناصر گرافیکی (برای خوانایی و زیبایی بصری)   |
//+------------------------------------------------------------------+
const int BASE_LABEL_FONT_SIZE = 7; // سایز فونت پایه برای اکثر لیبل‌ها
const int SMALL_LABEL_FONT_SIZE = 6; // سایز فونت کوچکتر برای خطوط کوتاه
const double VERTICAL_OFFSET_TICKS = 10.0; // ضریب آفست عمودی بر اساس اندازه تیک
const double OVERLAP_TIME_THRESHOLD_BARS = 1.5; // آستانه زمانی برای تشخیص همپوشانی (به تعداد کندل)
const double OVERLAP_PRICE_THRESHOLD_TICKS = 15.0; // آستانه قیمتی برای تشخیص همپوشانی (به تعداد تیک)
const int DYNAMIC_SIZE_CANDLE_THRESHOLD = 3; // تعداد کندل آستانه برای استفاده از فونت کوچکتر

//--- تابع کمکی: گرفتن پسوند نمایش شرطی (فقط اگر تایم‌فریم کتابخانه با چارت متفاوت باشد)
string GetDisplaySuffix(ENUM_TIMEFRAMES libTF, long chartID)
{
   ENUM_TIMEFRAMES chartTF = (ENUM_TIMEFRAMES)ChartPeriod(chartID);
   if (libTF != chartTF)
   {
      return " (" + TimeFrameToStringShort(libTF) + ")";
   }
   return "";
}

//--- تابع کمکی: بررسی همپوشانی موقعیت برای جلوگیری از تداخل لیبل‌ها
bool IsPositionOccupied(long chartID, datetime time, double price, ENUM_TIMEFRAMES libTF)
{
   double timeThresholdSeconds = OVERLAP_TIME_THRESHOLD_BARS * PeriodSeconds(libTF);
   double priceThreshold = OVERLAP_PRICE_THRESHOLD_TICKS * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   int total = ObjectsTotal(chartID, 0, OBJ_TEXT);
   for (int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(chartID, i);
      if (StringFind(name, TimeFrameToStringShort(libTF)) == -1) continue; // فقط آبجکت‌های این کتابخانه

      datetime existingTime = (datetime)ObjectGetInteger(chartID, name, OBJPROP_TIME, 0);
      double existingPrice = ObjectGetDouble(chartID, name, OBJPROP_PRICE, 0);

      bool timeOverlap = (MathAbs((double)(time - existingTime)) <= timeThresholdSeconds);
      bool priceOverlap = (MathAbs(price - existingPrice) <= priceThreshold);

      if (timeOverlap && priceOverlap) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| ساختارهای داده و شمارنده‌ها (Structs & Enums)                     |
//+------------------------------------------------------------------+

//--- ساختار داده برای نگهداری اطلاعات یک نقطه محوری سقف یا کف (Swing Point)
struct SwingPoint
{
   double   price;      // قیمت دقیق سقف/کف (بالاترین/پایین‌ترین نقطه شدو)
   double   body_price; // قیمت بدنه در نقطه سقف/کف (بالاترین/پایین‌ترین قیمت Open/Close در کندل فرکتال)
   datetime time;       // زمان کندلی که نقطه محوری در آن تشکیل شده
   int      bar_index;  // اندیس (شماره) کندل از دید متاتریدر
};

//--- ساختار داده برای نگهداری اطلاعات یک ناحیه شکاف ارزش منصفانه (Fair Value Gap - FVG)
struct FVG
{
   bool     isBullish;  // نوع FVG: صعودی (true) یا نزولی (false)
   double   highPrice;  // بالاترین قیمت ناحیه FVG (خط سقف)
   double   lowPrice;   // پایین‌ترین قیمت ناحیه FVG (خط کف)
   datetime time;       // زمان کندل میانی FVG (کندل 2) - برای شناسایی FVG
   bool     consumed;   // وضعیت مصرف شدگی (فیلد رزرو - در حال حاضر استفاده نمی‌شود)
};

//--- شمارنده (Enum) برای نگهداری وضعیت فعلی روند بازار
enum TREND_TYPE
{
   TREND_BULLISH,      // روند صعودی (Higher Highs / Higher Lows)
   TREND_BEARISH,      // روند نزولی (Lower Lows / Lower Highs)
   TREND_NONE          // بدون روند مشخص یا در حالت رنج
};

//--- ساختار داده برای نگهداری اطلاعات الگوی EQ (تست زون)
struct EQPattern
{
   bool     isBullish;      // نوع الگو: صعودی (true) برای تست کف (Double Bottom) یا نزولی (false) برای تست سقف (Double Top)
   datetime time_formation; // زمان کندل تایید (کندل قرمز/سبز) که الگو را نهایی کرده است
   double   price_entry;    // قیمت Low/High کندلی که وارد زون شده است (نقطه انتهایی خط چین)
   SwingPoint source_swing; // کپی کامل از SwingPoint اصلی که این الگو بر اساس آن شکل گرفته
};

//--- ساختار داده برای نگهداری اطلاعات الگوی EQ ماژور
struct MajorEQPattern
{
   bool     isBullish;      // نوع الگو: صعودی (true) یا نزولی (false)
   datetime time_formation; // زمان کندل تایید
   double   price_entry;    // قیمت Low/High کندل ورود به زون
   SwingPoint source_swing; // سوئینگ ماژور مبدا
};

//--- شمارنده برای انواع رویدادهای نقدینگی
enum ENUM_LIQUIDITY_TYPE
{
   LIQ_EQH,    // Equal High (تست سقف)
   LIQ_EQL,    // Equal Low (تست کف)
   LIQ_SMS,    // Swing Market Structure (تله ساختاری)
   LIQ_CF,     // Confirmation Flip (تله تایید شده)
   LIQ_PDH,    // Previous Day High
   LIQ_PDL,    // Previous Day Low
   LIQ_PWH,    // Previous Week High
   LIQ_PWL,    // Previous Week Low
   LIQ_PMH,    // Previous Month High
   LIQ_PML,    // Previous Month Low
   LIQ_PYH,    // Previous Year High
   LIQ_PYL     // Previous Year Low
};

//--- ساختار داده برای نگهداری تاریخچه رویدادهای نقدینگی
struct LiquidityEvent
{
   ENUM_LIQUIDITY_TYPE type;        // نوع نقدینگی
   bool                isBullish;   // جهت الگو (صعودی/نزولی)
   datetime            time;        // زمان رویداد
   double              price;       // قیمت مرتبط
   string              description; // توضیح کوتاه
   SwingPoint          source_swing;// منبع سوئینگ (برای EQ و تله‌ها)
};

//--- ساختار داده برای Order Block (OB) - استخراج شده به عنوان سراسری برای استفاده مشترک
struct OrderBlock
{
   bool     isBullish;  // نوع OB: صعودی (تقاضا، true) یا نزولی (عرضه، false)
   double   highPrice;  // قیمت سقف ناحیه OB (بالاترین قیمت کندل)
   double   lowPrice;   // قیمت کف ناحیه OB (پایین‌ترین قیمت کندل)
   datetime time;       // زمان کندل OB
   int      bar_index;  // اندیس کندل OB
};

//+------------------------------------------------------------------+
//| توابع کمکی (Helper Functions)                                    |
//+------------------------------------------------------------------+

//--- تابع تبدیل تایم فریم Enum به رشته کوتاه (مثلاً PERIOD_H4 به "4H")
string TimeFrameToStringShort(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "1M";
      case PERIOD_M5:  return "5M";
      case PERIOD_M15: return "15M";
      case PERIOD_M30: return "30M";
      case PERIOD_H1:  return "1H";
      case PERIOD_H4:  return "4H";
      case PERIOD_D1:  return "1D";
      case PERIOD_W1:  return "1W";
      case PERIOD_MN1: return "1M";
      default: return EnumToString(tf);
   }
}

//--- تابع کمکی برای لاگ‌گیری (با رفع خطای تبدیل نوع)
void LogEvent(const string message, const bool enabled, const string prefix = "")
{
   if(enabled)
   {
      Print(prefix, message);
   }
}

//==================================================================//
//                   کلاس ۲: مدیریت FVG (FVGManager)                  //
//==================================================================//
class FVGManager
{
private:
   //--- متغیرهای تنظیمات و محیط اجرا
   string           m_symbol;               // نماد جفت ارز
   ENUM_TIMEFRAMES  m_timeframe;            // تایم فریم اختصاصی این آبجکت
   long             m_chartId;              // ID چارت اجرایی اکسپرت
   bool             m_enableLogging;        // فعال/غیرفعال بودن لاگ (ورودی کپی شده از سازنده)
   string           m_timeframeSuffix;      // پسوند تایم‌فریم کوتاه شده (مثلاً "(4H)") برای نامگذاری اشیاء
   bool             m_showDrawing;          // کنترل نمایش ترسیمات FVG روی چارت

   //--- متغیرهای حالت
   FVG              m_fvgArray[];           // آرایه داینامیک برای نگهداری نواحی FVG شناسایی شده (سری)
   datetime         m_lastFVGCheckTime;     // برای جلوگیری از اجرای تکراری شناسایی FVG روی یک کندل

public:
   //+------------------------------------------------------------------+
   //| سازنده کلاس (Constructor)                                       |
   //+------------------------------------------------------------------+
   FVGManager(const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId, const bool enableLogging_in, const bool showDrawing)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      // اصلاح هشدار 'hiding global variable' با استفاده از نام ورودی متفاوت
      m_enableLogging = enableLogging_in;
      m_showDrawing = showDrawing;
      
      // تنظیم پسوند تایم فریم برای نمایش MTF (کوتاه شده)
      m_timeframeSuffix = " (" + TimeFrameToStringShort(timeframe) + ")";

      ArraySetAsSeries(m_fvgArray, true);
      ArrayResize(m_fvgArray, 0);
      m_lastFVGCheckTime = 0;
      
      // پاکسازی اشیاء قبلی مربوط به این تایم فریم روی چارت
      if (m_showDrawing)
      {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for(int i = total - 1; i >= 0; i--)
         {
            string name = ObjectName(m_chartId, i);
            if(StringFind(name, m_timeframeSuffix) != -1)
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }
      
      LogEvent("کلاس FVGManager برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.", m_enableLogging, "[FVG]");
   }

   //+------------------------------------------------------------------+
   //| مخرب کلاس (Destructor) - برای پاک کردن اشیاء هنگام حذف آبجکت     |
   //+------------------------------------------------------------------+
   ~FVGManager()
   {
      // پاک کردن اشیاء هنگام از بین رفتن آبجکت
      if (m_showDrawing)
      {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for(int i = total - 1; i >= 0; i--)
         {
            string name = ObjectName(m_chartId, i);
            if(StringFind(name, m_timeframeSuffix) != -1)
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }
      LogEvent("کلاس FVGManager متوقف شد.", m_enableLogging, "[FVG]");
   }
   
   //+------------------------------------------------------------------+
   //| توابع پردازش (Processing Methods)                                |
   //+------------------------------------------------------------------+
   
   //--- ۱. بررسی ابطال FVG در لحظه (با قیمت‌های ASK/BID) - هر تیک اجرا می‌شود
   bool ProcessNewTick()
   {
      double currentAsk = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double currentBid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      bool invalidatedNow = false;

      // حلقه از جدیدترین (0) تا قدیمی‌ترین (ArraySize-1) می‌رود
      for(int i = 0; i < ArraySize(m_fvgArray); i++)
      {
         if(m_fvgArray[i].consumed) continue;

         bool isInvalidated = false;
         string typeStr = m_fvgArray[i].isBullish ? "Bullish" : "Bearish";

         // FVG صعودی: اگر قیمت Bid به زیر خط پایین FVG برسد (باطل می‌شود)
         if(m_fvgArray[i].isBullish && currentBid < m_fvgArray[i].lowPrice) isInvalidated = true; 
         // FVG نزولی: اگر قیمت Ask به بالای خط بالای FVG برسد (باطل می‌شود)
         if(!m_fvgArray[i].isBullish && currentAsk > m_fvgArray[i].highPrice) isInvalidated = true; 

         if(isInvalidated)
         {
            if (m_showDrawing)
            {
                string objName = "FVG_" + TimeToString(m_fvgArray[i].time) + "_" + typeStr + m_timeframeSuffix;
                ObjectDelete(m_chartId, objName);
                ObjectDelete(m_chartId, objName + "_Text");
            }
            LogEvent("FVG از نوع " + typeStr + " در زمان " + TimeToString(m_fvgArray[i].time) + " ابطال و حذف شد.", m_enableLogging, "[FVG]");

            ArrayRemove(m_fvgArray, i, 1);
            i--; // چون یک عنصر حذف شد، باید اندیس را یکی کم کنیم
            invalidatedNow = true;
         }
      }
      return invalidatedNow;
   }
   
   //--- ۲. اجرای منطق FVG در کلوز کندل جدید
   bool ProcessNewBar()
   {
      bool newFVGFound = false;
      
      if (IdentifyFVG()) newFVGFound = true;
      if (m_showDrawing) UpdateFVGTexPositions(); // به‌روزرسانی موقعیت متن‌ها
      
      return newFVGFound;
   }

private:
   //--- تابع کمکی: بررسی بدنه قوی (با حفظ منطق اصلی)
   bool IsStrongBody(const int index) const
   {
      double open = iOpen(m_symbol, m_timeframe, index);
      double close = iClose(m_symbol, m_timeframe, index);
      double high = iHigh(m_symbol, m_timeframe, index);
      double low = iLow(m_symbol, m_timeframe, index);

      double body = MathAbs(open - close);
      double shadow = (high - low) - body;

      // شرط بدنه قوی: بادی باید بزرگتر از مجموع شدوها باشد
      return (body > shadow); 
   }

   //--- تابع: شناسایی FVG جدید (حفظ کامل منطق فیلترها)
   bool IdentifyFVG()
   {
      // از اجرای مجدد روی یک کندل جلوگیری شود
      if(m_lastFVGCheckTime == iTime(m_symbol, m_timeframe, 1)) return false;
      m_lastFVGCheckTime = iTime(m_symbol, m_timeframe, 1);

      if(iBars(m_symbol, m_timeframe) < 4) return false;

      int i = 2; // کندل میانی FVG (از 0 شمارش می‌شود)

      if (!IsStrongBody(i)) return false;

      double open1 = iOpen(m_symbol, m_timeframe, i-1); double close1 = iClose(m_symbol, m_timeframe, i-1);
      double open2 = iOpen(m_symbol, m_timeframe, i); double close2 = iClose(m_symbol, m_timeframe, i);
      double open3 = iOpen(m_symbol, m_timeframe, i+1); double close3 = iClose(m_symbol, m_timeframe, i+1);

      bool allBullish = (close1 > open1) && (close2 > open2) && (close3 > open3);
      bool allBearish = (close1 < open1) && (close2 < open2) && (close3 < open3);

      if (! (allBullish || allBearish)) return false; // فیلتر: هم‌جهت بودن کندل‌ها

      double high1 = iHigh(m_symbol, m_timeframe, i - 1); double low1  = iLow(m_symbol, m_timeframe, i - 1);
      double high3 = iHigh(m_symbol, m_timeframe, i + 1); double low3  = iLow(m_symbol, m_timeframe, i + 1);
      double body2 = MathAbs(open2 - close2);

      // FVG صعودی: Low1 > High3
      if (low1 > high3)
      {
          double fvgSize = low1 - high3;
          if (fvgSize < 0.5 * body2) return false; // فیلتر: اندازه FVG >= 50% بدنه کندل میانی

          // فیلتر: جلوگیری از ثبت FVG تکراری
          for(int j=0; j<ArraySize(m_fvgArray); j++) { if(m_fvgArray[j].time == iTime(m_symbol, m_timeframe, i) && m_fvgArray[j].isBullish) return false; } 

          AddFVG(true, high3, low1, iTime(m_symbol, m_timeframe, i)); // Low قیمت بالا و High قیمت پایین زون FVG است
          return true;
      }

      // FVG نزولی: High1 < Low3
      if (high1 < low3)
      {
          double fvgSize = low3 - high1;
          if (fvgSize < 0.5 * body2) return false; // فیلتر: اندازه FVG >= 50% بدنه کندل میانی

          // فیلتر: جلوگیری از ثبت FVG تکراری
          for(int j=0; j<ArraySize(m_fvgArray); j++) { if(m_fvgArray[j].time == iTime(m_symbol, m_timeframe, i) && !m_fvgArray[j].isBullish) return false; } 

          AddFVG(false, low3, high1, iTime(m_symbol, m_timeframe, i)); // Low قیمت بالا و High قیمت پایین زون FVG است
          return true;
      }

      return false;
   }
   
   //--- تابع: اضافه کردن FVG جدید و رسم آن (با مدیریت ظرفیت ۳۰ تایی)
   void AddFVG(const bool isBullish, const double lowPrice, const double highPrice, const datetime time)
   {
      // مدیریت ظرفیت: اگر از 30 عدد بیشتر شد، قدیمی‌ترین حذف شود
      if(ArraySize(m_fvgArray) >= 30)
      {
         int lastIndex = ArraySize(m_fvgArray) - 1;
         string typeStrOld = m_fvgArray[lastIndex].isBullish ? "Bullish" : "Bearish";
         if (m_showDrawing)
         {
             string objNameOld = "FVG_" + TimeToString(m_fvgArray[lastIndex].time) + "_" + typeStrOld + m_timeframeSuffix;
             ObjectDelete(m_chartId, objNameOld);
             ObjectDelete(m_chartId, objNameOld + "_Text");
         }
         ArrayRemove(m_fvgArray, lastIndex, 1);
      }

      // مقداردهی FVG جدید
      FVG newFVG;
      newFVG.isBullish = isBullish;
      newFVG.highPrice = highPrice; // قیمت سقف زون
      newFVG.lowPrice = lowPrice;   // قیمت کف زون
      newFVG.time = time;
      newFVG.consumed = false;

      // درج دستی به جای ArrayInsert
      int oldSize = ArraySize(m_fvgArray);
      ArrayResize(m_fvgArray, oldSize + 1);
      for (int j = oldSize; j > 0; j--)
      {
         m_fvgArray[j] = m_fvgArray[j - 1];
      }
      m_fvgArray[0] = newFVG;

      if (m_showDrawing) drawFVG(m_fvgArray[0]);
      string typeStr = isBullish ? "Bullish" : "Bearish";
      LogEvent("FVG جدید از نوع " + typeStr + " در زمان " + TimeToString(time) + " شناسایی شد.", m_enableLogging, "[FVG]");
   }
   
   //--- تابع: به‌روزرسانی موقعیت متن‌های FVG برای ماندن در وسط زون (دقیقاً مطابق نیاز کاربر)
   void UpdateFVGTexPositions()
   {
      // از زمان فعلی چارت اصلی استفاده می‌شود
      datetime currentTime = iTime(NULL, PERIOD_CURRENT, 0); 

      for(int i = 0; i < ArraySize(m_fvgArray); i++)
      {
         if(m_fvgArray[i].consumed) continue;

         string typeStr = m_fvgArray[i].isBullish ? "Bullish" : "Bearish";
         string textName = "FVG_" + TimeToString(m_fvgArray[i].time) + "_" + typeStr + m_timeframeSuffix + "_Text";

         // محاسبه زمان وسط بین زمان شروع FVG و زمان فعلی چارت اصلی
         datetime midTime = m_fvgArray[i].time + (currentTime - m_fvgArray[i].time) / 2;
         double midPrice = (m_fvgArray[i].highPrice + m_fvgArray[i].lowPrice) / 2;

         // جابجایی متن (رفع خطای تبدیل نوع ضمنی)
         ObjectMove(m_chartId, textName, 0, midTime, midPrice);
      }
   }

   //--- تابع ترسیمی: رسم FVG (با قابلیت MTF)
   void drawFVG(const FVG &fvg)
   {
      string typeStr = fvg.isBullish ? "Bullish" : "Bearish";
      string objName = "FVG_" + TimeToString(fvg.time) + "_" + typeStr + m_timeframeSuffix;
      string textName = objName + "_Text";

      color fvgColor = fvg.isBullish ? C'144,238,144' : C'255,160,160'; // سبز کمرنگ/قرمز کمرنگ

      datetime endTime = D'2030.01.01 00:00'; // امتداد زون

      // ایجاد مستطیل
      ObjectCreate(m_chartId, objName, OBJ_RECTANGLE, 0, fvg.time, fvg.highPrice, endTime, fvg.lowPrice);
      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, fvgColor);
      ObjectSetInteger(m_chartId, objName, OBJPROP_FILL, true);
      ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, true); // پشت کندل‌ها

      // محاسبه موقعیت اولیه وسط برای متن
      datetime currentTime = iTime(NULL, PERIOD_CURRENT, 0);
      datetime midTime = fvg.time + (currentTime - fvg.time) / 2;
      double midPrice = (fvg.highPrice + fvg.lowPrice) / 2;

      // ایجاد متن FVG با پسوند شرطی
      string suffix = GetDisplaySuffix(m_timeframe, m_chartId);
      ObjectCreate(m_chartId, textName, OBJ_TEXT, 0, midTime, midPrice);
      ObjectSetString(m_chartId, textName, OBJPROP_TEXT, "FVG" + suffix); 
      ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, clrAliceBlue);
      ObjectSetInteger(m_chartId, textName, OBJPROP_FONTSIZE, BASE_LABEL_FONT_SIZE);
      ObjectSetInteger(m_chartId, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
   }

public:
   //+------------------------------------------------------------------+
   //| توابع دسترسی عمومی (Accessors)                                  |
   //+------------------------------------------------------------------+
   // آرایه تمام FVGهای فعال را برمی‌گرداند (برای استفاده در منطق ترید)
   FVG GetFVG(const int index) const { return m_fvgArray[index]; }
   // تعداد FVGهای فعال را برمی‌گرداند
   int GetFVGCount() const { return ArraySize(m_fvgArray); }
   
   // تابع جدید: نزدیک‌ترین حمایت FVG (Bullish پایین‌تر از قیمت فعلی)
   FVG GetNearestSupportFVG() const
   {
      double currentClose = iClose(m_symbol, m_timeframe, 0);
      FVG nearest; nearest.highPrice = DBL_MAX; nearest.lowPrice = DBL_MAX; nearest.isBullish = true; // پیش‌فرض
      double minDist = DBL_MAX;
      for (int i = 0; i < ArraySize(m_fvgArray); i++)
      {
         if (m_fvgArray[i].consumed || !m_fvgArray[i].isBullish) continue;
         double mid = (m_fvgArray[i].highPrice + m_fvgArray[i].lowPrice) / 2;
         if (mid >= currentClose) continue; // فقط پایین‌تر
         double dist = currentClose - mid;
         if (dist < minDist) { minDist = dist; nearest = m_fvgArray[i]; }
      }
      return nearest;
   }
   
   // تابع جدید: نزدیک‌ترین مقاومت FVG (Bearish بالاتر از قیمت فعلی)
   FVG GetNearestResistanceFVG() const
   {
      double currentClose = iClose(m_symbol, m_timeframe, 0);
      FVG nearest; nearest.highPrice = -DBL_MAX; nearest.lowPrice = -DBL_MAX; nearest.isBullish = false; // پیش‌فرض
      double minDist = DBL_MAX;
      for (int i = 0; i < ArraySize(m_fvgArray); i++)
      {
         if (m_fvgArray[i].consumed || m_fvgArray[i].isBullish) continue;
         double mid = (m_fvgArray[i].highPrice + m_fvgArray[i].lowPrice) / 2;
         if (mid <= currentClose) continue; // فقط بالاتر
         double dist = mid - currentClose;
         if (dist < minDist) { minDist = dist; nearest = m_fvgArray[i]; }
      }
      return nearest;
   }
};

//==================================================================//
//               کلاس ۱: مدیریت ساختار بازار (MarketStructure)       //
//==================================================================//
class MarketStructure
{
private:
   //--- متغیرهای تنظیمات و محیط اجرا
   string           m_symbol;               // نماد جفت ارز
   ENUM_TIMEFRAMES  m_timeframe;            // تایم فریم اختصاصی این آبجکت
   long             m_chartId;              // ID چارت اجرایی اکسپرت
   bool             m_enableLogging;        // فعال/غیرفعال بودن لاگ
   string           m_timeframeSuffix;      // پسوند تایم‌فریم کوتاه شده
   bool             m_showDrawing;          // کنترل نمایش ترسیمات ساختار روی چارت
   int              m_fibUpdateLevel;       // سطح اصلاح فیبو (مثلاً 35)
   int              m_fractalLength;        // طول فرکتال (مثلاً 10)
   bool             m_enableOB_FVG_Check;   // فعال/غیرفعال کردن شرط FVG برای شناسایی OB (ورودی جدید سازنده)
   
   //--- متغیرهای حالت
   SwingPoint       m_swingHighs_Array[];   // آرایه سقف‌ها (سری)
   SwingPoint       m_swingLows_Array[];    // آرایه کف‌ها (سری)
   TREND_TYPE       m_currentTrend;         // وضعیت فعلی روند
   SwingPoint       m_pivotHighForTracking; // نقطه 100% فیبو (ثابت) در فاز نزولی
   SwingPoint       m_pivotLowForTracking;  // نقطه 100% فیبو (ثابت) در فاز صعودی
   bool             m_isTrackingHigh;       // فلگ: آیا در فاز "شکار سقف جدید" هستیم؟
   bool             m_isTrackingLow;        // فلگ: آیا در فاز "شکار کف جدید" هستیم؟
   datetime         m_lastCHoCHTime;        // زمان آخرین CHoCH
   datetime         m_lastBoSTime;          // زمان آخرین BoS
   string           m_trendObjectName;      // نام ثابت لیبل روند با پسوند
   
   //--- آرایه‌های ذخیره‌سازی برای Order Blocks
   OrderBlock       m_unmitigatedOBs[];     // آرایه OBهای مصرف نشده (unmitigated، سری)
   OrderBlock       m_mitigatedOBs[];       // آرایه OBهای مصرف شده (mitigated، سری)
   
   //--- متغیرهای کنترلی برای Order Blocks
   bool             m_isCurrentlyMitigatingOB; // وضعیت لحظه‌ای: آیا قیمت در حال مصرف یک OB است؟ (برای دسترسی عمومی)

   //--- متغیرهای حالت برای EQ ماژور
   MajorEQPattern   m_majorEQPatterns_Array[]; // آرایه EQهای ماژور (سری، ظرفیت ۴)
   SwingPoint       m_activeMajorHighCandidate;  // کاندیدای فعال برای EQ نزولی ماژور
   SwingPoint       m_activeMajorLowCandidate;   // کاندیدای فعال برای EQ صعودی ماژور
   datetime         m_lastMajorEQInvalidationCheck; // برای جلوگیری از تکرار ابطال
   datetime         m_lastMajorEQDetectionCheck;    // برای جلوگیری از تکرار تشخیص

public:
   //+------------------------------------------------------------------+
   //| سازنده کلاس (Constructor) - با ورودی جدید برای شرط FVG در OB   |
   //+------------------------------------------------------------------+
   MarketStructure(const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId, const bool enableLogging_in, const bool showDrawing, const int fibUpdateLevel_in, const int fractalLength_in, const bool enableOB_FVG_Check_in)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      // اصلاح هشدار 'hiding global variable'
      m_enableLogging = enableLogging_in;
      m_showDrawing = showDrawing;
      m_fibUpdateLevel = fibUpdateLevel_in;
      m_fractalLength = fractalLength_in;
      m_enableOB_FVG_Check = enableOB_FVG_Check_in; // مقداردهی ورودی جدید
      
      // تنظیم پسوند تایم فریم برای نمایش MTF (کوتاه شده)
      m_timeframeSuffix = " (" + TimeFrameToStringShort(timeframe) + ")";
      m_trendObjectName = "TrendLabel" + m_timeframeSuffix; 

      ArraySetAsSeries(m_swingHighs_Array, true);
      ArraySetAsSeries(m_swingLows_Array, true);
      ArrayResize(m_swingHighs_Array, 0);
      ArrayResize(m_swingLows_Array, 0);
      
      // مقداردهی اولیه آرایه‌های OB (سری با ظرفیت رزرو شده)
      ArraySetAsSeries(m_unmitigatedOBs, true);
      ArraySetAsSeries(m_mitigatedOBs, true);
      ArrayResize(m_unmitigatedOBs, 0, 10); // رزرو اولیه برای بهینه‌سازی
      ArrayResize(m_mitigatedOBs, 0, 10);   // رزرو اولیه برای بهینه‌سازی
      
      m_currentTrend = TREND_NONE;
      m_isTrackingHigh = false;
      m_isTrackingLow = false;
      m_lastCHoCHTime = 0;
      m_lastBoSTime = 0;
      m_isCurrentlyMitigatingOB = false; // مقداردهی اولیه وضعیت مصرف OB

      // مقداردهی اولیه ساختارهای پیوت ردیابی
      m_pivotHighForTracking.price = 0; m_pivotHighForTracking.time = 0; m_pivotHighForTracking.bar_index = -1; m_pivotHighForTracking.body_price = 0;
      m_pivotLowForTracking.price = 0; m_pivotLowForTracking.time = 0; m_pivotLowForTracking.bar_index = -1; m_pivotLowForTracking.body_price = 0;
      
      // پاکسازی اشیاء قبلی
      if (m_showDrawing)
      {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for(int i = total - 1; i >= 0; i--)
         {
            string name = ObjectName(m_chartId, i);
            if(StringFind(name, m_timeframeSuffix) != -1)
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }
      
      // شناسایی ساختار اولیه
      IdentifyInitialStructure();
      UpdateTrendLabel();
      
      // مقداردهی اولیه برای EQ ماژور
      ArraySetAsSeries(m_majorEQPatterns_Array, true);
      ArrayResize(m_majorEQPatterns_Array, 0, 4); // ظرفیت اولیه ۴
      m_activeMajorHighCandidate.bar_index = -1;
      m_activeMajorLowCandidate.bar_index = -1;
      m_lastMajorEQInvalidationCheck = 0;
      m_lastMajorEQDetectionCheck = 0;
      
      LogEvent("کلاس MarketStructure برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.", m_enableLogging, "[SMC]");
   }

   //+------------------------------------------------------------------+
   //| مخرب کلاس (Destructor)                                          |
   //+------------------------------------------------------------------+
   ~MarketStructure()
   {
      // پاک کردن اشیاء هنگام از بین رفتن آبجکت
      if (m_showDrawing)
      {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for(int i = total - 1; i >= 0; i--)
         {
            string name = ObjectName(m_chartId, i);
            if(StringFind(name, m_timeframeSuffix) != -1)
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }
      LogEvent("کلاس MarketStructure متوقف شد.", m_enableLogging, "[SMC]");
   }
   
   //+------------------------------------------------------------------+
   //| تابع جدید: پردازش تیک جدید برای مدیریت OB (میتگیشن و ابطال لحظه‌ای) |
   //+------------------------------------------------------------------+
   bool ProcessNewTick()
   {
      ProcessOrderBlocks(); // فراخوانی مدیریت چرخه حیات OBها
      return m_isCurrentlyMitigatingOB; // بازگشت وضعیت مصرف لحظه‌ای برای استفاده اکسپرت
   }
   
   //+------------------------------------------------------------------+
   //| تابع اصلی: پردازش کندل بسته شده (در OnTick با شرط NewBar فراخوانی شود) |
   //+------------------------------------------------------------------+
   bool ProcessNewBar()
   {
      bool structureChanged = false;
      
      ProcessOrderBlocks(); // مدیریت OBها در ابتدای پردازش کندل جدید (برای ابطال/میتگیشن)
      
      //--- ۱. بررسی شکست ساختار
      if(ArraySize(m_swingHighs_Array) >= 1 && ArraySize(m_swingLows_Array) >= 1)
      {
         CheckForBreakout();
      }

      //--- ۲. ردیابی و تایید نقطه محوری جدید
      if(m_isTrackingHigh || m_isTrackingLow)
      {
         if(CheckForNewSwingPoint())
         {
            structureChanged = true;
            if (m_showDrawing) ObjectDelete(m_chartId, "Tracking_Fib" + m_timeframeSuffix);
         }
         else
         {
            // به‌روزرسانی فیبوناچی ردیاب فقط در صورت نیاز
            if (m_showDrawing) DrawTrackingFibonacci(); 
         }
      }
      
      //--- ۳. به‌روزرسانی نمایش روند
      if(UpdateTrendLabel()) structureChanged = true;
      
      //--- ۴. پردازش الگوهای EQ ماژور
      ProcessMajorEQInvalidation();
      ProcessMajorEQDetection();
      
      return structureChanged;
   }

private:
   //--- شناسایی ساختار اولیه بازار (بر مبنای فرکتال)
   void IdentifyInitialStructure()
   {
      int barsCount = iBars(m_symbol, m_timeframe);
      if(barsCount < m_fractalLength * 2 + 1) return;
      
      // جستجو برای اولین سقف و کف معتبر
      for(int i = m_fractalLength; i < barsCount - m_fractalLength; i++)
      {
         bool isSwingHigh = true;
         bool isSwingLow = true;

         for(int j = 1; j <= m_fractalLength; j++)
         {
             if(iHigh(m_symbol, m_timeframe, i) < iHigh(m_symbol, m_timeframe, i - j) || iHigh(m_symbol, m_timeframe, i) < iHigh(m_symbol, m_timeframe, i + j)) isSwingHigh = false;
             if(iLow(m_symbol, m_timeframe, i) > iLow(m_symbol, m_timeframe, i - j) || iLow(m_symbol, m_timeframe, i) > iLow(m_symbol, m_timeframe, i + j)) isSwingLow = false;
         }

         if(isSwingHigh && ArraySize(m_swingHighs_Array) == 0) 
         {
            double body_price = MathMax(iOpen(m_symbol, m_timeframe, i), iClose(m_symbol, m_timeframe, i));
            AddSwingHigh(iHigh(m_symbol, m_timeframe, i), iTime(m_symbol, m_timeframe, i), i, body_price);
         }
         if(isSwingLow && ArraySize(m_swingLows_Array) == 0) 
         {
            double body_price = MathMin(iOpen(m_symbol, m_timeframe, i), iClose(m_symbol, m_timeframe, i));
            AddSwingLow(iLow(m_symbol, m_timeframe, i), iTime(m_symbol, m_timeframe, i), i, body_price);
         }

         if(ArraySize(m_swingHighs_Array) > 0 && ArraySize(m_swingLows_Array) > 0) break;
      }
   }
   
   //--- بررسی شکست سقف یا کف (BoS/CHoCH) و شناسایی OB بلافاصله پس از آن
   void CheckForBreakout()
   {
      if(m_isTrackingHigh || m_isTrackingLow) return;
      
      double close_1 = iClose(m_symbol, m_timeframe, 1);
      SwingPoint lastHigh = m_swingHighs_Array[0];
      SwingPoint lastLow = m_swingLows_Array[0];

      //--- شکست سقف (BoS/CHoCH صعودی) - شناسایی OB صعودی (تقاضا)
      if(close_1 > lastHigh.price)
      {
         bool isCHoCH = (m_currentTrend == TREND_BEARISH);
         string breakType = isCHoCH ? "CHoCH" : "BoS";
         if (isCHoCH) m_lastCHoCHTime = iTime(m_symbol, m_timeframe, 1); else m_lastBoSTime = iTime(m_symbol, m_timeframe, 1);
         LogEvent(">>> رویداد: شکست سقف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد.", m_enableLogging, "[SMC]");
         if (m_showDrawing) drawBreak(lastHigh, iTime(m_symbol, m_timeframe, 1), close_1, true, isCHoCH);

         m_pivotLowForTracking = FindOppositeSwing(lastHigh.time, iTime(m_symbol, m_timeframe, 1), false); 

         // شناسایی OB صعودی بلافاصله پس از یافتن پیوت
         IdentifyOrderBlock(true, iBarShift(m_symbol, m_timeframe, iTime(m_symbol, m_timeframe, 1), false), m_pivotLowForTracking.bar_index);

         m_isTrackingHigh = true; m_isTrackingLow = false;
         LogEvent("--> فاز جدید: [شکار سقف] فعال شد. نقطه 100% فیبو (ثابت) در کف " + DoubleToString(m_pivotLowForTracking.price, _Digits) + " ثبت شد.", m_enableLogging, "[SMC]");
      }
      //--- شکست کف (BoS/CHoCH نزولی) - شناسایی OB نزولی (عرضه)
      else if(close_1 < lastLow.price)
      {
         bool isCHoCH = (m_currentTrend == TREND_BULLISH);
         string breakType = isCHoCH ? "CHoCH" : "BoS";
         if (isCHoCH) m_lastCHoCHTime = iTime(m_symbol, m_timeframe, 1); else m_lastBoSTime = iTime(m_symbol, m_timeframe, 1);
         LogEvent(">>> رویداد: شکست کف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد.", m_enableLogging, "[SMC]");
         if (m_showDrawing) drawBreak(lastLow, iTime(m_symbol, m_timeframe, 1), close_1, false, isCHoCH);

         m_pivotHighForTracking = FindOppositeSwing(lastLow.time, iTime(m_symbol, m_timeframe, 1), true); 

         // شناسایی OB نزولی بلافاصله پس از یافتن پیوت
         IdentifyOrderBlock(false, iBarShift(m_symbol, m_timeframe, iTime(m_symbol, m_timeframe, 1), false), m_pivotHighForTracking.bar_index);

         m_isTrackingLow = true; m_isTrackingHigh = false;
         LogEvent("--> فاز جدید: [شکار کف] فعال شد. نقطه 100% فیبو (ثابت) در سقف " + DoubleToString(m_pivotHighForTracking.price, _Digits) + " ثبت شد.", m_enableLogging, "[SMC]");
      }
   }
   
   //--- تابع جدید: شناسایی Order Block بر اساس الگوریتم مشخص شده (با اصلاح منطق FVG)
   void IdentifyOrderBlock(const bool isBullish, const int breakBar, const int pivotBarIndex)
   {
      if (breakBar < 1 || pivotBarIndex < 0 || breakBar >= pivotBarIndex) return; // محدوده نامعتبر

      int startScan = breakBar + 1; // شروع اسکن از کندل قبل از شکست
      int endScan = pivotBarIndex;  // پایان اسکن در کندل پیوت (100% فیبو)

      // اسکن معکوس از جدیدتر (startScan) به قدیمی‌تر (endScan)
      for (int i = startScan; i <= endScan; i++)
      {
         bool candidate = false;

         if (isBullish) // OB صعودی (تقاضا) - پس از شکست سقف
         {
            // شرط ۱: کندل نزولی (رنگ مخالف)
            if (iClose(m_symbol, m_timeframe, i) < iOpen(m_symbol, m_timeframe, i))
            {
               // شرط ۲: جمع‌آوری نقدینگی (Low پایین‌تر از Low کندل قبل) - نکته: i+1 در خط زمان قبل از کندل i قرار دارد
               if (iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i + 1))
               {
                  candidate = true;

                  // شرط ۳: ایجاد گپ FVG ساده (اختیاری) - اصلاح شده برای چک گپ واقعی (عدم همپوشانی)
                  if (m_enableOB_FVG_Check)
                  {
                     if (i < 2) candidate = false; // اطمینان از وجود کندل‌های ک
                  else if (iLow(m_symbol, m_timeframe, i - 2) <= iHigh(m_symbol, m_timeframe, i)) candidate = false;// اگر همپوشانی وجود داشته باشد، رد کن (گپ باید کامل با=شد: Low(i-2) > High(i))
                  }
               }
            }
         }
         else // OB نزولی (عرضه) - پس از شکست کف
         {
            // شرط ۱: کندل صعودی (رنگ مخالف)
            if (iClose(m_symbol, m_timeframe, i) > iOpen(m_symbol, m_timeframe, i))
            {
               // شرط ۲: جمع‌آوری نقدینگی (High بالاتر از High کندل قبل) - نکته: i+1 در خط زمان قبل از کندل i قرار دارد
               if (iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i + 1))
               {
                  candidate = true;

                  // شرط ۳: ایجاد گپ FVG ساده (اختیاری) - اصلاح شده برای چک گپ واقعی (عدم همپوشانی)
                  if (m_enableOB_FVG_Check)
                  {
                     if (i < 2) candidate = false; // اطمینان از وجود کندل‌های کافی
                     else if (iHigh(m_symbol, m_timeframe, i - 2) >= iLow(m_symbol, m_timeframe, i)) candidate = false; // اگر همپوشانی وجود داشته باشد، رد کن (گپ باید کامل باشد: High(i-2) < Low(i))
                  }
               }
            }
         }

         if (candidate)
         {
            // ایجاد و اضافه کردن OB جدید
            OrderBlock newOB;
            newOB.isBullish = isBullish;
            newOB.highPrice = iHigh(m_symbol, m_timeframe, i);
            newOB.lowPrice = iLow(m_symbol, m_timeframe, i);
            newOB.time = iTime(m_symbol, m_timeframe, i);
            newOB.bar_index = i;

            AddUnmitigatedOB(newOB);
            LogEvent("OB جدید " + (isBullish ? "صعودی (تقاضا)" : "نزولی (عرضه)") + " در زمان " + TimeToString(newOB.time) + " شناسایی شد.", m_enableLogging, "[SMC-OB]");
            break; // فقط اولین (جدیدترین) کاندیدا را انتخاب کن و حلقه را متوقف کن
         }
      }
   }
   
   //--- تابع جدید: اضافه کردن OB جدید به آرایه unmitigated با مدیریت ظرفیت (حداکثر ۱۰)
   void AddUnmitigatedOB(const OrderBlock &newOB)
   {
      // مدیریت ظرفیت: اگر بیش از ۱۰ شد، قدیمی‌ترین (آخر آرایه) را حذف کن
      if (ArraySize(m_unmitigatedOBs) >= 10)
      {
         int lastIndex = ArraySize(m_unmitigatedOBs) - 1;
         string typeStrOld = m_unmitigatedOBs[lastIndex].isBullish ? "Bullish" : "Bearish";
         if (m_showDrawing)
         {
            string objNameOld = "OB_" + TimeToString(m_unmitigatedOBs[lastIndex].time) + "_" + typeStrOld + m_timeframeSuffix;
            ObjectDelete(m_chartId, objNameOld);
            ObjectDelete(m_chartId, objNameOld + "_Text");
         }
         ArrayRemove(m_unmitigatedOBs, lastIndex, 1);
         LogEvent("ظرفیت unmitigated OB تکمیل. قدیمی‌ترین OB حذف شد.", m_enableLogging, "[SMC-OB]");
      }

      // درج دستی OB جدید در ابتدای آرایه (سری)
      int oldSize = ArraySize(m_unmitigatedOBs);
      ArrayResize(m_unmitigatedOBs, oldSize + 1);
      for (int j = oldSize; j > 0; j--)
      {
         m_unmitigatedOBs[j] = m_unmitigatedOBs[j - 1];
      }
      m_unmitigatedOBs[0] = newOB;

      if (m_showDrawing) drawOrderBlock(m_unmitigatedOBs[0]);
   }
   
   //--- تابع جدید: مدیریت چرخه حیات OBها (میتگیشن و ابطال با قیمت‌های لحظه‌ای)
   void ProcessOrderBlocks()
   {
      double currentAsk = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double currentBid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      m_isCurrentlyMitigatingOB = false; // ریست وضعیت لحظه‌ای در ابتدای هر تیک/بار

      // مرحله ۱: چک میتگیشن (مصرف) برای OBهای unmitigated
      for (int i = 0; i < ArraySize(m_unmitigatedOBs); i++)
      {
         OrderBlock ob = m_unmitigatedOBs[i];
         bool mitigated = false;

         // چک وارد شدن قیمت به OB (میتگیشن)
         if (ob.isBullish && ob.lowPrice <= currentAsk && currentAsk <= ob.highPrice) mitigated = true;
         if (!ob.isBullish && ob.lowPrice <= currentBid && currentBid <= ob.highPrice) mitigated = true;

         if (mitigated)
         {
            // انتقال به آرایه mitigated
            AddMitigatedOB(ob);
            m_isCurrentlyMitigatingOB = true; // تنظیم وضعیت لحظه‌ای مصرف

            // حذف از آرایه unmitigated
            ArrayRemove(m_unmitigatedOBs, i, 1);
            i--; // تنظیم اندیس پس از حذف
            LogEvent("OB " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " مصرف (mitigated) شد.", m_enableLogging, "[SMC-OB]");
         }
      }

      // مرحله ۲: چک ابطال (invalidation) برای هر دو آرایه unmitigated و mitigated
      // اول unmitigated
      for (int i = 0; i < ArraySize(m_unmitigatedOBs); i++)
      {
         OrderBlock ob = m_unmitigatedOBs[i];
         bool invalidated = false;

         // چک عبور قیمت از OB (ابطال)
         if (ob.isBullish && currentBid < ob.lowPrice) invalidated = true;
         if (!ob.isBullish && currentAsk > ob.highPrice) invalidated = true;

         if (invalidated)
         {
            // پاک کردن اشیاء گرافیکی
            if (m_showDrawing) deleteOBDrawingObjects(ob, false);

            // حذف از آرایه
            ArrayRemove(m_unmitigatedOBs, i, 1);
            i--;
            LogEvent("OB " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " ابطال (invalidated) شد.", m_enableLogging, "[SMC-OB]");
         }
      }

      // سپس mitigated
      for (int i = 0; i < ArraySize(m_mitigatedOBs); i++)
      {
         OrderBlock ob = m_mitigatedOBs[i];
         bool invalidated = false;

         // چک عبور قیمت از OB (ابطال)
         if (ob.isBullish && currentBid < ob.lowPrice) invalidated = true;
         if (!ob.isBullish && currentAsk > ob.highPrice) invalidated = true;

         if (invalidated)
         {
            // پاک کردن اشیاء گرافیکی
            if (m_showDrawing) deleteOBDrawingObjects(ob, true);

            // حذف از آرایه
            ArrayRemove(m_mitigatedOBs, i, 1);
            i--;
            LogEvent("OB مصرف شده " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " ابطال (invalidated) شد.", m_enableLogging, "[SMC-OB]");
         }
      }
   }
   
   //--- تابع جدید: اضافه کردن OB به آرایه mitigated با مدیریت ظرفیت (حداکثر ۱۰) و آپدیت گرافیکی
   void AddMitigatedOB(const OrderBlock &ob)
   {
      // مدیریت ظرفیت: اگر بیش از ۱۰ شد، قدیمی‌ترین را حذف کن
      if (ArraySize(m_mitigatedOBs) >= 10)
      {
         int lastIndex = ArraySize(m_mitigatedOBs) - 1;
         if (m_showDrawing) deleteOBDrawingObjects(m_mitigatedOBs[lastIndex], true);
         ArrayRemove(m_mitigatedOBs, lastIndex, 1);
         LogEvent("ظرفیت mitigated OB تکمیل. قدیمی‌ترین OB مصرف شده حذف شد.", m_enableLogging, "[SMC-OB]");
      }

      // درج دستی OB در ابتدای آرایه
      int oldSize = ArraySize(m_mitigatedOBs);
      ArrayResize(m_mitigatedOBs, oldSize + 1);
      for (int j = oldSize; j > 0; j--)
      {
         m_mitigatedOBs[j] = m_mitigatedOBs[j - 1];
      }
      m_mitigatedOBs[0] = ob;

      // آپدیت گرافیکی برای نشان دادن مصرف شده (اضافه کردن $ به متن)
      if (m_showDrawing) updateOBToMitigated(m_mitigatedOBs[0]);
   }
   
   //--- تابع جدید: رسم OB (با قابلیت MTF، مستطیل سفید شفاف و متن)
   void drawOrderBlock(const OrderBlock &ob)
   {
      string typeStr = ob.isBullish ? "Bullish" : "Bearish";
      string objName = "OB_" + TimeToString(ob.time) + "_" + typeStr + m_timeframeSuffix;
      string textName = objName + "_Text";

      color obColor = C'245,245,245'; // سفید شفاف
      datetime endTime = D'2030.01.01 00:00'; // امتداد زون

      // ایجاد مستطیل
      ObjectCreate(m_chartId, objName, OBJ_RECTANGLE, 0, ob.time, ob.highPrice, endTime, ob.lowPrice);
      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, obColor);
      ObjectSetInteger(m_chartId, objName, OBJPROP_FILL, true);
      ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, true); // پشت کندل‌ها

      // محاسبه موقعیت اولیه وسط برای متن
      datetime currentTime = iTime(NULL, PERIOD_CURRENT, 0);
      datetime midTime = ob.time + (currentTime - ob.time) / 2;
      double midPrice = (ob.highPrice + ob.lowPrice) / 2;

      // ایجاد متن OB با پسوند شرطی
      string suffix = GetDisplaySuffix(m_timeframe, m_chartId);
      ObjectCreate(m_chartId, textName, OBJ_TEXT, 0, midTime, midPrice);
      ObjectSetString(m_chartId, textName, OBJPROP_TEXT, "OB" + suffix); 
      ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, clrBlack); // رنگ متن برای تمایز
      ObjectSetInteger(m_chartId, textName, OBJPROP_FONTSIZE, BASE_LABEL_FONT_SIZE);
      ObjectSetInteger(m_chartId, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
   }
   
   //--- تابع جدید: آپدیت گرافیکی OB به حالت mitigated (اضافه کردن $ به متن)
   void updateOBToMitigated(const OrderBlock &ob)
   {
      string typeStr = ob.isBullish ? "Bullish" : "Bearish";
      string textName = "OB_" + TimeToString(ob.time) + "_" + typeStr + m_timeframeSuffix + "_Text";

      // فقط متن را آپدیت کن (اضافه کردن $)
      string suffix = GetDisplaySuffix(m_timeframe, m_chartId);
      ObjectSetString(m_chartId, textName, OBJPROP_TEXT, "OB$" + suffix);
   }
   
   //--- تابع جدید: پاک کردن اشیاء گرافیکی یک OB خاص (تغییر نام برای وضوح بیشتر)
   void deleteOBDrawingObjects(const OrderBlock &ob, const bool isMitigated)
   {
      string typeStr = ob.isBullish ? "Bullish" : "Bearish";
      string objName = "OB_" + TimeToString(ob.time) + "_" + typeStr + m_timeframeSuffix;
      string textName = objName + "_Text";

      ObjectDelete(m_chartId, objName);
      ObjectDelete(m_chartId, textName);
   }
   
   //--- یافتن نقطه محوری مقابل (پیوت - 100% فیبو)
   SwingPoint FindOppositeSwing(const datetime brokenSwingTime, const datetime breakTime, const bool findHigh)
   {
       double extremePrice = findHigh ? 0 : DBL_MAX;
       double extremeBodyPrice = findHigh ? 0 : DBL_MAX;
       datetime extremeTime = 0;
       int extremeIndex = -1;

       int startBar = iBarShift(m_symbol, m_timeframe, breakTime, false);
       int endBar = iBarShift(m_symbol, m_timeframe, brokenSwingTime, false);

       SwingPoint errorResult; errorResult.price = 0; errorResult.time = 0; errorResult.bar_index = -1; errorResult.body_price = 0;

       if(startBar == -1 || endBar == -1 || startBar >= endBar) return errorResult;

       for (int i = startBar + 1; i <= endBar; i++)
       {
           if (findHigh)
           {
               if (iHigh(m_symbol, m_timeframe, i) > extremePrice) { 
                  extremePrice = iHigh(m_symbol, m_timeframe, i); 
                  extremeTime = iTime(m_symbol, m_timeframe, i); 
                  extremeIndex = i; 
               }
               double bodyHigh = MathMax(iOpen(m_symbol, m_timeframe, i), iClose(m_symbol, m_timeframe, i));
               if (bodyHigh > extremeBodyPrice) extremeBodyPrice = bodyHigh;
           }
           else
           {
               if (iLow(m_symbol, m_timeframe, i) < extremePrice) { 
                  extremePrice = iLow(m_symbol, m_timeframe, i); 
                  extremeTime = iTime(m_symbol, m_timeframe, i); 
                  extremeIndex = i; 
               }
               double bodyLow = MathMin(iOpen(m_symbol, m_timeframe, i), iClose(m_symbol, m_timeframe, i));
               if (bodyLow < extremeBodyPrice) extremeBodyPrice = bodyLow;
           }
       }

       SwingPoint result; result.price = extremePrice; result.time = extremeTime; result.bar_index = extremeIndex; result.body_price = extremeBodyPrice;

       if (extremeIndex != -1)
       {
           // ثبت نقطه 100% فیبو به عنوان Swing Point جدید و رسم آن
           if (findHigh) AddSwingHigh(extremePrice, extremeTime, extremeIndex, extremeBodyPrice); 
           else AddSwingLow(extremePrice, extremeTime, extremeIndex, extremeBodyPrice);
           return result;
       }
       return errorResult;
   }
   
   //--- یافتن سقف/کف مطلق در یک محدوده زمانی (برای 0% فیبو)
   SwingPoint FindExtremePrice(const int startBar, const int endBar, const bool findHigh) const
   {
       double extremePrice = findHigh ? 0 : DBL_MAX;
       double extremeBodyPrice = findHigh ? 0 : DBL_MAX;
       datetime extremeTime = 0;
       int extremeIndex = -1;

       for (int i = startBar; i <= endBar; i++)
       {
           if (findHigh)
           {
               if (iHigh(m_symbol, m_timeframe, i) > extremePrice) { 
                  extremePrice = iHigh(m_symbol, m_timeframe, i); 
                  extremeTime = iTime(m_symbol, m_timeframe, i); 
                  extremeIndex = i; 
               }
               double bodyHigh = MathMax(iOpen(m_symbol, m_timeframe, i), iClose(m_symbol, m_timeframe, i));
               if (bodyHigh > extremeBodyPrice) extremeBodyPrice = bodyHigh;
           }
           else
           {
               if (iLow(m_symbol, m_timeframe, i) < extremePrice) { 
                  extremePrice = iLow(m_symbol, m_timeframe, i); 
                  extremeTime = iTime(m_symbol, m_timeframe, i); 
                  extremeIndex = i; 
               }
               double bodyLow = MathMin(iOpen(m_symbol, m_timeframe, i), iClose(m_symbol, m_timeframe, i));
               if (bodyLow < extremeBodyPrice) extremeBodyPrice = bodyLow;
           }
       }

       SwingPoint result; result.price = extremePrice; result.time = extremeTime; result.bar_index = extremeIndex; result.body_price = extremeBodyPrice;
       return result;
   }
   
   //--- ردیابی و تایید Swing Point جدید با آپدیت 0% فیبو (منطق ۳۵٪ اصلاح)
   bool CheckForNewSwingPoint()
   {
       //--- ۱. ردیابی سقف جدید (HH/LH)
       if (m_isTrackingHigh)
       {
           if (m_pivotLowForTracking.bar_index == -1) return false;
           
           SwingPoint current0Per;
           int startBar = iBarShift(m_symbol, m_timeframe, m_pivotLowForTracking.time, false);
           current0Per = FindExtremePrice(1, startBar, true); // 0% فیبو فعلی

           if (current0Per.bar_index == -1 || current0Per.price <= m_pivotLowForTracking.price) return false;

           double range = current0Per.price - m_pivotLowForTracking.price;
           double fibLevel = current0Per.price - (range * (m_fibUpdateLevel / 100.0));
           double close_1 = iClose(m_symbol, m_timeframe, 1);

           if (close_1 <= fibLevel) // شرط تایید (بسته شدن در 35% یا پایین‌تر)
           {
               LogEvent("<<< تایید شد: شرط اصلاح " + IntegerToString(m_fibUpdateLevel) + "٪ برای سقف جدید برقرار شد.", m_enableLogging, "[SMC]");
               AddSwingHigh(current0Per.price, current0Per.time, current0Per.bar_index, current0Per.body_price);
               m_isTrackingHigh = false;
               return true;
           }
       }

       //--- ۲. ردیابی کف جدید (LL/HL)
       else if (m_isTrackingLow)
       {
           if (m_pivotHighForTracking.bar_index == -1) return false;

           SwingPoint current0Per;
           int startBar = iBarShift(m_symbol, m_timeframe, m_pivotHighForTracking.time, false);
           current0Per = FindExtremePrice(1, startBar, false); // 0% فیبو فعلی

           if (current0Per.bar_index == -1 || current0Per.price >= m_pivotHighForTracking.price) return false;

           double range = m_pivotHighForTracking.price - current0Per.price;
           double fibLevel = current0Per.price + (range * (m_fibUpdateLevel / 100.0));
           double close_1 = iClose(m_symbol, m_timeframe, 1);

           if (close_1 >= fibLevel) // شرط تایید (بسته شدن در 35% یا بالاتر)
           {
               LogEvent("<<< تایید شد: شرط اصلاح " + IntegerToString(m_fibUpdateLevel) + "٪ برای کف جدید برقرار شد.", m_enableLogging, "[SMC]");
               AddSwingLow(current0Per.price, current0Per.time, current0Per.bar_index, current0Per.body_price);
               m_isTrackingLow = false;
               return true;
           }
       }
       return false;
   }

   //--- تابع: ترسیم فیبوناچی متحرک (ردیابی)
   void DrawTrackingFibonacci()
   {
       SwingPoint p100, p0;
       bool isBullish = m_isTrackingHigh;

       // تعیین نقاط 100% و 0%
       if (m_isTrackingHigh)
       {
           p100 = m_pivotLowForTracking;
           int startBar = iBarShift(m_symbol, m_timeframe, p100.time, false);
           p0 = FindExtremePrice(1, startBar, true);
           if (p0.bar_index == -1 || p0.price <= p100.price) { ObjectDelete(m_chartId, "Tracking_Fib" + m_timeframeSuffix); return; }
       }
       else if (m_isTrackingLow)
       {
           p100 = m_pivotHighForTracking;
           int startBar = iBarShift(m_symbol, m_timeframe, p100.time, false);
           p0 = FindExtremePrice(1, startBar, false);
           if (p0.bar_index == -1 || p0.price >= p100.price) { ObjectDelete(m_chartId, "Tracking_Fib" + m_timeframeSuffix); return; }
       }
       else { ObjectDelete(m_chartId, "Tracking_Fib" + m_timeframeSuffix); return; }

       string objName = "Tracking_Fib" + m_timeframeSuffix;
       ObjectDelete(m_chartId, objName);

       ObjectCreate(m_chartId, objName, OBJ_FIBO, 0, p100.time, p100.price, p0.time, p0.price);
       ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, isBullish ? clrDodgerBlue : clrOrangeRed);
       ObjectSetInteger(m_chartId, objName, OBJPROP_RAY_RIGHT, true);
       ObjectSetInteger(m_chartId, objName, OBJPROP_WIDTH, 1);

       // تنظیم سطوح (با رفع خطای تبدیل نوع ضمنی)
       ObjectSetDouble(m_chartId, objName, OBJPROP_LEVELVALUE, 0, 0.0);
       ObjectSetString(m_chartId, objName, OBJPROP_LEVELTEXT, 0, "0% (Movable)" + m_timeframeSuffix);

       ObjectSetDouble(m_chartId, objName, OBJPROP_LEVELVALUE, 1, (double)m_fibUpdateLevel / 100.0);
       ObjectSetString(m_chartId, objName, OBJPROP_LEVELTEXT, 1, IntegerToString(m_fibUpdateLevel) + "% (Confirmation)" + m_timeframeSuffix);

       ObjectSetDouble(m_chartId, objName, OBJPROP_LEVELVALUE, 2, 1.0);
       ObjectSetString(m_chartId, objName, OBJPROP_LEVELTEXT, 2, "100% (Fixed Pivot)" + m_timeframeSuffix);

       for(int i = 3; i < 10; i++) ObjectSetDouble(m_chartId, objName, OBJPROP_LEVELVALUE, i, 0.0);
   }

   //--- اضافه کردن سقف جدید و ترسیم آن 
   void AddSwingHigh(const double price, const datetime time, const int bar_index, const double body_price)
   {
      if(ArraySize(m_swingHighs_Array) >= 2)
      {
         if (m_showDrawing)
         {
             ObjectDelete(m_chartId, "  H_" + TimeToString(m_swingHighs_Array[1].time) + m_timeframeSuffix);
             ObjectDelete(m_chartId, "  H_" + TimeToString(m_swingHighs_Array[1].time) + m_timeframeSuffix + "_Text");
         }
         ArrayRemove(m_swingHighs_Array, ArraySize(m_swingHighs_Array) - 1, 1);
      }

      int oldSize = ArraySize(m_swingHighs_Array);
      ArrayResize(m_swingHighs_Array, oldSize + 1);
      for (int j = oldSize; j > 0; j--)
      {
         m_swingHighs_Array[j] = m_swingHighs_Array[j - 1];
      }
      m_swingHighs_Array[0].price = price;
      m_swingHighs_Array[0].time = time;
      m_swingHighs_Array[0].bar_index = bar_index;
      m_swingHighs_Array[0].body_price = body_price;

      // آپدیت کاندیدای فعال برای EQ ماژور نزولی
      m_activeMajorHighCandidate = m_swingHighs_Array[0];
      LogEvent("سقف ماژور " + TimeToString(m_swingHighs_Array[0].time) + " به عنوان کاندیدای EQ ماژور تنظیم شد.", m_enableLogging, "[SMC-EQ]");

      if (m_showDrawing) drawSwingPoint(m_swingHighs_Array[0], true);
      LogEvent("سقف جدید در قیمت " + DoubleToString(price, _Digits) + " ثبت شد.", m_enableLogging, "[SMC]");
   }

   //--- اضافه کردن کف جدید و ترسیم آن 
   void AddSwingLow(const double price, const datetime time, const int bar_index, const double body_price)
   {
      if(ArraySize(m_swingLows_Array) >= 2)
      {
         if (m_showDrawing)
         {
             ObjectDelete(m_chartId, "  L_" + TimeToString(m_swingLows_Array[1].time) + m_timeframeSuffix);
             ObjectDelete(m_chartId, "  L_" + TimeToString(m_swingLows_Array[1].time) + m_timeframeSuffix + "_Text");
         }
         ArrayRemove(m_swingLows_Array, ArraySize(m_swingLows_Array) - 1, 1);
      }

      int oldSize = ArraySize(m_swingLows_Array);
      ArrayResize(m_swingLows_Array, oldSize + 1);
      for (int j = oldSize; j > 0; j--)
      {
         m_swingLows_Array[j] = m_swingLows_Array[j - 1];
      }
      m_swingLows_Array[0].price = price;
      m_swingLows_Array[0].time = time;
      m_swingLows_Array[0].bar_index = bar_index;
      m_swingLows_Array[0].body_price = body_price;

      // آپدیت کاندیدای فعال برای EQ ماژور صعودی
      m_activeMajorLowCandidate = m_swingLows_Array[0];
      LogEvent("کف ماژور " + TimeToString(m_swingLows_Array[0].time) + " به عنوان کاندیدای EQ ماژور تنظیم شد.", m_enableLogging, "[SMC-EQ]");

      if (m_showDrawing) drawSwingPoint(m_swingLows_Array[0], false);
      LogEvent("کف جدید در قیمت " + DoubleToString(price, _Digits) + " ثبت شد.", m_enableLogging, "[SMC]");
   }

   //--- به‌روزرسانی لیبل روند (با پسوند تایم فریم و موقعیت مناسب)
   bool UpdateTrendLabel()
   {
      TREND_TYPE oldTrend = m_currentTrend;

      if(ArraySize(m_swingHighs_Array) >= 2 && ArraySize(m_swingLows_Array) >= 2)
      {
         // منطق تشخیص روند بر اساس HH/HL و LL/LH
         if(m_swingHighs_Array[0].price > m_swingHighs_Array[1].price && m_swingLows_Array[0].price > m_swingLows_Array[1].price) m_currentTrend = TREND_BULLISH;
         else if(m_swingHighs_Array[0].price < m_swingHighs_Array[1].price && m_swingLows_Array[0].price < m_swingLows_Array[1].price) m_currentTrend = TREND_BEARISH;
         else m_currentTrend = TREND_NONE;
      }
      else m_currentTrend = TREND_NONE;

      // آپدیت گرافیکی لیبل روند (فقط در صورت تغییر و اگر نمایش فعال باشد)
      if(m_showDrawing && oldTrend != m_currentTrend)
      {
         ObjectDelete(m_chartId, m_trendObjectName);
         string trendText; color trendColor;
         switch(m_currentTrend)
         {
            case TREND_BULLISH:
            {
               trendText = "Bullish Trend (HH/HL)";
               trendColor = clrDeepSkyBlue;
               LogEvent("وضعیت روند به صعودی تغییر یافت.", m_enableLogging, "[SMC]");
               break;
            }
            case TREND_BEARISH:
            {
               trendText = "Bearish Trend (LL/LH)";
               trendColor = clrOrangeRed;
               LogEvent("وضعیت روند به نزولی تغییر یافت.", m_enableLogging, "[SMC]");
               break;
            }
            default:
            {
               trendText = "No Trend / Ranging";
               trendColor = clrGray;
               LogEvent("وضعیت روند به بدون روند تغییر یافت.", m_enableLogging, "[SMC]");
               break;
            }
         }
         
         // محاسبه موقعیت نمایش لیبل بر اساس تایم فریم (اصلاح خطای سینتکسی)
         int tf_index = (int)m_timeframe;
         // هر تایم فریم یک شیفت ثابت در YDISTANCE دارد
         int y_offset = 20; 
         if (tf_index == 1 || tf_index == 5 || tf_index == 15 || tf_index == 30) y_offset = 20; // M1-M30
         else if (tf_index == 60) y_offset = 40; // H1
         else if (tf_index == 240) y_offset = 60; // H4
         else if (tf_index == 1440) y_offset = 80; // D1
         else y_offset = 100;
         
         // جابجایی هر تایم فریم نسبت به تایم فریم‌های دیگر
         int y_distance_base = 20;
         int y_distance_per_tf = 18;
         int y_position = y_distance_base + ((int)m_timeframe - (int)PERIOD_M1) * y_distance_per_tf;

         ObjectCreate(m_chartId, m_trendObjectName, OBJ_LABEL, 0, 0, 0);
         // (اصلاح خطای تبدیل نوع ضمنی)
         ObjectSetString(m_chartId, m_trendObjectName, OBJPROP_TEXT, trendText + m_timeframeSuffix); 
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_XDISTANCE, 10);
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_YDISTANCE, y_offset); // استفاده از محاسبه ساده شده و شیفت منطقی

         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_COLOR, trendColor);
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_FONTSIZE, 12);
         return true;
      }
      return false;
   }

   //--- ترسیم سقف/کف (با پسوند تایم فریم)
   void drawSwingPoint(const SwingPoint &sp, const bool isHigh)
   {
      string objName = (isHigh ? "H_" : "L_") + TimeToString(sp.time) + m_timeframeSuffix;
      ObjectDelete(m_chartId, objName);

      ObjectCreate(m_chartId, objName, OBJ_ARROW, 0, sp.time, sp.price);
      ObjectSetInteger(m_chartId, objName, OBJPROP_ARROWCODE, 77);
      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, isHigh ? clrDodgerBlue : clrRed);
      ObjectSetInteger(m_chartId, objName, OBJPROP_ANCHOR, isHigh ? ANCHOR_BOTTOM : ANCHOR_TOP);
   }

   //--- ترسیم شکست (BoS/CHoCH) (با پسوند تایم فریم و شیفت زمانی)
   void drawBreak(const SwingPoint &brokenSwing, const datetime breakTime, const double breakPrice, const bool isHighBreak, const bool isCHoCH)
   {
       string breakType = isCHoCH ? "CHoCH" : "BoS";
       color breakColor = isCHoCH ? clrCrimson : (isHighBreak ? clrSeaGreen : clrOrange);
       string objName = "Break_" + TimeToString(brokenSwing.time) + m_timeframeSuffix;
       string textName = objName + "_Text";
       ObjectDelete(m_chartId, objName);
       ObjectDelete(m_chartId, textName);

       ObjectCreate(m_chartId, objName, OBJ_TREND, 0, brokenSwing.time, brokenSwing.price, breakTime, brokenSwing.price);
       ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, breakColor);
       ObjectSetInteger(m_chartId, objName, OBJPROP_STYLE, STYLE_DOT);

       // محتوای متن با پسوند شرطی
       string suffix = GetDisplaySuffix(m_timeframe, m_chartId);
       string fullText = breakType + suffix;

       // سایز فونت داینامیک
       int barStart = iBarShift(m_symbol, m_timeframe, brokenSwing.time, false);
       int barEnd = iBarShift(m_symbol, m_timeframe, breakTime, false);
       int candleDistance = MathAbs(barEnd - barStart);
       int fontSize = (candleDistance < DYNAMIC_SIZE_CANDLE_THRESHOLD) ? SMALL_LABEL_FONT_SIZE : BASE_LABEL_FONT_SIZE;

       // موقعیت متن با آفست
       datetime midTime = brokenSwing.time + (breakTime - brokenSwing.time) / 2;
       double midPrice = brokenSwing.price;
       double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
       double verticalOffset = tickSize * VERTICAL_OFFSET_TICKS;
       double textPrice = midPrice + (isHighBreak ? verticalOffset : -verticalOffset);

       // مدیریت همپوشانی
       while (IsPositionOccupied(m_chartId, midTime, textPrice, m_timeframe))
       {
          textPrice += (isHighBreak ? (verticalOffset / 2.0) : (-verticalOffset / 2.0));
       }

       // ایجاد متن
       ObjectCreate(m_chartId, textName, OBJ_TEXT, 0, midTime, textPrice);
       ObjectSetString(m_chartId, textName, OBJPROP_TEXT, fullText);
       ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, breakColor);
       ObjectSetInteger(m_chartId, textName, OBJPROP_FONTSIZE, fontSize);
       ObjectSetInteger(m_chartId, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
   }

   //--- تابع کمکی: بررسی کندل قوی (برای تایید EQ)
   bool IsStrongCandle(const int shift) const
   {
      double open = iOpen(m_symbol, m_timeframe, shift);
      double close = iClose(m_symbol, m_timeframe, shift);
      double high = iHigh(m_symbol, m_timeframe, shift);
      double low = iLow(m_symbol, m_timeframe, shift);
      
      double body = MathAbs(open - close);
      double range = high - low;
      
      // شرط قوی: بدنه بیش از 50% رنج کندل
      return (body > 0.5 * range);
   }

   //--- تابع: پردازش ابطال الگوهای EQ ماژور تایید شده (مرگ بعد از زندگی)
   void ProcessMajorEQInvalidation()
   {
      // جلوگیری از اجرای تکراری روی یک کندل
      datetime currentTime = iTime(m_symbol, m_timeframe, 1);
      if (currentTime == m_lastMajorEQInvalidationCheck) return;
      m_lastMajorEQInvalidationCheck = currentTime;

      // حلقه را از آخر به اول می‌زنیم تا حذف کردن یک عنصر، باعث بهم ریختن اندیس‌ها نشود
      for (int i = ArraySize(m_majorEQPatterns_Array) - 1; i >= 0; i--)
      {
         MajorEQPattern eq = m_majorEQPatterns_Array[i];

         // بازسازی زون واکنش الگو
         double zoneHigh = eq.isBullish ? eq.source_swing.body_price : eq.source_swing.price;
         double zoneLow = eq.isBullish ? eq.source_swing.price : eq.source_swing.body_price;

         bool isInvalidated = false;
         // شرط ابطال برای EQ نزولی (Double Top)
         if (!eq.isBullish && iClose(m_symbol, m_timeframe, 1) > zoneHigh)
         {
            isInvalidated = true;
         }
         // شرط ابطال برای EQ صعودی (Double Bottom)
         if (eq.isBullish && iClose(m_symbol, m_timeframe, 1) < zoneLow)
         {
            isInvalidated = true;
         }

         if (isInvalidated)
         {
            LogEvent("الگوی EQ ماژور در زمان " + TimeToString(eq.time_formation) + " با بسته شدن قیمت خارج از زون باطل شد.", m_enableLogging, "[SMC-EQ]");

            // پاک کردن تمام اشیاء گرافیکی مربوط به این EQ - هماهنگ با CLiquidityManager (نام‌گذاری Liq_EQ_Major_...)
            string baseName = "Liq_EQ_Major_" + TimeToString(eq.source_swing.time) + m_timeframeSuffix;
            string lineName = baseName + "_Line";
            string textName = baseName + "_Text";
            ObjectDelete(m_chartId, lineName);
            ObjectDelete(m_chartId, textName);

            // حذف الگو از آرایه حافظه
            ArrayRemove(m_majorEQPatterns_Array, i, 1);
         }
      }
   }

   //--- تابع: پردازش شناسایی الگوهای EQ ماژور جدید
   void ProcessMajorEQDetection()
   {
      // جلوگیری از اجرای تکراری روی یک کندل
      datetime currentTime = iTime(m_symbol, m_timeframe, 1);
      if (currentTime == m_lastMajorEQDetectionCheck) return;
      m_lastMajorEQDetectionCheck = currentTime;

      // --- بخش ۱: ارزیابی کاندیدای سقف فعال (برای EQ نزولی) ---
      if (m_activeMajorHighCandidate.bar_index != -1) // آیا اصلاً کاندیدای فعالی داریم؟
      {
         // شرط ابطال 1: آیا سقف جدیدتری از کاندیدای ما تشکیل شده؟
         if (GetSwingHigh(0).time > m_activeMajorHighCandidate.time)
         {
            LogEvent("کاندیدای سقف ماژور " + TimeToString(m_activeMajorHighCandidate.time) + " توسط سقف جدیدتر باطل شد.", m_enableLogging, "[SMC-EQ]");
            m_activeMajorHighCandidate = GetSwingHigh(0); // کاندیدا به سقف جدید آپدیت می‌شود
            return; // در این تیک کاری با این کاندیدا نداریم
         }

         // تعریف زون فرضی
         double zoneHigh = m_activeMajorHighCandidate.price;
         double zoneLow = m_activeMajorHighCandidate.body_price;

         // شرط ابطال ۲: آیا کندل بسته شده فعلی بالای زون بسته شده؟
         if (iClose(m_symbol, m_timeframe, 1) > zoneHigh)
         {
            LogEvent("کاندیدای سقف ماژور " + TimeToString(m_activeMajorHighCandidate.time) + " با بسته شدن قیمت بالای زون باطل شد.", m_enableLogging, "[SMC-EQ]");
            m_activeMajorHighCandidate.bar_index = -1; // کاندیدا غیرفعال می‌شود
            return;
         }

         // شرط ورود و تایید الگو
         if (iHigh(m_symbol, m_timeframe, 1) >= zoneLow) // آیا کندل فعلی وارد زون شده؟
         {
            // آیا کندل فعلی یک کندل تایید نزولی و قوی است؟
            if (iClose(m_symbol, m_timeframe, 1) < iOpen(m_symbol, m_timeframe, 1) && IsStrongCandle(1))
            {
               // الگو تایید شد!
               MajorEQPattern newEQ;
               newEQ.isBullish = false;
               newEQ.time_formation = iTime(m_symbol, m_timeframe, 1); // زمان تایید
               newEQ.price_entry = iHigh(m_symbol, m_timeframe, 1); // High کندل تایید
               newEQ.source_swing = m_activeMajorHighCandidate;

               // درج دستی به جای ArrayInsert
               int oldSize = ArraySize(m_majorEQPatterns_Array);
               ArrayResize(m_majorEQPatterns_Array, oldSize + 1);
               for (int j = oldSize; j > 0; j--)
               {
                  m_majorEQPatterns_Array[j] = m_majorEQPatterns_Array[j - 1];
               }
               m_majorEQPatterns_Array[0] = newEQ;

               // مدیریت ظرفیت (حداکثر 4)
               if (ArraySize(m_majorEQPatterns_Array) > 4)
               {
                  int lastIndex = ArraySize(m_majorEQPatterns_Array) - 1;
                  MajorEQPattern oldestEQ = m_majorEQPatterns_Array[lastIndex];

                  LogEvent("ظرفیت EQ ماژور تکمیل. قدیمی‌ترین الگو در زمان " + TimeToString(oldestEQ.time_formation) + " حذف می‌شود.", m_enableLogging, "[SMC-EQ]");

                  // پاک کردن اشیاء گرافیکی الگوی قدیمی
                  string baseNameOld = "Liq_EQ_Major_" + TimeToString(oldestEQ.source_swing.time) + m_timeframeSuffix;
                  string lineNameOld = baseNameOld + "_Line";
                  string textNameOld = baseNameOld + "_Text";
                  ObjectDelete(m_chartId, lineNameOld);
                  ObjectDelete(m_chartId, textNameOld);

                  // حذف از آرایه حافظه
                  ArrayRemove(m_majorEQPatterns_Array, lastIndex, 1);
               }
               
               LogEvent("الگوی EQ ماژور نزولی تایید شد.", m_enableLogging, "[SMC-EQ]");

               m_activeMajorHighCandidate.bar_index = -1; // کاندیدا پس از موفقیت، غیرفعال می‌شود
            }
         }
      }

      // --- بخش ۲: ارزیابی کاندیدای کف فعال (برای EQ صعودی) ---
      if (m_activeMajorLowCandidate.bar_index != -1)
      {
         // شرط ابطال 1: آیا کف جدیدتری از کاندیدای ما تشکیل شده؟
         if (GetSwingLow(0).time > m_activeMajorLowCandidate.time)
         {
            LogEvent("کاندیدای کف ماژور " + TimeToString(m_activeMajorLowCandidate.time) + " توسط کف جدیدتر باطل شد.", m_enableLogging, "[SMC-EQ]");
            m_activeMajorLowCandidate = GetSwingLow(0); // کاندیدا به کف جدید آپدیت می‌شود
            return; // در این تیک کاری با این کاندیدا نداریم
         }

         // تعریف زون فرضی
         double zoneLow = m_activeMajorLowCandidate.price;
         double zoneHigh = m_activeMajorLowCandidate.body_price;

         // شرط ابطال ۲: آیا کندل بسته شده فعلی پایین زون بسته شده؟
         if (iClose(m_symbol, m_timeframe, 1) < zoneLow)
         {
            LogEvent("کاندیدای کف ماژور " + TimeToString(m_activeMajorLowCandidate.time) + " با بسته شدن قیمت پایین زون باطل شد.", m_enableLogging, "[SMC-EQ]");
            m_activeMajorLowCandidate.bar_index = -1; // کاندیدا غیرفعال می‌شود
            return;
         }

         // شرط ورود و تایید الگو
         if (iLow(m_symbol, m_timeframe, 1) <= zoneHigh) // آیا کندل فعلی وارد زون شده؟
         {
            // آیا کندل فعلی یک کندل تایید صعودی و قوی است؟
            if (iClose(m_symbol, m_timeframe, 1) > iOpen(m_symbol, m_timeframe, 1) && IsStrongCandle(1))
            {
               // الگو تایید شد!
               MajorEQPattern newEQ;
               newEQ.isBullish = true;
               newEQ.time_formation = iTime(m_symbol, m_timeframe, 1); // زمان تایید
               newEQ.price_entry = iLow(m_symbol, m_timeframe, 1); // Low کندل تایید
               newEQ.source_swing = m_activeMajorLowCandidate;

               // درج دستی به جای ArrayInsert
               int oldSize = ArraySize(m_majorEQPatterns_Array);
               ArrayResize(m_majorEQPatterns_Array, oldSize + 1);
               for (int j = oldSize; j > 0; j--)
               {
                  m_majorEQPatterns_Array[j] = m_majorEQPatterns_Array[j - 1];
               }
               m_majorEQPatterns_Array[0] = newEQ;

               // مدیریت ظرفیت (حداکثر 4)
               if (ArraySize(m_majorEQPatterns_Array) > 4)
               {
                  int lastIndex = ArraySize(m_majorEQPatterns_Array) - 1;
                  MajorEQPattern oldestEQ = m_majorEQPatterns_Array[lastIndex];

                  LogEvent("ظرفیت EQ ماژور تکمیل. قدیمی‌ترین الگو در زمان " + TimeToString(oldestEQ.time_formation) + " حذف می‌شود.", m_enableLogging, "[SMC-EQ]");

                  // پاک کردن اشیاء گرافیکی الگوی قدیمی
                  string baseNameOld = "Liq_EQ_Major_" + TimeToString(oldestEQ.source_swing.time) + m_timeframeSuffix;
                  string lineNameOld = baseNameOld + "_Line";
                  string textNameOld = baseNameOld + "_Text";
                  ObjectDelete(m_chartId, lineNameOld);
                  ObjectDelete(m_chartId, textNameOld);

                  // حذف از آرایه حافظه
                  ArrayRemove(m_majorEQPatterns_Array, lastIndex, 1);
               }
               
               LogEvent("الگوی EQ ماژور صعودی تایید شد.", m_enableLogging, "[SMC-EQ]");

               m_activeMajorLowCandidate.bar_index = -1; // کاندیدا پس از موفقیت، غیرفعال می‌شود
            }
         }
      }
   }

public:
   //+------------------------------------------------------------------+
   //| توابع دسترسی عمومی (Accessors) - برای استفاده اکسپرت معاملاتی     |
   //+------------------------------------------------------------------+
   
   //--- زمان آخرین CHoCH/BoS (به صورت زمان نه اندیس)
   datetime GetLastChoChTime() const { return m_lastCHoCHTime; }
   datetime GetLastBoSTime() const { return m_lastBoSTime; }
   
   //--- آخرین سقف و کف ساختاری (به صورت ساختار کامل SwingPoint)
   // (بررسی اندازه آرایه برای جلوگیری از خطای دسترسی)
   SwingPoint GetLastSwingHigh() const { return (ArraySize(m_swingHighs_Array) > 0) ? m_swingHighs_Array[0] : SwingPoint(); } 
   SwingPoint GetLastSwingLow() const { return (ArraySize(m_swingLows_Array) > 0) ? m_swingLows_Array[0] : SwingPoint(); }
   
   //--- دو سقف آخر
   SwingPoint GetSwingHigh(const int index) const { return (index >= 0 && index < ArraySize(m_swingHighs_Array)) ? m_swingHighs_Array[index] : SwingPoint(); }
   
   //--- دو کف آخر
   SwingPoint GetSwingLow(const int index) const { return (index >= 0 && index < ArraySize(m_swingLows_Array)) ? m_swingLows_Array[index] : SwingPoint(); }
   
   //--- وضعیت روند فعلی
   TREND_TYPE GetCurrentTrend() const { return m_currentTrend; }
   
   //--- توابع جدید برای دسترسی به OBهای مصرف نشده (unmitigated)
   int GetUnmitigatedOBCount() const { return ArraySize(m_unmitigatedOBs); }
   OrderBlock GetUnmitigatedOB(const int index) const 
   { 
      if (index >= 0 && index < ArraySize(m_unmitigatedOBs)) return m_unmitigatedOBs[index]; 
      OrderBlock empty; empty.isBullish = false; empty.highPrice = 0; empty.lowPrice = 0; empty.time = 0; empty.bar_index = -1; 
      return empty; 
   }
   
   //--- توابع جدید برای دسترسی به OBهای مصرف شده (mitigated)
   int GetMitigatedOBCount() const { return ArraySize(m_mitigatedOBs); }
   OrderBlock GetMitigatedOB(const int index) const 
   { 
      if (index >= 0 && index < ArraySize(m_mitigatedOBs)) return m_mitigatedOBs[index]; 
      OrderBlock empty; empty.isBullish = false; empty.highPrice = 0; empty.lowPrice = 0; empty.time = 0; empty.bar_index = -1; 
      return empty; 
   }
   
   //--- وضعیت لحظه‌ای مصرف OB
   bool IsCurrentlyMitigatingOB() const { return m_isCurrentlyMitigatingOB; }
   
   //--- توابع دسترسی به EQ های ماژور تایید شده
   int GetMajorEQPatternCount() const { return ArraySize(m_majorEQPatterns_Array); }
   MajorEQPattern GetMajorEQPattern(const int index) const
   {
      if (index >= 0 && index < ArraySize(m_majorEQPatterns_Array)) return m_majorEQPatterns_Array[index];
      MajorEQPattern empty; empty.time_formation = 0; // مقداردهی اولیه برای شناسایی خطا
      return empty;
   }
   
   //--- تابع جدید برای گرفتن آخرین EQ ماژور تایید شده (برای سادگی کار CLiquidityManager)
   MajorEQPattern GetLastMajorEQPattern() const
   {
      if(ArraySize(m_majorEQPatterns_Array) > 0) return m_majorEQPatterns_Array[0];
      MajorEQPattern empty; empty.time_formation = 0;
      return empty;
   }
};

//==================================================================//
//             کلاس ۳: مدیریت ساختار مینور بازار (MinorStructure)    //
//==================================================================//
class MinorStructure
{
private:
   //--- متغیرهای تنظیمات و محیط اجرا
   string           m_symbol;               // نماد جفت ارز
   ENUM_TIMEFRAMES  m_timeframe;            // تایم فریم اختصاصی این آبجکت
   long             m_chartId;              // ID چارت اجرایی اکسپرت
   bool             m_enableLogging;        // فعال/غیرفعال بودن لاگ
   string           m_timeframeSuffix;      // پسوند تایم‌فریم کوتاه شده برای نامگذاری اشیاء
   bool             m_showDrawing;          // کنترل نمایش ترسیمات مینور روی چارت
   int              m_aoFractalLength;      // طول فرکتال AO (تعداد میله‌های اطراف، مثلاً 3)
   bool             m_enableMinorOB_FVG_Check; // فعال/غیرفعال کردن شرط FVG برای شناسایی OB مینور (ورودی جدید سازنده)

   //--- هندل اندیکاتور
   int              m_ao_handle;            // هندل اندیکاتور Awesome Oscillator (بدون نمایش)

   //--- متغیرهای حالت
   SwingPoint       m_minorSwingHighs_Array[]; // آرایه سقف‌های مینور (سری، ظرفیت حداکثر ۱۰)
   SwingPoint       m_minorSwingLows_Array[];  // آرایه کف‌های مینور (سری، ظرفیت حداکثر ۱۰)
   EQPattern        m_eqPatterns_Array[];      // آرایه الگوهای EQ (سری، ظرفیت حداکثر ۱۰)
   SwingPoint       m_activeHighCandidate;     // کاندیدای فعال فعلی برای EQ نزولی
   SwingPoint       m_activeLowCandidate;      // کاندیدای فعال فعلی برای EQ صعودی
   datetime         m_lastHighTime;            // زمان آخرین سقف ذخیره شده (برای اسکن)
   datetime         m_lastLowTime;             // زمان آخرین کف ذخیره شده (برای اسکن)
   datetime         m_lastProcessedBarTime;    // زمان آخرین کندل پردازش شده (برای تشخیص NewBar)

   //--- آرایه‌های ذخیره‌سازی برای Order Blocks مینور
   OrderBlock       m_minorUnmitigatedOBs[];   // آرایه OBهای مصرف نشده مینور (unmitigated، سری)
   OrderBlock       m_minorMitigatedOBs[];     // آرایه OBهای مصرف شده مینور (mitigated، سری)
   
   //--- متغیرهای کنترلی برای Order Blocks مینور
   bool             m_isCurrentlyMitigatingMinorOB; // وضعیت لحظه‌ای: آیا قیمت در حال مصرف یک OB مینور است؟

public:
   //+------------------------------------------------------------------+
   //| سازنده کلاس (Constructor)                                       |
   //+------------------------------------------------------------------+
   MinorStructure(const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId, const bool enableLogging_in, const bool showDrawing, const int aoFractalLength_in, const bool enableMinorOB_FVG_Check_in)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      m_enableLogging = enableLogging_in;
      m_showDrawing = showDrawing;
      m_aoFractalLength = aoFractalLength_in;
      m_enableMinorOB_FVG_Check = enableMinorOB_FVG_Check_in; // مقداردهی ورودی جدید
      
      // تنظیم پسوند تایم فریم برای نمایش MTF (کوتاه شده)
      m_timeframeSuffix = " (" + TimeFrameToStringShort(timeframe) + ")";

      // هندل AO بدون نمایش
      m_ao_handle = iAO(m_symbol, m_timeframe);
      if (m_ao_handle == INVALID_HANDLE)
      {
         if (m_enableLogging) Print("[MINOR] خطا در ایجاد هندل Awesome Oscillator.");
      }

      ArraySetAsSeries(m_minorSwingHighs_Array, true);
      ArraySetAsSeries(m_minorSwingLows_Array, true);
      ArraySetAsSeries(m_eqPatterns_Array, true);
      ArrayResize(m_minorSwingHighs_Array, 0, 10); // رزرو اولیه برای بهینه‌سازی
      ArrayResize(m_minorSwingLows_Array, 0, 10);  // رزرو اولیه برای بهینه‌سازی
      ArrayResize(m_eqPatterns_Array, 0, 10);      // رزرو اولیه برای بهینه‌سازی
      
      // مقداردهی اولیه آرایه‌های OB مینور (سری با ظرفیت رزرو شده)
      ArraySetAsSeries(m_minorUnmitigatedOBs, true);
      ArraySetAsSeries(m_minorMitigatedOBs, true);
      ArrayResize(m_minorUnmitigatedOBs, 0, 10); // رزرو اولیه
      ArrayResize(m_minorMitigatedOBs, 0, 10);   // رزرو اولیه
      
      m_activeHighCandidate.bar_index = -1;
      m_activeLowCandidate.bar_index = -1;
      m_lastHighTime = 0;
      m_lastLowTime = 0;
      m_lastProcessedBarTime = 0;
      m_isCurrentlyMitigatingMinorOB = false; // مقداردهی اولیه

      // پاکسازی اشیاء قبلی مربوط به این کلاس روی چارت
      if (m_showDrawing)
      {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for(int i = total - 1; i >= 0; i--)
         {
            string name = ObjectName(m_chartId, i);
            if(StringFind(name, m_timeframeSuffix) != -1 && (StringFind(name, "Minor_") != -1 || StringFind(name, "Confirmed_") != -1 || StringFind(name, "EQ_") != -1))
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }
      
      // اسکن اولیه برای یافتن مینورهای اولیه
      ScanInitialMinors();
      
      LogEvent("کلاس MinorStructure برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.", m_enableLogging, "[MINOR]");
   }

   //+------------------------------------------------------------------+
   //| مخرب کلاس (Destructor) - برای پاک کردن اشیاء هنگام حذف آبجکت     |
   //+------------------------------------------------------------------+
   ~MinorStructure()
   {
      // پاک کردن اشیاء هنگام از بین رفتن آبجکت
      if (m_showDrawing)
      {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for(int i = total - 1; i >= 0; i--)
         {
            string name = ObjectName(m_chartId, i);
            if(StringFind(name, m_timeframeSuffix) != -1 && (StringFind(name, "Minor_") != -1 || StringFind(name, "Confirmed_") != -1 || StringFind(name, "EQ_") != -1 || StringFind(name, "MinorOB_") != -1))
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }
      if (m_ao_handle != INVALID_HANDLE) IndicatorRelease(m_ao_handle); // آزادسازی هندل برای بهینه‌سازی منابع MT5
      LogEvent("کلاس MinorStructure متوقف شد.", m_enableLogging, "[MINOR]");
   }
   
   //+------------------------------------------------------------------+
   //| تابع جدید: پردازش تیک جدید برای مدیریت OB مینور (میتگیشن و ابطال لحظه‌ای) |
   //+------------------------------------------------------------------+
   bool ProcessNewTick()
   {
      ProcessMinorOrderBlocks(); // فراخوانی مدیریت چرخه حیات OBهای مینور
      return m_isCurrentlyMitigatingMinorOB; // بازگشت وضعیت مصرف لحظه‌ای برای استفاده اکسپرت
   }
   
   //+------------------------------------------------------------------+
   //| تابع اصلی: پردازش کندل بسته شده (در OnTick با شرط NewBar فراخوانی شود) |
   //+------------------------------------------------------------------+
   bool ProcessNewBar()
   {
      datetime currentBarTime = iTime(m_symbol, m_timeframe, 0);
      if (currentBarTime == m_lastProcessedBarTime) return false; // جلوگیری از اجرای تکراری بدون کندل جدید
      m_lastProcessedBarTime = currentBarTime;

      bool newMinorFound = false;
      
      // کش کردن بافر AO برای کل بازه اسکن (بهینه‌سازی برای جلوگیری از CopyBuffer تکراری)
      int barsCount = iBars(m_symbol, m_timeframe);
      double aoBuffer[];
      ArraySetAsSeries(aoBuffer, true);
      if (CopyBuffer(m_ao_handle, 0, 0, barsCount, aoBuffer) <= 0)
      {
         if (m_enableLogging) Print("[MINOR] خطا در کش کردن بافر AO: ", GetLastError());
         return false;
      }
      
      // اسکن برای سقف‌های مینور
      newMinorFound |= ScanForMinors(aoBuffer, true);
      
      // اسکن برای کف‌های مینور
      newMinorFound |= ScanForMinors(aoBuffer, false);
      
      // ابطال الگوهای EQ تایید شده (مرگ بعد از زندگی)
      ProcessEQInvalidation();
      
      // شناسایی الگوی EQ جدید
      ProcessEQDetection();
      
      if (newMinorFound && m_enableLogging) LogEvent("مینور جدید شناسایی شد.", m_enableLogging, "[MINOR]");
      
      return newMinorFound;
   }

private:
   //--- تابع: اسکن اولیه برای یافتن حداقل یک سقف و یک کف مینور (از جدید به قدیم)
   void ScanInitialMinors()
   {
      int barsCount = iBars(m_symbol, m_timeframe);
      if (barsCount < 2 * m_aoFractalLength + 1) return; // حداقل کندل لازم موجود نیست
      
      int initialScanLimit = MathMin(200, barsCount - 1); // محدود به 100-200 کندل اخیر
      
      // کش کردن بافر AO برای اسکن اولیه
      double aoBuffer[];
      ArraySetAsSeries(aoBuffer, true);
      if (CopyBuffer(m_ao_handle, 0, 0, initialScanLimit + 1, aoBuffer) <= 0)
      {
         if (m_enableLogging) Print("[MINOR] خطا در کش کردن بافر AO برای اسکن اولیه: ", GetLastError());
         return;
      }
      
      bool foundHigh = false;
      bool foundLow = false;
      
      // اسکن از جدیدترین (shift کوچک) به قدیمی‌تر (shift بزرگ)
      for (int shift = m_aoFractalLength; shift <= initialScanLimit; shift++)
      {
         if (!foundHigh && IsAOFractalHigh(shift, aoBuffer))
         {
            SwingPoint adjusted = AdjustMinorPoint(shift, true);
            if (adjusted.bar_index != -1 && AddMinorPoint(adjusted, true))
            {
               foundHigh = true;
               m_lastHighTime = adjusted.time;
               if (m_enableLogging) LogEvent("سقف مینور اولیه شناسایی شد.", m_enableLogging, "[MINOR]");
            }
         }
         
         if (!foundLow && IsAOFractalLow(shift, aoBuffer))
         {
            SwingPoint adjusted = AdjustMinorPoint(shift, false);
            if (adjusted.bar_index != -1 && AddMinorPoint(adjusted, false))
            {
               foundLow = true;
               m_lastLowTime = adjusted.time;
               if (m_enableLogging) LogEvent("کف مینور اولیه شناسایی شد.", m_enableLogging, "[MINOR]");
            }
         }
         
         if (foundHigh && foundLow) break; // وقتی هر دو پیدا شد، اسکن را متوقف کن (بهینه‌سازی)
      }
      
      // اگر چیزی پیدا نشد، صبر تا حداقل کندل لازم و لاگ (بدون تکرار اسکن در سازنده)
      if (!foundHigh || !foundLow)
      {
         if (m_enableLogging) Print("[MINOR] در اسکن اولیه، مینور کامل پیدا نشد. منتظر کندل‌های بیشتر.");
      }
   }
   
   //--- تابع: اسکن برای سقف/کف مینور (از قدیم به جدید، با کش بافر)
   bool ScanForMinors(const double &aoBuffer[], const bool isHigh)
   {
      int barsCount = iBars(m_symbol, m_timeframe);
      datetime lastTime = isHigh ? m_lastHighTime : m_lastLowTime;
      int startShift = (lastTime == 0) ? barsCount - 1 : iBarShift(m_symbol, m_timeframe, lastTime, false);
      if (startShift < 0 || startShift < 2 * m_aoFractalLength + 1) return false; // بازه کافی نیست
      
      bool newFound = false;
      
      // اسکن از قدیمی‌ترین (startShift بزرگ) به جدیدترین (shift کوچک، تا m_aoFractalLength)
      for (int shift = startShift; shift >= m_aoFractalLength; shift--)
      {
         bool isFractal = isHigh ? IsAOFractalHigh(shift, aoBuffer) : IsAOFractalLow(shift, aoBuffer);
         if (isFractal)
         {
            SwingPoint adjusted = AdjustMinorPoint(shift, isHigh);
            if (adjusted.bar_index != -1 && AddMinorPoint(adjusted, isHigh))
            {
               if (isHigh) m_lastHighTime = adjusted.time;
               else m_lastLowTime = adjusted.time;
               newFound = true;
            }
         }
      }
      
      return newFound;
   }
   
   //--- تابع: بررسی شرط فرکتال برای سقف AO (بالاتر از اطراف، با کش بافر)
   bool IsAOFractalHigh(const int centerShift, const double &aoBuffer[]) const
   {
      if (centerShift < m_aoFractalLength || centerShift + m_aoFractalLength >= ArraySize(aoBuffer)) return false;
      
      double ao_center = aoBuffer[centerShift];
      if (ao_center == 0.0) return false;

      bool isHigh = true;
      
      for (int j = 1; j <= m_aoFractalLength; j++)
      {
         double left = aoBuffer[centerShift + j]; // چون ArraySetAsSeries(true)، shift بزرگ‌تر = قدیمی‌تر
         double right = aoBuffer[centerShift - j]; // shift کوچک‌تر = جدیدتر
         if (left == 0.0 || right == 0.0 || ao_center <= left || ao_center <= right)
         {
            isHigh = false;
            break;
         }
      }
      return isHigh;
   }
   
   //--- تابع: بررسی شرط فرکتال برای کف AO (پایین‌تر از اطراف، با کش بافر)
   bool IsAOFractalLow(const int centerShift, const double &aoBuffer[]) const
   {
      if (centerShift < m_aoFractalLength || centerShift + m_aoFractalLength >= ArraySize(aoBuffer)) return false;
      
      double ao_center = aoBuffer[centerShift];
      if (ao_center == 0.0) return false;

      bool isLow = true;
      
      for (int j = 1; j <= m_aoFractalLength; j++)
      {
         double left = aoBuffer[centerShift + j];
         double right = aoBuffer[centerShift - j];
         if (left == 0.0 || right == 0.0 || ao_center >= left || ao_center >= right)
         {
            isLow = false;
            break;
         }
      }
      return isLow;
   }
   
   //--- تابع کمکی جدید: بررسی فرکتال قیمتی ساده (نسبت به ۲ کندل چپ و راست)
   bool isPriceFractal(const int shift, const bool isHigh) const
   {
      if (shift < 2 || shift + 2 >= iBars(m_symbol, m_timeframe)) return false;
      
      if (isHigh)
      {
         double high_center = iHigh(m_symbol, m_timeframe, shift);
         bool isFractal = true;
         for (int j = 1; j <= 2; j++)
         {
            if (high_center <= iHigh(m_symbol, m_timeframe, shift - j) || high_center <= iHigh(m_symbol, m_timeframe, shift + j))
            {
               isFractal = false;
               break;
            }
         }
         return isFractal;
      }
      else
      {
         double low_center = iLow(m_symbol, m_timeframe, shift);
         bool isFractal = true;
         for (int j = 1; j <= 2; j++)
         {
            if (low_center >= iLow(m_symbol, m_timeframe, shift - j) || low_center >= iLow(m_symbol, m_timeframe, shift + j))
            {
               isFractal = false;
               break;
            }
         }
         return isFractal;
      }
   }
   
   //--- تابع بازنویسی شده: ریگلاژ قیمت در بازه اطراف (با جستجوی فرکتال قیمتی و استخراج body_price)
   SwingPoint AdjustMinorPoint(const int centerShift, const bool isHigh) const
   {
      SwingPoint result; result.price = isHigh ? 0 : DBL_MAX; result.body_price = isHigh ? 0 : DBL_MAX; result.time = 0; result.bar_index = -1;
      
      int start = centerShift - m_aoFractalLength;
      int end = centerShift + m_aoFractalLength;
      
      if (start < 0 || end >= iBars(m_symbol, m_timeframe)) return result; // جلوگیری از دسترسی خارج از محدوده
      
      SwingPoint bestFractal; bestFractal.price = isHigh ? 0 : DBL_MAX; bestFractal.time = 0; bestFractal.bar_index = -1;
      
      // مرحله اول: جستجو برای بهترین فرکتال قیمتی
      for (int i = start; i <= end; i++)
      {
         if (isPriceFractal(i, isHigh))
         {
            double extPrice = isHigh ? iHigh(m_symbol, m_timeframe, i) : iLow(m_symbol, m_timeframe, i);
            if ((isHigh && extPrice > bestFractal.price) || (!isHigh && extPrice < bestFractal.price))
            {
               bestFractal.price = extPrice;
               bestFractal.time = iTime(m_symbol, m_timeframe, i);
               bestFractal.bar_index = i;
            }
         }
      }
      
      // بررسی حیاتی: اگر هیچ فرکتالی پیدا نشد، برگردان خالی
      if (bestFractal.bar_index == -1) return result;
      
      // مرحله دوم: استخراج بالاترین/پایین‌ترین قیمت بدنه در پنجره
      double bestBodyPrice = isHigh ? 0 : DBL_MAX;
      for (int i = start; i <= end; i++)
      {
         double open_i = iOpen(m_symbol, m_timeframe, i);
         double close_i = iClose(m_symbol, m_timeframe, i);
         double bodyExt = isHigh ? MathMax(open_i, close_i) : MathMin(open_i, close_i);
         if ((isHigh && bodyExt > bestBodyPrice) || (!isHigh && bodyExt < bestBodyPrice))
         {
            bestBodyPrice = bodyExt;
         }
      }
      
      bestFractal.body_price = bestBodyPrice;
      
      if (m_enableLogging && bestFractal.bar_index != centerShift)
      {
         LogEvent((isHigh ? "سقف" : "کف") + " مینور: قیمت اولیه " + DoubleToString(isHigh ? iHigh(m_symbol, m_timeframe, centerShift) : iLow(m_symbol, m_timeframe, centerShift), _Digits) + 
                  " در زمان " + TimeToString(iTime(m_symbol, m_timeframe, centerShift)) + "، پس از ریگلاژ به " + DoubleToString(bestFractal.price, _Digits) + 
                  " (بدنه: " + DoubleToString(bestBodyPrice, _Digits) + ") در زمان " + TimeToString(bestFractal.time), m_enableLogging, "[MINOR]");
      }
      
      return bestFractal;
   }
   
   //--- تابع کمکی: بررسی کندل قوی (برای تایید EQ)
   bool IsStrongCandle(const int shift) const
   {
      double open = iOpen(m_symbol, m_timeframe, shift);
      double close = iClose(m_symbol, m_timeframe, shift);
      double high = iHigh(m_symbol, m_timeframe, shift);
      double low = iLow(m_symbol, m_timeframe, shift);
      
      double body = MathAbs(open - close);
      double range = high - low;
      
      // شرط قوی: بدنه بیش از 50% رنج کندل
      return (body > 0.5 * range);
   }
   
   //--- تابع جدید: پردازش ابطال الگوهای EQ تایید شده (مرگ بعد از زندگی)
   void ProcessEQInvalidation()
   {
      // حلقه را از آخر به اول می‌زنیم تا حذف کردن یک عنصر، باعث بهم ریختن اندیس‌ها نشود
      for (int i = ArraySize(m_eqPatterns_Array) - 1; i >= 0; i--)
      {
         EQPattern eq = m_eqPatterns_Array[i];

         // بازسازی زون واکنش الگو
         double zoneHigh = eq.isBullish ? eq.source_swing.body_price : eq.source_swing.price;
         double zoneLow = eq.isBullish ? eq.source_swing.price : eq.source_swing.body_price;

         bool isInvalidated = false;
         // شرط ابطال برای EQ نزولی (Double Top)
         if (!eq.isBullish && iClose(m_symbol, m_timeframe, 1) > zoneHigh)
         {
            isInvalidated = true;
         }
         // شرط ابطال برای EQ صعودی (Double Bottom)
         if (eq.isBullish && iClose(m_symbol, m_timeframe, 1) < zoneLow)
         {
            isInvalidated = true;
         }

         if (isInvalidated)
         {
            LogEvent("الگوی EQ در زمان " + TimeToString(eq.time_formation) + " با بسته شدن قیمت خارج از زون باطل شد.", m_enableLogging, "[MINOR]");

            // پاک کردن تمام اشیاء گرافیکی مربوط به این EQ
            //deleteEQObjects(eq); // کامنت شده برای حذف رسم تکراری برای
            string baseName = "Liq_EQ_Minor_" + TimeToString(eq.source_swing.time) + m_timeframeSuffix;
            string lineName = baseName + "_Line";
            string textName = baseName + "_Text";
            ObjectDelete(m_chartId, lineName);
            ObjectDelete(m_chartId, textName);

            // حذف الگو از آرایه حافظه
            ArrayRemove(m_eqPatterns_Array, i, 1);
         }
      }
   }
   
   //--- تابع اصلی: شناسایی الگوی EQ (بازنویسی شده با منطق کاندیدای فعال)
   void ProcessEQDetection()
   {
      // --- بخش ۱: ارزیابی کاندیدای سقف فعال (برای EQ نزولی) ---
      if (m_activeHighCandidate.bar_index != -1) // آیا اصلاً کاندیدای فعالی داریم؟
      {
         // شرط ابطال 1: آیا سقف جدیدتری از کاندیدای ما تشکیل شده؟
         if (GetMinorHighsCount() > 0 && GetMinorSwingHigh(0).time > m_activeHighCandidate.time)
         {
            LogEvent("کاندیدای سقف " + TimeToString(m_activeHighCandidate.time) + " توسط سقف جدیدتر باطل شد.", m_enableLogging, "[MINOR]");
            m_activeHighCandidate = GetMinorSwingHigh(0); // کاندیدا به سقف جدید آپدیت می‌شود
            return; // در این تیک کاری با این کاندیدا نداریم
         }

         // تعریف زون فرضی
         double zoneHigh = m_activeHighCandidate.price;
         double zoneLow = m_activeHighCandidate.body_price;

         // شرط ابطال 2: آیا کندل بسته شده فعلی بالای زون بسته شده؟
         if (iClose(m_symbol, m_timeframe, 1) > zoneHigh)
         {
            LogEvent("کاندیدای سقف " + TimeToString(m_activeHighCandidate.time) + " با بسته شدن قیمت بالای زون باطل شد.", m_enableLogging, "[MINOR]");
            m_activeHighCandidate.bar_index = -1; // کاندیدا غیرفعال می‌شود
            return;
         }

         // شرط ورود و تایید الگو
         if (iHigh(m_symbol, m_timeframe, 1) >= zoneLow) // آیا کندل فعلی وارد زون شده؟
         {
            // آیا کندل فعلی یک کندل تایید نزولی و قوی است؟
            if (iClose(m_symbol, m_timeframe, 1) < iOpen(m_symbol, m_timeframe, 1) && IsStrongCandle(1))
            {
               // الگو تایید شد!
               EQPattern newEQ;
               newEQ.isBullish = false;
               newEQ.time_formation = iTime(m_symbol, m_timeframe, 1); // زمان تایید
               newEQ.price_entry = iHigh(m_symbol, m_timeframe, 1); // High کندل تایید
               newEQ.source_swing = m_activeHighCandidate;

               // درج دستی به جای ArrayInsert
               int oldSize = ArraySize(m_eqPatterns_Array);
               ArrayResize(m_eqPatterns_Array, oldSize + 1);
               for (int j = oldSize; j > 0; j--)
               {
                  m_eqPatterns_Array[j] = m_eqPatterns_Array[j - 1];
               }
               m_eqPatterns_Array[0] = newEQ;

               // مدیریت ظرفیت (حداکثر 4)
               if (ArraySize(m_eqPatterns_Array) > 4)
               {
                  int lastIndex = ArraySize(m_eqPatterns_Array) - 1;
                  EQPattern oldestEQ = m_eqPatterns_Array[lastIndex];

                  LogEvent("ظرفیت EQ تکمیل. قدیمی‌ترین الگو در زمان " + TimeToString(oldestEQ.time_formation) + " حذف می‌شود.", m_enableLogging, "[MINOR]");

                  // پاک کردن اشیاء گرافیکی الگوی قدیمی با تابع کمکی
                  //deleteEQObjects(oldestEQ); // کامنت شده برای حذف رسم تکراری
                  string baseNameOld = "Liq_EQ_Minor_" + TimeToString(oldestEQ.source_swing.time) + m_timeframeSuffix;
                  string lineNameOld = baseNameOld + "_Line";
                  string textNameOld = baseNameOld + "_Text";
                  ObjectDelete(m_chartId, lineNameOld);
                  ObjectDelete(m_chartId, textNameOld);

                  // حذف از آرایه حافظه
                  ArrayRemove(m_eqPatterns_Array, lastIndex, 1);
               }
               
               //if (m_showDrawing) drawConfirmedEQ(m_eqPatterns_Array[0]); // کامنت شده برای حذف رسم تکراری
               LogEvent("الگوی EQ نزولی تایید و رسم شد.", m_enableLogging, "[MINOR]");

               m_activeHighCandidate.bar_index = -1; // کاندیدا پس از موفقیت، غیرفعال می‌شود
            }
         }
      }

      // --- بخش ۲: ارزیابی کاندیدای کف فعال (برای EQ صعودی) ---
      if (m_activeLowCandidate.bar_index != -1)
      {
         // شرط ابطال 1: آیا کف جدیدتری از کاندیدای ما تشکیل شده؟
         if (GetMinorLowsCount() > 0 && GetMinorSwingLow(0).time > m_activeLowCandidate.time)
         {
            LogEvent("کاندیدای کف " + TimeToString(m_activeLowCandidate.time) + " توسط کف جدیدتر باطل شد.", m_enableLogging, "[MINOR]");
            m_activeLowCandidate = GetMinorSwingLow(0); // کاندیدا به کف جدید آپدیت می‌شود
            return; // در این تیک کاری با این کاندیدا نداریم
         }

         // تعریف زون فرضی
         double zoneLow = m_activeLowCandidate.price;
         double zoneHigh = m_activeLowCandidate.body_price;

         // شرط ابطال 2: آیا کندل بسته شده فعلی پایین زون بسته شده؟
         if (iClose(m_symbol, m_timeframe, 1) < zoneLow)
         {
            LogEvent("کاندیدای کف " + TimeToString(m_activeLowCandidate.time) + " با بسته شدن قیمت پایین زون باطل شد.", m_enableLogging, "[MINOR]");
            m_activeLowCandidate.bar_index = -1; // کاندیدا غیرفعال می‌شود
            return;
         }

         // شرط ورود و تایید الگو
         if (iLow(m_symbol, m_timeframe, 1) <= zoneHigh) // آیا کندل فعلی وارد زون شده؟
         {
            // آیا کندل فعلی یک کندل تایید صعودی و قوی است؟
            if (iClose(m_symbol, m_timeframe, 1) > iOpen(m_symbol, m_timeframe, 1) && IsStrongCandle(1))
            {
               // الگو تایید شد!
               EQPattern newEQ;
               newEQ.isBullish = true;
               newEQ.time_formation = iTime(m_symbol, m_timeframe, 1); // زمان تایید
               newEQ.price_entry = iLow(m_symbol, m_timeframe, 1); // Low کندل تایید
               newEQ.source_swing = m_activeLowCandidate;

               // درج دستی به جای ArrayInsert
               int oldSize = ArraySize(m_eqPatterns_Array);
               ArrayResize(m_eqPatterns_Array, oldSize + 1);
               for (int j = oldSize; j > 0; j--)
               {
                  m_eqPatterns_Array[j] = m_eqPatterns_Array[j - 1];
               }
               m_eqPatterns_Array[0] = newEQ;

               // مدیریت ظرفیت (حداکثر 4)
               if (ArraySize(m_eqPatterns_Array) > 4)
               {
                  int lastIndex = ArraySize(m_eqPatterns_Array) - 1;
                  EQPattern oldestEQ = m_eqPatterns_Array[lastIndex];

                  LogEvent("ظرفیت EQ تکمیل. قدیمی‌ترین الگو در زمان " + TimeToString(oldestEQ.time_formation) + " حذف می‌شود.", m_enableLogging, "[MINOR]");

                  // پاک کردن اشیاء گرافیکی الگوی قدیمی با تابع کمکی
                  //deleteEQObjects(oldestEQ); // کامنت شده برای حذف رسم تکراری
                  string baseNameOld = "Liq_EQ_Minor_" + TimeToString(oldestEQ.source_swing.time) + m_timeframeSuffix;
                  string lineNameOld = baseNameOld + "_Line";
                  string textNameOld = baseNameOld + "_Text";
                  ObjectDelete(m_chartId, lineNameOld);
                  ObjectDelete(m_chartId, textNameOld);

                  // حذف از آرایه حافظه
                  ArrayRemove(m_eqPatterns_Array, lastIndex, 1);
               }
               
               //if (m_showDrawing) drawConfirmedEQ(m_eqPatterns_Array[0]); // کامنت شده برای حذف رسم تکراری
               LogEvent("الگوی EQ صعودی تایید و رسم شد.", m_enableLogging, "[MINOR]");

               m_activeLowCandidate.bar_index = -1; // کاندیدا پس از موفقیت، غیرفعال می‌شود
            }
         }
      }
   }
   
   //--- تابع ترسیمی: رسم نقطه مینور (فقط فلش کوچک و آفست، بدون زون)
   void drawMinorSwingPoint(const SwingPoint &sp, const bool isHigh)
   {
      string objName = (isHigh ? "Minor_H_" : "Minor_L_") + TimeToString(sp.time) + m_timeframeSuffix;
      ObjectDelete(m_chartId, objName);

      double offset = _Point * 50; // آفست کوچک برای قرارگیری بهتر
      double drawPrice = isHigh ? sp.price + offset : sp.price - offset;

      if (!ObjectCreate(m_chartId, objName, OBJ_ARROW, 0, sp.time, drawPrice))
      {
         if (m_enableLogging) Print("[MINOR] خطا در ایجاد شیء: ", GetLastError());
         return;
      }
      ObjectSetInteger(m_chartId, objName, OBJPROP_ARROWCODE, isHigh ? 217 : 218); // 217: فلش رو به پایین (سقف)، 218: فلش رو به بالا (کف)
      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(m_chartId, objName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(m_chartId, objName, OBJPROP_ANCHOR, isHigh ? ANCHOR_TOP : ANCHOR_BOTTOM);
   }
   
   //--- تابع جدید: رسم الگوی EQ تایید شده (زون خاکستری + خط چین + لیبل EQ)
   void drawConfirmedEQ(const EQPattern &eq)
   {
      // --- بخش اول: رسم زون خاکستری که حالا تایید شده ---
      string obName = "Confirmed_OB_" + TimeToString(eq.source_swing.time) + m_timeframeSuffix;
      datetime endTime = D'2030.01.01 00:00';
      color obColor = clrLightGray; // رنگ خاکستری روشن برای هر دو حالت
      double highZone = eq.isBullish ? eq.source_swing.body_price : eq.source_swing.price;
      double lowZone = eq.isBullish ? eq.source_swing.price : eq.source_swing.body_price;

    /*  ObjectCreate(m_chartId, obName, OBJ_RECTANGLE, 0, eq.source_swing.time, highZone, endTime, lowZone);
      ObjectSetInteger(m_chartId, obName, OBJPROP_COLOR, obColor);
      ObjectSetInteger(m_chartId, obName, OBJPROP_FILL, true);
      ObjectSetInteger(m_chartId, obName, OBJPROP_BACK, true);
*///کامنت شده تا فعلان زون رسم نشود 
      // --- بخش دوم: رسم خط چین و لیبل EQ ---
      string eqLineName = "EQ_Line_" + TimeToString(eq.time_formation) + m_timeframeSuffix;
      string eqTextName = "EQ_Text_" + TimeToString(eq.time_formation) + m_timeframeSuffix;
      color eqColor = eq.isBullish ? clrBlue : clrPink; // سبز برای کف، قرمز برای سقف

      // نقطه چین از سقف اصلی تا High/Low کندل تایید
      ObjectCreate(m_chartId, eqLineName, OBJ_TREND, 0, eq.source_swing.time, eq.source_swing.price, eq.time_formation, eq.price_entry);
      ObjectSetInteger(m_chartId, eqLineName, OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSetInteger(m_chartId, eqLineName, OBJPROP_COLOR, eqColor);
      ObjectSetInteger(m_chartId, eqLineName, OBJPROP_WIDTH, 1);

      // لیبل متن "EQ"
      double midPrice = (eq.source_swing.price + eq.price_entry) / 2;
      datetime midTime = eq.source_swing.time + (eq.time_formation - eq.source_swing.time) / 2;
      ObjectCreate(m_chartId, eqTextName, OBJ_TEXT, 0, midTime, midPrice);
      ObjectSetString(m_chartId, eqTextName, OBJPROP_TEXT, "EQ" + m_timeframeSuffix);
      ObjectSetInteger(m_chartId, eqTextName, OBJPROP_COLOR, eqColor);
      ObjectSetInteger(m_chartId, eqTextName, OBJPROP_ANCHOR, ANCHOR_CENTER);
   }
   
   //--- تابع کمکی جدید: پاک کردن تمام اشیاء گرافیکی مربوط به یک الگوی EQ
   void deleteEQObjects(const EQPattern &eq)
   {
      // ساختن نام دقیق آبجکت‌ها بر اساس اطلاعات الگو
      string obName = "Confirmed_OB_" + TimeToString(eq.source_swing.time) + m_timeframeSuffix;
      string eqLineName = "EQ_Line_" + TimeToString(eq.time_formation) + m_timeframeSuffix;
      string eqTextName = "EQ_Text_" + TimeToString(eq.time_formation) + m_timeframeSuffix;

      // حذف هر سه آبجکت از چارت
      ObjectDelete(m_chartId, obName);
      ObjectDelete(m_chartId, eqLineName);
      ObjectDelete(m_chartId, eqTextName);
   }
   
   //--- تابع جدید: شناسایی Order Block مینور بر اساس الگوریتم مشخص شده (با اصلاح منطق FVG)
   void IdentifyMinorOrderBlock(const SwingPoint &newSwing, const bool isHigh)
   {
      bool isBullish = !isHigh; // برای سقف جدید (isHigh=true)، OB نزولی (عرضه، isBullish=false) و بالعکس
      
      int startScan = newSwing.bar_index + 1; // شروع اسکن از کندل قبل از سوئینگ جدید
      int endScan = isHigh ? GetMinorSwingHigh(1).bar_index : GetMinorSwingLow(1).bar_index;
      
      if (endScan == -1 || startScan > endScan) return; // محدوده نامعتبر یا سوئینگ قبلی وجود ندارد
      
      // اسکن معکوس از جدیدتر (startScan) به قدیمی‌تر (endScan)
      for (int i = startScan; i <= endScan; i++)
      {
         bool candidate = false;

         if (isBullish) // OB صعودی (تقاضا) - پس از کف جدید (isHigh=false)
         {
            // شرط ۱: کندل نزولی (رنگ مخالف)
            if (iClose(m_symbol, m_timeframe, i) < iOpen(m_symbol, m_timeframe, i))
            {
               // شرط ۲: جمع‌آوری نقدینگی (Low پایین‌تر از Low کندل قبل)
               if (iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i + 1))
               {
                  candidate = true;

                  // شرط ۳: ایجاد گپ FVG ساده (اختیاری)
                  if (m_enableMinorOB_FVG_Check)
                  {
                     if (i < 2) candidate = false;
                     else if (iLow(m_symbol, m_timeframe, i - 2) <= iHigh(m_symbol, m_timeframe, i)) candidate = false;
                  }
               }
            }
         }
         else // OB نزولی (عرضه) - پس از سقف جدید (isHigh=true)
         {
            // شرط ۱: کندل صعودی (رنگ مخالف)
            if (iClose(m_symbol, m_timeframe, i) > iOpen(m_symbol, m_timeframe, i))
            {
               // شرط ۲: جمع‌آوری نقدینگی (High بالاتر از High کندل قبل)
               if (iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i + 1))
               {
                  candidate = true;

                  // شرط ۳: ایجاد گپ FVG ساده (اختیاری)
                  if (m_enableMinorOB_FVG_Check)
                  {
                     if (i < 2) candidate = false;
                     else if (iHigh(m_symbol, m_timeframe, i - 2) >= iLow(m_symbol, m_timeframe, i)) candidate = false;
                  }
               }
            }
         }

         if (candidate)
         {
            // ایجاد و اضافه کردن OB جدید
            OrderBlock newOB;
            newOB.isBullish = isBullish;
            newOB.highPrice = iHigh(m_symbol, m_timeframe, i);
            newOB.lowPrice = iLow(m_symbol, m_timeframe, i);
            newOB.time = iTime(m_symbol, m_timeframe, i);
            newOB.bar_index = i;

            AddMinorUnmitigatedOB(newOB);
            LogEvent("OB مینور جدید " + (isBullish ? "صعودی (تقاضا)" : "نزولی (عرضه)") + " در زمان " + TimeToString(newOB.time) + " شناسایی شد.", m_enableLogging, "[MINOR-OB]");
            break; // فقط اولین (جدیدترین) کاندیدا را انتخاب کن
         }
      }
   }
   
   //--- تابع جدید: اضافه کردن OB جدید به آرایه unmitigated مینور با مدیریت ظرفیت (حداکثر ۱۰)
   void AddMinorUnmitigatedOB(const OrderBlock &newOB)
   {
      // مدیریت ظرفیت: اگر بیش از ۱۰ شد، قدیمی‌ترین را حذف کن
      if (ArraySize(m_minorUnmitigatedOBs) >= 10)
      {
         int lastIndex = ArraySize(m_minorUnmitigatedOBs) - 1;
         ArrayRemove(m_minorUnmitigatedOBs, lastIndex, 1);
         LogEvent("ظرفیت unmitigated OB مینور تکمیل. قدیمی‌ترین OB حذف شد.", m_enableLogging, "[MINOR-OB]");
      }

      // درج دستی OB جدید در ابتدای آرایه (سری)
      int oldSize = ArraySize(m_minorUnmitigatedOBs);
      ArrayResize(m_minorUnmitigatedOBs, oldSize + 1);
      for (int j = oldSize; j > 0; j--)
      {
         m_minorUnmitigatedOBs[j] = m_minorUnmitigatedOBs[j - 1];
      }
      m_minorUnmitigatedOBs[0] = newOB;
   }
   
   //--- تابع جدید: اضافه کردن OB به آرایه mitigated مینور با مدیریت ظرفیت (حداکثر ۱۰)
   void AddMinorMitigatedOB(const OrderBlock &ob)
   {
      // مدیریت ظرفیت: اگر بیش از ۱۰ شد، قدیمی‌ترین را حذف کن
      if (ArraySize(m_minorMitigatedOBs) >= 10)
      {
         int lastIndex = ArraySize(m_minorMitigatedOBs) - 1;
         ArrayRemove(m_minorMitigatedOBs, lastIndex, 1);
         LogEvent("ظرفیت mitigated OB مینور تکمیل. قدیمی‌ترین OB مصرف شده حذف شد.", m_enableLogging, "[MINOR-OB]");
      }

      // درج دستی OB در ابتدای آرایه
      int oldSize = ArraySize(m_minorMitigatedOBs);
      ArrayResize(m_minorMitigatedOBs, oldSize + 1);
      for (int j = oldSize; j > 0; j--)
      {
         m_minorMitigatedOBs[j] = m_minorMitigatedOBs[j - 1];
      }
      m_minorMitigatedOBs[0] = ob;
   }
   
   //--- تابع جدید: مدیریت چرخه حیات OBهای مینور (میتگیشن و ابطال با قیمت‌های لحظه‌ای)
   void ProcessMinorOrderBlocks()
   {
      double currentAsk = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double currentBid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      m_isCurrentlyMitigatingMinorOB = false; // ریست وضعیت لحظه‌ای

      // مرحله ۱: چک میتگیشن (مصرف) برای OBهای unmitigated
      for (int i = 0; i < ArraySize(m_minorUnmitigatedOBs); i++)
      {
         OrderBlock ob = m_minorUnmitigatedOBs[i];
         bool mitigated = false;

         // چک وارد شدن قیمت به OB (میتگیشن)
         if (ob.isBullish && ob.lowPrice <= currentAsk && currentAsk <= ob.highPrice) mitigated = true;
         if (!ob.isBullish && ob.lowPrice <= currentBid && currentBid <= ob.highPrice) mitigated = true;

         if (mitigated)
         {
            // انتقال به آرایه mitigated
            AddMinorMitigatedOB(ob);
            m_isCurrentlyMitigatingMinorOB = true;

            // حذف از آرایه unmitigated
            ArrayRemove(m_minorUnmitigatedOBs, i, 1);
            i--;
            LogEvent("OB مینور " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " مصرف (mitigated) شد.", m_enableLogging, "[MINOR-OB]");
         }
      }

      // مرحله ۲: چک ابطال (invalidation) برای هر دو آرایه unmitigated و mitigated
      // اول unmitigated
      for (int i = 0; i < ArraySize(m_minorUnmitigatedOBs); i++)
      {
         OrderBlock ob = m_minorUnmitigatedOBs[i];
         bool invalidated = false;

         // چک عبور قیمت از OB (ابطال)
         if (ob.isBullish && currentBid < ob.lowPrice) invalidated = true;
         if (!ob.isBullish && currentAsk > ob.highPrice) invalidated = true;

         if (invalidated)
         {
            // حذف از آرایه (بدون پاک کردن گرافیکی، چون پیش‌فرض رسم نمی‌شود)
            ArrayRemove(m_minorUnmitigatedOBs, i, 1);
            i--;
            LogEvent("OB مینور " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " ابطال (invalidated) شد.", m_enableLogging, "[MINOR-OB]");
         }
      }

      // سپس mitigated
      for (int i = 0; i < ArraySize(m_minorMitigatedOBs); i++)
      {
         OrderBlock ob = m_minorMitigatedOBs[i];
         bool invalidated = false;

         // چک عبور قیمت از OB (ابطال)
         if (ob.isBullish && currentBid < ob.lowPrice) invalidated = true;
         if (!ob.isBullish && currentAsk > ob.highPrice) invalidated = true;

         if (invalidated)
         {
            // حذف از آرایه (بدون پاک کردن گرافیکی)
            ArrayRemove(m_minorMitigatedOBs, i, 1);
            i--;
            LogEvent("OB مینور مصرف شده " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " ابطال (invalidated) شد.", m_enableLogging, "[MINOR-OB]");
         }
      }
   }
   
   //--- تابع اصلاح شده: اضافه کردن نقطه مینور (با ورودی SwingPoint کامل و مدیریت تکرار و ظرفیت)
   bool AddMinorPoint(const SwingPoint &newPoint, const bool isHigh)
   {
      if (newPoint.time == 0 || newPoint.price == 0) return false;
      
      SwingPoint arr[];
      if (isHigh)
      {
         ArrayCopy(arr, m_minorSwingHighs_Array, 0, 0, WHOLE_ARRAY);
      }
      else
      {
         ArrayCopy(arr, m_minorSwingLows_Array, 0, 0, WHOLE_ARRAY);
      }
      
      // چک تکرار بر اساس زمان
      for (int j = 0; j < ArraySize(arr); j++)
      {
         if (arr[j].time == newPoint.time) return false;
      }
      
      if (isHigh)
      {
         int oldSize = ArraySize(m_minorSwingHighs_Array);
         ArrayResize(m_minorSwingHighs_Array, oldSize + 1);
         for (int j = oldSize; j > 0; j--)
         {
            m_minorSwingHighs_Array[j] = m_minorSwingHighs_Array[j - 1];
         }
         m_minorSwingHighs_Array[0] = newPoint;

         // مدیریت ظرفیت (حداکثر 10)
         if (ArraySize(m_minorSwingHighs_Array) > 10)
         {
            int lastIndex = ArraySize(m_minorSwingHighs_Array) - 1;
            if (m_showDrawing)
            {
               string objNameOld = "Minor_H_" + TimeToString(m_minorSwingHighs_Array[lastIndex].time) + m_timeframeSuffix;
               ObjectDelete(m_chartId, objNameOld);
            }
            ArrayRemove(m_minorSwingHighs_Array, lastIndex, 1);
         }
         
         if (m_showDrawing) drawMinorSwingPoint(newPoint, true);
         if (m_enableLogging) LogEvent("سقف مینور جدید در قیمت " + DoubleToString(newPoint.price, _Digits) + " شناسایی شد.", m_enableLogging, "[MINOR]");
         
         // آپدیت کاندیدای فعال
         m_activeHighCandidate = newPoint;
         LogEvent("سقف مینور " + TimeToString(newPoint.time) + " به عنوان کاندیدای فعال جدید برای EQ تنظیم شد.", m_enableLogging, "[MINOR]");
         
         // فراخوانی شناسایی OB مینور
         IdentifyMinorOrderBlock(newPoint, true);
         
         return true;
      }
      else
      {
         int oldSize = ArraySize(m_minorSwingLows_Array);
         ArrayResize(m_minorSwingLows_Array, oldSize + 1);
         for (int j = oldSize; j > 0; j--)
         {
            m_minorSwingLows_Array[j] = m_minorSwingLows_Array[j - 1];
         }
         m_minorSwingLows_Array[0] = newPoint;

         // مدیریت ظرفیت (حداکثر 10)
         if (ArraySize(m_minorSwingLows_Array) > 10)
         {
            int lastIndex = ArraySize(m_minorSwingLows_Array) - 1;
            if (m_showDrawing)
            {
               string objNameOld = "Minor_L_" + TimeToString(m_minorSwingLows_Array[lastIndex].time) + m_timeframeSuffix;
               ObjectDelete(m_chartId, objNameOld);
            }
            ArrayRemove(m_minorSwingLows_Array, lastIndex, 1);
         }
         
         if (m_showDrawing) drawMinorSwingPoint(newPoint, false);
         if (m_enableLogging) LogEvent("کف مینور جدید در قیمت " + DoubleToString(newPoint.price, _Digits) + " شناسایی شد.", m_enableLogging, "[MINOR]");
         
         // آپدیت کاندیدای فعال
         m_activeLowCandidate = newPoint;
         LogEvent("کف مینور " + TimeToString(newPoint.time) + " به عنوان کاندیدای فعال جدید برای EQ تنظیم شد.", m_enableLogging, "[MINOR]");
         
         // فراخوانی شناسایی OB مینور
         IdentifyMinorOrderBlock(newPoint, false);
         
         return true;
      }
      
      return false;
   }

public:
   //+------------------------------------------------------------------+
   //| تابع جدید: رسم خاص یک OB مینور (عنداللزوم)                     |
   //+------------------------------------------------------------------+
   void DrawSpecificMinorOB(const int index, const bool draw, const bool isUnmitigated)
   {
      OrderBlock ob;
      if (isUnmitigated)
      {
         if (index < 0 || index >= ArraySize(m_minorUnmitigatedOBs)) return;
         ob = m_minorUnmitigatedOBs[index];
      }
      else
      {
         if (index < 0 || index >= ArraySize(m_minorMitigatedOBs)) return;
         ob = m_minorMitigatedOBs[index];
      }

      string typeStr = ob.isBullish ? "Bullish" : "Bearish";
      string objName = "MinorOB_" + TimeToString(ob.time) + "_" + typeStr + m_timeframeSuffix;
      string textName = objName + "_Text";

      if (!draw)
      {
         ObjectDelete(m_chartId, objName);
         ObjectDelete(m_chartId, textName);
         return;
      }

      color obColor = C'245,245,245'; // سفید شفاف
      datetime endTime = D'2030.01.01 00:00'; // امتداد زون

      // ایجاد مستطیل
      ObjectCreate(m_chartId, objName, OBJ_RECTANGLE, 0, ob.time, ob.highPrice, endTime, ob.lowPrice);
      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, obColor);
      ObjectSetInteger(m_chartId, objName, OBJPROP_FILL, true);
      ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, true); // پشت کندل‌ها

      // محاسبه موقعیت اولیه وسط برای متن
      datetime currentTime = iTime(NULL, PERIOD_CURRENT, 0);
      datetime midTime = ob.time + (currentTime - ob.time) / 2;
      double midPrice = (ob.highPrice + ob.lowPrice) / 2;

      // ایجاد متن OB با پسوند شرطی
      string suffix = GetDisplaySuffix(m_timeframe, m_chartId);
      string text = isUnmitigated ? "MinorOB" + suffix : "MinorOB$" + suffix;
      ObjectCreate(m_chartId, textName, OBJ_TEXT, 0, midTime, midPrice);
      ObjectSetString(m_chartId, textName, OBJPROP_TEXT, text); 
      ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(m_chartId, textName, OBJPROP_FONTSIZE, BASE_LABEL_FONT_SIZE);
      ObjectSetInteger(m_chartId, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
   }
   
   //+------------------------------------------------------------------+
   //| توابع دسترسی عمومی (Accessors)                                  |
   //+------------------------------------------------------------------+
   SwingPoint GetMinorSwingHigh(const int index) const 
   { 
      if (index >= 0 && index < ArraySize(m_minorSwingHighs_Array)) return m_minorSwingHighs_Array[index]; 
      SwingPoint empty; empty.price = 0; empty.time = 0; empty.bar_index = -1; empty.body_price = 0; 
      return empty; 
   }
   
   SwingPoint GetMinorSwingLow(const int index) const 
   { 
      if (index >= 0 && index < ArraySize(m_minorSwingLows_Array)) return m_minorSwingLows_Array[index]; 
      SwingPoint empty; empty.price = 0; empty.time = 0; empty.bar_index = -1; empty.body_price = 0; 
      return empty; 
   }
   
   int GetMinorHighsCount() const { return ArraySize(m_minorSwingHighs_Array); }
   int GetMinorLowsCount() const { return ArraySize(m_minorSwingLows_Array); }
   
   //--- تعداد الگوهای EQ شناسایی شده را برمی‌گرداند
   int GetEQPatternCount() const { return ArraySize(m_eqPatterns_Array); }
   
   //--- یک الگوی EQ خاص را بر اساس اندیس برمی‌گرداند
   EQPattern GetEQPattern(const int index) const 
   { 
      if (index >= 0 && index < ArraySize(m_eqPatterns_Array)) return m_eqPatterns_Array[index]; 
      EQPattern empty; // برگرداندن یک ساختار خالی در صورت خطا
      return empty; 
   }

   //--- تابع جدید برای گرفتن آخرین EQ مینور تایید شده (برای سادگی کار CLiquidityManager)
   EQPattern GetLastEQPattern() const
   {
      if(ArraySize(m_eqPatterns_Array) > 0) return m_eqPatterns_Array[0];
      EQPattern empty; empty.time_formation = 0;
      return empty;
   }

   //--- توابع دسترسی به OBهای مینور مصرف نشده (unmitigated)
   int GetMinorUnmitigatedOBCount() const { return ArraySize(m_minorUnmitigatedOBs); }
   OrderBlock GetMinorUnmitigatedOB(const int index) const 
   { 
      if (index >= 0 && index < ArraySize(m_minorUnmitigatedOBs)) return m_minorUnmitigatedOBs[index]; 
      OrderBlock empty; empty.isBullish = false; empty.highPrice = 0; empty.lowPrice = 0; empty.time = 0; empty.bar_index = -1; 
      return empty; 
   }
   
   //--- توابع دسترسی به OBهای مینور مصرف شده (mitigated)
   int GetMinorMitigatedOBCount() const { return ArraySize(m_minorMitigatedOBs); }
   OrderBlock GetMinorMitigatedOB(const int index) const 
   { 
      if (index >= 0 && index < ArraySize(m_minorMitigatedOBs)) return m_minorMitigatedOBs[index]; 
      OrderBlock empty; empty.isBullish = false; empty.highPrice = 0; empty.lowPrice = 0; empty.time = 0; empty.bar_index = -1; 
      return empty; 
   }
   
   //--- وضعیت لحظه‌ای مصرف OB مینور
   bool IsCurrentlyMitigatingMinorOB() const { return m_isCurrentlyMitigatingMinorOB; }
};

//==================================================================//
//             کلاس ۴: مدیریت نقدینگی بازار (CLiquidityManager)     //
//==================================================================//
class CLiquidityManager
{
private:
   //--- وابستگی‌ها (تزریق شده از طریق سازنده)
   MarketStructure *m_major; // پوینتر به آبجکت ساختار ماژور
   MinorStructure  *m_minor; // پوینتر به آبجکت ساختار مینور

   //--- تنظیمات اصلی
   string           m_symbol;          // نماد معاملاتی
   ENUM_TIMEFRAMES  m_timeframe;       // تایم فریم اجرایی این آبجکت
   long             m_chartId;         // شناسه چارت
   bool             m_enableLogging;   // فعال/غیرفعال کردن لاگ‌ها
   string           m_timeframeSuffix; // پسوند تایم فریم برای نامگذاری اشیاء
   bool             m_showDrawing;     // کنترل کلی نمایش ترسیمات این کلاس

   //--- تنظیمات نمایش انواع نقدینگی (ورودی‌های سازنده)
   bool             m_drawEQ;          // نمایش EQ های ماژور و مینور
   bool             m_drawTraps;       // نمایش تله‌های SMS/CF
   bool             m_drawPDL;         // نمایش سقف/کف روزانه
   bool             m_drawPWL;         // نمایش سقف/کف هفتگی
   bool             m_drawPML;         // نمایش سقف/کف ماهانه
   bool             m_drawPYL;         // نمایش سقف/کف سالانه

   //--- آرایه تاریخچه رویدادهای نقدینگی
   LiquidityEvent   m_liquidityHistory[]; // آرایه سری، ظرفیت ۵۰

   //--- متغیرهای حالت برای ماشین حالت SMS/CF
   enum ENUM_SMS_CF_STATE {
      STATE_IDLE,                     // حالت بیکار، منتظر CHoCH
      STATE_WAITING_FOR_OPPOSING_BOS, // CHoCH رخ داده، منتظر BoS مخالف
      STATE_WAITING_FOR_CONFIRMING_BREAK // SMS تایید شده، منتظر شکست تایید کننده CF
   };
   ENUM_SMS_CF_STATE m_trapState;     // حالت فعلی ماشین
   datetime         m_lastKnownCHoCH;   // زمان آخرین CHoCH دیده شده در دنباله
   datetime         m_lastKnownBoS;     // زمان BoS مخالف (که SMS را تایید کرد)
   TREND_TYPE       m_preCHoCHTrend;    // روند ماژور *قبل* از CHoCH اولیه
   SwingPoint       m_sms_source_swing; // سوئینگ پوینت ماژوری که باعث CHoCH اولیه شد
   SwingPoint       m_cf_source_swing;  // سوئینگ پوینت ماژوری که باعث BoS مخالف شد

   //--- متغیرهای ردیابی برای جلوگیری از ثبت تکراری EQ
   datetime         m_lastSeenMajorEQTime; // زمان آخرین EQ ماژور ثبت شده
   datetime         m_lastSeenMinorEQTime; // زمان آخرین EQ مینور ثبت شده

   //--- متغیرهای ردیابی و ذخیره سطوح دوره‌ای
   datetime         m_lastDailyCheck;   // زمان آخرین به‌روزرسانی روزانه
   datetime         m_lastWeeklyCheck;  // زمان آخرین به‌روزرسانی هفتگی
   datetime         m_lastMonthlyCheck; // زمان آخرین به‌روزرسانی ماهانه
   datetime         m_lastYearlyCheck;  // زمان آخرین به‌روزرسانی سالانه
   // مقادیر سطوح قبلی
   double           m_pdl, m_pdh, m_pwl, m_pwh, m_pml, m_pmh, m_pyl, m_pyh;
   // نام اشیاء گرافیکی سطوح دوره‌ای (برای آپدیت/حذف آسان)
   string           m_pdhLineName, m_pdlLineName, m_pwhLineName, m_pwlLineName;
   string           m_pmhLineName, m_pmlLineName, m_pyhLineName, m_pylLineName;

   //--- متغیر کمکی برای اطمینان از اجرای ProcessNewBar
   datetime         m_lastProcessedBarTime;

   //--- تابع کمکی: ثبت رویداد نقدینگی
   void RegisterLiquidityEvent(ENUM_LIQUIDITY_TYPE type, bool isBullish, datetime time, double price, string desc, SwingPoint &source)
   {
      if (ArraySize(m_liquidityHistory) > 0 && m_liquidityHistory[0].type == type && m_liquidityHistory[0].time == time) return; // جلوگیری از تکرار
      
      LiquidityEvent newEvent;
      newEvent.type = type;
      newEvent.isBullish = isBullish;
      newEvent.time = time;
      newEvent.price = price;
      newEvent.description = desc;
      newEvent.source_swing = source;

      // مدیریت ظرفیت
      if (ArraySize(m_liquidityHistory) >= 50) ArrayRemove(m_liquidityHistory, 49, 1);

      // درج دستی
      int oldSize = ArraySize(m_liquidityHistory);
      ArrayResize(m_liquidityHistory, oldSize + 1);
      for (int j = oldSize; j > 0; j--)
      {
         m_liquidityHistory[j] = m_liquidityHistory[j - 1];
      }
      m_liquidityHistory[0] = newEvent;

      LogEvent("رویداد نقدینگی " + EnumToString(type) + " ثبت شد.", m_enableLogging, "[LIQ]");
   }

   //--- تابع کمکی: رسم سطوح دوره‌ای
   void DrawPeriodicLevel(double price, const string objName, const string label, color clr, ENUM_LINE_STYLE style, int width = 1)
   {
      ObjectDelete(m_chartId, objName);
      ObjectDelete(m_chartId, objName + "_Text");

      if (!ObjectCreate(m_chartId, objName, OBJ_HLINE, 0, 0, price)) return;

      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(m_chartId, objName, OBJPROP_STYLE, style);
      ObjectSetInteger(m_chartId, objName, OBJPROP_WIDTH, width);
      ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, true);

      if (ObjectCreate(m_chartId, objName + "_Text", OBJ_TEXT, 0, TimeCurrent() + PeriodSeconds() * 10, price))
      {
         string suffix = GetDisplaySuffix(m_timeframe, m_chartId);
         ObjectSetString(m_chartId, objName + "_Text", OBJPROP_TEXT, label + suffix);
         ObjectSetInteger(m_chartId, objName + "_Text", OBJPROP_COLOR, clr);
         ObjectSetInteger(m_chartId, objName + "_Text", OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
         ObjectSetInteger(m_chartId, objName + "_Text", OBJPROP_FONTSIZE, BASE_LABEL_FONT_SIZE - 1);
      }
   }

   //--- تابع کمکی: رسم رویداد EQ
   void DrawEQEvent(SwingPoint &source, datetime time_form, double price_entry, ENUM_LIQUIDITY_TYPE type, bool isMajor)
   {
      string baseName = "Liq_EQ_" + (isMajor ? "Major_" : "Minor_") + TimeToString(source.time) + m_timeframeSuffix;
      string lineName = baseName + "_Line"; string textName = baseName + "_Text";
      ObjectDelete(m_chartId, lineName); ObjectDelete(m_chartId, textName);
      color clr = (type == LIQ_EQL) ? clrBlue : clrPink;
      if (ObjectCreate(m_chartId, lineName, OBJ_TREND, 0, source.time, source.price, time_form, price_entry))
      {
         ObjectSetInteger(m_chartId, lineName, OBJPROP_STYLE, STYLE_DASHDOTDOT);
         ObjectSetInteger(m_chartId, lineName, OBJPROP_COLOR, clr);
         ObjectSetInteger(m_chartId, lineName, OBJPROP_WIDTH, 1);
      }
      double midPrice = (source.price + price_entry) / 2;
      datetime midTime = source.time + (time_form - source.time) / 2;

      double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      double verticalOffset = tickSize * VERTICAL_OFFSET_TICKS;
      bool isEQH = (type == LIQ_EQH);
      double textPrice = midPrice + (isEQH ? verticalOffset : -verticalOffset);

      // مدیریت همپوشانی
      while (IsPositionOccupied(m_chartId, midTime, textPrice, m_timeframe))
      {
         textPrice += (isEQH ? (verticalOffset / 2.0) : (-verticalOffset / 2.0));
      }

      int barStart = iBarShift(m_symbol, m_timeframe, source.time, false);
      int barEnd = iBarShift(m_symbol, m_timeframe, time_form, false);
      int candleDistance = MathAbs(barEnd - barStart);
      int fontSize = (candleDistance < DYNAMIC_SIZE_CANDLE_THRESHOLD) ? SMALL_LABEL_FONT_SIZE : BASE_LABEL_FONT_SIZE;

      if (ObjectCreate(m_chartId, textName, OBJ_TEXT, 0, midTime, textPrice))
      {
         string label = "";
         if (isMajor) {
            label = (type == LIQ_EQL) ? "EQLS" : "EQHS";
         } else {
            label = (type == LIQ_EQL) ? "EQL" : "EQH";
         }
         string suffix = GetDisplaySuffix(m_timeframe, m_chartId);
         ObjectSetString(m_chartId, textName, OBJPROP_TEXT, label + suffix);
         ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, clr);
         ObjectSetInteger(m_chartId, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
         ObjectSetInteger(m_chartId, textName, OBJPROP_FONTSIZE, fontSize);

         // چرخش متن بر اساس زاویه خط
         double deltaPricePoints = (price_entry - source.price) / SymbolInfoDouble(m_symbol, SYMBOL_POINT);
         double deltaTimeSeconds = (double)(time_form - source.time);
         if (deltaTimeSeconds != 0)
         {
            double angle_rad = atan2(deltaPricePoints * SymbolInfoDouble(m_symbol, SYMBOL_POINT) / tickSize, deltaTimeSeconds);
            double angle_deg = angle_rad * 180.0 / M_PI;
            ObjectSetDouble(m_chartId, textName, OBJPROP_ANGLE, -angle_deg);
         }
      }
   }

   //--- تابع کمکی: رسم رویداد تله (SMS/CF)
   void DrawTrapEvent(SwingPoint &source, ENUM_LIQUIDITY_TYPE type)
   { 
      string objName = "Liq_Trap_" + EnumToString(type) + "_" + TimeToString(source.time) + m_timeframeSuffix;
      ObjectDelete(m_chartId, objName);
      color clr = (type == LIQ_SMS) ? C'128,0,128' : C'255,140,0'; // Purple for SMS, Orange for CF
      double price = source.price + (type == LIQ_SMS ? 1 : -1) * 10 * _Point; // کمی آفست برای دیده شدن
      if (ObjectCreate(m_chartId, objName, OBJ_TEXT, 0, source.time, price))
      {
         string suffix = GetDisplaySuffix(m_timeframe, m_chartId);
         ObjectSetString(m_chartId, objName, OBJPROP_TEXT, (type == LIQ_SMS ? "SMS$" : "CF$") + suffix);
         ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, clr);
         ObjectSetInteger(m_chartId, objName, OBJPROP_ANCHOR, (type == LIQ_SMS ? ANCHOR_BOTTOM : ANCHOR_TOP));
         ObjectSetInteger(m_chartId, objName, OBJPROP_FONTSIZE, BASE_LABEL_FONT_SIZE);
      }
   }

   //--- تابع: به‌روزرسانی سطوح دوره‌ای
   bool UpdatePeriodicLevels()
   {
      bool changed = false;

      // روزانه
      if (m_drawPDL)
      {
         datetime currentDayStart = iTime(m_symbol, PERIOD_D1, 0);
         if (currentDayStart > m_lastDailyCheck)
         {
            m_lastDailyCheck = currentDayStart;
            double pdh = iHigh(m_symbol, PERIOD_D1, 1);
            double pdl = iLow(m_symbol, PERIOD_D1, 1);
            if (pdh != 0 && pdh != m_pdh)
            {
               m_pdh = pdh;
               SwingPoint emptySwing; // ساختار خالی برای فیلد source_swing
               RegisterLiquidityEvent(LIQ_PDH, false, currentDayStart, m_pdh, "PDH", emptySwing);
               DrawPeriodicLevel(m_pdh, m_pdhLineName, "PDH", clrGreen, STYLE_DOT);
               changed = true;
            }
            if (pdl != 0 && pdl != m_pdl)
            {
               m_pdl = pdl;
               SwingPoint emptySwing; // ساختار خالی برای فیلد source_swing
               RegisterLiquidityEvent(LIQ_PDL, true, currentDayStart, m_pdl, "PDL", emptySwing);
               DrawPeriodicLevel(m_pdl, m_pdlLineName, "PDL", clrRed, STYLE_DOT);
               changed = true;
            }
         }
      }

      // هفتگی
      if (m_drawPWL)
      {
         datetime currentWeekStart = iTime(m_symbol, PERIOD_W1, 0);
         if (currentWeekStart > m_lastWeeklyCheck)
         {
            m_lastWeeklyCheck = currentWeekStart;
            double pwh = iHigh(m_symbol, PERIOD_W1, 1);
            double pwl = iLow(m_symbol, PERIOD_W1, 1);
            if (pwh != 0 && pwh != m_pwh)
            {
               m_pwh = pwh;
               SwingPoint emptySwing;
               RegisterLiquidityEvent(LIQ_PWH, false, currentWeekStart, m_pwh, "PWH", emptySwing);
               DrawPeriodicLevel(m_pwh, m_pwhLineName, "PWH", clrDarkGreen, STYLE_DASHDOT);
               changed = true;
            }
            if (pwl != 0 && pwl != m_pwl)
            {
               m_pwl = pwl;
               SwingPoint emptySwing;
               RegisterLiquidityEvent(LIQ_PWL, true, currentWeekStart, m_pwl, "PWL", emptySwing);
               DrawPeriodicLevel(m_pwl, m_pwlLineName, "PWL", clrDarkRed, STYLE_DASHDOT);
               changed = true;
            }
         }
      }

      // ماهانه
      if (m_drawPML)
      {
         datetime currentMonthStart = iTime(m_symbol, PERIOD_MN1, 0);
         if (currentMonthStart > m_lastMonthlyCheck)
         {
            m_lastMonthlyCheck = currentMonthStart;
            double pmh = iHigh(m_symbol, PERIOD_MN1, 1);
            double pml = iLow(m_symbol, PERIOD_MN1, 1);
            if (pmh != 0 && pmh != m_pmh)
            {
               m_pmh = pmh;
               SwingPoint emptySwing;
               RegisterLiquidityEvent(LIQ_PMH, false, currentMonthStart, m_pmh, "PMH", emptySwing);
               DrawPeriodicLevel(m_pmh, m_pmhLineName, "PMH", clrForestGreen, STYLE_DASHDOTDOT);
               changed = true;
            }
            if (pml != 0 && pml != m_pml)
            {
               m_pml = pml;
               SwingPoint emptySwing;
               RegisterLiquidityEvent(LIQ_PML, true, currentMonthStart, m_pml, "PML", emptySwing);
               DrawPeriodicLevel(m_pml, m_pmlLineName, "PML", clrFireBrick, STYLE_DASHDOTDOT);
               changed = true;
            }
         }
      }

      // سالانه
      if (m_drawPYL)
      {
         MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
         int current_year_day = dt.day_of_year;
         datetime currentYearStart = TimeCurrent() - (TimeCurrent() % 31536000); // تقریبی شروع سال
         if (current_year_day < 5 && currentYearStart > m_lastYearlyCheck)
         {
            m_lastYearlyCheck = currentYearStart;
            MqlRates rates[];
            int copied = CopyRates(m_symbol, PERIOD_MN1, 1, 12, rates);
            if (copied == 12)
            {
               double yearlyHigh = 0, yearlyLow = DBL_MAX;
               for (int k = 0; k < 12; k++)
               {
                  if (rates[k].high > yearlyHigh) yearlyHigh = rates[k].high;
                  if (rates[k].low < yearlyLow) yearlyLow = rates[k].low;
               }
               if (yearlyHigh != 0 && yearlyHigh != m_pyh)
               {
                  m_pyh = yearlyHigh;
                  SwingPoint emptySwing;
                  RegisterLiquidityEvent(LIQ_PYH, false, currentYearStart, m_pyh, "PYH", emptySwing);
                  DrawPeriodicLevel(m_pyh, m_pyhLineName, "PYH", clrLimeGreen, STYLE_SOLID, 2);
                  changed = true;
               }
               if (yearlyLow != 0 && yearlyLow != m_pyl)
               {
                  m_pyl = yearlyLow;
                  SwingPoint emptySwing;
                  RegisterLiquidityEvent(LIQ_PYL, true, currentYearStart, m_pyl, "PYL", emptySwing);
                  DrawPeriodicLevel(m_pyl, m_pylLineName, "PYL", clrIndianRed, STYLE_SOLID, 2);
                  changed = true;
               }
            }
         }
      }
      return changed;
   }

   //--- تابع: اسکن برای EQ
   bool ScanForEQ()
   {
      bool changed = false;

      // چک EQ ماژور
      datetime processedMajorSourceTimes[];
      ArrayResize(processedMajorSourceTimes, 0);
      MajorEQPattern majorEq = m_major.GetLastMajorEQPattern();
      if (majorEq.time_formation > m_lastSeenMajorEQTime)
      {
         m_lastSeenMajorEQTime = majorEq.time_formation;
         ENUM_LIQUIDITY_TYPE type = majorEq.isBullish ? LIQ_EQL : LIQ_EQH;
         RegisterLiquidityEvent(type, majorEq.isBullish, majorEq.time_formation, majorEq.price_entry, "Major " + EnumToString(type), majorEq.source_swing);
         if (m_drawEQ && m_showDrawing) DrawEQEvent(majorEq.source_swing, majorEq.time_formation, majorEq.price_entry, type, true);
         int size = ArraySize(processedMajorSourceTimes);
         ArrayResize(processedMajorSourceTimes, size + 1);
         processedMajorSourceTimes[size] = majorEq.source_swing.time;
         changed = true;
      }

      // چک EQ مینور
      EQPattern minorEq = m_minor.GetLastEQPattern();
      if (minorEq.time_formation > m_lastSeenMinorEQTime)
      {
         bool overlap = false;
         for (int k = 0; k < ArraySize(processedMajorSourceTimes); k++)
         {
            if (processedMajorSourceTimes[k] == minorEq.source_swing.time)
            {
               overlap = true;
               break;
            }
         }
         if (!overlap)
         {
            ENUM_LIQUIDITY_TYPE type = minorEq.isBullish ? LIQ_EQL : LIQ_EQH;
            RegisterLiquidityEvent(type, minorEq.isBullish, minorEq.time_formation, minorEq.price_entry, "Minor " + EnumToString(type), minorEq.source_swing);
            if (m_drawEQ && m_showDrawing) DrawEQEvent(minorEq.source_swing, minorEq.time_formation, minorEq.price_entry, type, false);
            changed = true;
         } else {
            LogEvent("EQ مینور به دلیل همپوشانی با ماژور رسم نشد.", m_enableLogging, "[LIQ]");
         }
         m_lastSeenMinorEQTime = minorEq.time_formation; // همیشه آپدیت شود
      }

      return changed;
   }

   //--- تابع: اسکن برای تله‌های ساختاری
   bool ScanForStructuralTraps()
   {
      bool changed = false;
      datetime currentCHoCH = m_major.GetLastChoChTime();
      datetime currentBoS = m_major.GetLastBoSTime();
      TREND_TYPE currentTrend = m_major.GetCurrentTrend();
      SwingPoint lastHigh = m_major.GetLastSwingHigh();
      SwingPoint lastLow = m_major.GetLastSwingLow();

      switch (m_trapState)
      {
         case STATE_IDLE:
            if (currentCHoCH > m_lastKnownCHoCH && currentCHoCH > m_lastKnownBoS)
            {
               m_lastKnownCHoCH = currentCHoCH;
               m_preCHoCHTrend = (currentTrend == TREND_BULLISH) ? TREND_BEARISH : TREND_BULLISH;
               m_sms_source_swing = (currentTrend == TREND_BULLISH) ? m_major.GetSwingHigh(1) : m_major.GetSwingLow(1);
               if (m_sms_source_swing.time == 0) m_sms_source_swing = (currentTrend == TREND_BULLISH) ? lastHigh : lastLow;
               m_trapState = STATE_WAITING_FOR_OPPOSING_BOS;
               LogEvent("وضعیت تله به STATE_WAITING_FOR_OPPOSING_BOS تغییر یافت.", m_enableLogging, "[LIQ]");
            }
            break;
         case STATE_WAITING_FOR_OPPOSING_BOS:
            if (currentBoS > m_lastKnownCHoCH)
            {
               m_lastKnownBoS = currentBoS;
               if (currentTrend == m_preCHoCHTrend)
               {
                  RegisterLiquidityEvent(LIQ_SMS, (m_preCHoCHTrend == TREND_BULLISH), m_sms_source_swing.time, m_sms_source_swing.price, "SMS", m_sms_source_swing);
                  if (m_drawTraps && m_showDrawing) DrawTrapEvent(m_sms_source_swing, LIQ_SMS);
                  m_cf_source_swing = (currentTrend == TREND_BEARISH) ? m_major.GetSwingLow(1) : m_major.GetSwingHigh(1);
                  if (m_cf_source_swing.time == 0) m_cf_source_swing = (currentTrend == TREND_BEARISH) ? lastLow : lastHigh;
                  m_trapState = STATE_WAITING_FOR_CONFIRMING_BREAK;
                  changed = true;
                  LogEvent("تله SMS تایید شد.", m_enableLogging, "[LIQ]");
               }
               else
               {
                  m_trapState = STATE_IDLE;
                  LogEvent("تله SMS تایید نشد.", m_enableLogging, "[LIQ]");
               }
            }
            else if (currentCHoCH > m_lastKnownCHoCH)
            {
               m_lastKnownCHoCH = currentCHoCH;
               m_preCHoCHTrend = (currentTrend == TREND_BULLISH) ? TREND_BEARISH : TREND_BULLISH;
               m_sms_source_swing = (currentTrend == TREND_BULLISH) ? m_major.GetSwingHigh(1) : m_major.GetSwingLow(1);
               if (m_sms_source_swing.time == 0) m_sms_source_swing = (currentTrend == TREND_BULLISH) ? lastHigh : lastLow;
               m_trapState = STATE_WAITING_FOR_OPPOSING_BOS;
               LogEvent("تله ریست شد به دلیل CHoCH جدید.", m_enableLogging, "[LIQ]");
            }
            break;
         case STATE_WAITING_FOR_CONFIRMING_BREAK:
         {
            datetime latestBreak = MathMax(currentCHoCH, currentBoS);
            if (latestBreak > m_lastKnownBoS)
            {
               if (currentTrend != m_preCHoCHTrend)
               {
                  RegisterLiquidityEvent(LIQ_CF, (currentTrend == TREND_BULLISH), m_cf_source_swing.time, m_cf_source_swing.price, "CF", m_cf_source_swing);
                  if (m_drawTraps && m_showDrawing) DrawTrapEvent(m_cf_source_swing, LIQ_CF);
                  changed = true;
                  LogEvent("تله CF تایید شد.", m_enableLogging, "[LIQ]");
               }
               else
               {
                  LogEvent("تله CF تایید نشد.", m_enableLogging, "[LIQ]");
               }
               m_trapState = STATE_IDLE;
               if (currentCHoCH > m_lastKnownCHoCH) m_lastKnownCHoCH = currentCHoCH;
               if (currentBoS > m_lastKnownBoS) m_lastKnownBoS = currentBoS;
            }
            break;
      }}
      return changed;
   }

public:
   //+------------------------------------------------------------------+
   //| سازنده کلاس (Constructor)                                       |
   //+------------------------------------------------------------------+
   CLiquidityManager(MarketStructure *major_ptr, MinorStructure *minor_ptr,
                     const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId,
                     const bool enableLogging_in, const bool showDrawing_in,
                     const bool drawEQ_in, const bool drawTraps_in,
                     const bool drawPDL_in, const bool drawPWL_in,
                     const bool drawPML_in, const bool drawPYL_in)
   {
      if (CheckPointer(major_ptr) == POINTER_INVALID || CheckPointer(minor_ptr) == POINTER_INVALID)
      {
         LogEvent("خطای حیاتی: پوینترهای Major/Minor نامعتبر هستند!", true, "[LIQ]");
         return;
      }

      m_major = major_ptr;
      m_minor = minor_ptr;
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      m_enableLogging = enableLogging_in;
      m_showDrawing = showDrawing_in;
      m_drawEQ = drawEQ_in;
      m_drawTraps = drawTraps_in;
      m_drawPDL = drawPDL_in;
      m_drawPWL = drawPWL_in;
      m_drawPML = drawPML_in;
      m_drawPYL = drawPYL_in;

      m_timeframeSuffix = " (" + TimeFrameToStringShort(timeframe) + ")";

      ArraySetAsSeries(m_liquidityHistory, true);
      ArrayResize(m_liquidityHistory, 0, 50);

      m_trapState = STATE_IDLE;
      m_lastKnownCHoCH = 0;
      m_lastKnownBoS = 0;
      m_preCHoCHTrend = TREND_NONE;
      m_sms_source_swing.time = 0; m_sms_source_swing.bar_index = -1;
      m_cf_source_swing.time = 0; m_cf_source_swing.bar_index = -1;
      m_lastSeenMajorEQTime = 0;
      m_lastSeenMinorEQTime = 0;

      m_lastDailyCheck = 0; m_lastWeeklyCheck = 0; m_lastMonthlyCheck = 0; m_lastYearlyCheck = 0;
      m_pdl = 0; m_pdh = 0; m_pwl = 0; m_pwh = 0; m_pml = 0; m_pmh = 0; m_pyl = 0; m_pyh = 0;

      m_pdhLineName = "PeriodLevel_PDH" + m_timeframeSuffix;
      m_pdlLineName = "PeriodLevel_PDL" + m_timeframeSuffix;
      m_pwhLineName = "PeriodLevel_PWH" + m_timeframeSuffix;
      m_pwlLineName = "PeriodLevel_PWL" + m_timeframeSuffix;
      m_pmhLineName = "PeriodLevel_PMH" + m_timeframeSuffix;
      m_pmlLineName = "PeriodLevel_PML" + m_timeframeSuffix;
      m_pyhLineName = "PeriodLevel_PYH" + m_timeframeSuffix;
      m_pylLineName = "PeriodLevel_PYL" + m_timeframeSuffix;

      m_lastProcessedBarTime = 0;

      // پاکسازی اشیاء قبلی
      if (m_showDrawing)
      {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for (int i = total - 1; i >= 0; i--)
         {
            string name = ObjectName(m_chartId, i);
            if (StringFind(name, m_timeframeSuffix) != -1 && (StringFind(name, "Liq_") != -1 || StringFind(name, "PeriodLevel_") != -1))
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }

      LogEvent("کلاس CLiquidityManager برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.", m_enableLogging, "[LIQ]");
   }

   //+------------------------------------------------------------------+
   //| مخرب کلاس (Destructor)                                           |
   //+------------------------------------------------------------------+
   ~CLiquidityManager()
   {
      if (m_showDrawing)
      {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for (int i = total - 1; i >= 0; i--)
         {
            string name = ObjectName(m_chartId, i);
            if (StringFind(name, m_timeframeSuffix) != -1 && (StringFind(name, "Liq_") != -1 || StringFind(name, "PeriodLevel_") != -1))
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }
      LogEvent("کلاس CLiquidityManager متوقف شد.", m_enableLogging, "[LIQ]");
   }

   //+------------------------------------------------------------------+
   //| تابع اصلی: پردازش کندل بسته شده                                |
   //+------------------------------------------------------------------+
   bool ProcessNewBar()
   {
      datetime currentBarTime = iTime(m_symbol, m_timeframe, 0);
      if (currentBarTime == m_lastProcessedBarTime) return false;
      m_lastProcessedBarTime = currentBarTime;

      if (CheckPointer(m_major) == POINTER_INVALID || CheckPointer(m_minor) == POINTER_INVALID) return false;

      bool changed = false;
      changed |= UpdatePeriodicLevels();
      changed |= ScanForEQ();
      changed |= ScanForStructuralTraps();
      return changed;
   }

   //+------------------------------------------------------------------+
   //| توابع دسترسی عمومی (Accessors)                                  |
   //+------------------------------------------------------------------+
   int GetHistoryCount() const { return ArraySize(m_liquidityHistory); }

   LiquidityEvent GetEvent(const int index) const
   {
      if (index >= 0 && index < ArraySize(m_liquidityHistory)) return m_liquidityHistory[index];
      LiquidityEvent empty; empty.time = 0;
      return empty;
   }

   LiquidityEvent GetLastEvent() const
   {
      if (ArraySize(m_liquidityHistory) > 0) return m_liquidityHistory[0];
      LiquidityEvent empty; empty.time = 0;
      return empty;
   }

   LiquidityEvent GetLastEventByType(ENUM_LIQUIDITY_TYPE type) const
   {
      for (int i = 0; i < ArraySize(m_liquidityHistory); i++)
      {
         if (m_liquidityHistory[i].type == type) return m_liquidityHistory[i];
      }
      LiquidityEvent empty; empty.time = 0;
      return empty;
   }
};
//+------------------------------------------------------------------+
