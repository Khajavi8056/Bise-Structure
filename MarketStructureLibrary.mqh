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
#include <Arrays\ArrayObj.mqh>      // برای کار با آرایه آبجکت‌ها (CArrayObj)
#include <Arrays\ArrayString.mqh>   // برای کار با آرایه رشته‌ها (CArrayString)
#include <Arrays\ArrayLong.mqh>     // <<< این مهمه! برای کار با آرایه اعداد (CArrayLong)


//+------------------------------------------------------------------+
//| تنظیمات رنگ‌ها (برای تغییر آسان بدون جستجو در کد)               |
//+------------------------------------------------------------------+
const color COLOR_FVG_BULLISH = C'228,232,168'; // سبز کمرنگ برای FVG صعودی (شفاف/هاله)
const color COLOR_FVG_BEARISH = C'228,232,168'; // قرمز کمرنگ برای FVG نزولی (شفاف/هاله)
const color COLOR_OB_ZONE = C'224,213,103';     // سفید کمرنگ برای زون OB (شفاف/هاله)
const color COLOR_OB_TEXT = clrBlack;           // رنگ متن OB
const color COLOR_SWING_HIGH = clrBlack;   // رنگ سقف سوئینگ
const color COLOR_SWING_LOW = clrBlack;           // رنگ کف سوئینگ
const color COLOR_BREAK_CHoCH = clrBlack;     // رنگ شکست CHoCH
const color COLOR_BREAK_BoS_BULL = clrBlack ; // رنگ شکست BoS صعودی
const color COLOR_BREAK_BoS_BEAR = clrBlack;   // رنگ شکست BoS نزولی
const color COLOR_TREND_BULL = clrGreen;  // رنگ لیبل روند صعودی
const color COLOR_TREND_BEAR = clrOrangeRed;    // رنگ لیبل روند نزولی
const color COLOR_TREND_NONE = clrGray;         // رنگ لیبل بدون روند
const color COLOR_FIB_TRACK_BULL =  C'254,240,165'; // رنگ فیبو ردیاب صعودی
const color COLOR_FIB_TRACK_BEAR =  C'254,240,165';  // رنگ فیبو ردیاب نزولی
const color COLOR_LABEL_TEXT = clrBlack;    // رنگ متن لیبل‌ها
const color COLOR_MINOR_SWING = clrBlack;      // رنگ نقاط مینور
const color COLOR_EQ_BULL = clrBlack;            // رنگ EQ صعودی
const color COLOR_EQ_BEAR = clrAntiqueWhite;            // رنگ EQ نزولی
const color COLOR_EQ_ZONE = clrNONE;       // رنگ زون EQ
const color COLOR_SMS_TRAP = C'128,0,128';      // رنگ تله SMS
const color COLOR_CF_TRAP = C'255,140,0';       // رنگ تله CF
const color COLOR_PDH = clrBlack;               // رنگ PDH
const color COLOR_PDL = clrBlack;                 // رنگ PDL
const color COLOR_PWH = clrBlack;           // رنگ PWH
const color COLOR_PWL = clrBlack;             // رنگ PWL
const color COLOR_PMH = clrBlack;         // رنگ PMH
const color COLOR_PML = clrBlack;           // رنگ PML
const color COLOR_PYH = clrBlack;           // رنگ PYH
const color COLOR_PYL = clrBlack;           // رنگ PYL

//+------------------------------------------------------------------+
//| تنظیمات لاگ (سیستم لاگ حرفه‌ای و طبقه‌بندی شده)                 |
//+------------------------------------------------------------------+
enum LOG_LEVEL
{
   LOG_FULL,       // تمام لاگ‌ها (هر حرکت، محاسبه، اتفاق)
   LOG_PERFORMANCE,// لاگ‌های عملکردی مهم (بدون تکرار، مرتب مثل جدول)
   LOG_ERROR       // فقط خطاها و هشدارها
};

const LOG_LEVEL DEFAULT_LOG_LEVEL = LOG_PERFORMANCE; // سطح پیش‌فرض

// کدهای خطا (برای لاگ‌های خطا)
const int ERROR_CODE_101 = 101; // خطای دسترسی به داده (مثل iHigh/iLow)
const int ERROR_CODE_102 = 102; // خطای ایجاد آبجکت گرافیکی
const int ERROR_CODE_103 = 103; // خطای وابستگی کلاس (پوینتر نامعتبر)
const int ERROR_CODE_104 = 104; // خطای ظرفیت آرایه (over capacity)
const int ERROR_CODE_105 = 105; // خطای شناسایی ساختار (invalid detection)
const int ERROR_CODE_106 = 106; // خطای ابطال (invalidation error)
const int ERROR_CODE_107 = 107; // خطای هندل اندیکاتور
const int ERROR_CODE_108 = 108; // خطای کپی بافر
const int ERROR_CODE_109 = 109; // خطای همپوشانی لیبل

// کدهای عملکرد (برای لاگ‌های عملکردی)
const int PERF_CODE_201 = 201; // شناسایی FVG جدید
const int PERF_CODE_202 = 202; // ابطال FVG
const int PERF_CODE_203 = 203; // شناسایی سوئینگ جدید
const int PERF_CODE_204 = 204; // شکست ساختار (BoS/CHoCH)
const int PERF_CODE_205 = 205; // تغییر روند
const int PERF_CODE_206 = 206; // شناسایی OB جدید
const int PERF_CODE_207 = 207; // مصرف OB (mitigation)
const int PERF_CODE_208 = 208; // ابطال OB
const int PERF_CODE_209 = 209; // شناسایی EQ جدید
const int PERF_CODE_210 = 210; // ابطال EQ
const int PERF_CODE_211 = 211; // شناسایی مینور جدید
const int PERF_CODE_212 = 212; // به‌روزرسانی سطوح دوره‌ای
const int PERF_CODE_213 = 213; // شناسایی تله SMS/CF
const int PERF_CODE_214 = 214; // ثبت رویداد نقدینگی
 // آستانه تشخیص (مثلاً ۰.۶۶ یعنی سایه باید ۶۶٪ کل رنج باشه)
   const double      PINBAR_SHADOW_RATIO_THRESHOLD = 0.66;
   // آستانه بدنه (مثلاً ۰.۳۳ یعنی بدنه نباید از ۳۳٪ کل رنج بزرگتر باشه)
   const double      PINBAR_BODY_RATIO_THRESHOLD = 0.33;

//+------------------------------------------------------------------+
//| تابع لاگ مرکزی (با سطح‌بندی، کد و فرمت جدولی)                   |
//+------------------------------------------------------------------+
void CentralLog(const LOG_LEVEL level, const LOG_LEVEL currentLevel, const int code, const string prefix, const string message, const bool isError = false)
{
   if (currentLevel == LOG_ERROR && !isError) return; // فقط خطاها در سطح ERROR
   if (currentLevel == LOG_PERFORMANCE && level != LOG_PERFORMANCE && !isError) return; // فقط عملکردی و خطاها در سطح PERFORMANCE
   // در FULL همه چاپ می‌شوند

   string logType = isError ? "ERROR" : (level == LOG_PERFORMANCE ? "PERF" : "INFO");
   string timeStr = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   string codeStr = (code > 0) ? IntegerToString(code) : "-";
   string formatted = StringFormat("%s | %s | %s | %s | %s", timeStr, logType, codeStr, prefix, message);
   Print(formatted);
}

//+------------------------------------------------------------------+
//| تعاریف سراسری برای عناصر گرافیکی (برای خوانایی و زیبایی بصری)   |
//+------------------------------------------------------------------+
const int BASE_LABEL_FONT_SIZE = 8; // سایز فونت پایه برای اکثر لیبل‌ها
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
   datetime time;       // زمان کندل که نقطه محوری در آن تشکیل شده
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
   LOG_LEVEL        m_logLevel;             // سطح لاگ
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
      m_enableLogging = enableLogging_in;
      m_logLevel = DEFAULT_LOG_LEVEL;
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
      
      CentralLog(LOG_FULL, m_logLevel, 0, "[FVG]", "کلاس FVGManager برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.");
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
      CentralLog(LOG_FULL, m_logLevel, 0, "[FVG]", "کلاس FVGManager متوقف شد.");
   }
   
   //+------------------------------------------------------------------+
   //| توابع پردازش (Processing Methods)                                |
   //+------------------------------------------------------------------+
   
   //--- ۱. بررسی ابطال FVG در لحظه (با قیمت‌های ASK/BID) - هر تیک اجرا می‌شود
   bool ProcessNewTick()
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[FVG]", "شروع پردازش تیک جدید.");
      double currentAsk = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double currentBid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      bool invalidatedNow = false;

      // حلقه از جدیدترین (0) به قدیمی‌ترین (ArraySize-1) می‌رود
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_202, "[FVG]", "FVG از نوع " + typeStr + " در زمان " + TimeToString(m_fvgArray[i].time) + " ابطال و حذف شد.");
            ArrayRemove(m_fvgArray, i, 1);
            i--; // چون یک عنصر حذف شد، باید اندیس را یکی کم کنیم
            invalidatedNow = true;
         }
      }
      CentralLog(LOG_FULL, m_logLevel, 0, "[FVG]", "پایان پردازش تیک جدید.");
      return invalidatedNow;
   }
   
   //--- ۲. اجرای منطق FVG در کلوز کندل جدید
   bool ProcessNewBar()
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[FVG]", "شروع پردازش بار جدید.");
      bool newFVGFound = false;
      
      if (IdentifyFVG()) newFVGFound = true;
      if (m_showDrawing) UpdateFVGTexPositions(); // به‌روزرسانی موقعیت متن‌ها
      
      CentralLog(LOG_FULL, m_logLevel, 0, "[FVG]", "پایان پردازش بار جدید.");
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
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[FVG]", "ظرفیت FVG تکمیل. قدیمی‌ترین حذف شد.");
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
      CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[FVG]", "FVG جدید از نوع " + typeStr + " در زمان " + TimeToString(time) + " شناسایی شد.");
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

      color fvgColor = fvg.isBullish ? COLOR_FVG_BULLISH : COLOR_FVG_BEARISH;

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
      ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, COLOR_LABEL_TEXT);
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
   LOG_LEVEL        m_logLevel;             // سطح لاگ
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
      m_enableLogging = enableLogging_in;
      m_logLevel = DEFAULT_LOG_LEVEL;
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
       ChartSetInteger(0, CHART_SHOW_GRID, false);
  
   // تنظیم رنگ کندل‌ها
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrWhite);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrBlack);
   ChartSetInteger(0, CHART_COLOR_CHART_UP, clrBlack);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrBlack);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrBlack);
  ChartSetInteger(0,CHART_COLOR_BACKGROUND, C'254,240,165'); 
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "کلاس MarketStructure برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.");
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
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "کلاس MarketStructure متوقف شد.");
   }
   
   //+------------------------------------------------------------------+
   //| تابع جدید: پردازش تیک جدید برای مدیریت OB (میتگیشن و ابطال لحظه‌ای) |
   //+------------------------------------------------------------------+
   bool ProcessNewTick()
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "شروع پردازش تیک جدید برای OB.");
      ProcessOrderBlocks(); // فراخوانی مدیریت چرخه حیات OBها
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان پردازش تیک جدید برای OB.");
      return m_isCurrentlyMitigatingOB; // بازگشت وضعیت مصرف لحظه‌ای برای استفاده اکسپرت
   }
   
   //+------------------------------------------------------------------+
   //| تابع اصلی: پردازش کندل بسته شده (در OnTick با شرط NewBar فراخوانی شود) |
   //+------------------------------------------------------------------+
   bool ProcessNewBar()
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "شروع پردازش بار جدید.");
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

      //--- ۵. به‌روزرسانی موقعیت متن‌های OB
      if (m_showDrawing) UpdateOBTextPositions(); 
      
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان پردازش بار جدید.");
      return structureChanged;
   }

