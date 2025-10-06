//+------------------------------------------------------------------+
//|                                MarketStructureLibrary.mqh       |
//|                                  Copyright 2025, Khajavi & Gemini |
//|                                             Powerd by Gemini AI |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi & Gemini"
#property link      "https://www.google.com"
#property version   "5.60"

//+------------------------------------------------------------------+
//| ساختارهای داده و شمارنده‌ها (Structs & Enums)                     |
//+------------------------------------------------------------------+

//--- ساختار داده برای نگهداری اطلاعات یک نقطه محوری سقف یا کف (Swing Point)
struct SwingPoint
{
   double   price;      // قیمت دقیق سقف یا کف
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
   bool     consumed;   // وضعیت مصرف شدگی: آیا قیمت به ناحیه بازگشته است؟ (حذف خواهد شد)
};

//--- شمارنده (Enum) برای نگهداری وضعیت فعلی روند بازار
enum TREND_TYPE
{
   TREND_BULLISH,      // روند صعودی (سقف‌ها و کف‌های بالاتر)
   TREND_BEARISH,      // روند نزولی (سقف‌ها و کف‌های پایین‌تر)
   TREND_NONE          // بدون روند مشخص یا در حالت رنج
};

//--- تابع کمکی برای لاگ‌گیری (Helper Function for Logging)
void LogEvent(string message, bool enabled, string prefix = "")
{
   if(enabled)
   {
      Print(prefix + message);
   }
}

//==================================================================//
//                   کلاس ۲: مدیریت FVG (FVGManager)                  //
//==================================================================//
class FVGManager
{
private:
   //--- متغیرهای مربوط به تنظیمات و محیط اجرا
   string           m_symbol;               // نماد جفت ارز برای دسترسی به داده‌ها
   ENUM_TIMEFRAMES  m_timeframe;            // تایم فریم اختصاصی این آبجکت
   long             m_chartId;              // ID چارت اجرایی اکسپرت
   bool             m_enableLogging;        // فعال/غیرفعال بودن لاگ
   string           m_timeframeSuffix;      // پسوند تایم‌فریم (مثلاً "(H1)") برای نامگذاری اشیاء
   bool             m_showDrawing;          // کنترل نمایش ترسیمات FVG روی چارت

   //--- متغیرهای حالت
   FVG              m_fvgArray[];           // آرایه داینامیک برای نگهداری نواحی FVG شناسایی شده
   datetime         m_lastFVGCheckTime;     // برای جلوگیری از اجرای تکراری شناسایی FVG

public:
   //+------------------------------------------------------------------+
   //| سازنده کلاس (Constructor)                                       |
   //+------------------------------------------------------------------+
   FVGManager(string symbol, ENUM_TIMEFRAMES timeframe, long chartId, bool enableLogging, bool showDrawing)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      m_enableLogging = enableLogging;
      m_showDrawing = showDrawing;
      
      // تنظیم پسوند تایم فریم برای نمایش MTF
      m_timeframeSuffix = " (" + EnumToString(timeframe) + ")";

      // تنظیم آرایه به صورت سری: اندیس 0 جدیدترین عنصر است
      ArraySetAsSeries(m_fvgArray, true);
      ArrayResize(m_fvgArray, 0);
      
      m_lastFVGCheckTime = 0;
      
      // در صورت اجرای مجدد، اشیاء قبلی این تایم فریم را پاک کن
      if (m_showDrawing) ObjectsDeleteAll(m_chartId, 0, -1, m_timeframeSuffix);
      
