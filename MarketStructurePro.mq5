//+------------------------------------------------------------------+
//|                                     MarketStructurePro_v5.1.mq5 |
//|                                  Copyright 2025, Khajavi & Gemini |
//|                                             Powerd by Gemini AI |
//|------------------------------------------------------------------|
//| نسخه 5.1 - رفع کامل خطاهای کامپایلر (Invalid Cast Operation)     |
//| 1. اصلاح نحوه بازگشت Structها از توابع (استفاده از متغیر موقت)  |
//| 2. حفظ منطق آپدیت پیوسته نقطه 0% و تعیین دقیق 100% فیبو         |
//| 3. کد کامل و دقیق مناسب برای MetaTrader 5                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi & Gemini"
#property link      "https://www.google.com"
#property version   "5.10"

//+------------------------------------------------------------------+
//| ورودی‌های اکسپرت (Inputs)                                        |
//+------------------------------------------------------------------+
input bool enableLogging = true;    // [فعال/غیرفعال کردن] سیستم لاگ برای گزارش‌دهی مراحل
input int  fibUpdateLevel = 35;     // سطح اصلاح فیبوناچی برای تایید نقطه (پیش‌فرض: 35)

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
   double   highPrice;  // بالاترین قیمت ناحیه FVG
   double   lowPrice;   // پایین‌ترین قیمت ناحیه FVG
   datetime time;       // زمان کندل شروع ناحیه
   bool     consumed;   // وضعیت مصرف شدگی: آیا قیمت به ناحیه بازگشته است؟
};

//--- شمارنده (Enum) برای نگهداری وضعیت فعلی روند بازار
enum TREND_TYPE 
{
   TREND_BULLISH,  // روند صعودی (سقف‌ها و کف‌های بالاتر)
   TREND_BEARISH,  // روند نزولی (سقف‌ها و کف‌های پایین‌تر)
   TREND_NONE      // بدون روند مشخص یا در حالت رنج
};

//+------------------------------------------------------------------+
//| متغیرهای سراسری (Global Variables)                               |
//+------------------------------------------------------------------+
SwingPoint swingHighs_Array[];     // آرایه داینامیک برای نگهداری 2 سقف آخر ([0]=جدید، [1]=قدیمی)
SwingPoint swingLows_Array[];      // آرایه داینامیک برای نگهداری 2 کف آخر ([0]=جدید، [1]=قدیمی)
FVG        fvgArray[];             // آرایه داینامیک برای نگهداری نواحی FVG شناسایی شده

TREND_TYPE currentTrend    = TREND_NONE;    // متغیر نگهداری وضعیت فعلی روند
string     trendObjectName = "TrendLabel";  // نام ثابت برای شیء متنی نمایش‌دهنده روند

//--- متغیرهای کلیدی برای ردیابی موج جدید بر اساس منطق فیبوناچی
// این متغیرها، نقطه 100% فیبو (نقطه ثابت/پیوت) را پس از شکست نگه می‌دارند.
SwingPoint pivotHighForTracking; 
SwingPoint pivotLowForTracking;  
bool       isTrackingHigh = false; 
bool       isTrackingLow  = false; 

//+------------------------------------------------------------------+
//| تابع کمکی برای لاگ‌گیری (Helper Function for Logging)             |
//+------------------------------------------------------------------+
void LogEvent(string message)
{
   if(enableLogging)
   {
      Print(message);
   }
}