private:
     //این  ساختار اولیه فقط برای بار اول و یکبار برای شروع چرخش منطق نیاز هست و سیستم با اولین شکست ساختار  یک خود ترمیمی نهفته دارد و در صورت که ان فرکتال ساد اولیه هم اشتباه باشد  با اغولین شکست اصلاح 

   //--- شناسایی ساختار اولیه بازار (بر مبنای فرکتال)
   // توجه: این فرکتال اولیه فقط برای بار اول و شروع چرخه منطقی استفاده می‌شود. با اولین شکست (CHoCH/BoS) ساختار واقعی شکل می‌گیرد و اگر اولیه اشتباه باشد، با ساختار جدید جایگزین می‌شود.
   void IdentifyInitialStructure()
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "شروع شناسایی ساختار اولیه.");
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
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان شناسایی ساختار اولیه.");
   }
   
   //--- بررسی شکست سقف یا کف (BoS/CHoCH) و شناسایی OB بلافاصله پس از آن
   void CheckForBreakout()
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "شروع چک شکست ساختار.");
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
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[SMC]", ">>> رویداد: شکست سقف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد.");
         if (m_showDrawing) drawBreak(lastHigh, iTime(m_symbol, m_timeframe, 1), close_1, true, isCHoCH);

         m_pivotLowForTracking = FindOppositeSwing(lastHigh.time, iTime(m_symbol, m_timeframe, 1), false); 

         // شناسایی OB صعودی بلافاصله پس از یافتن پیوت
         IdentifyOrderBlock(true, iBarShift(m_symbol, m_timeframe, iTime(m_symbol, m_timeframe, 1), false), m_pivotLowForTracking.bar_index);

         m_isTrackingHigh = true; m_isTrackingLow = false;
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_203, "[SMC]", "-. فاز جدید: [شکار سقف] فعال شد. نقطه 100% فیبو (ثابت) در کف " + DoubleToString(m_pivotLowForTracking.price, _Digits) + " ثبت شد.");
      }
      //--- شکست کف (BoS/CHoCH نزولی) - شناسایی OB نزولی (عرضه)
      else if(close_1 < lastLow.price)
      {
         bool isCHoCH = (m_currentTrend == TREND_BULLISH);
         string breakType = isCHoCH ? "CHoCH" : "BoS";
         if (isCHoCH) m_lastCHoCHTime = iTime(m_symbol, m_timeframe, 1); else m_lastBoSTime = iTime(m_symbol, m_timeframe, 1);
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[SMC]", ">>> رویداد: شکست کف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد.");
         if (m_showDrawing) drawBreak(lastLow, iTime(m_symbol, m_timeframe, 1), close_1, false, isCHoCH);

         m_pivotHighForTracking = FindOppositeSwing(lastLow.time, iTime(m_symbol, m_timeframe, 1), true); 

         // شناسایی OB نزولی بلافاصله پس از یافتن پیوت
         IdentifyOrderBlock(false, iBarShift(m_symbol, m_timeframe, iTime(m_symbol, m_timeframe, 1), false), m_pivotHighForTracking.bar_index);

         m_isTrackingLow = true; m_isTrackingHigh = false;
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_203, "[SMC]", "-. فاز جدید: [شکار کف] فعال شد. نقطه 100% فیبو (ثابت) در سقف " + DoubleToString(m_pivotHighForTracking.price, _Digits) + " ثبت شد.");
      }
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان چک شکست ساختار.");
   }
   
   //--- تابع جدید: شناسایی Order Block بر اساس الگوریتم مشخص شده (با اصلاح منطق FVG)
   void IdentifyOrderBlock(const bool isBullish, const int breakBar, const int pivotBarIndex)
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC-OB]", "شروع شناسایی OB.");
      if (breakBar < 1 || pivotBarIndex < 0 || breakBar >= pivotBarIndex) {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_105, "[SMC-OB]", "محدوده نامعتبر برای شناسایی OB.", true);
         return;
      }

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
                     if (i < 2) candidate = false; // اطمینان از وجود کندل‌های کافی
                     else if (iLow(m_symbol, m_timeframe, i - 2) <= iHigh(m_symbol, m_timeframe, i)) candidate = false;// اگر همپوشانی وجود داشته باشد، رد کن (گپ باید کامل باشد: Low(i-2) > High(i))
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_206, "[SMC-OB]", "OB جدید " + (isBullish ? "صعودی (تقاضا)" : "نزولی (عرضه)") + " در زمان " + TimeToString(newOB.time) + " شناسایی شد.");
            break; // فقط اولین (جدیدترین) کاندیدا را انتخاب کن و حلقه را متوقف کن
         }
      }
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC-OB]", "پایان شناسایی OB.");
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
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[SMC-OB]", "ظرفیت unmitigated OB تکمیل. قدیمی‌ترین OB حذف شد.");
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
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC-OB]", "شروع پردازش چرخه حیات OB.");
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_207, "[SMC-OB]", "OB " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " مصرف (mitigated) شد.");
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_208, "[SMC-OB]", "OB " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " ابطال (invalidated) شد.");
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_208, "[SMC-OB]", "OB مصرف شده " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " ابطال (invalidated) شد.");
         }
      }
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC-OB]", "پایان پردازش چرخه حیات OB.");
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
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[SMC-OB]", "ظرفیت mitigated OB تکمیل. قدیمی‌ترین OB مصرف شده حذف شد.");
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
   
   //--- تابع جدید: رسم OB (با قابلیت MTF، مستطیل سفید شفاف و متن در وسط)
   void drawOrderBlock(const OrderBlock &ob)
   {
      string typeStr = ob.isBullish ? "Bullish" : "Bearish";
      string objName = "OB_" + TimeToString(ob.time) + "_" + typeStr + m_timeframeSuffix;
      string textName = objName + "_Text";

      color obColor = COLOR_OB_ZONE; // رنگ شفاف
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
      ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, COLOR_OB_TEXT);
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
   
   //--- تابع جدید: به‌روزرسانی موقعیت متن‌های OB برای ماندن در وسط زون
   void UpdateOBTextPositions()
   {
      datetime currentTime = iTime(NULL, PERIOD_CURRENT, 0); 

      // برای unmitigated OBها
      for (int i = 0; i < ArraySize(m_unmitigatedOBs); i++)
      {
         OrderBlock ob = m_unmitigatedOBs[i];
         string typeStr = ob.isBullish ? "Bullish" : "Bearish";
         string textName = "OB_" + TimeToString(ob.time) + "_" + typeStr + m_timeframeSuffix + "_Text";

         datetime midTime = ob.time + (currentTime - ob.time) / 2;
         double midPrice = (ob.highPrice + ob.lowPrice) / 2;

         ObjectMove(m_chartId, textName, 0, midTime, midPrice);
      }

      // برای mitigated OBها
      for (int i = 0; i < ArraySize(m_mitigatedOBs); i++)
      {
         OrderBlock ob = m_mitigatedOBs[i];
         string typeStr = ob.isBullish ? "Bullish" : "Bearish";
         string textName = "OB_" + TimeToString(ob.time) + "_" + typeStr + m_timeframeSuffix + "_Text";

         datetime midTime = ob.time + (currentTime - ob.time) / 2;
         double midPrice = (ob.highPrice + ob.lowPrice) / 2;

         ObjectMove(m_chartId, textName, 0, midTime, midPrice);
      }
   }

   //--- یافتن نقطه محوری مقابل (پیوت - 100% فیبو)
   SwingPoint FindOppositeSwing(const datetime brokenSwingTime, const datetime breakTime, const bool findHigh)
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "شروع یافتن پیوت مقابل.");
      double extremePrice = findHigh ? 0 : DBL_MAX;
      double extremeBodyPrice = findHigh ? 0 : DBL_MAX;
      datetime extremeTime = 0;
      int extremeIndex = -1;

      int startBar = iBarShift(m_symbol, m_timeframe, breakTime, false);
      int endBar = iBarShift(m_symbol, m_timeframe, brokenSwingTime, false);

      SwingPoint errorResult; errorResult.price = 0; errorResult.time = 0; errorResult.bar_index = -1; errorResult.body_price = 0;

      if(startBar == -1 || endBar == -1 || startBar >= endBar) {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_105, "[SMC]", "محدوده نامعتبر برای یافتن پیوت مقابل.", true);
         return errorResult;
      }

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
           CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان یافتن پیوت مقابل.");
           return result;
      }
      CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_105, "[SMC]", "پیوت مقابل پیدا نشد.", true);
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
       CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "شروع چک سوئینگ پوینت جدید.");
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

           if (close_1 <= fibLevel) // شرط تایی(بسته شدن در 35% یا پایین‌تر)
           {
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_203, "[SMC]", "<<< تایید شد: شرط اصلاح " + IntegerToString(m_fibUpdateLevel) + "٪ برای سقف جدید برقرار شد.");
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
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_203, "[SMC]", "<<< تایید شد: شرط اصلاح " + IntegerToString(m_fibUpdateLevel) + "٪ برای کف جدید برقرار شد.");
               AddSwingLow(current0Per.price, current0Per.time, current0Per.bar_index, current0Per.body_price);
               m_isTrackingLow = false;
               return true;
           }
       }
       CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان چک سوئینگ پوینت جدید.");
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
      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, isBullish ? COLOR_FIB_TRACK_BULL : COLOR_FIB_TRACK_BEAR);
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
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "شروع اضافه کردن سقف جدید.");
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
      CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_203, "[SMC-EQ]", "سقف ماژور " + TimeToString(m_swingHighs_Array[0].time) + " به عنوان کاندیدای EQ ماژور تنظیم شد.");

      if (m_showDrawing) drawSwingPoint(m_swingHighs_Array[0], true);
      CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_203, "[SMC]", "سقف جدید در قیمت " + DoubleToString(price, _Digits) + " ثبت شد.");
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان اضافه کردن سقف جدید.");
   }

   //--- اضافه کردن کف جدید و ترسیم آن 
   void AddSwingLow(const double price, const datetime time, const int bar_index, const double body_price)
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "شروع اضافه کردن کف جدید.");
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
      CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_203, "[SMC-EQ]", "کف ماژور " + TimeToString(m_swingLows_Array[0].time) + " به عنوان کاندیدای EQ ماژور تنظیم شد.");

      if (m_showDrawing) drawSwingPoint(m_swingLows_Array[0], false);
      CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_203, "[SMC]", "کف جدید در قیمت " + DoubleToString(price, _Digits) + " ثبت شد.");
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان اضافه کردن کف جدید.");
   }

   //--- به‌روزرسانی لیبل روند (با پسوند تایم فریم و موقعیت مناسب)
   bool UpdateTrendLabel()
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "شروع به‌روزرسانی لیبل روند.");
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
               trendColor = COLOR_TREND_BULL;
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_205, "[SMC]", "وضعیت روند به صعودی تغییر یافت.");
               break;
            }
            case TREND_BEARISH:
            {
               trendText = "Bearish Trend (LL/LH)";
               trendColor = COLOR_TREND_BEAR;
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_205, "[SMC]", "وضعیت روند به نزولی تغییر یافت.");
               break;
            }
            default:
            {
               trendText = "No Trend / Ranging";
               trendColor = COLOR_TREND_NONE;
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_205, "[SMC]", "وضعیت روند به بدون روند تغییر یافت.");
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

         ObjectSetInteger(m_chartId,m_trendObjectName, OBJPROP_COLOR, trendColor);
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_FONTSIZE, 12);
         CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان به‌روزرسانی لیبل روند.");
         return true;
      }
      CentralLog(LOG_FULL, m_logLevel, 0, "[SMC]", "پایان به‌روزرسانی لیبل روند بدون تغییر.");
      return false;
   }

   //--- ترسیم سقف/کف (با پسوند تایم فریم)
   void drawSwingPoint(const SwingPoint &sp, const bool isHigh)
   {
      string objName = (isHigh ? "H_" : "L_") + TimeToString(sp.time) + m_timeframeSuffix;
      ObjectDelete(m_chartId, objName);

      ObjectCreate(m_chartId, objName, OBJ_ARROW, 0, sp.time, sp.price);
      ObjectSetInteger(m_chartId, objName, OBJPROP_ARROWCODE, 77);
            ObjectSetInteger(m_chartId, objName, OBJPROP_WIDTH, 1);

      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, isHigh ? COLOR_SWING_HIGH : COLOR_SWING_LOW);
      ObjectSetInteger(m_chartId, objName, OBJPROP_ANCHOR, isHigh ? ANCHOR_BOTTOM : ANCHOR_TOP);
   }

   //--- ترسیم شکست (BoS/CHoCH) (با پسوند تایم فریم و شیفت زمانی)
   void drawBreak(const SwingPoint &brokenSwing, const datetime breakTime, const double breakPrice, const bool isHighBreak, const bool isCHoCH)
   {
       string breakType = isCHoCH ? "CHoCH" : "BoS";
       color breakColor = isCHoCH ? COLOR_BREAK_CHoCH : (isHighBreak ? COLOR_BREAK_BoS_BULL : COLOR_BREAK_BoS_BEAR);
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
       double verticalOffset = tickSize * VERTICAL_OFFSET_TICKS*2;
       double textPrice = midPrice + (isHighBreak ? verticalOffset : -verticalOffset);

       // مدیریت همپوشانی
       while (IsPositionOccupied(m_chartId, midTime, textPrice,m_timeframe))
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

      // حلقه از آخر به اول برای جلوگیری از بهم ریختن اندیس‌ها
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[SMC-EQ]", "الگوی EQ ماژور در زمان " + TimeToString(eq.time_formation) + " با بسته شدن قیمت خارج از زون باطل شد.");
            // پاک کردن اشیاء گرافیکی
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[SMC-EQ]", "کاندیدای سقف ماژور " + TimeToString(m_activeMajorHighCandidate.time) + " توسط سقف جدیدتر باطل شد.");
            m_activeMajorHighCandidate = GetSwingHigh(0); // کاندیدا به سقف جدید آپدیت می‌شود
            return; // در این تیک کاری با این کاندیدا نداریم
         }

         // تعریف زون فرضی
         double zoneHigh = m_activeMajorHighCandidate.price;
         double zoneLow = m_activeMajorHighCandidate.body_price;

         // شرط ابطال ۲: آیا کندل بسته شده فعلی بالای زون بسته شده؟
         if (iClose(m_symbol, m_timeframe, 1) > zoneHigh)
         {
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[SMC-EQ]", "کاندیدای سقف ماژور " + TimeToString(m_activeMajorHighCandidate.time) + " با بسته شدن قیمت بالای زون باطل شد.");
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

                  CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[SMC-EQ]", "ظرفیت EQ ماژور تکمیل. قدیمی‌ترین الگو در زمان " + TimeToString(oldestEQ.time_formation) + " حذف می‌شود.");

                  // پاک کردن اشیاء گرافیکی الگوی قدیمی
                  string baseNameOld = "Liq_EQ_Major_" + TimeToString(oldestEQ.source_swing.time) + m_timeframeSuffix;
                  string lineNameOld = baseNameOld + "_Line";
                  string textNameOld = baseNameOld + "_Text";
                  ObjectDelete(m_chartId, lineNameOld);
                  ObjectDelete(m_chartId, textNameOld);

                  // حذف از آرایه حافظه
                  ArrayRemove(m_majorEQPatterns_Array, lastIndex, 1);
               }
               
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_209, "[SMC-EQ]", "الگوی EQ ماژور نزولی تایید شد.");

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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[SMC-EQ]", "کاندیدای کف ماژور " + TimeToString(m_activeMajorLowCandidate.time) + " توسط کف جدیدتر باطل شد.");
            m_activeMajorLowCandidate = GetSwingLow(0); // کاندیدا به کف جدید آپدیت می‌شود
            return; // در این تیک کاری با این کاندیدا نداریم
         }

         // تعریف زون فرضی
         double zoneLow = m_activeMajorLowCandidate.price;
         double zoneHigh = m_activeMajorLowCandidate.body_price;

         // شرط ابطال ۲: آیا کندل بسته شده فعلی پایین زون بسته شده؟
         if (iClose(m_symbol, m_timeframe, 1) < zoneLow)
         {
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[SMC-EQ]", "کاندیدای کف ماژور " + TimeToString(m_activeMajorLowCandidate.time) + " با بسته شدن قیمت پایین زون باطل شد.");
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
               newEQ.price_entry = iLow(m_symbol, m_timeframe, 1); // Low کندل ورود به زون
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

                  CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[SMC-EQ]", "ظرفیت EQ ماژور تکمیل. قدیمی‌ترین الگو در زمان " + TimeToString(oldestEQ.time_formation) + " حذف می‌شود.");

                  // پاک کردن اشیاء گرافیکی الگوی قدیمی
                  string baseNameOld = "Liq_EQ_Major_" + TimeToString(oldestEQ.source_swing.time) + m_timeframeSuffix;
                  string lineNameOld = baseNameOld + "_Line";
                  string textNameOld = baseNameOld + "_Text";
                  ObjectDelete(m_chartId, lineNameOld);
                  ObjectDelete(m_chartId, textNameOld);

                  // حذف از آرایه حافظه
                  ArrayRemove(m_majorEQPatterns_Array, lastIndex, 1);
               }
               
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_209, "[SMC-EQ]", "الگوی EQ ماژور صعودی تایید شد.");

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
   
    //+------------------------------------------------------------------+
   
};