      LogEvent("کلاس FVGManager برای نماد " + symbol + " و تایم فریم " + EnumToString(timeframe) + " آغاز به کار کرد.", m_enableLogging, "[FVG]");
   }

   //+------------------------------------------------------------------+
   //| مخرب کلاس (Destructor) - برای پاک کردن اشیاء هنگام حذف آبجکت     |
   //+------------------------------------------------------------------+
   ~FVGManager()
   {
      if (m_showDrawing) ObjectsDeleteAll(m_chartId, 0, -1, m_timeframeSuffix);
      LogEvent("کلاس FVGManager متوقف و اشیاء ترسیمی آن پاک شدند.", m_enableLogging, "[FVG]");
   }
   
   //+------------------------------------------------------------------+
   //| توابع مدیریت FVG (با حفظ کامل منطق اصلی)                        |
   //+------------------------------------------------------------------+
   
   //--- ۱. بررسی ابطال FVG در لحظه (با قیمت‌های ASK/BID) - هر تیک اجرا می‌شود
   bool ProcessNewTick()
   {
      double currentAsk = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double currentBid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      bool invalidatedNow = false;

      for(int i = 0; i < ArraySize(m_fvgArray); i++)
      {
         if(m_fvgArray[i].consumed) continue;

         bool isInvalidated = false;
         string typeStr = m_fvgArray[i].isBullish ? "Bullish" : "Bearish";

         if(m_fvgArray[i].isBullish && currentBid < m_fvgArray[i].lowPrice) isInvalidated = true; // ابطال صعودی
         if(!m_fvgArray[i].isBullish && currentAsk > m_fvgArray[i].highPrice) isInvalidated = true; // ابطال نزولی

         if(isInvalidated)
         {
            // حذف FVG ابطال شده
            if (m_showDrawing)
            {
                string objName = "FVG_" + TimeToString(m_fvgArray[i].time) + "_" + typeStr + m_timeframeSuffix;
                ObjectDelete(m_chartId, objName);
                ObjectDelete(m_chartId, objName + "_Text");
            }
            LogEvent("FVG از نوع " + typeStr + " در زمان " + TimeToString(m_fvgArray[i].time) + " ابطال و حذف شد.", m_enableLogging, "[FVG]");

            ArrayRemove(m_fvgArray, i, 1);
            i--;
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
      if (m_showDrawing) UpdateFVGTexPositions();
      
      return newFVGFound;
   }

private:
   //--- تابع کمکی: بررسی بدنه قوی
   bool IsStrongBody(int index)
   {
      double open = iOpen(m_symbol, m_timeframe, index);
      double close = iClose(m_symbol, m_timeframe, index);
      double high = iHigh(m_symbol, m_timeframe, index);
      double low = iLow(m_symbol, m_timeframe, index);

      double body = MathAbs(open - close);
      double shadow = (high - low) - body;

      return (body > shadow); // شرط بدنه قوی
   }

   //--- تابع: شناسایی FVG جدید (حفظ کامل منطق فیلترها)
   bool IdentifyFVG()
   {
      if(m_lastFVGCheckTime == iTime(m_symbol, m_timeframe, 1)) return false;
      m_lastFVGCheckTime = iTime(m_symbol, m_timeframe, 1);

      if(iBars(m_symbol, m_timeframe) < 4) return false;

      int i = 2; // کندل میانی FVG

      if (!IsStrongBody(i)) return false;

      double open1 = iOpen(m_symbol, m_timeframe, i-1); double close1 = iClose(m_symbol, m_timeframe, i-1);
      double open2 = iOpen(m_symbol, m_timeframe, i); double close2 = iClose(m_symbol, m_timeframe, i);
      double open3 = iOpen(m_symbol, m_timeframe, i+1); double close3 = iClose(m_symbol, m_timeframe, i+1);

      bool allBullish = (close1 > open1) && (close2 > open2) && (close3 > open3);
      bool allBearish = (close1 < open1) && (close2 < open2) && (close3 < open3);

      if (! (allBullish || allBearish)) return false; // هم‌جهت بودن کندل‌ها

      double high1 = iHigh(m_symbol, m_timeframe, i - 1); double low1  = iLow(m_symbol, m_timeframe, i - 1);
      double high3 = iHigh(m_symbol, m_timeframe, i + 1); double low3  = iLow(m_symbol, m_timeframe, i + 1);
      double body2 = MathAbs(open2 - close2);

      // FVG صعودی
      if (low1 > high3)
      {
          double fvgSize = low1 - high3;
          if (fvgSize < 0.5 * body2) return false; // فیلتر اندازه

          for(int j=0; j<ArraySize(m_fvgArray); j++) { if(m_fvgArray[j].time == iTime(m_symbol, m_timeframe, i) && m_fvgArray[j].isBullish) return false; } // تکراری

          AddFVG(true, high3, low1, iTime(m_symbol, m_timeframe, i));
          return true;
      }

      // FVG نزولی
      if (high1 < low3)
      {
          double fvgSize = low3 - high1;
          if (fvgSize < 0.5 * body2) return false; // فیلتر اندازه

          for(int j=0; j<ArraySize(m_fvgArray); j++) { if(m_fvgArray[j].time == iTime(m_symbol, m_timeframe, i) && !m_fvgArray[j].isBullish) return false; } // تکراری

          AddFVG(false, low3, high1, iTime(m_symbol, m_timeframe, i));
          return true;
      }

      return false;
   }
   
   //--- تابع: اضافه کردن FVG جدید و رسم آن
   void AddFVG(bool isBullish, double highPrice, double lowPrice, datetime time)
   {
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

      FVG newFVG;
      newFVG.isBullish = isBullish;
      newFVG.highPrice = highPrice;
      newFVG.lowPrice = lowPrice;
      newFVG.time = time;
      newFVG.consumed = false;

      FVG temp[1]; temp[0] = newFVG;
      if (ArrayInsert(m_fvgArray, temp, 0))
      {
         if (m_showDrawing) drawFVG(m_fvgArray[0]);
         string typeStr = isBullish ? "Bullish" : "Bearish";
         LogEvent("FVG جدید از نوع " + typeStr + " در زمان " + TimeToString(time) + " شناسایی شد.", m_enableLogging, "[FVG]");
      }
      else
      {
          LogEvent("خطا: نتوانست FVG جدید را در آرایه درج کند.", m_enableLogging, "[FVG]");
      }
   }
   
   //--- تابع: به‌روزرسانی موقعیت متن‌های FVG برای ماندن در وسط زون
   void UpdateFVGTexPositions()
   {
      datetime currentTime = iTime(NULL, PERIOD_CURRENT, 0); // زمان کندل جاری چارت اصلی

      for(int i = 0; i < ArraySize(m_fvgArray); i++)
      {
         if(m_fvgArray[i].consumed) continue;

         string typeStr = m_fvgArray[i].isBullish ? "Bullish" : "Bearish";
         string textName = "FVG_" + TimeToString(m_fvgArray[i].time) + "_" + typeStr + m_timeframeSuffix + "_Text";

         // محاسبه زمان وسط بین زمان شروع FVG و زمان فعلی چارت اصلی (برای امتداد)
         datetime midTime = m_fvgArray[i].time + (currentTime - m_fvgArray[i].time) / 2;
         double midPrice = (m_fvgArray[i].highPrice + m_fvgArray[i].lowPrice) / 2;

         ObjectMove(m_chartId, textName, 0, midTime, midPrice);
      }
   }

   //--- تابع ترسیمی: رسم FVG (با قابلیت MTF)
   void drawFVG(const FVG &fvg)
   {
      string typeStr = fvg.isBullish ? "Bullish" : "Bearish";
      string objName = "FVG_" + TimeToString(fvg.time) + "_" + typeStr + m_timeframeSuffix;
      string textName = objName + "_Text";

      color fvgColor = fvg.isBullish ? C'144,238,144' : C'255,160,160'; // LightGreen / LightCoral

      datetime endTime = D'2030.01.01 00:00'; // امتداد زون

      // ایجاد مستطیل
      ObjectCreate(m_chartId, objName, OBJ_RECTANGLE, 0, fvg.time, fvg.highPrice, endTime, fvg.lowPrice);
      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, fvgColor);
      ObjectSetInteger(m_chartId, objName, OBJPROP_FILL, true);
      ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, true);
      ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTABLE, false);

      // محاسبه موقعیت اولیه وسط برای متن
      datetime currentTime = iTime(NULL, PERIOD_CURRENT, 0);
      datetime midTime = fvg.time + (currentTime - fvg.time) / 2;
      double midPrice = (fvg.highPrice + fvg.lowPrice) / 2;

      ObjectCreate(m_chartId, textName, OBJ_TEXT, 0, midTime, midPrice);
      ObjectSetString(m_chartId, textName, OBJPROP_TEXT, "FVG" + m_timeframeSuffix); // اضافه کردن پسوند
      ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, clrDimGray);
      ObjectSetInteger(m_chartId, textName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(m_chartId, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
      ObjectSetInteger(m_chartId, textName, OBJPROP_SELECTABLE, false);
   }

public:
   //+------------------------------------------------------------------+
   //| توابع دسترسی عمومی (Accessors)                                  |
   //+------------------------------------------------------------------+
   FVG GetFVG(int index) const { return m_fvgArray[index]; }
   int GetFVGCount() const { return ArraySize(m_fvgArray); }
};