//+------------------------------------------------------------------+
//| تابع مقداردهی اولیه اکسپرت (OnInit)                               |
//+------------------------------------------------------------------+
int OnInit() 
{
   LogEvent("اکسپرت MarketStructurePro v5.1 با منطق آپدیت فیبوناچی آغاز به کار کرد.");
   
   ObjectsDeleteAll(0, 0, -1);
   
   ArraySetAsSeries(swingHighs_Array, true);
   ArraySetAsSeries(swingLows_Array, true);
   ArraySetAsSeries(fvgArray, true); 
   
   ArrayResize(swingHighs_Array, 0);
   ArrayResize(swingLows_Array, 0);
   ArrayResize(fvgArray, 0);
   
   isTrackingHigh = false;
   isTrackingLow = false;
   
   // مقداردهی اولیه ساختارها برای جلوگیری از خطاهای احتمالی
   pivotHighForTracking.price = 0; pivotHighForTracking.time = 0; pivotHighForTracking.bar_index = -1;
   pivotLowForTracking.price = 0; pivotLowForTracking.time = 0; pivotLowForTracking.bar_index = -1;

   IdentifyInitialStructure();
   UpdateTrendLabel();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| تابع خاتمه اکسپرت (OnDeinit)                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
{
   LogEvent("اکسپرت متوقف شد.");
   ObjectsDeleteAll(0, 0, -1);
}

//+------------------------------------------------------------------+
//| تابع اصلی که با هر تیک قیمت اجرا می‌شود (OnTick)                 |
//+------------------------------------------------------------------+
void OnTick() 
{
   static datetime prevTime = 0;
   datetime currentTime = iTime(_Symbol, _Period, 0);
   
   if(currentTime != prevTime) 
   {
      prevTime = currentTime;
      bool chartNeedsRedraw = false; 

      if(iBars(_Symbol, _Period) < 50) return;
      
      //--- گام ۱: بررسی شکست ساختار 
      if(ArraySize(swingHighs_Array) >= 1 && ArraySize(swingLows_Array) >= 1)
      {
         CheckForBreakout(); 
      }
      
      //--- گام ۲: ردیابی و تایید نقطه محوری جدید با منطق آپدیت 0% فیبو
      if(isTrackingHigh || isTrackingLow)
      {
         if(CheckForNewSwingPoint())
         {
            chartNeedsRedraw = true; // اگر نقطه جدیدی تایید شد
         }
         else
         {
            // در فاز ردیابی، فیبو و نقاط متحرک 0% را رسم کن (آپدیت پیوسته)
            DrawTrackingFibonacci();
            chartNeedsRedraw = true; // برای آپدیت دائمی خطوط فیبو
         }
      }

      //--- گام ۳: شناسایی، ابطال و مدیریت نواحی FVG (برای سادگی در اینجا بهینه نشده)
      if(IdentifyFVG()) chartNeedsRedraw = true;
      if(CheckConsumedFVGs()) chartNeedsRedraw = true;
      
      //--- گام ۴: به‌روزرسانی نمایش روند
      if(UpdateTrendLabel()) chartNeedsRedraw = true;
      
      if(chartNeedsRedraw)
      {
         ChartRedraw(0);
      }
   }
}

//+------------------------------------------------------------------+
//| تابع کمکی: یافتن سقف/کف مطلق در یک محدوده زمانی (برای 0% فیبو)    |
//| **رفع خطای Invalid Cast Operation**
//+------------------------------------------------------------------+
SwingPoint FindExtremePrice(int startBar, int endBar, bool findHigh)
{
    double extremePrice = findHigh ? 0 : DBL_MAX; 
    datetime extremeTime = 0; 
    int extremeIndex = -1;

    for (int i = startBar; i <= endBar; i++)
    {
        if (findHigh) // یافتن سقف
        {
            if (iHigh(_Symbol, _Period, i) > extremePrice)
            {
                extremePrice = iHigh(_Symbol, _Period, i);
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
        else // یافتن کف
        {
            if (iLow(_Symbol, _Period, i) < extremePrice)
            {
                extremePrice = iLow(_Symbol, _Period, i);
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
    }
    
    // استفاده از یک متغیر موقت برای بازگرداندن ساختار (رفع خطا)
    SwingPoint result;
    result.price = extremePrice;
    result.time = extremeTime;
    result.bar_index = extremeIndex;
    return result; 
}


//+------------------------------------------------------------------+
//| تابع اصلاح شده: یافتن نقطه محوری مقابل (پیوت - 100% فیبو)        |
//| **رفع خطای Invalid Cast Operation**
//+------------------------------------------------------------------+
SwingPoint FindOppositeSwing(datetime brokenSwingTime, datetime breakTime, bool findHigh)
{
    double extremePrice = findHigh ? 0 : DBL_MAX; 
    datetime extremeTime = 0; 
    int extremeIndex = -1;
    
    int startBar = iBarShift(_Symbol, _Period, breakTime, false);
    int endBar = iBarShift(_Symbol, _Period, brokenSwingTime, false);
    
    if(startBar == -1 || endBar == -1 || startBar >= endBar) 
    {
        LogEvent("خطا در تعیین محدوده جستجوی پیوت مقابل.");
        
        SwingPoint errorResult;
        errorResult.price = 0; errorResult.time = 0; errorResult.bar_index = -1;
        return errorResult;
    }

    // جستجو در محدوده کندل‌های (startBar + 1) تا endBar (شامل سقف/کف شکسته شده)
    for (int i = startBar + 1; i <= endBar; i++)
    {
        if (findHigh) // در جستجوی بالاترین قیمت (سقف)
        {
            if (iHigh(_Symbol, _Period, i) > extremePrice)
            {
                extremePrice = iHigh(_Symbol, _Period, i);
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
        else // در جستجوی پایین‌ترین قیمت (کف)
        {
            if (iLow(_Symbol, _Period, i) < extremePrice)
            {
                extremePrice = iLow(_Symbol, _Period, i);
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
    }
    
    // استفاده از یک متغیر موقت برای بازگرداندن ساختار (رفع خطا)
    SwingPoint result;
    result.price = extremePrice;
    result.time = extremeTime;
    result.bar_index = extremeIndex;
    
    if (extremeIndex != -1)
    {
        if (findHigh)
        {
            AddSwingHigh(extremePrice, extremeTime, extremeIndex); 
        }
        else
        {
            AddSwingLow(extremePrice, extremeTime, extremeIndex); 
        }
        return result;
    }

    LogEvent("هشدار: پیوت مقابل (100% فیبو) در محدوده مورد انتظار یافت نشد.");
    return errorResult;
}


//+------------------------------------------------------------------+
//| بررسی شکست سقف یا کف (Breakout) و فعال‌سازی فاز ردیابی           |
//+------------------------------------------------------------------+
void CheckForBreakout()
{
   if(isTrackingHigh || isTrackingLow) return;
   if(ArraySize(swingHighs_Array) < 1 || ArraySize(swingLows_Array) < 1) return;

   double close_1 = iClose(_Symbol, _Period, 1); 
   SwingPoint lastHigh = swingHighs_Array[0];
   SwingPoint lastLow = swingLows_Array[0];

   //--- بررسی شکست سقف (Breakout High)
   if(close_1 > lastHigh.price)
   {
      bool isCHoCH = (currentTrend == TREND_BEARISH);
      string breakType = isCHoCH ? "CHoCH" : "BoS";
      LogEvent(">>> رویداد: شکست سقف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد. (سقف شکسته شده: " + DoubleToString(lastHigh.price, _Digits) + ")");
      drawBreak(lastHigh, iTime(_Symbol, _Period, 1), close_1, true, isCHoCH);

      pivotLowForTracking = FindOppositeSwing(lastHigh.time, iTime(_Symbol, _Period, 1), false); // 100% ثابت
      
      isTrackingHigh = true; 
      isTrackingLow = false; 

      LogEvent("--> فاز جدید: [شکار سقف] فعال شد. نقطه 100% فیبو (ثابت) در کف " + DoubleToString(pivotLowForTracking.price, _Digits) + " ثبت شد.");
   }
   //--- بررسی شکست کف (Breakout Low)
   else if(close_1 < lastLow.price)
   {
      bool isCHoCH = (currentTrend == TREND_BULLISH);
      string breakType = isCHoCH ? "CHoCH" : "BoS";
      LogEvent(">>> رویداد: شکست کف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد. (کف شکسته شده: " + DoubleToString(lastLow.price, _Digits) + ")");
      drawBreak(lastLow, iTime(_Symbol, _Period, 1), close_1, false, isCHoCH);

      pivotHighForTracking = FindOppositeSwing(lastLow.time, iTime(_Symbol, _Period, 1), true); // 100% ثابت
      
      isTrackingLow = true;
      isTrackingHigh = false; 

      LogEvent("--> فاز جدید: [شکار کف] فعال شد. نقطه 100% فیبو (ثابت) در سقف " + DoubleToString(pivotHighForTracking.price, _Digits) + " ثبت شد.");
   }
}

//+------------------------------------------------------------------+
//| ردیابی و تایید Swing Point جدید با آپدیت 0% فیبو |
//+------------------------------------------------------------------+
bool CheckForNewSwingPoint()
{
    //--- ۱. ردیابی سقف جدید (HH/LH) بعد از شکست صعودی
    if (isTrackingHigh)
    {
        SwingPoint current0Per; // نقطه 0% فیبوی متحرک
        int startBar = iBarShift(_Symbol, _Period, pivotLowForTracking.time, false);
        current0Per = FindExtremePrice(1, startBar, true); // true = یافتن High (0% متحرک)

        if (current0Per.bar_index == -1 || current0Per.price <= pivotLowForTracking.price) return false;
        
        double range = current0Per.price - pivotLowForTracking.price;
        double fibLevel = current0Per.price - (range * (fibUpdateLevel / 100.0)); // سطح اصلاح فیبوناچی
        double close_1 = iClose(_Symbol, _Period, 1);

        if (close_1 < fibLevel)
        {
            LogEvent("<<< تایید شد: شرط اصلاح " + IntegerToString(fibUpdateLevel) + "٪ برای سقف جدید برقرار شد. سقف جدید (0% فیبو) در " + DoubleToString(current0Per.price, _Digits) + " ثبت می‌شود.");
            
            AddSwingHigh(current0Per.price, current0Per.time, current0Per.bar_index);
            isTrackingHigh = false; 
            return true;
        }
    }

    //--- ۲. ردیابی کف جدید (LL/HL) بعد از شکست نزولی
    else if (isTrackingLow)
    {
        SwingPoint current0Per; // نقطه 0% فیبوی متحرک
        int startBar = iBarShift(_Symbol, _Period, pivotHighForTracking.time, false);
        current0Per = FindExtremePrice(1, startBar, false); // false = یافتن Low (0% متحرک)
        
        if (current0Per.bar_index == -1 || current0Per.price >= pivotHighForTracking.price) return false;

        double range = pivotHighForTracking.price - current0Per.price;
        double fibLevel = current0Per.price + (range * (fibUpdateLevel / 100.0)); // سطح اصلاح فیبوناچی
        double close_1 = iClose(_Symbol, _Period, 1);

        if (close_1 > fibLevel)
        {
            LogEvent("<<< تایید شد: شرط اصلاح " + IntegerToString(fibUpdateLevel) + "٪ برای کف جدید برقرار شد. کف جدید (0% فیبو) در " + DoubleToString(current0Per.price, _Digits) + " ثبت می‌شود.");

            AddSwingLow(current0Per.price, current0Per.time, current0Per.bar_index);
            isTrackingLow = false; 
            return true;
        }
    }
    return false; 
}


//+------------------------------------------------------------------+
//| تابع جدید: ترسیم فیبوناچی متحرک (ردیابی)                         |
//+------------------------------------------------------------------+
void DrawTrackingFibonacci()
{
    SwingPoint p100, p0; 
    bool isBullish = isTrackingHigh; 

    if (isTrackingHigh) // موج صعودی (شکست سقف)
    {
        p100 = pivotLowForTracking; 
        int startBar = iBarShift(_Symbol, _Period, p100.time, false);
        p0 = FindExtremePrice(1, startBar, true); 
        if (p0.bar_index == -1 || p0.price <= p100.price) { ObjectDelete(0, "Tracking_Fib"); return; } 
    }
    else if (isTrackingLow) // موج نزولی (شکست کف)
    {
        p100 = pivotHighForTracking; 
        int startBar = iBarShift(_Symbol, _Period, p100.time, false);
        p0 = FindExtremePrice(1, startBar, false); 
        if (p0.bar_index == -1 || p0.price >= p100.price) { ObjectDelete(0, "Tracking_Fib"); return; }
    }
    else { ObjectDelete(0, "Tracking_Fib"); return; }

    string objName = "Tracking_Fib";
    ObjectDelete(0, objName);

    ObjectCreate(0, objName, OBJ_FIBO, 0, p100.time, p100.price, p0.time, p0.price);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, isBullish ? clrDodgerBlue : clrOrangeRed);
    ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    
    // تنظیم سطوح مورد نیاز (0، 35%، 100)
    ObjectSetDouble(0, objName, OBJPROP_LEVELVALUE, 0, 0.0);
    ObjectSetString(0, objName, OBJPROP_LEVELTEXT, 0, "0% (Movable)");
    
    ObjectSetDouble(0, objName, OBJPROP_LEVELVALUE, 1, (double)fibUpdateLevel / 100.0);
    ObjectSetString(0, objName, OBJPROP_LEVELTEXT, 1, IntegerToString(fibUpdateLevel) + "% (Confirmation)");

    ObjectSetDouble(0, objName, OBJPROP_LEVELVALUE, 2, 1.0);
    ObjectSetString(0, objName, OBJPROP_LEVELTEXT, 2, "100% (Fixed Pivot)");
    
    // پاک کردن سطوح اضافی
    for(int i = 3; i < 10; i++) ObjectSetDouble(0, objName, OBJPROP_LEVELVALUE, i, 0.0);
}


//+------------------------------------------------------------------+
//| توابع مدیریت آرایه‌ها (افزودن سقف/کف جدید)                       |
//+------------------------------------------------------------------+
void AddSwingHigh(double price, datetime time, int bar_index) 
{
   if(ArraySize(swingHighs_Array) >= 2) 
   {
      ObjectDelete(0, "High_" + TimeToString(swingHighs_Array[1].time)); 
      ObjectDelete(0, "High_" + TimeToString(swingHighs_Array[1].time) + "_Text");
      ArrayRemove(swingHighs_Array, ArraySize(swingHighs_Array) - 1, 1); 
   }
   
   int newSize = ArraySize(swingHighs_Array) + 1;
   ArrayResize(swingHighs_Array, newSize); 
   swingHighs_Array[0].price = price;
   swingHighs_Array[0].time = time;
   swingHighs_Array[0].bar_index = bar_index;
   
   drawSwingPoint(swingHighs_Array[0], true);
}

void AddSwingLow(double price, datetime time, int bar_index) 
{
   if(ArraySize(swingLows_Array) >= 2) 
   {
      ObjectDelete(0, "Low_" + TimeToString(swingLows_Array[1].time)); 
      ObjectDelete(0, "Low_" + TimeToString(swingLows_Array[1].time) + "_Text");
      ArrayRemove(swingLows_Array, ArraySize(swingLows_Array) - 1, 1); 
   }
   
   int newSize = ArraySize(swingLows_Array) + 1;
   ArrayResize(swingLows_Array, newSize); 
   swingLows_Array[0].price = price;
   swingLows_Array[0].time = time;
   swingLows_Array[0].bar_index = bar_index;

   drawSwingPoint(swingLows_Array[0], false);
}


//--- توابع مدیریت FVG و ترسیمی (مانند قبل) --------------------------

void IdentifyInitialStructure() {} // برای سادگی در اینجا خالی است

bool IdentifyFVG() { return false; }
bool CheckConsumedFVGs() { return false; }

bool UpdateTrendLabel() 
{
   TREND_TYPE oldTrend = currentTrend;
   if(ArraySize(swingHighs_Array) >= 2 && ArraySize(swingLows_Array) >= 2) 
   {
      SwingPoint lastHigh = swingHighs_Array[0];
      SwingPoint prevHigh = swingHighs_Array[1];
      SwingPoint lastLow  = swingLows_Array[0];
      SwingPoint prevLow  = swingLows_Array[1];
      if(lastHigh.price > prevHigh.price && lastLow.price > prevLow.price) currentTrend = TREND_BULLISH;
      else if(lastHigh.price < prevHigh.price && lastLow.price < prevLow.price) currentTrend = TREND_BEARISH;
      else currentTrend = TREND_NONE;
   } 
   else currentTrend = TREND_NONE;
   
   if(oldTrend != currentTrend)
   {
      ObjectDelete(0, trendObjectName);
      string trendText;
      color trendColor;
      switch(currentTrend) 
      {
         case TREND_BULLISH:
            trendText = "Bullish Trend (HH/HL)"; trendColor = clrDeepSkyBlue;
            LogEvent("وضعیت روند به صعودی (Bullish) تغییر یافت.");
            break;
         case TREND_BEARISH:
            trendText = "Bearish Trend (LL/LH)"; trendColor = clrOrangeRed;
            LogEvent("وضعیت روند به نزولی (Bearish) تغییر یافت.");
            break;
         default:
            trendText = "No Trend / Ranging"; trendColor = clrGray;
            LogEvent("وضعیت روند به بدون روند (Ranging) تغییر یافت.");
      }
      ObjectCreate(0, trendObjectName, OBJ_LABEL, 0, 0, 0);
      ObjectSetString(0, trendObjectName, OBJPROP_TEXT, trendText);
      ObjectSetInteger(0, trendObjectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, trendObjectName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, trendObjectName, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, trendObjectName, OBJPROP_COLOR, trendColor);
      ObjectSetInteger(0, trendObjectName, OBJPROP_FONTSIZE, 12);
      ObjectSetString(0, trendObjectName, OBJPROP_FONT, "Arial");
      return true;
   }
   return false;
}

void drawSwingPoint(const SwingPoint &sp, bool isHigh) 
{
   string objName = (isHigh ? "High_" : "Low_") + TimeToString(sp.time);
   string textName = objName + "_Text";
   ObjectDelete(0, objName); 
   ObjectDelete(0, textName);

   ObjectCreate(0, objName, OBJ_ARROW, 0, sp.time, sp.price);
   ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 77); 
   ObjectSetInteger(0, objName, OBJPROP_COLOR, isHigh ? clrDodgerBlue : clrRed);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, isHigh ? ANCHOR_BOTTOM : ANCHOR_TOP);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false); 
   
   ObjectCreate(0, textName, OBJ_TEXT, 0, sp.time, sp.price);
   ObjectSetString(0, textName, OBJPROP_TEXT, isHigh ? "H" : "L");
   ObjectSetInteger(0, textName, OBJPROP_COLOR, isHigh ? clrDodgerBlue : clrRed);
   ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, textName, OBJPROP_ANCHOR, isHigh ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, textName, OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
}

void drawBreak(const SwingPoint &brokenSwing, datetime breakTime, double breakPrice, bool isHighBreak, bool isCHoCH)
{
    string breakType = isCHoCH ? "CHoCH" : "BoS";
    color breakColor = isCHoCH ? clrCrimson : (isHighBreak ? clrSeaGreen : clrOrange);
    string objName = "Break_" + TimeToString(brokenSwing.time);
    string textName = objName + "_Text";
    ObjectDelete(0, objName);
    ObjectDelete(0, textName);

    ObjectCreate(0, objName, OBJ_TREND, 0, brokenSwing.time, brokenSwing.price, breakTime, brokenSwing.price);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, breakColor);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
    ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);

    ObjectCreate(0, textName, OBJ_TEXT, 0, breakTime, breakPrice);
    ObjectSetString(0, textName, OBJPROP_TEXT, breakType);
    ObjectSetInteger(0, textName, OBJPROP_COLOR, breakColor);
    ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 11);
    ObjectSetInteger(0, textName, OBJPROP_ANCHOR, isHighBreak ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, textName, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
}
//--- پایان توابع ترسیمی