//==================================================================//
//             کلاس ۳: مدیریت ساختار مینور بازار (MinorStructure)    //
//==================================================================//

enum ENUM_MINOR_OSCILLATOR_TYPE
{
   OSC_MOMENTUM_WAVE, // OMW
   OSC_ACCEL_PULSE    // OAP
};


class MinorStructure
{
private:
   //--- متغیرهای تنظیمات و محیط اجرا
   string           m_symbol;               // نماد جفت ارز
   ENUM_TIMEFRAMES  m_timeframe;            // تایم فریم اختصاصی این آبجکت
   long             m_chartId;              // ID چارت اجرایی اکسپرت
   bool             m_enableLogging;        // فعال/غیرفعال بودن لاگ
   LOG_LEVEL        m_logLevel;             // سطح لاگ
   string           m_timeframeSuffix;      // پسوند تایم‌فریم کوتاه شده برای نامگذاری اشیاء
   bool             m_showDrawing;          // کنترل نمایش ترسیمات مینور روی چارت
   int              m_aoFractalLength;      // طول فرکتال AO/AC (تعداد میله‌های اطراف، مثلاً 3 یا 5) 
   bool             m_enableMinorOB_FVG_Check; // فعال/غیرفعال کردن شرط FVG برای شناسایی OB مینور (ورودی جدید سازنده)
   ENUM_MINOR_OSCILLATOR_TYPE m_oscillatorType;     // نوع اوسیلاتور انتخابی (AO یا AC)
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
  MinorStructure(const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId, const bool enableLogging_in, const bool showDrawing, const int fractalLength_in, const bool enableMinorOB_FVG_Check_in, const ENUM_MINOR_OSCILLATOR_TYPE oscType_in)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      m_enableLogging = enableLogging_in;
      m_logLevel = DEFAULT_LOG_LEVEL;
      m_showDrawing = showDrawing;
      m_aoFractalLength = fractalLength_in; // اسم ورودی برای وضوح بیشتر تغییر کرد
      m_enableMinorOB_FVG_Check = enableMinorOB_FVG_Check_in;
      m_oscillatorType = oscType_in; // ذخیره نوع اوسیلاتور انتخابی

      
      // تنظیم پسوند تایم فریم برای نمایش MTF (کوتاه شده)
      m_timeframeSuffix = " (" + TimeFrameToStringShort(timeframe) + ")";

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
       string oscName = (m_oscillatorType == OSC_MOMENTUM_WAVE) ? "AO (موج مومنتوم)" : "AC (پالس شتاب)";
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "اوسیلاتور فعال برای تشخیص مینور: " + oscName);
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "کلاس MinorStructure برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.");
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
            if(StringFind(name, m_timeframeSuffix) != -1 && (StringFind(name, "Minor_") != -1 || StringFind(name, "Confirmed_") != -1 || StringFind(name, "EQ_") != -1 || StringFind(name, "MinorOB_" ) != -1))
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "کلاس MinorStructure متوقف شد.");
   }
   
   //+------------------------------------------------------------------+
   //| تابع جدید: پردازش تیک جدید برای مدیریت OB مینور (میتگیشن و ابطال لحظه‌ای) |
   //+------------------------------------------------------------------+
   bool ProcessNewTick()
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR-OB]", "شروع پردازش تیک جدید برای OB مینور.");
      ProcessMinorOrderBlocks(); // فراخوانی مدیریت چرخه حیات OBهای مینور
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR-OB]", "پایان پردازش تیک جدید برای OB مینور.");
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

      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "شروع پردازش بار جدید.");

      bool newMinorFound = false;
      
      // اسکن برای سقف‌های مینور
      newMinorFound |= ScanForMinors(true);
      
      // اسکن برای کف‌های مینور
      newMinorFound |= ScanForMinors(false);
      
      // ابطال الگوهای EQ تایید شده (مرگ بعد از زندگی)
      ProcessEQInvalidation();
      
      // شناسایی الگوی EQ جدید
      ProcessEQDetection();
      
      if (newMinorFound)
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_211, "[MINOR]", "مینور جدید شناسایی شد.");

      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "پایان پردازش بار جدید.");
      return newMinorFound;
   }