//==================================================================//
//               کلاس ۱: مدیریت ساختار بازار (MarketStructure)       //
//==================================================================//
class MarketStructure
{
private:
   //--- متغیرهای مربوط به تنظیمات و محیط اجرا
   string           m_symbol;               // نماد جفت ارز
   ENUM_TIMEFRAMES  m_timeframe;            // تایم فریم اختصاصی این آبجکت
   long             m_chartId;              // ID چارت اجرایی اکسپرت
   bool             m_enableLogging;        // فعال/غیرفعال بودن لاگ
   string           m_timeframeSuffix;      // پسوند تایم‌فریم (مثلاً "(H1)") برای نامگذاری اشیاء
   bool             m_showDrawing;          // کنترل نمایش ترسیمات ساختار روی چارت
   int              m_fibUpdateLevel;       // سطح اصلاح فیبو (مثلاً 35)
   int              m_fractalLength;        // طول فرکتال (مثلاً 10)
   
   //--- متغیرهای حالت
   SwingPoint       m_swingHighs_Array[];   // آرایه سقف‌ها
   SwingPoint       m_swingLows_Array[];    // آرایه کف‌ها
   TREND_TYPE       m_currentTrend;         // وضعیت فعلی روند
   SwingPoint       m_pivotHighForTracking; // نقطه 100% فیبو (ثابت) در فاز نزولی
   SwingPoint       m_pivotLowForTracking;  // نقطه 100% فیبو (ثابت) در فاز صعودی
   bool             m_isTrackingHigh;       // فلگ: آیا در فاز "شکار سقف جدید" هستیم؟
   bool             m_isTrackingLow;        // فلگ: آیا در فاز "شکار کف جدید" هستیم؟
   datetime         m_lastCHoCHTime;        // زمان آخرین CHoCH
   datetime         m_lastBoSTime;          // زمان آخرین BoS
   string           m_trendObjectName;      // نام ثابت لیبل روند

public:
   //+------------------------------------------------------------------+
   //| سازنده کلاس (Constructor)                                       |
   //+------------------------------------------------------------------+
   MarketStructure(string symbol, ENUM_TIMEFRAMES timeframe, long chartId, bool enableLogging, bool showDrawing, int fibUpdateLevel, int fractalLength)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      m_enableLogging = enableLogging;
      m_showDrawing = showDrawing;
      m_fibUpdateLevel = fibUpdateLevel;
      m_fractalLength = fractalLength;
      