private:
   //--- تابع: اسکن اولیه برای یافتن حداقل یک سقف و یک کف مینور (از جدید به قدیم)
   void ScanInitialMinors()
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "شروع اسکن اولیه مینورها.");
      int barsCount = iBars(m_symbol, m_timeframe);
      if (barsCount < 2 * m_aoFractalLength + 1) return; // حداقل کندل لازم موجود نیست
      
      int initialScanLimit = MathMin(200, barsCount - 1); // محدود به 100-200 کندل اخیر
      
      bool foundHigh = false;
      bool foundLow = false;
      
      // اسکن از جدیدترین (shift small) به قدیمی‌تر (shift large)
      for (int shift = m_aoFractalLength; shift <= initialScanLimit; shift++)
      {
         if (!foundHigh && IsOscillatorFractalHigh(shift))
         {
            SwingPoint adjusted = AdjustMinorPoint(shift, true);
            if (adjusted.bar_index != -1 && AddMinorPoint(adjusted, true))
            {
               foundHigh = true;
               m_lastHighTime = adjusted.time;
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_211, "[MINOR]", "سقف مینور اولیه شناسایی شد.");
            }
         }
         
         if (!foundLow && IsOscillatorFractalLow(shift))
         {
            SwingPoint adjusted = AdjustMinorPoint(shift, false);
            if (adjusted.bar_index != -1 && AddMinorPoint(adjusted, false))
            {
               foundLow = true;
               m_lastLowTime = adjusted.time;
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_211, "[MINOR]", "کف مینور اولیه شناسایی شد.");
            }
         }
         
         if (foundHigh && foundLow) break; // وقتی هر دو پیدا شد، اسکن را متوقف کن (بهینه‌سازی)
      }
      
      // اگر چیزی پیدا نشد، صبر تا حداقل کندل لازم و لاگ (بدون تکرار اسکن در سازنده)
      if (!foundHigh || !foundLow)
      {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_105, "[MINOR]", "در اسکن اولیه، مینور کامل پیدا نشد. منتظر کندل‌های بیشتر.", true);
      }
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "پایان اسکن اولیه مینورها.");
   }
   
   //--- تابع: اسکن برای سقف/کف مینور (از قدیم به جدید)
   bool ScanForMinors(const bool isHigh)
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "شروع اسکن مینورها.");
      int barsCount = iBars(m_symbol, m_timeframe);
      datetime lastTime = isHigh ? m_lastHighTime : m_lastLowTime;
      int startShift = (lastTime == 0) ? barsCount - 1 : iBarShift(m_symbol, m_timeframe, lastTime, false);
      if (startShift < 0 || startShift < 2 * m_aoFractalLength + 1) return false; // بازه کافی نیست
      
      bool newFound = false;
      
      // اسکن از قدیمی‌ترین (startShift بزرگ) به جدیدترین (shift کوچک، تا m_aoFractalLength)
      for (int shift = startShift; shift >= m_aoFractalLength; shift--)
      {
         bool isFractal = isHigh ? IsOscillatorFractalHigh(shift) : IsOscillatorFractalLow(shift);
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
      
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "پایان اسکن مینورها.");
      return newFound;
   }
   
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

   
   //--- تابع کمکی جدید: بررسی فرکتال قیمتی ساده (نسبت به ۲ کندل چپ و راست)
   bool isPriceFractal(const int shift, const bool isHigh) const
   {
      if (shift < 3 || shift + 3 >= iBars(m_symbol, m_timeframe)) return false;
      
      if (isHigh)
      {
         double high_center = iHigh(m_symbol, m_timeframe, shift);
         bool isFractal = true;
         for (int j = 1; j <= 3; j++)
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
         for (int j = 1; j <= 3; j++)
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
            bestBodyPrice = bodyExt;
      }
      
      bestFractal.body_price = bestBodyPrice;
      
      if (bestFractal.bar_index != centerShift)
      {
         CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", (isHigh ? "سقف" : "کف") + " مینور: قیمت اولیه " + DoubleToString(isHigh ? iHigh(m_symbol, m_timeframe, centerShift) : iLow(m_symbol, m_timeframe, centerShift), _Digits) + 
                  " در زمان " + TimeToString(iTime(m_symbol, m_timeframe, centerShift)) + "، پس از ریگلاژ به " + DoubleToString(bestFractal.price, _Digits) + 
                  " (بدنه: " + DoubleToString(bestBodyPrice, _Digits) + ") در زمان " + TimeToString(bestFractal.time));
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[MINOR]", "الگوی EQ در زمان " + TimeToString(eq.time_formation) + " با بسته شدن قیمت خارج از زون باطل شد.");

            // پاک کردن تمام اشیاء گرافیکی مربوط به این EQ
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[MINOR]", "کاندیدای سقف " + TimeToString(m_activeHighCandidate.time) + " توسط سقف جدیدتر باطل شد.");
            m_activeHighCandidate = GetMinorSwingHigh(0); // کاندیدا به سقف جدید آپدیت می‌شود
            return; // در این تیک کاری با این کاندیدا نداریم
         }

         // تعریف زون فرضی
         double zoneHigh = m_activeHighCandidate.price;
         double zoneLow = m_activeHighCandidate.body_price;

         // شرط ابطال 2: آیا کندل بسته شده فعلی بالای زون بسته شده؟
         if (iClose(m_symbol, m_timeframe, 1) > zoneHigh)
         {
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[MINOR]", "کاندیدای سقف " + TimeToString(m_activeHighCandidate.time) + " با بسته شدن قیمت بالای زون باطل شد.");
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

                  CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[MINOR]", "ظرفیت EQ تکمیل. قدیمی‌ترین الگو در زمان " + TimeToString(oldestEQ.time_formation) + " حذف می‌شود.");

                  // پاک کردن اشیاء گرافیکی الگوی قدیمی با تابع کمکی
                  string baseNameOld = "Liq_EQ_Minor_" + TimeToString(oldestEQ.source_swing.time) + m_timeframeSuffix;
                  string lineNameOld = baseNameOld + "_Line";
                  string textNameOld = baseNameOld + "_Text";
                  ObjectDelete(m_chartId, lineNameOld);
                  ObjectDelete(m_chartId, textNameOld);

                  // حذف از آرایه حافظه
                  ArrayRemove(m_eqPatterns_Array, lastIndex, 1);
               }
               
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_209, "[MINOR]", "الگوی EQ نزولی تایید شد.");

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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[MINOR]", "کاندیدای کف " + TimeToString(m_activeLowCandidate.time) + " توسط کف جدیدتر باطل شد.");
            m_activeLowCandidate = GetMinorSwingLow(0); // کاندیدا به کف جدید آپدیت می‌شود
            return; // در این تیک کاری با این کاندیدا نداریم
         }

         // تعریف زون فرضی
         double zoneLow = m_activeLowCandidate.price;
         double zoneHigh = m_activeLowCandidate.body_price;

         // شرط ابطال 2: آیا کندل بسته شده فعلی پایین زون بسته شده؟
         if (iClose(m_symbol, m_timeframe, 1) < zoneLow)
         {
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_210, "[MINOR]", "کاندیدای کف " + TimeToString(m_activeLowCandidate.time) + " با بسته شدن قیمت پایین زون باطل شد.");
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

                  CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[MINOR]", "ظرفیت EQ تکمیل. قدیمی‌ترین الگو در زمان " + TimeToString(oldestEQ.time_formation) + " حذف می‌شود.");

                  // پاک کردن اشیاء گرافیکی الگوی قدیمی با تابع کمکی
                  string baseNameOld = "Liq_EQ_Minor_" + TimeToString(oldestEQ.source_swing.time) + m_timeframeSuffix;
                  string lineNameOld = baseNameOld + "_Line";
                  string textNameOld = baseNameOld + "_Text";
                  ObjectDelete(m_chartId, lineNameOld);
                  ObjectDelete(m_chartId, textNameOld);

                  // حذف از آرایه حافظه
                  ArrayRemove(m_eqPatterns_Array, lastIndex, 1);
               }
               
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_209, "[MINOR]", "الگوی EQ صعودی تایید شد.");

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
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_102, "[MINOR]", "خطا در ایجاد شیء: " + IntegerToString(GetLastError()), true);
         return;
      }
      ObjectSetInteger(m_chartId, objName, OBJPROP_ARROWCODE, isHigh ? 218 : 217); // 217: فلش رو به پایین (سقف)، 218: فلش رو به بالا (کف)
      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, COLOR_MINOR_SWING);
      ObjectSetInteger(m_chartId, objName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(m_chartId, objName, OBJPROP_ANCHOR, isHigh ? ANCHOR_TOP : ANCHOR_BOTTOM);
   }
   
   //--- تابع جدید: رسم الگوی EQ تایید شده (زون خاکستری + خط چین + لیبل EQ)
   void drawConfirmedEQ(const EQPattern &eq)
   {
      // --- بخش اول: رسم زون خاکستری که حالا تایید شده ---
      string obName = "Confirmed_OB_" + TimeToString(eq.source_swing.time) + m_timeframeSuffix;
      datetime endTime = D'2030.01.01 00:00';
      color obColor = COLOR_EQ_ZONE; // رنگ خاکستری روشن برای هر دو حالت
      double highZone = eq.isBullish ? eq.source_swing.body_price : eq.source_swing.price;
      double lowZone = eq.isBullish ? eq.source_swing.price : eq.source_swing.body_price;

      ObjectCreate(m_chartId, obName, OBJ_RECTANGLE, 0, eq.source_swing.time, highZone, endTime, lowZone);
      ObjectSetInteger(m_chartId, obName, OBJPROP_COLOR, obColor);
      ObjectSetInteger(m_chartId, obName, OBJPROP_FILL, true);
      ObjectSetInteger(m_chartId, obName, OBJPROP_BACK, true);

      // --- بخش دوم: رسم خط چین و لیبل EQ ---
      string eqLineName = "EQ_Line_" + TimeToString(eq.time_formation) + m_timeframeSuffix;
      string eqTextName = "EQ_Text_" + TimeToString(eq.time_formation) + m_timeframeSuffix;
      color eqColor = eq.isBullish ? COLOR_EQ_BULL : COLOR_EQ_BEAR; // سبز برای کف، قرمز برای سقف

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
      string obName = "Confirmed_OB_" + TimeToString(eq.source_swing.time) + m_timeframeSuffix;
      string eqLineName = "EQ_Line_" + TimeToString(eq.time_formation) + m_timeframeSuffix;
      string eqTextName = "EQ_Text_" + TimeToString(eq.time_formation) + m_timeframeSuffix;

      ObjectDelete(m_chartId, obName);
      ObjectDelete(m_chartId, eqLineName);
      ObjectDelete(m_chartId, eqTextName);
   }
   
   //--- تابع جدید: شناسایی Order Block مینور بر اساس الگوریتم مشخص شده (با اصلاح منطق FVG)
   void IdentifyMinorOrderBlock(const SwingPoint &newSwing, const bool isHigh)
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR-OB]", "شروع شناسایی OB مینور.");
      bool isBullish = !isHigh; // برای سقف جدید (isHigh=true)، OB نزولی (عرضه، isBullish=false) و بالعکس
      
      int startScan = newSwing.bar_index + 1; // شروع اسکن از کندل قبل از سوئینگ جدید
      int endScan = isHigh ? GetMinorSwingHigh(1).bar_index : GetMinorSwingLow(1).bar_index;
      
      if (endScan == -1 || startScan > endScan) {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_105, "[MINOR-OB]", "محدوده نامعتبر برای شناسایی OB مینور.", true);
         return; // محدوده نامعتبر یا سوئینگ قبلی وجود ندارد
      }
      
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_206, "[MINOR-OB]", "OB مینور جدید " + (isBullish ? "صعودی (تقاضا)" : "نزولی (عرضه)") + " در زمان " + TimeToString(newOB.time) + " شناسایی شد.");
            break; // فقط اولین (جدیدترین) کاندیدا را انتخاب کن
         }
      }
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR-OB]", "پایان شناسایی OB مینور.");
   }
   
   //--- تابع جدید: اضافه کردن OB جدید به آرایه unmitigated مینور با مدیریت ظرفیت (حداکثر ۱۰)
   void AddMinorUnmitigatedOB(const OrderBlock &newOB)
   {
      // مدیریت ظرفیت: اگر بیش از ۱۰ شد، قدیمی‌ترین را حذف کن
      if (ArraySize(m_minorUnmitigatedOBs) >= 10)
      {
         int lastIndex = ArraySize(m_minorUnmitigatedOBs) - 1;
         ArrayRemove(m_minorUnmitigatedOBs, lastIndex, 1);
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[MINOR-OB]", "ظرفیت unmitigated OB مینور تکمیل. قدیمی‌ترین OB حذف شد.");
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
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_204, "[MINOR-OB]", "ظرفیت mitigated OB مینور تکمیل. قدیمی‌ترین OB مصرف شده حذف شد.");
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_207, "[MINOR-OB]", "OB مینور " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " مصرف (mitigated) شد.");
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_208, "[MINOR-OB]", "OB مینور " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " ابطال (invalidated) شد.");
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
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_208, "[MINOR-OB]", "OB مینور مصرف شده " + (ob.isBullish ? "صعودی" : "نزولی") + " در زمان " + TimeToString(ob.time) + " ابطال (invalidated) شد.");
         }
      }
   }
   
   //--- تابع اصلاح شده: اضافه کردن نقطه مینور (با ورودی SwingPoint کامل و مدیریت تکرار و ظرفیت)
   bool AddMinorPoint(const SwingPoint &newPoint, const bool isHigh)
   {
      CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "شروع اضافه کردن نقطه مینور.");
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
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_211, "[MINOR]", "سقف مینور جدید در قیمت " + DoubleToString(newPoint.price, _Digits) + " شناسایی شد.");
         
         // آپدیت کاندیدای فعال
         m_activeHighCandidate = newPoint;
         CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "سقف مینور " + TimeToString(newPoint.time) + " به عنوان کاندیدای فعال جدید برای EQ تنظیم شد.");
         
         // فراخوانی شناسایی OB مینور
         IdentifyMinorOrderBlock(newPoint, true);
         
         CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "پایان اضافه کردن نقطه مینور.");
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
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_211, "[MINOR]", "کف مینور جدید در قیمت " + DoubleToString(newPoint.price, _Digits) + " شناسایی شد.");
         
         // آپدیت کاندیدای فعال
         m_activeLowCandidate = newPoint;
         CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "کف مینور " + TimeToString(newPoint.time) + " به عنوان کاندیدای فعال جدید برای EQ تنظیم شد.");
         
         // فراخوانی شناسایی OB مینور
         IdentifyMinorOrderBlock(newPoint, false);
         
         CentralLog(LOG_FULL, m_logLevel, 0, "[MINOR]", "پایان اضافه کردن نقطه مینور.");
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

      color obColor = COLOR_OB_ZONE; // سفید شفاف
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
      ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, COLOR_OB_TEXT);
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
   LOG_LEVEL        m_logLevel;        // سطح لاگ
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

      CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_214, "[LIQ]", "رویداد نقدینگی " + EnumToString(type) + " ثبت شد.");
   }

   //--- تابع کمکی: رسم سطوح سطوح دوره‌ای
   void DrawPeriodicLevel(double price, const string objName, const string label, color clr, ENUM_LINE_STYLE style, int width = 1)
   {
      ObjectDelete(m_chartId, objName);
      ObjectDelete(m_chartId, objName + "_Text");

      if (!ObjectCreate(m_chartId, objName, OBJ_HLINE, 0, 0, price)) return;

      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(m_chartId, objName, OBJPROP_STYLE, style);
      ObjectSetInteger(m_chartId, objName, OBJPROP_WIDTH, width);
      ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, true);

      if (ObjectCreate(m_chartId, objName + "_Text", OBJ_TEXT, 0, TimeCurrent(), price))
      {
         string suffix = GetDisplaySuffix(m_timeframe, m_chartId);
         ObjectSetString(m_chartId, objName + "_Text", OBJPROP_TEXT, label + suffix);
         ObjectSetInteger(m_chartId, objName + "_Text", OBJPROP_COLOR, clr);
         ObjectSetInteger(m_chartId, objName + "_Text", OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
         ObjectSetInteger(m_chartId, objName + "_Text", OBJPROP_FONTSIZE, BASE_LABEL_FONT_SIZE - 1);
      }
   }

   //--- تابع جدید: به‌روزرسانی موقعیت لیبل‌های سطوح دوره‌ای (برای چسبیدن به لبه راست چارت)
   void UpdatePeriodicLabelPositions()
   {
      datetime current_time = TimeCurrent();

      string names[] = {m_pdhLineName, m_pdlLineName, m_pwhLineName, m_pwlLineName, m_pmhLineName, m_pmlLineName, m_pyhLineName, m_pylLineName};
      for (int i = 0; i < ArraySize(names); i++)
      {
         string textName = names[i] + "_Text";
         if (ObjectFind(m_chartId, textName) != -1)
         {
            double price = ObjectGetDouble(m_chartId, textName, OBJPROP_PRICE);
            ObjectMove(m_chartId, textName, 0, current_time, price);
         }
      }
   }

   //--- تابع کمکی: رسم رویداد EQ
   void DrawEQEvent(SwingPoint &source, datetime time_form, double price_entry, ENUM_LIQUIDITY_TYPE type, bool isMajor)
   {
      string baseName = "Liq_EQ_" + (isMajor ? "Major_" : "Minor_") + TimeToString(source.time) + m_timeframeSuffix;
      string lineName = baseName + "_Line"; string textName = baseName + "_Text";
      ObjectDelete(m_chartId, lineName); ObjectDelete(m_chartId, textName);
      color clr = (type == LIQ_EQL) ? COLOR_EQ_BULL : COLOR_EQ_BEAR;
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
      color clr = (type == LIQ_SMS) ? COLOR_SMS_TRAP : COLOR_CF_TRAP; // Purple for SMS, Orange for CF
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
               DrawPeriodicLevel(m_pdh, m_pdhLineName, "PDH", COLOR_PDH, STYLE_DOT);
               changed = true;
            }
            if (pdl != 0 && pdl != m_pdl)
            {
               m_pdl = pdl;
               SwingPoint emptySwing; // ساختار خالی برای فیلد source_swing
               RegisterLiquidityEvent(LIQ_PDL, true, currentDayStart, m_pdl, "PDL", emptySwing);
               DrawPeriodicLevel(m_pdl, m_pdlLineName, "PDL", COLOR_PDL, STYLE_DOT);
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
               DrawPeriodicLevel(m_pwh, m_pwhLineName, "PWH", COLOR_PWH, STYLE_DASHDOT);
               changed = true;
            }
            if (pwl != 0 && pwl != m_pwl)
            {
               m_pwl = pwl;
               SwingPoint emptySwing;
               RegisterLiquidityEvent(LIQ_PWL, true, currentWeekStart, m_pwl, "PWL", emptySwing);
               DrawPeriodicLevel(m_pwl, m_pwlLineName, "PWL", COLOR_PWL, STYLE_DASHDOT);
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
               DrawPeriodicLevel(m_pmh, m_pmhLineName, "PMH", COLOR_PMH, STYLE_DASHDOTDOT);
               changed = true;
            }
            if (pml != 0 && pml != m_pml)
            {
               m_pml = pml;
               SwingPoint emptySwing;
               RegisterLiquidityEvent(LIQ_PML, true, currentMonthStart, m_pml, "PML", emptySwing);
               DrawPeriodicLevel(m_pml, m_pmlLineName, "PML", COLOR_PML, STYLE_DASHDOTDOT);
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
                  DrawPeriodicLevel(m_pyh, m_pyhLineName, "PYH", COLOR_PYH, STYLE_SOLID, 2);
                  changed = true;
               }
               if (yearlyLow != 0 && yearlyLow != m_pyl)
               {
                  m_pyl = yearlyLow;
                  SwingPoint emptySwing;
                  RegisterLiquidityEvent(LIQ_PYL, true, currentYearStart, m_pyl, "PYL", emptySwing);
                  DrawPeriodicLevel(m_pyl, m_pylLineName, "PYL", COLOR_PYL, STYLE_SOLID, 2);
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
            CentralLog(LOG_FULL, m_logLevel, 0, "[LIQ]", "EQ مینور به دلیل همپوشانی با ماژور رسم نشد.");
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
               m_preCHoCHTrend = (currentTrend ==TREND_BULLISH) ? TREND_BEARISH : TREND_BULLISH;
               m_sms_source_swing = (currentTrend == TREND_BULLISH) ? m_major.GetSwingHigh(1) : m_major.GetSwingLow(1);
               if (m_sms_source_swing.time == 0) m_sms_source_swing = (currentTrend == TREND_BULLISH) ? lastHigh : lastLow;
               m_trapState = STATE_WAITING_FOR_OPPOSING_BOS;
               CentralLog(LOG_FULL, m_logLevel, 0, "[LIQ]", "وضعیت تله به STATE_WAITING_FOR_OPPOSING_BOS تغییر یافت.");
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
                  CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_213, "[LIQ]", "تله SMS تایید شد.");
               }
               else
               {
                  m_trapState = STATE_IDLE;
                  CentralLog(LOG_FULL, m_logLevel, 0, "[LIQ]", "تله SMS تایید نشد.");
               }
            }
            else if (currentCHoCH > m_lastKnownCHoCH)
            {
               m_lastKnownCHoCH = currentCHoCH;
               m_preCHoCHTrend = (currentTrend == TREND_BULLISH) ? TREND_BEARISH : TREND_BULLISH;
               m_sms_source_swing = (currentTrend == TREND_BULLISH) ? m_major.GetSwingHigh(1) : m_major.GetSwingLow(1);
               if (m_sms_source_swing.time == 0) m_sms_source_swing = (currentTrend == TREND_BULLISH) ? lastHigh : lastLow;
               m_trapState = STATE_WAITING_FOR_OPPOSING_BOS;
               CentralLog(LOG_FULL, m_logLevel, 0, "[LIQ]", "تله ریست شد به دلیل CHoCH جدید.");
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
                  CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_213, "[LIQ]", "تله CF تایید شد.");
               }
               else
               {
                  CentralLog(LOG_FULL, m_logLevel, 0, "[LIQ]", "تله CF تایید نشد.");
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
         CentralLog(LOG_ERROR, DEFAULT_LOG_LEVEL, ERROR_CODE_103, "[LIQ]", "خطای حیاتی: پوینترهای Major/Minor نامعتبر هستند!", true);
         return;
      }

      m_major = major_ptr;
      m_minor = minor_ptr;
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      m_enableLogging = enableLogging_in;
      m_logLevel = DEFAULT_LOG_LEVEL;
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

      CentralLog(LOG_FULL, m_logLevel, 0, "[LIQ]", "کلاس CLiquidityManager برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.");
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
      CentralLog(LOG_FULL, m_logLevel, 0, "[LIQ]", "کلاس CLiquidityManager متوقف شد.");
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

      CentralLog(LOG_FULL, m_logLevel, 0, "[LIQ]", "شروع پردازش بار جدید.");

      bool changed = false;
      changed |= UpdatePeriodicLevels();
      changed |= ScanForEQ();
      changed |= ScanForStructuralTraps();

      // به‌روزرسانی موقعیت لیبل‌های سطوح دوره‌ای برای چسبیدن به لبه راست
      if (m_showDrawing) UpdatePeriodicLabelPositions();

      CentralLog(LOG_FULL, m_logLevel, 0, "[LIQ]", "پایان پردازش بار جدید.");
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
//| کلاس شناسایی پین‌بار (تکی و ادغام شده)                          |
//+------------------------------------------------------------------+
// ساختار ۱: کندل مجازی (برای نگهداری نتیجه ادغام)
// این ساختار، دیتای ۱، ۲ یا ۳ کندل ادغام شده رو نگه می‌داره
struct VirtualCandle
{
   double   open;           // اوپنِ قدیمی‌ترین کندل
   double   high;           // بالاترین High در مجموعه
   double   low;            // پایین‌ترین Low در مجموعه
   double   close;          // کلوزِ جدیدترین کندل
   datetime time_oldest;    // زمانِ قدیمی‌ترین کندل (برای نام‌گذاری آبجکت)
   datetime time_newest;    // زمانِ جدیدترین کندل (برای بررسی)
   int      candle_count;   // چند کندل ادغام شدن؟ (۱، ۲ یا ۳)
};

// ساختار ۲: نتیجه پین‌بار (خروجی تابع)
// این ساختار، مشخصات پین‌بار پیدا شده رو برمی‌گردونه
struct PinbarResult
{
   bool           isBullish;      // صعودیه (Hammer) یا نزولی (Shooting Star)؟
   VirtualCandle  candle_data;    // دیتای کندل مجازی که پین‌بار رو ساخته
   string         type_name;      // اسم نوع: "Single C1", "Agg C2+C3", "Agg C1C2C3" و...
};

class CPinbarDetector
{
private:
   // --- متغیرهای داخلی ---
   string            m_symbol;
   ENUM_TIMEFRAMES   m_period;
   long              m_chartId;
   string            m_timeframeSuffix;

  

   // --- توابع کمکی داخلی (Private) ---

   // تابع اصلی ادغام کندل‌ها
   // shift_newest: اندیس جدیدترین کندل (مثلاً ۱)
   // count: تعداد کندل برای ادغام (مثلاً ۳)
   VirtualCandle GetVirtualCandle(const int shift_newest, const int count)
   {
      VirtualCandle vc;
      vc.candle_count = count;
      vc.time_newest = iTime(m_symbol, m_period, shift_newest);
      vc.time_oldest = iTime(m_symbol, m_period, shift_newest + count - 1);
      
      // اوپنِ قدیمی‌ترین و کلوزِ جدیدترین
      vc.open = iOpen(m_symbol, m_period, shift_newest + count - 1);
      vc.close = iClose(m_symbol, m_period, shift_newest);
      
      // پیدا کردن اکستریمم‌ها در پنجره
      vc.high = 0;
      vc.low = DBL_MAX;
      for(int i = shift_newest; i < shift_newest + count; i++)
      {
         if(iHigh(m_symbol, m_period, i) > vc.high) vc.high = iHigh(m_symbol, m_period, i);
         if(iLow(m_symbol, m_period, i) < vc.low)   vc.low = iLow(m_symbol, m_period, i);
      }
      
      return vc;
   }

   // تابع اصلی ریاضیات پین‌بار
   // 0 = پین‌بار نیست
   // 1 = پین‌بار صعودی (Bullish)
   // 2 = پین‌بار نزولی (Bearish)
   int CheckPinbarLogic(VirtualCandle &vc)
   {
      double totalRange = vc.high - vc.low;
      
      // جلوگیری از خطای تقسیم بر صفر (کندل دوجی یا بدون حرکت)
      if(totalRange < SymbolInfoDouble(m_symbol, SYMBOL_POINT)) return 0;
      
      double body = MathAbs(vc.open - vc.close);
      
      // شرط ۱: بدنه باید کوچک باشد
      if((body / totalRange) >= PINBAR_BODY_RATIO_THRESHOLD) return 0;
      
      // شرط ۲: یکی از سایه‌ها باید خیلی بلند باشد
      double upperShadow = vc.high - MathMax(vc.open, vc.close);
      double lowerShadow = MathMin(vc.open, vc.close) - vc.low;
      
      if((lowerShadow / totalRange) >= PINBAR_SHADOW_RATIO_THRESHOLD) return 1; // صعودی
      if((upperShadow / totalRange) >= PINBAR_SHADOW_RATIO_THRESHOLD) return 2; // نزولی
      
      return 0; // پین‌بار نیست
   }
   