      // تنظیم پسوند تایم فریم برای نمایش MTF
      m_timeframeSuffix = " (" + EnumToString(timeframe) + ")";
      m_trendObjectName = "TrendLabel" + m_timeframeSuffix; // نام لیبل روند با پسوند

      // تنظیم آرایه‌ها به صورت سری
      ArraySetAsSeries(m_swingHighs_Array, true);
      ArraySetAsSeries(m_swingLows_Array, true);
      
      ArrayResize(m_swingHighs_Array, 0);
      ArrayResize(m_swingLows_Array, 0);
      
      m_currentTrend = TREND_NONE;
      m_isTrackingHigh = false;
      m_isTrackingLow = false;
      m_lastCHoCHTime = 0;
      m_lastBoSTime = 0;

      // مقداردهی اولیه ساختارها
      m_pivotHighForTracking.price = 0; m_pivotHighForTracking.time = 0; m_pivotHighForTracking.bar_index = -1;
      m_pivotLowForTracking.price = 0; m_pivotLowForTracking.time = 0; m_pivotLowForTracking.bar_index = -1;
      
      // در صورت اجرای مجدد، اشیاء قبلی این تایم فریم را پاک کن
      if (m_showDrawing) ObjectsDeleteAll(m_chartId, 0, -1, m_timeframeSuffix);
      
      // شناسایی ساختار اولیه
      IdentifyInitialStructure();
      UpdateTrendLabel();
      
      LogEvent("کلاس MarketStructure برای نماد " + symbol + " و تایم فریم " + EnumToString(timeframe) + " آغاز به کار کرد.", m_enableLogging, "[SMC]");
   }

   //+------------------------------------------------------------------+
   //| مخرب کلاس (Destructor)                                          |
   //+------------------------------------------------------------------+
   ~MarketStructure()
   {
      if (m_showDrawing) ObjectsDeleteAll(m_chartId, 0, -1, m_timeframeSuffix);
      LogEvent("کلاس MarketStructure متوقف و اشیاء ترسیمی آن پاک شدند.", m_enableLogging, "[SMC]");
   }
   
   //+------------------------------------------------------------------+
   //| تابع اصلی: پردازش کندل بسته شده (در OnTick با شرط NewBar فراخوانی شود) |
   //+------------------------------------------------------------------+
   bool ProcessNewBar()
   {
      bool structureChanged = false;
      
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
            if (m_showDrawing) DrawTrackingFibonacci(); // به‌روزرسانی فیبوناچی ردیاب
         }
      }
      
      //--- ۳. به‌روزرسانی نمایش روند
      if(UpdateTrendLabel()) structureChanged = true;
      
      return structureChanged;
   }