   // تابع برای ساختن اسم منحصر به فرد آبجکت (برای جلوگیری از رسم تکراری)
   string GetObjectName(PinbarResult &result)
   {
      // اسم باید شامل نوع، زمان شروع و تایم فریم باشد
      // این تضمین می‌کنه که هر پین‌بار فقط یک بار رسم بشه
      return "Pinbar_" + result.type_name + "_" + 
             TimeToString(result.candle_data.time_oldest) + 
             m_timeframeSuffix;
   }

   // تابع رسم علامت π
   void DrawPinbar(PinbarResult &result)
   {
      string objName = GetObjectName(result);
      
      // چک کردن عدم وجود آبجکت (مهم‌ترین بخش برای جلوگیری از رسم تکراری)
      if(ObjectFind(m_chartId, objName) != -1)
      {
         // آبجکت از قبل وجود داره، پس کاری نکن
         return; 
      }
      
      // محاسبه محل رسم
      datetime drawTime = result.candle_data.time_oldest; // در شروع کندل مجازی رسم می‌کنیم
      double drawPrice;
      double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      
      if(result.isBullish)
      {
         // زیر Low کندل مجازی
         drawPrice = result.candle_data.low - (tickSize * 10); // ۱۰ تیک آفست
      }
      else
      {
         // بالای High کندل مجازی
         drawPrice = result.candle_data.high + (tickSize * 10); // ۱۰ تیک آفست
      }
      
      // ایجاد آبجکت متن
      if(ObjectCreate(m_chartId, objName, OBJ_TEXT, 0, drawTime, drawPrice))
      {
         ObjectSetString(m_chartId, objName, OBJPROP_TEXT, "π");
         ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, (result.isBullish ? clrGreen : clrRed));
         ObjectSetInteger(m_chartId, objName, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(m_chartId, objName, OBJPROP_ANCHOR, (result.isBullish ? ANCHOR_TOP : ANCHOR_BOTTOM));
      }
   }


public:
   // --- سازنده (Constructor) ---
   CPinbarDetector(void) {} // سازنده ساده

   // --- تابع اصلی و عمومی (Public) ---
   
   // تابع اصلی که از بیرون صدا زده می‌شه
   // ورودی‌ها: نماد، تایم‌فریم، آیدی چارت، آیا رسم شود؟
   // خروجی: تعداد پین‌بارهای پیدا شده (و پُر کردن آرایه results_array)
   int DetectPinbars(string symbol, ENUM_TIMEFRAMES period, long chartId, bool draw, PinbarResult &results_array[])
   {
      // مقداردهی اولیه متغیرهای کلاس
      m_symbol = symbol;
      m_period = period;
      m_chartId = chartId;
      m_timeframeSuffix = " (" + TimeFrameToStringShort(period) + ")";
      
      // پاک کردن آرایه خروجی برای شروع تمیز
      ArrayResize(results_array, 0);
      
      // بررسی وجود کندل کافی
      if(iBars(m_symbol, m_period) < 4) return 0; // چون تا شیفت ۳ نیاز داریم

      // آرایه‌ای برای نگهداری موقت نتایج
      PinbarResult found_pins[];
      int pin_count = 0;
      
      VirtualCandle vc;
      int logic_result;

      // --- شروع ۶ مرحله بررسی ---
      
      // ۱. چک تکی C1 (shift 1)
      vc = GetVirtualCandle(1, 1);
      logic_result = CheckPinbarLogic(vc);
      if(logic_result > 0)
      {
         pin_count++;
         ArrayResize(found_pins, pin_count);
         found_pins[pin_count - 1].isBullish = (logic_result == 1);
         found_pins[pin_count - 1].candle_data = vc;
         found_pins[pin_count - 1].type_name = "Single_C1";
      }

      // ۲. چک تکی C2 (shift 2)
      vc = GetVirtualCandle(2, 1);
      logic_result = CheckPinbarLogic(vc);
      if(logic_result > 0)
      {
         pin_count++;
         ArrayResize(found_pins, pin_count);
         found_pins[pin_count - 1].isBullish = (logic_result == 1);
         found_pins[pin_count - 1].candle_data = vc;
         found_pins[pin_count - 1].type_name = "Single_C2";
      }

      // ۳. چک تکی C3 (shift 3)
      vc = GetVirtualCandle(3, 1);
      logic_result = CheckPinbarLogic(vc);
      if(logic_result > 0)
      {
         pin_count++;
         ArrayResize(found_pins, pin_count);
         found_pins[pin_count - 1].isBullish = (logic_result == 1);
         found_pins[pin_count - 1].candle_data = vc;
         found_pins[pin_count - 1].type_name = "Single_C3";
      }

      // ۴. چک ادغام C1+C2 (shift 1, count 2)
      vc = GetVirtualCandle(1, 2);
      logic_result = CheckPinbarLogic(vc);
      if(logic_result > 0)
      {
         pin_count++;
         ArrayResize(found_pins, pin_count);
         found_pins[pin_count - 1].isBullish = (logic_result == 1);
         found_pins[pin_count - 1].candle_data = vc;
         found_pins[pin_count - 1].type_name = "Agg_C1C2";
      }

      // ۵. چک ادغام C2+C3 (shift 2, count 2)
      vc = GetVirtualCandle(2, 2);
      logic_result = CheckPinbarLogic(vc);
      if(logic_result > 0)
      {
         pin_count++;
         ArrayResize(found_pins, pin_count);
         found_pins[pin_count - 1].isBullish = (logic_result == 1);
         found_pins[pin_count - 1].candle_data = vc;
         found_pins[pin_count - 1].type_name = "Agg_C2C3";
      }

      // ۶. چک ادغام C1+C2+C3 (shift 1, count 3)
      vc = GetVirtualCandle(1, 3);
      logic_result = CheckPinbarLogic(vc);
      if(logic_result > 0)
      {
         pin_count++;
         ArrayResize(found_pins, pin_count);
         found_pins[pin_count - 1].isBullish = (logic_result == 1);
         found_pins[pin_count - 1].candle_data = vc;
         found_pins[pin_count - 1].type_name = "Agg_C1C2C3";
      }
      
      // --- پایان بررسی ---
      
      // کپی کردن نتایج پیدا شده به آرایه خروجی
      ArrayResize(results_array, pin_count);
      for(int i = 0; i < pin_count; i++)
      {
         results_array[i] = found_pins[i];
      }
      
      // اگر نیاز به رسم بود، حالا رسم کن
      if(draw && pin_count > 0)
      {
         for(int i = 0; i < pin_count; i++)
         {
            DrawPinbar(results_array[i]);
         }
      }
      
      // برگرداندن تعداد پین‌بارهای پیدا شده
      return pin_count;
   }
};
//+------------------------------------------------------------------+
//|                                                                  |
//| کلاس ۵: مدیریت مناطق واکنشی (Draw & Flip)                        |
//| (CReactionZones)                                                 |
//| نسخه ۱.۳ - اصلاحات بر اساس استانداردهای MQL5                     |
//|                                                                  |
//| توضیحات کلی:                                                     |
//| این کلاس مسئول شناسایی، مدیریت و نمایش خطوط Draw و Flip است.   |
//| - Draw: اولین واکنش قیمت به OB در بازه شکست ساختار.             |
//| - Flip: آخرین حمایت/مقاومت قبل از Draw (با دو روش F1 و F2).     |
//|                                                                  |
//| نکات کلیدی MQL5:                                                |
//| - پوینترها با '.' برای دسترسی به اعضا استفاده می‌شوند.         |
//| - از CheckPointer() برای اعتبارسنجی پوینترها استفاده می‌شود.     |
//| - آرایه‌ها با ArrayResize، ArrayRemove مدیریت می‌شوند.           |
//| - کلاس از CObject برای لیست‌ها (CArrayObj) ارث‌بری می‌کند.        |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi - HipoAlgoritm"
#property link      "https://github.com/Khajavi8056/"
#property version   "1.30"

//--- ثابت‌ها برای تنظیمات کلاس
#define MAX_REACTION_LINE_AGE_BARS 500 // حداکثر عمر یک خط Draw/Flip (به تعداد کندل)
#define MAX_REACTION_LINES_PER_TYPE 10 // حداکثر تعداد خطوط Draw/Flip از هر نوع (صعودی/نزولی)

//--- نوع خط واکنشی (برای وضوح بیشتر)
enum ENUM_REACTION_LINE_TYPE
{
   LINE_TYPE_DRAW, // خط Draw (اولین واکنش به OB)
   LINE_TYPE_FLIP  // خط Flip (آخرین حمایت/مقاومت قبل از Draw)
};

//--- رنگ‌های ثابت برای خطوط
const color COLOR_DRAW_BULL = clrGreen;     // رنگ Draw صعودی
const color COLOR_DRAW_BEAR = clrRed;       // رنگ Draw نزولی
const color COLOR_FLIP_BULL = clrLime;      // رنگ Flip صعودی
const color COLOR_FLIP_BEAR = clrOrangeRed; // رنگ Flip نزولی

//+------------------------------------------------------------------+
//| کلاس داده برای نگهداری اطلاعات خطوط Draw و Flip                 |
//| ارث‌بری از CObject برای استفاده در CArrayObj                     |
//+------------------------------------------------------------------+
class CReactionLine : public CObject
{
public:
   datetime source_ob_time;       // زمان (ID) OB ماژور منبع که این خط از آن مشتق شده
   int      source_ob_bar_index;  // اندیس OB ماژور منبع (برای اطمینان از یکتایی)
   ENUM_REACTION_LINE_TYPE lineType; // نوع خط: Draw یا Flip
   bool     isBullish;            // آیا این خط حمایت صعودی است (true) یا مقاومت نزولی (false)؟
   
   //--- اطلاعات قیمت و زمان
   double   price;                // قیمت دقیق خط
   datetime time;                 // زمان ایجاد (برای Draw: زمان کندل واکنش، برای Flip: زمان شکست ساختار)
   int      bar_index;            // اندیس کندل ایجاد
   
   //--- اطلاعات اضافی (مخصوص Flip)
   string   flipType;             // "F1" (بر اساس مینور) یا "F2" (بر اساس اکستریمم قیمت)
   
   //--- متغیرهای گرافیکی (برای مدیریت آسان‌تر)
   string   obj_name_line;        // نام آبجکت خط روی چارت
   string   obj_name_label;       // نام آبجکت لیبل روی چارت
   
   //--- سازنده پیش‌فرض
   CReactionLine(void)
   {
      source_ob_time = 0;
      source_ob_bar_index = -1;
      lineType = LINE_TYPE_DRAW;
      isBullish = false;
      price = 0.0;
      time = 0;
      bar_index = -1;
      flipType = "";
      obj_name_line = "";
      obj_name_label = "";
   }
};

//+------------------------------------------------------------------+
//| کلاس اصلی CReactionZones                                         |
//|                                                                   |
//| وظایف اصلی:                                                      |
//| - شناسایی Draw و Flip بر اساس OBهای جدید.                        |
//| - مدیریت ظرفیت و ابطال خطوط قدیمی.                              |
//| - نمایش و به‌روزرسانی گرافیکی خطوط.                            |
//+------------------------------------------------------------------+
class CReactionZones
{
private:
   //--- وابستگی‌ها (تزریق شده از سازنده)
   MarketStructure *m_major;      // پوینتر به کلاس ساختار ماژور (برای دسترسی به OBها و ساختارها)
   MinorStructure  *m_minor;      // پوینتر به کلاس ساختار مینور (برای محاسبه Flipهای F1)
   
   //--- تنظیمات اصلی (ورودی‌های سازنده)
   string           m_symbol;     // نماد معاملاتی
   ENUM_TIMEFRAMES  m_timeframe;  // تایم فریم اجرایی
   long             m_chartId;    // شناسه چارت برای رسم
   bool             m_enableLogging; // فعال/غیرفعال لاگ
   LOG_LEVEL        m_logLevel;   // سطح لاگ
   string           m_timeframeSuffix; // پسوند برای نام اشیاء (برای MTF)
   bool             m_showDrawing; // کنترل نمایش روی چارت
   