private:
   //--- شناسایی ساختار اولیه بازار (بر مبنای فرکتال)
   void IdentifyInitialStructure()
   {
      int barsCount = iBars(m_symbol, m_timeframe);
      if(barsCount < m_fractalLength * 2 + 1) return;
      
      for(int i = m_fractalLength; i < barsCount - m_fractalLength; i++)
      {
         bool isSwingHigh = true;
         bool isSwingLow = true;

         for(int j = 1; j <= m_fractalLength; j++)
         {
             if(iHigh(m_symbol, m_timeframe, i) < iHigh(m_symbol, m_timeframe, i - j) || iHigh(m_symbol, m_timeframe, i) < iHigh(m_symbol, m_timeframe, i + j)) isSwingHigh = false;
             if(iLow(m_symbol, m_timeframe, i) > iLow(m_symbol, m_timeframe, i - j) || iLow(m_symbol, m_timeframe, i) > iLow(m_symbol, m_timeframe, i + j)) isSwingLow = false;
         }

         if(isSwingHigh && ArraySize(m_swingHighs_Array) == 0) AddSwingHigh(iHigh(m_symbol, m_timeframe, i), iTime(m_symbol, m_timeframe, i), i);
         if(isSwingLow && ArraySize(m_swingLows_Array) == 0) AddSwingLow(iLow(m_symbol, m_timeframe, i), iTime(m_symbol, m_timeframe, i), i);

         if(ArraySize(m_swingHighs_Array) > 0 && ArraySize(m_swingLows_Array) > 0) break;
      }
   }
   
   //--- بررسی شکست سقف یا کف (حفظ کامل منطق اصلی)
   void CheckForBreakout()
   {
      if(m_isTrackingHigh || m_isTrackingLow) return;
      
      double close_1 = iClose(m_symbol, m_timeframe, 1);
      SwingPoint lastHigh = m_swingHighs_Array[0];
      SwingPoint lastLow = m_swingLows_Array[0];

      //--- شکست سقف (BoS/CHoCH صعودی)
      if(close_1 > lastHigh.price)
      {
         bool isCHoCH = (m_currentTrend == TREND_BEARISH);
         string breakType = isCHoCH ? "CHoCH" : "BoS";
         if (isCHoCH) m_lastCHoCHTime = iTime(m_symbol, m_timeframe, 1); else m_lastBoSTime = iTime(m_symbol, m_timeframe, 1);
         LogEvent(">>> رویداد: شکست سقف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد.", m_enableLogging, "[SMC]");
         if (m_showDrawing) drawBreak(lastHigh, iTime(m_symbol, m_timeframe, 1), close_1, true, isCHoCH);

         m_pivotLowForTracking = FindOppositeSwing(lastHigh.time, iTime(m_symbol, m_timeframe, 1), false); // 100% فیبو (ثابت)

         m_isTrackingHigh = true; m_isTrackingLow = false;
         LogEvent("--> فاز جدید: [شکار سقف] فعال شد. نقطه 100% فیبو (ثابت) در کف " + DoubleToString(m_pivotLowForTracking.price, _Digits) + " ثبت شد.", m_enableLogging, "[SMC]");
      }
      //--- شکست کف (BoS/CHoCH نزولی)
      else if(close_1 < lastLow.price)
      {
         bool isCHoCH = (m_currentTrend == TREND_BULLISH);
         string breakType = isCHoCH ? "CHoCH" : "BoS";
         if (isCHoCH) m_lastCHoCHTime = iTime(m_symbol, m_timeframe, 1); else m_lastBoSTime = iTime(m_symbol, m_timeframe, 1);
         LogEvent(">>> رویداد: شکست کف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد.", m_enableLogging, "[SMC]");
         if (m_showDrawing) drawBreak(lastLow, iTime(m_symbol, m_timeframe, 1), close_1, false, isCHoCH);

         m_pivotHighForTracking = FindOppositeSwing(lastLow.time, iTime(m_symbol, m_timeframe, 1), true); // 100% فیبو (ثابت)

         m_isTrackingLow = true; m_isTrackingHigh = false;
         LogEvent("--> فاز جدید: [شکار کف] فعال شد. نقطه 100% فیبو (ثابت) در سقف " + DoubleToString(m_pivotHighForTracking.price, _Digits) + " ثبت شد.", m_enableLogging, "[SMC]");
      }
   }
   
   //--- یافتن نقطه محوری مقابل (پیوت - 100% فیبو)
   SwingPoint FindOppositeSwing(datetime brokenSwingTime, datetime breakTime, bool findHigh)
   {
       double extremePrice = findHigh ? 0 : DBL_MAX;
       datetime extremeTime = 0;
       int extremeIndex = -1;

       int startBar = iBarShift(m_symbol, m_timeframe, breakTime, false);
       int endBar = iBarShift(m_symbol, m_timeframe, brokenSwingTime, false);

       SwingPoint errorResult; errorResult.price = 0; errorResult.time = 0; errorResult.bar_index = -1;

       if(startBar == -1 || endBar == -1 || startBar >= endBar) return errorResult;

       for (int i = startBar + 1; i <= endBar; i++)
       {
           if (findHigh)
           {
               if (iHigh(m_symbol, m_timeframe, i) > extremePrice) { extremePrice = iHigh(m_symbol, m_timeframe, i); extremeTime = iTime(m_symbol, m_timeframe, i); extremeIndex = i; }
           }
           else
           {
               if (iLow(m_symbol, m_timeframe, i) < extremePrice) { extremePrice = iLow(m_symbol, m_timeframe, i); extremeTime = iTime(m_symbol, m_timeframe, i); extremeIndex = i; }
           }
       }

       SwingPoint result; result.price = extremePrice; result.time = extremeTime; result.bar_index = extremeIndex;

       if (extremeIndex != -1)
       {
           // ثبت نقطه 100% فیبو به عنوان Swing Point جدید (دقیقا مطابق منطق اصلی)
           if (findHigh) AddSwingHigh(extremePrice, extremeTime, extremeIndex); else AddSwingLow(extremePrice, extremeTime, extremeIndex);
           return result;
       }
       return errorResult;
   }
   
   //--- یافتن سقف/کف مطلق در یک محدوده زمانی (برای 0% فیبو)
   SwingPoint FindExtremePrice(int startBar, int endBar, bool findHigh)
   {
       double extremePrice = findHigh ? 0 : DBL_MAX;
       datetime extremeTime = 0;
       int extremeIndex = -1;

       for (int i = startBar; i <= endBar; i++)
       {
           if (findHigh)
           {
               if (iHigh(m_symbol, m_timeframe, i) > extremePrice) { extremePrice = iHigh(m_symbol, m_timeframe, i); extremeTime = iTime(m_symbol, m_timeframe, i); extremeIndex = i; }
           }
           else
           {
               if (iLow(m_symbol, m_timeframe, i) < extremePrice) { extremePrice = iLow(m_symbol, m_timeframe, i); extremeTime = iTime(m_symbol, m_timeframe, i); extremeIndex = i; }
           }
       }

       SwingPoint result; result.price = extremePrice; result.time = extremeTime; result.bar_index = extremeIndex;
       return result;
   }
   
   //--- ردیابی و تایید Swing Point جدید با آپدیت 0% فیبو (حفظ کامل منطق اصلی)
   bool CheckForNewSwingPoint()
   {
       //--- ۱. ردیابی سقف جدید (HH/LH) بعد از شکست صعودی
       if (m_isTrackingHigh)
       {
           if (m_pivotLowForTracking.bar_index == -1) return false;
           
           SwingPoint current0Per;
           int startBar = iBarShift(m_symbol, m_timeframe, m_pivotLowForTracking.time, false);
           current0Per = FindExtremePrice(1, startBar, true);

           if (current0Per.bar_index == -1 || current0Per.price <= m_pivotLowForTracking.price) return false;

           double range = current0Per.price - m_pivotLowForTracking.price;
           double fibLevel = current0Per.price - (range * (m_fibUpdateLevel / 100.0));
           double close_1 = iClose(m_symbol, m_timeframe, 1);

           if (close_1 <= fibLevel) // شرط تایید (بسته شدن در 35% یا پایین‌تر)
           {
               LogEvent("<<< تایید شد: شرط اصلاح " + IntegerToString(m_fibUpdateLevel) + "٪ برای سقف جدید برقرار شد.", m_enableLogging, "[SMC]");
               AddSwingHigh(current0Per.price, current0Per.time, current0Per.bar_index);
               m_isTrackingHigh = false;
               return true;
           }
       }

       //--- ۲. ردیابی کف جدید (LL/HL) بعد از شکست نزولی
       else if (m_isTrackingLow)
       {
           if (m_pivotHighForTracking.bar_index == -1) return false;

           SwingPoint current0Per;
           int startBar = iBarShift(m_symbol, m_timeframe, m_pivotHighForTracking.time, false);
           current0Per = FindExtremePrice(1, startBar, false);

           if (current0Per.bar_index == -1 || current0Per.price >= m_pivotHighForTracking.price) return false;

           double range = m_pivotHighForTracking.price - current0Per.price;
           double fibLevel = current0Per.price + (range * (m_fibUpdateLevel / 100.0));
           double close_1 = iClose(m_symbol, m_timeframe, 1);

           if (close_1 >= fibLevel) // شرط تایید (بسته شدن در 35% یا بالاتر)
           {
               LogEvent("<<< تایید شد: شرط اصلاح " + IntegerToString(m_fibUpdateLevel) + "٪ برای کف جدید برقرار شد.", m_enableLogging, "[SMC]");
               AddSwingLow(current0Per.price, current0Per.time, current0Per.bar_index);
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

       // تنظیم سطوح
       ObjectSetDouble(m_chartId, objName, OBJPROP_LEVELVALUE, 0, 0.0);
       ObjectSetString(m_chartId, objName, OBJPROP_LEVELTEXT, 0, "0% (Movable)" + m_timeframeSuffix);

       ObjectSetDouble(m_chartId, objName, OBJPROP_LEVELVALUE, 1, (double)m_fibUpdateLevel / 100.0);
       ObjectSetString(m_chartId, objName, OBJPROP_LEVELTEXT, 1, IntegerToString(m_fibUpdateLevel) + "% (Confirmation)" + m_timeframeSuffix);

       ObjectSetDouble(m_chartId, objName, OBJPROP_LEVELVALUE, 2, 1.0);
       ObjectSetString(m_chartId, objName, OBJPROP_LEVELTEXT, 2, "100% (Fixed Pivot)" + m_timeframeSuffix);

       for(int i = 3; i < 10; i++) ObjectSetDouble(m_chartId, objName, OBJPROP_LEVELVALUE, i, 0.0);
   }

   //--- اضافه کردن سقف جدید و ترسیم آن (با مدیریت ظرفیت و نمایش MTF)
   void AddSwingHigh(double price, datetime time, int bar_index)
   {
      if(ArraySize(m_swingHighs_Array) >= 2)
      {
         if (m_showDrawing)
         {
             ObjectDelete(m_chartId, "High_" + TimeToString(m_swingHighs_Array[1].time) + m_timeframeSuffix);
             ObjectDelete(m_chartId, "High_" + TimeToString(m_swingHighs_Array[1].time) + m_timeframeSuffix + "_Text");
         }
         ArrayRemove(m_swingHighs_Array, ArraySize(m_swingHighs_Array) - 1, 1);
      }

      int newSize = ArraySize(m_swingHighs_Array) + 1;
      ArrayResize(m_swingHighs_Array, newSize);
      m_swingHighs_Array[0].price = price;
      m_swingHighs_Array[0].time = time;
      m_swingHighs_Array[0].bar_index = bar_index;

      if (m_showDrawing) drawSwingPoint(m_swingHighs_Array[0], true);
      LogEvent("سقف جدید در قیمت " + DoubleToString(price, _Digits) + " ثبت شد.", m_enableLogging, "[SMC]");
   }

   //--- اضافه کردن کف جدید و ترسیم آن (با مدیریت ظرفیت و نمایش MTF)
   void AddSwingLow(double price, datetime time, int bar_index)
   {
      if(ArraySize(m_swingLows_Array) >= 2)
      {
         if (m_showDrawing)
         {
             ObjectDelete(m_chartId, "Low_" + TimeToString(m_swingLows_Array[1].time) + m_timeframeSuffix);
             ObjectDelete(m_chartId, "Low_" + TimeToString(m_swingLows_Array[1].time) + m_timeframeSuffix + "_Text");
         }
         ArrayRemove(m_swingLows_Array, ArraySize(m_swingLows_Array) - 1, 1);
      }

      int newSize = ArraySize(m_swingLows_Array) + 1;
      ArrayResize(m_swingLows_Array, newSize);
      m_swingLows_Array[0].price = price;
      m_swingLows_Array[0].time = time;
      m_swingLows_Array[0].bar_index = bar_index;

      if (m_showDrawing) drawSwingPoint(m_swingLows_Array[0], false);
      LogEvent("کف جدید در قیمت " + DoubleToString(price, _Digits) + " ثبت شد.", m_enableLogging, "[SMC]");
   }

   //--- به‌روزرسانی لیبل روند (با پسوند تایم فریم)
   bool UpdateTrendLabel()
   {
      TREND_TYPE oldTrend = m_currentTrend;

      if(ArraySize(m_swingHighs_Array) >= 2 && ArraySize(m_swingLows_Array) >= 2)
      {
         SwingPoint lastHigh = m_swingHighs_Array[0];
         SwingPoint prevHigh = m_swingHighs_Array[1];
         SwingPoint lastLow  = m_swingLows_Array[0];
         SwingPoint prevLow  = m_swingLows_Array[1];

         if(lastHigh.price > prevHigh.price && lastLow.price > prevLow.price) m_currentTrend = TREND_BULLISH;
         else if(lastHigh.price < prevHigh.price && lastLow.price < prevLow.price) m_currentTrend = TREND_BEARISH;
         else m_currentTrend = TREND_NONE;
      }
      else m_currentTrend = TREND_NONE;

      // آپدیت گرافیکی لیبل روند
      if(m_showDrawing && oldTrend != m_currentTrend)
      {
         ObjectDelete(m_chartId, m_trendObjectName);
         string trendText; color trendColor;
         switch(m_currentTrend)
         {
            case TREND_BULLISH: trendText = "Bullish Trend (HH/HL)"; trendColor = clrDeepSkyBlue; LogEvent("وضعیت روند به صعودی تغییر یافت.", m_enableLogging, "[SMC]"); break;
            case TREND_BEARISH: trendText = "Bearish Trend (LL/LH)"; trendColor = clrOrangeRed; LogEvent("وضعیت روند به نزولی تغییر یافت.", m_enableLogging, "[SMC]"); break;
            default: trendText = "No Trend / Ranging"; trendColor = clrGray; LogEvent("وضعیت روند به بدون روند تغییر یافت.", m_enableLogging, "[SMC]");
         }
         
         ObjectCreate(m_chartId, m_trendObjectName, OBJ_LABEL, 0, 0, 0);
         ObjectSetString(m_chartId, m_trendObjectName, OBJPROP_TEXT, trendText + m_timeframeSuffix); // اضافه کردن پسوند
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_XDISTANCE, 10);
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_YDISTANCE, (EnumToInteger(m_timeframe) / 60) * 15 + 20); // تغییر موقعیت بر اساس تایم فریم
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_COLOR, trendColor);
         ObjectSetInteger(m_chartId, m_trendObjectName, OBJPROP_FONTSIZE, 12);
         ObjectSetString(m_chartId, m_trendObjectName, OBJPROP_FONT, "Arial");
         return true;
      }
      return false;
   }

   //--- ترسیم سقف/کف (با پسوند تایم فریم)
   void drawSwingPoint(const SwingPoint &sp, bool isHigh)
   {
      string objName = (isHigh ? "H_" : "L_") + TimeToString(sp.time) + m_timeframeSuffix;
      string textName = objName + "_Text";
      ObjectDelete(m_chartId, objName);
      ObjectDelete(m_chartId, textName);

      ObjectCreate(m_chartId, objName, OBJ_ARROW, 0, sp.time, sp.price);
      ObjectSetInteger(m_chartId, objName, OBJPROP_ARROWCODE, 77);
      ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, isHigh ? clrDodgerBlue : clrRed);
      ObjectSetInteger(m_chartId, objName, OBJPROP_ANCHOR, isHigh ? ANCHOR_BOTTOM : ANCHOR_TOP);

      ObjectCreate(m_chartId, textName, OBJ_TEXT, 0, sp.time, sp.price);
      ObjectSetString(m_chartId, textName, OBJPROP_TEXT, (isHigh ? "H" : "L") + m_timeframeSuffix);
      ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, isHigh ? clrDodgerBlue : clrRed);
      ObjectSetInteger(m_chartId, textName, OBJPROP_ANCHOR, isHigh ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
   }

   //--- ترسیم شکست (BoS/CHoCH) (با پسوند تایم فریم)
   void drawBreak(const SwingPoint &brokenSwing, datetime breakTime, double breakPrice, bool isHighBreak, bool isCHoCH)
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

       // شیفت زمانی برای فاصله بیشتر از کندل (20% عرض کندل)
       datetime textTime = breakTime + PeriodSeconds(m_timeframe) / 5;

       ObjectCreate(m_chartId, textName, OBJ_TEXT, 0, textTime, breakPrice);
       ObjectSetString(m_chartId, textName, OBJPROP_TEXT, breakType + m_timeframeSuffix); // اضافه کردن پسوند
       ObjectSetInteger(m_chartId, textName, OBJPROP_COLOR, breakColor);
       ObjectSetInteger(m_chartId, textName, OBJPROP_ANCHOR, isHighBreak ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
   }
   
public:
   //+------------------------------------------------------------------+
   //| توابع دسترسی عمومی (Accessors) - برای استفاده اکسپرت معاملاتی     |
   //+------------------------------------------------------------------+
   
   //--- زمان آخرین CHoCH/BoS (به صورت زمان نه اندیس)
   datetime GetLastChoChTime() const { return m_lastCHoCHTime; }
   datetime GetLastBoSTime() const { return m_lastBoSTime; }
   
   //--- آخرین سقف و کف ساختاری (به صورت ساختار کامل SwingPoint)
   SwingPoint GetLastSwingHigh() const { return (ArraySize(m_swingHighs_Array) > 0) ? m_swingHighs_Array[0] : m_swingHighs_Array[0]; } // برمی‌گرداند 0 در صورت خالی بودن
   SwingPoint GetLastSwingLow() const { return (ArraySize(m_swingLows_Array) > 0) ? m_swingLows_Array[0] : m_swingLows_Array[0]; }
   
   //--- وضعیت روند فعلی
   TREND_TYPE GetCurrentTrend() const { return m_currentTrend; }
};
//+------------------------------------------------------------------+