   //--- لیست‌های نگهداری خطوط (با استفاده از CArrayObj برای مدیریت پوینترها)
   CArrayObj       *m_drawLines; // لیست خطوط Draw (CReactionLine*)
   CArrayObj       *m_flipLines; // لیست خطوط Flip (CReactionLine*)
   
   //--- لیست ردیابی OBهای پردازش شده (برای جلوگیری از تکرار)
   CArrayLong      *m_processedOB_IDs; // لیست datetime OBهای پردازش شده
 
   //--- متغیرهای کنترلی داخلی
   datetime         m_lastProcessedBarTime; // زمان آخرین بار پردازش شده (برای جلوگیری از تکرار)
   
   //--- تابع کمکی داخلی: اعتبارسنجی پوینترها (در هر تابع اصلی استفاده می‌شود)
   bool IsValidDependencies(void) const
   {
      if (CheckPointer(m_major) == POINTER_INVALID || CheckPointer(m_minor) == POINTER_INVALID)
      {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_103, "[RZ]", "خطا: وابستگی‌های Major/Minor نامعتبر هستند.", true);
         return false;
      }
      return true;
   }
   
   //--- تابع کمکی داخلی: اضافه کردن خط به لیست با مدیریت ظرفیت
   void AddToListWithCapacity(CArrayObj *list, CReactionLine *newLine)
   {
      if (CheckPointer(list) == POINTER_INVALID || CheckPointer(newLine) == POINTER_INVALID) return;
      
      // مدیریت ظرفیت بر اساس نوع (صعودی/نزولی)
      ManageListCapacity(list, newLine.isBullish);
      
      // اضافه کردن خط جدید
      list.Add(newLine);
   }
   
   //--- تابع کمکی داخلی: جستجو در CArrayLong (جایگزین ArraySearch)
   int SearchInLongArray(const CArrayLong *array, long value) const
   {
      if (CheckPointer(array) == POINTER_INVALID) return -1;
      int total = array.Total();
      for (int i = 0; i < total; i++)
      {
         if (array.At(i) == value) return i;
      }
      return -1;
   }
   
   //--- تابع کمکی داخلی: مدیریت ظرفیت لیست (حذف قدیمی‌ترین خط از نوع مشابه اگر ظرفیت پر باشد)
   void ManageListCapacity(CArrayObj *list, bool isBullish)
   {
      if (CheckPointer(list) == POINTER_INVALID) return;
      
      int count = 0;
      // شمارش تعداد خطوط از نوع مشابه (صعودی یا نزولی)
      for (int i = 0; i < list.Total(); i++)
      {
         CReactionLine *line = (CReactionLine*)list.At(i);
         if (CheckPointer(line) == POINTER_INVALID) continue;
         if (line.isBullish == isBullish) count++;
      }
      
      // اگر ظرفیت پر شده، قدیمی‌ترین خط از نوع مشابه را حذف کن
      if (count >= MAX_REACTION_LINES_PER_TYPE)
      {
         int oldest_index = -1;
         datetime oldest_time = D'2999.12.31'; // زمان آینده برای شروع مقایسه
         
         for (int i = 0; i < list.Total(); i++)
         {
            CReactionLine *line = (CReactionLine*)list.At(i);
            if (CheckPointer(line) == POINTER_INVALID) continue;
            
            if (line.isBullish == isBullish && line.time < oldest_time)
            {
               oldest_time = line.time;
               oldest_index = i;
            }
         }
         
         if (oldest_index != -1)
         {
            CReactionLine *lineToDel = (CReactionLine*)list.At(oldest_index);
            if (CheckPointer(lineToDel) == POINTER_INVALID) return;
            
            string listType = (list == m_drawLines) ? "Draw" : "Flip";
            CentralLog(LOG_FULL, m_logLevel, 0, "[RZ]", "ظرفیت لیست " + listType + " " + (isBullish ? "صعودی" : "نزولی") + " پر شد. حذف قدیمی‌ترین خط (" + lineToDel.obj_name_line + ").");
            
            DeleteReactionLine(lineToDel, oldest_index, list);
         }
      }
   }
   
   //--- تابع داخلی: حذف خط (پاک کردن گرافیک و حذف از لیست و حافظه)
   void DeleteReactionLine(CReactionLine *line, int index, CArrayObj *list)
   {
      if (CheckPointer(line) == POINTER_INVALID || CheckPointer(list) == POINTER_INVALID) return;
      
      // حذف اشیاء گرافیکی اگر نمایش فعال باشد
      if (m_showDrawing)
      {
         ObjectDelete(m_chartId, line.obj_name_line);
         ObjectDelete(m_chartId, line.obj_name_label);
      }
      
      // حذف از لیست
      list.Delete(index);
      
      // آزاد کردن حافظه
      delete line;
   }
   
   //--- تابع محاسباتی داخلی: محاسبه خط Draw (اولین واکنش به OB)
   // ورودی‌ها: OB منبع، زمان شکست ساختار
   // خروجی: پوینتر به CReactionLine جدید یا NULL اگر پیدا نشد
   // منطق: جستجو از جدید به قدیم در بازه OB تا شکست، پیدا کردن اولین کندل که به OB واکنش نشان داده (High/Low وارد زون شده)
   CReactionLine* CalculateDrawLine(OrderBlock &ob, datetime break_time)
   {
      int break_index = iBarShift(m_symbol, m_timeframe, break_time, false);
      int ob_index = ob.bar_index;
      
      // چک اعتبار بازه جستجو
      if (break_index == -1 || ob_index == -1 || ob_index <= break_index + 1)
      {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_105, "[RZ-Draw]", "بازه جستجو نامعتبر. BreakIndex: " + IntegerToString(break_index) + ", OBIndex: " + IntegerToString(ob_index), true);
         return NULL;
      }
      
      // حلقه جستجو: از کندل قبل از OB (جدیدتر) به سمت کندل بعد از شکست (قدیمی‌تر)
      for (int i = ob_index - 1; i > break_index; i--)
      {
         bool reaction_found = false;
         double reaction_price = 0.0;
         
         if (ob.isBullish) // OB صعودی: دنبال واکنش حمایت (High وارد زون)
         {
            double high = iHigh(m_symbol, m_timeframe, i);
            if (high >= ob.lowPrice && high <= ob.highPrice)
            {
               reaction_found = true;
               reaction_price = high;
            }
         }
         else // OB نزولی: دنبال واکنش مقاومت (Low وارد زون)
         {
            double low = iLow(m_symbol, m_timeframe, i);
            if (low >= ob.lowPrice && low <= ob.highPrice)
            {
               reaction_found = true;
               reaction_price = low;
            }
         }
         
         if (reaction_found)
         {
            // ایجاد شیء جدید
            CReactionLine *line = new CReactionLine();
            line.source_ob_time = ob.time;
            line.source_ob_bar_index = ob.bar_index;
            line.lineType = LINE_TYPE_DRAW;
            line.isBullish = ob.isBullish;
            line.price = reaction_price;
            line.time = iTime(m_symbol, m_timeframe, i);
            line.bar_index = i;
            line.flipType = "";
            
            // نام‌گذاری اشیاء گرافیکی
            string typeStr = (line.isBullish ? "Draw_Bull" : "Draw_Bear");
            line.obj_name_line = "RZ_" + typeStr + "_" + TimeToString(line.time, TIME_DATE|TIME_MINUTES|TIME_SECONDS) + m_timeframeSuffix;
            line.obj_name_label = line.obj_name_line + "_Label";
            
            return line;
         }
      }
      
      // اگر هیچ واکنشی پیدا نشد
      CentralLog(LOG_FULL, m_logLevel, 0, "[RZ-Draw]", "هیچ Draw برای OB در " + TimeToString(ob.time) + " پیدا نشد.");
      return NULL;
   }
   
   //--- تابع محاسباتی داخلی: محاسبه خط Flip (آخرین حمایت/مقاومت قبل از Draw)
   // ورودی‌ها: خط Draw محاسبه شده، OB منبع، زمان شکست
   // خروجی: پوینتر به CReactionLine جدید یا NULL اگر پیدا نشد
   // منطق: جستجو در "منطقه جنگ" (بازه شکست تا Draw) برای آخرین مینور (F1) یا اکستریمم (F2)
   CReactionLine* CalculateFlipLine(CReactionLine *drawLine, OrderBlock &sourceOB, datetime break_time)
   {
      if (CheckPointer(drawLine) == POINTER_INVALID) return NULL;
      
      int break_index = iBarShift(m_symbol, m_timeframe, break_time, false);
      int draw_index = drawLine.bar_index;
      
      // تعیین بازه "منطقه جنگ": از کندل بعد از شکست تا کندل قبل از Draw
      int search_start = break_index + 1; // شروع جستجو (جدیدتر)
      int search_end = draw_index - 1;    // پایان جستجو (قدیمی‌تر)
      
      if (search_end < search_start)
      {
         CentralLog(LOG_FULL, m_logLevel, 0, "[RZ-Flip]", "هیچ Flip پیدا نشد: بازه جنگ معتبر نیست.");
         return NULL;
      }
      
      double flipPrice = 0.0;
      string flipType = "";
      
      // روش F1: جستجو برای آخرین سوئینگ مینور در بازه
      double f1_price = 0.0;
      datetime f1_time = 0;
      int minorCount = drawLine.isBullish ? m_minor.GetMinorHighsCount() : m_minor.GetMinorLowsCount();
      
      for (int i = 0; i < minorCount; i++)
      {
         SwingPoint sp = drawLine.isBullish ? m_minor.GetMinorSwingHigh(i) : m_minor.GetMinorSwingLow(i);
         if (sp.time >= iTime(m_symbol, m_timeframe, search_end) && sp.time <= iTime(m_symbol, m_timeframe, search_start))
         {
            if (sp.time > f1_time)
            {
               f1_time = sp.time;
               f1_price = sp.price;
            }
         }
      }
      
      if (f1_price != 0.0)
      {
         flipPrice = f1_price;
         flipType = "F1";
         CentralLog(LOG_FULL, m_logLevel, 0, "[RZ-Flip]", "F1 پیدا شد (بر اساس مینور): قیمت " + DoubleToString(flipPrice, _Digits));
      }
      
      // روش F2: اگر F1 پیدا نشد، جستجو برای اکستریمم قیمت در بازه
      if (flipPrice == 0.0)
      {
         int count = search_end - search_start + 1;
         if (count > 0)
         {
            if (drawLine.isBullish)
            {
               int highest_idx = iHighest(m_symbol, m_timeframe, MODE_HIGH, count, search_start);
               if (highest_idx != -1) flipPrice = iHigh(m_symbol, m_timeframe, highest_idx);
            }
            else
            {
               int lowest_idx = iLowest(m_symbol, m_timeframe, MODE_LOW, count, search_start);
               if (lowest_idx != -1) flipPrice = iLow(m_symbol, m_timeframe, lowest_idx);
            }
            
            if (flipPrice != 0.0)
            {
               flipType = "F2";
               CentralLog(LOG_FULL, m_logLevel, 0, "[RZ-Flip]", "F2 پیدا شد (بر اساس اکستریمم): قیمت " + DoubleToString(flipPrice, _Digits));
            }
         }
      }
      
      // چک نهایی: اگر قیمت پیدا شد و معتبر بود
      if (flipPrice != 0.0)
      {
         bool price_valid = (drawLine.isBullish && flipPrice <= drawLine.price) || (!drawLine.isBullish && flipPrice >= drawLine.price);
         if (price_valid)
         {
            CReactionLine *line = new CReactionLine();
            line.source_ob_time = sourceOB.time;
            line.source_ob_bar_index = sourceOB.bar_index;
            line.lineType = LINE_TYPE_FLIP;
            line.isBullish = sourceOB.isBullish;
            line.price = flipPrice;
            line.time = break_time;
            line.bar_index = break_index;
            line.flipType = flipType;
            
            // نام‌گذاری اشیاء
            string typeStr = (line.isBullish ? "Flip_Bull" : "Flip_Bear");
            line.obj_name_line = "RZ_" + typeStr + "_" + TimeToString(line.time, TIME_DATE|TIME_MINUTES|TIME_SECONDS) + m_timeframeSuffix;
            line.obj_name_label = line.obj_name_line + "_Label";
            
            return line;
         }
         else
         {
            CentralLog(LOG_FULL, m_logLevel, 0, "[RZ-Flip]", "Flip رد شد: قیمت نامعتبر نسبت به Draw.");
         }
      }
      
      CentralLog(LOG_FULL, m_logLevel, 0, "[RZ-Flip]", "هیچ Flip برای OB در " + TimeToString(sourceOB.time) + " پیدا نشد.");
      return NULL;
   }
   
   //--- تابع داخلی: رسم یک خط (با لیبل و امتداد به راست)
   void DrawReactionLine(CReactionLine *line)
   {
      if (!m_showDrawing || CheckPointer(line) == POINTER_INVALID) return;
      
      // رسم خط افقی
      datetime endTime = D'2030.01.01 00:00'; // امتداد به آینده
      color lineColor;
      
      if (line.lineType == LINE_TYPE_DRAW)
      {
         lineColor = line.isBullish ? COLOR_DRAW_BULL : COLOR_DRAW_BEAR;
      }
      else // LINE_TYPE_FLIP
      {
         lineColor = line.isBullish ? COLOR_FLIP_BULL : COLOR_FLIP_BEAR;
      }
      
      if (ObjectCreate(m_chartId, line.obj_name_line, OBJ_TREND, 0, line.time, line.price, endTime, line.price))
      {
         ObjectSetInteger(m_chartId, line.obj_name_line, OBJPROP_COLOR, lineColor);
         ObjectSetInteger(m_chartId, line.obj_name_line, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(m_chartId, line.obj_name_line, OBJPROP_WIDTH, 1);
         ObjectSetInteger(m_chartId, line.obj_name_line, OBJPROP_RAY_RIGHT, true);
         ObjectSetInteger(m_chartId, line.obj_name_line, OBJPROP_BACK, true);
      }
      else
      {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_102, "[RZ]", "خطا در ایجاد خط: " + line.obj_name_line, true);
         return;
      }
      
      // رسم لیبل (متن)
      string labelText = (line.lineType == LINE_TYPE_DRAW ? "Draw" : "Flip " + line.flipType) + m_timeframeSuffix;
      if (ObjectCreate(m_chartId, line.obj_name_label, OBJ_TEXT, 0, line.time, line.price))
      {
         ObjectSetString(m_chartId, line.obj_name_label, OBJPROP_TEXT, labelText);
         ObjectSetInteger(m_chartId, line.obj_name_label, OBJPROP_COLOR, lineColor);
         ObjectSetInteger(m_chartId, line.obj_name_label, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
         ObjectSetInteger(m_chartId, line.obj_name_label, OBJPROP_FONTSIZE, BASE_LABEL_FONT_SIZE);
      }
      else
      {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_102, "[RZ]", "خطا در ایجاد لیبل: " + line.obj_name_label, true);
      }
   }
   
   //--- تابع داخلی: به‌روزرسانی موقعیت لیبل یک خط (برای چسبیدن به لبه راست)
   void UpdateLineLabelPosition(CReactionLine *line)
   {
      if (CheckPointer(line) == POINTER_INVALID) return;
      datetime current_time = TimeCurrent();
      if (ObjectFind(m_chartId, line.obj_name_label) != -1)
      {
         ObjectMove(m_chartId, line.obj_name_label, 0, current_time, line.price);
      }
   }
   
   //--- تابع داخلی: به‌روزرسانی موقعیت تمام لیبل‌ها (برای هر تیک یا بار جدید)
   void UpdateAllLabelPositions(void)
   {
      datetime current_time = TimeCurrent();

      // برای Drawها
      for (int i = 0; i < m_drawLines.Total(); i++)
      {
         CReactionLine *line = (CReactionLine*)m_drawLines.At(i);
         UpdateLineLabelPosition(line);
      }
      
      // برای Flipها
      for (int i = 0; i < m_flipLines.Total(); i++)
      {
         CReactionLine *line = (CReactionLine*)m_flipLines.At(i);
         UpdateLineLabelPosition(line);
      }
   }
   
   //--- تابع داخلی: ابطال خطوط قدیمی بر اساس عمر (تعداد کندل)
   void InvalidateOldLines(void)
   {
      int currentBar = iBars(m_symbol, m_timeframe) - 1; // اندیس کندل فعلی
      
      // برای Drawها
      for (int i = m_drawLines.Total() - 1; i >= 0; i--)
      {
         CReactionLine *line = (CReactionLine*)m_drawLines.At(i);
         if (CheckPointer(line) == POINTER_INVALID) continue;
         
         int age = currentBar - line.bar_index;
         if (age > MAX_REACTION_LINE_AGE_BARS)
         {
            CentralLog(LOG_FULL, m_logLevel, 0, "[RZ]", "ابطال خط Draw قدیمی (" + line.obj_name_line + ") به دلیل عمر بیش از " + IntegerToString(MAX_REACTION_LINE_AGE_BARS) + " کندل.");
            DeleteReactionLine(line, i, m_drawLines);
         }
      }
      
      // برای Flipها
      for (int i = m_flipLines.Total() - 1; i >= 0; i--)
      {
         CReactionLine *line = (CReactionLine*)m_flipLines.At(i);
         if (CheckPointer(line) == POINTER_INVALID) continue;
         
         int age = currentBar - line.bar_index;
         if (age > MAX_REACTION_LINE_AGE_BARS)
         {
            CentralLog(LOG_FULL, m_logLevel, 0, "[RZ]", "ابطال خط Flip قدیمی (" + line.obj_name_line + ") به دلیل عمر بیش از " + IntegerToString(MAX_REACTION_LINE_AGE_BARS) + " کندل.");
            DeleteReactionLine(line, i, m_flipLines);
         }
      }
   }
   
   //--- تابع داخلی: چک تکراری بودن OB منبع (بر اساس time و bar_index)
   bool IsOBProcessed(OrderBlock &ob)
   {
      if (CheckPointer(m_processedOB_IDs) == POINTER_INVALID) return false;
      long id = (long)ob.time * 100000 + ob.bar_index;
      return (SearchInLongArray(m_processedOB_IDs, id) != -1);
   }
   
   //--- تابع داخلی: علامت‌گذاری OB به عنوان پردازش شده
   void MarkOBAsProcessed(OrderBlock &ob)
   {
      if (CheckPointer(m_processedOB_IDs) == POINTER_INVALID) return;
      long id = (long)ob.time * 100000 + ob.bar_index;
      m_processedOB_IDs.Add(id);
   }

public:
   //--- سازنده (با ورودی‌های استاندارد)
   CReactionZones(MarketStructure *major_ptr, MinorStructure *minor_ptr,
                  const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId,
                  const bool enableLogging_in, const bool showDrawing_in)
   {
      if (CheckPointer(major_ptr) == POINTER_INVALID || CheckPointer(minor_ptr) == POINTER_INVALID)
      {
         CentralLog(LOG_ERROR, DEFAULT_LOG_LEVEL, ERROR_CODE_103, "[RZ]", "خطای حیاتی: پوینترهای Major/Minor نامعتبر هستند!", true);
         return;
      }

      m_major = major_ptr;
      m_minor = minor_ptr;
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      m_enableLogging = enableLogging_in;
      m_logLevel = DEFAULT_LOG_LEVEL;
      m_showDrawing = showDrawing_in;
      m_timeframeSuffix = " (" + TimeFrameToStringShort(timeframe) + ")";

      m_drawLines = new CArrayObj();
      m_flipLines = new CArrayObj();
      m_processedOB_IDs = new CArrayLong();
      m_lastProcessedBarTime = 0;

      // پاکسازی اشیاء قبلی
      if (m_showDrawing)
      {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for (int i = total - 1; i >= 0; i--)
         {
            string name = ObjectName(m_chartId, i);
            if (StringFind(name, m_timeframeSuffix) != -1 && StringFind(name, "RZ_") != -1)
            {
               ObjectDelete(m_chartId, name);
            }
         }
      }

      CentralLog(LOG_FULL, m_logLevel, 0, "[RZ]", "کلاس CReactionZones برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.");
   }
   
   //--- مخرب
   ~CReactionZones()
   {
      // حذف تمام خطوط و لیست‌ها
      for (int i = m_drawLines.Total() - 1; i >= 0; i--)
      {
         CReactionLine *line = (CReactionLine*)m_drawLines.At(i);
         DeleteReactionLine(line, i, m_drawLines);
      }
      delete m_drawLines;
      
      for (int i = m_flipLines.Total() - 1; i >= 0; i--)
      {
         CReactionLine *line = (CReactionLine*)m_flipLines.At(i);
         DeleteReactionLine(line, i, m_flipLines);
      }
      delete m_flipLines;
      
      delete m_processedOB_IDs;
      
      CentralLog(LOG_FULL, m_logLevel, 0, "[RZ]", "کلاس CReactionZones متوقف شد.");
   }
   
   //--- تابع اصلی پردازش (در OnTick با شرط NewBar)
   bool ProcessNewBar(void)
   {
      datetime currentBarTime = iTime(m_symbol, m_timeframe, 0);
      if (currentBarTime == m_lastProcessedBarTime) return false;
      m_lastProcessedBarTime = currentBarTime;
      
      if (!IsValidDependencies()) return false;
      
      CentralLog(LOG_FULL, m_logLevel, 0, "[RZ]", "شروع پردازش بار جدید.");
      
      bool changed = false;
      
      // ابطال خطوط قدیمی
      InvalidateOldLines();
      
      // چک برای OBهای جدید (unmitigated)
      int obCount = m_major.GetUnmitigatedOBCount();
      for (int i = 0; i < obCount; i++)
      {
         OrderBlock ob = m_major.GetUnmitigatedOB(i);
         if (IsOBProcessed(ob)) continue;
         
         // گرفتن زمان شکست ساختار مرتبط (آخرین BoS/CHoCH قبل از OB)
         datetime break_time = m_major.GetLastBoSTime();
         if (break_time == 0) break_time = m_major.GetLastChoChTime();
         if (break_time == 0) continue;
         
         // محاسبه Draw
         CReactionLine *drawLine = CalculateDrawLine(ob, break_time);
         if (CheckPointer(drawLine) != POINTER_INVALID)
         {
            AddToListWithCapacity(m_drawLines, drawLine);
            if (m_showDrawing) DrawReactionLine(drawLine);
            changed = true;
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "Draw جدید شناسایی شد: قیمت " + DoubleToString(drawLine.price, _Digits));
            
            // محاسبه Flip بر اساس Draw
            CReactionLine *flipLine = CalculateFlipLine(drawLine, ob, break_time);
            if (CheckPointer(flipLine) != POINTER_INVALID)
            {
               AddToListWithCapacity(m_flipLines, flipLine);
               if (m_showDrawing) DrawReactionLine(flipLine);
               changed = true;
               CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "Flip جدید (" + flipLine.flipType + ") شناسایی شد: قیمت " + DoubleToString(flipLine.price, _Digits));
            }
         }
         
         // علامت‌گذاری OB به عنوان پردازش شده
         MarkOBAsProcessed(ob);
      }
      
      // به‌روزرسانی موقعیت تمام لیبل‌ها
      UpdateAllLabelPositions();
      
      CentralLog(LOG_FULL, m_logLevel, 0, "[RZ]", "پایان پردازش بار جدید.");
      return changed;
   }
   
   //--- توابع دسترسی عمومی
   int GetDrawCount(void) const { return m_drawLines.Total(); }
   int GetFlipCount(void) const { return m_flipLines.Total(); }
   
   CReactionLine* GetDrawLine(int index) const
   {
      if (index < 0 || index >= m_drawLines.Total()) return NULL;
      return (CReactionLine*)m_drawLines.At(index);
   }
   
   CReactionLine* GetFlipLine(int index) const
   {
      if (index < 0 || index >= m_flipLines.Total()) return NULL;
      return (CReactionLine*)m_flipLines.At(index);
   }
   
   //--- تابع عمومی برای به‌روزرسانی موقعیت لیبل‌ها (برای فراخوانی در OnTick)
   void UpdateGraphics(void)
   {
      UpdateAllLabelPositions();
   }
};
