//+------------------------------------------------------------------+
//|                                     MarketStructurePro_v5.4.mq5 |
//|                                  Copyright 2025, Khajavi & Gemini |
//|                                             Powerd by Gemini AI |
//|------------------------------------------------------------------|
//| نسخه 5.4 - فیکس نهایی مدیریت FVG، رفع خطاهای کامپایلر و ترسیم زون |
//| 1. اصلاح فراخوانی تابع ArrayInsert برای رفع خطای "variable expected".|
//| 2. حذف OBJPROP_TIMEMAX و استفاده از زمان فعلی برای امتداد زون FVG.|
//| 3. حفظ تنها FVGهای سالم (حذف کامل ابطال شده‌ها).                 |
//| 4. بهینه‌سازی منطق FVG بر اساس سه کندل (1، 2، 3).                |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi & Gemini"
#property link      "https://www.google.com"
#property version   "5.40"

//+------------------------------------------------------------------+
//| ورودی‌های اکسپرت (Inputs)                                        |
//+------------------------------------------------------------------+
input bool enableLogging = true;    // [فعال/غیرفعال کردن] سیستم لاگ برای گزارش‌دهی مراحل
input int  fibUpdateLevel = 35;     // سطح اصلاح فیبوناچی برای تایید نقطه (مثلاً 35% یا 0.35)
input int  fractalLength = 10;      // تعداد کندل‌های چپ و راست برای شناسایی سقف/کف اولیه (فرکتال)

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

//+------------------------------------------------------------------+
//| متغیرهای سراسری (Global Variables)                               |
//+------------------------------------------------------------------+
SwingPoint swingHighs_Array[];     // آرایه داینامیک برای نگهداری 2 سقف آخر ([0]=جدید، [1]=قدیمی)
SwingPoint swingLows_Array[];      // آرایه داینامیک برای نگهداری 2 کف آخر ([0]=جدید، [1]=قدیمی)
FVG        fvgArray[];             // آرایه داینامیک برای نگهداری نواحی FVG شناسایی شده (حداکثر 30)

TREND_TYPE currentTrend    = TREND_NONE;    // متغیر نگهداری وضعیت فعلی روند
string     trendObjectName = "TrendLabel";  // نام ثابت برای شیء متنی نمایش‌دهنده روند

//--- متغیرهای کلیدی برای ردیابی موج جدید بر اساس منطق فیبوناچی
SwingPoint pivotHighForTracking; // نقطه 100% فیبو (ثابت) در فاز نزولی
SwingPoint pivotLowForTracking;  // نقطه 100% فیبو (ثابت) در فاز صعودی
bool       isTrackingHigh = false; // فلگ وضعیت: آیا در فاز "شکار سقف جدید" هستیم؟
bool       isTrackingLow  = false; // فلگ وضعیت: آیا در فاز "شکار کف جدید" هستیم؟

//--- متغیر استاتیک برای جلوگیری از اجرای تکراری FVG روی یک کندل بسته شده
static datetime lastFVGCheckTime = 0;

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
   LogEvent("اکسپرت MarketStructurePro v5.4 با منطق پیشرفته SMC، FVG و فیبوناچی آغاز به کار کرد.");

   ObjectsDeleteAll(0, 0, -1);

   // تنظیم آرایه‌ها به صورت سری: اندیس 0 جدیدترین عنصر است
   ArraySetAsSeries(swingHighs_Array, true);
   ArraySetAsSeries(swingLows_Array, true);
   ArraySetAsSeries(fvgArray, true);

   ArrayResize(swingHighs_Array, 0);
   ArrayResize(swingLows_Array, 0);
   ArrayResize(fvgArray, 0);

   isTrackingHigh = false;
   isTrackingLow = false;

   // مقداردهی اولیه ساختارها
   pivotHighForTracking.price = 0; pivotHighForTracking.time = 0; pivotHighForTracking.bar_index = -1;
   pivotLowForTracking.price = 0; pivotLowForTracking.time = 0; pivotLowForTracking.bar_index = -1;

   // شناسایی ساختار اولیه فقط از جدیدترین داده‌ها
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

   bool chartNeedsRedraw = false;

   // نیاز به حداقل 50 کندل برای اجرای منطق
   if(iBars(_Symbol, _Period) < 50) return;

   //--- گام ۱: بررسی ابطال FVG در لحظه (با ASK/BID) - هر تیک اجرا می‌شود
   if(CheckFVGInvalidation()) chartNeedsRedraw = true;

   // اجرای منطق ساختار و FVG فقط در کلوز کندل جدید
   if(currentTime != prevTime)
   {
      prevTime = currentTime;

      //--- گام ۲: بررسی شکست ساختار
      if(ArraySize(swingHighs_Array) >= 1 && ArraySize(swingLows_Array) >= 1)
      {
         CheckForBreakout();
      }

      //--- گام ۳: ردیابی و تایید نقطه محوری جدید با منطق آپدیت 0% فیبو
      if(isTrackingHigh || isTrackingLow)
      {
         if(CheckForNewSwingPoint())
         {
            chartNeedsRedraw = true;
            ObjectDelete(0, "Tracking_Fib"); // حذف فیبوناچی ردیاب پس از تایید
         }
         else
         {
            DrawTrackingFibonacci(); // به‌روزرسانی فیبوناچی ردیاب
            chartNeedsRedraw = true;
         }
      }

      //--- گام ۴: شناسایی FVG جدید (فقط یک بار با کلوز کندل جدید)
      if(IdentifyFVG()) chartNeedsRedraw = true;

      //--- گام ۵: به‌روزرسانی نمایش روند
      if(UpdateTrendLabel()) chartNeedsRedraw = true;

      if(chartNeedsRedraw)
      {
         ChartRedraw(0);
      }
   }
}

//+------------------------------------------------------------------+
//| شناسایی ساختار اولیه بازار (بر مبنای فرکتال ۱۰ کندلی)             |
//+------------------------------------------------------------------+
void IdentifyInitialStructure()
{
   int barsCount = iBars(_Symbol, _Period);

   if(barsCount < fractalLength * 2 + 1) return;

   // جستجو برای یافتن سقف و کف معتبر نزدیک به حال (کندل‌های اخیر)
   for(int i = fractalLength; i < barsCount - fractalLength; i++)
   {
      bool isSwingHigh = true;
      bool isSwingLow = true;

      for(int j = 1; j <= fractalLength; j++)
      {
         // برای سقف
         if(iHigh(_Symbol, _Period, i) < iHigh(_Symbol, _Period, i - j) || iHigh(_Symbol, _Period, i) < iHigh(_Symbol, _Period, i + j))
         {
            isSwingHigh = false;
         }

         // برای کف
         if(iLow(_Symbol, _Period, i) > iLow(_Symbol, _Period, i - j) || iLow(_Symbol, _Period, i) > iLow(_Symbol, _Period, i + j))
         {
            isSwingLow = false;
         }
      }

      if(isSwingHigh && ArraySize(swingHighs_Array) == 0)
      {
         AddSwingHigh(iHigh(_Symbol, _Period, i), iTime(_Symbol, _Period, i), i);
         LogEvent("ساختار اولیه: اولین سقف در قیمت " + DoubleToString(iHigh(_Symbol, _Period, i), _Digits) + " شناسایی شد.");
      }
      if(isSwingLow && ArraySize(swingLows_Array) == 0)
      {
         AddSwingLow(iLow(_Symbol, _Period, i), iTime(_Symbol, _Period, i), i);
         LogEvent("ساختار اولیه: اولین کف در قیمت " + DoubleToString(iLow(_Symbol, _Period, i), _Digits) + " شناسایی شد.");
      }

      if(ArraySize(swingHighs_Array) > 0 && ArraySize(swingLows_Array) > 0)
      {
          break; // پس از یافتن هر دو، جستجو را متوقف کن
      }
   }
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

      pivotLowForTracking = FindOppositeSwing(lastHigh.time, iTime(_Symbol, _Period, 1), false); // 100% فیبو (ثابت)

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

      pivotHighForTracking = FindOppositeSwing(lastLow.time, iTime(_Symbol, _Period, 1), true); // 100% فیبو (ثابت)

      isTrackingLow = true;
      isTrackingHigh = false;

      LogEvent("--> فاز جدید: [شکار کف] فعال شد. نقطه 100% فیبو (ثابت) در سقف " + DoubleToString(pivotHighForTracking.price, _Digits) + " ثبت شد.");
   }
}


//+------------------------------------------------------------------+
//| تابع: یافتن نقطه محوری مقابل (پیوت - 100% فیبو) - رفع خطای ساختار |
//+------------------------------------------------------------------+
SwingPoint FindOppositeSwing(datetime brokenSwingTime, datetime breakTime, bool findHigh)
{
    double extremePrice = findHigh ? 0 : DBL_MAX;
    datetime extremeTime = 0;
    int extremeIndex = -1;

    int startBar = iBarShift(_Symbol, _Period, breakTime, false);
    int endBar = iBarShift(_Symbol, _Period, brokenSwingTime, false);

    SwingPoint errorResult;
    errorResult.price = 0; errorResult.time = 0; errorResult.bar_index = -1;

    if(startBar == -1 || endBar == -1 || startBar >= endBar)
    {
        LogEvent("خطا: محدوده جستجوی پیوت مقابل نامعتبر است.");
        return errorResult;
    }

    // جستجو از جدیدترین کندل (startBar + 1) به سمت قدیم (endBar)
    for (int i = startBar + 1; i <= endBar; i++)
    {
        if (findHigh)
        {
            if (iHigh(_Symbol, _Period, i) > extremePrice)
            {
                extremePrice = iHigh(_Symbol, _Period, i);
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
        else
        {
            if (iLow(_Symbol, _Period, i) < extremePrice)
            {
                extremePrice = iLow(_Symbol, _Period, i);
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
    }

    SwingPoint result;
    result.price = extremePrice;
    result.time = extremeTime;
    result.bar_index = extremeIndex;

    if (extremeIndex != -1)
    {
        // ثبت نقطه 100% فیبو به عنوان Swing Point جدید
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
//| تابع کمکی: یافتن سقف/کف مطلق در یک محدوده زمانی (برای 0% فیبو)    |
//+------------------------------------------------------------------+
SwingPoint FindExtremePrice(int startBar, int endBar, bool findHigh)
{
    double extremePrice = findHigh ? 0 : DBL_MAX;
    datetime extremeTime = 0;
    int extremeIndex = -1;

    // جستجو از جدیدترین کندل (startBar) به سمت قدیم (endBar)
    for (int i = startBar; i <= endBar; i++)
    {
        if (findHigh)
        {
            if (iHigh(_Symbol, _Period, i) > extremePrice)
            {
                extremePrice = iHigh(_Symbol, _Period, i);
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
        else
        {
            if (iLow(_Symbol, _Period, i) < extremePrice)
            {
                extremePrice = iLow(_Symbol, _Period, i);
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
    }

    SwingPoint result;
    result.price = extremePrice;
    result.time = extremeTime;
    result.bar_index = extremeIndex;
    return result;
}


//+------------------------------------------------------------------+
//| ردیابی و تایید Swing Point جدید با آپدیت 0% فیبو |
//+------------------------------------------------------------------+
bool CheckForNewSwingPoint()
{
    //--- ۱. ردیابی سقف جدید (HH/LH) بعد از شکست صعودی
    if (isTrackingHigh)
    {
        if (pivotLowForTracking.bar_index == -1) return false;

        SwingPoint current0Per;
        int startBar = iBarShift(_Symbol, _Period, pivotLowForTracking.time, false);
        // جستجو برای 0% فیبو از کندل 1 (بسته شده) تا نقطه 100% فیبو
        current0Per = FindExtremePrice(1, startBar, true);

        if (current0Per.bar_index == -1 || current0Per.price <= pivotLowForTracking.price) return false;

        double range = current0Per.price - pivotLowForTracking.price;
        double fibLevel = current0Per.price - (range * (fibUpdateLevel / 100.0));
        double close_1 = iClose(_Symbol, _Period, 1);

        // شرط تایید: کلوز کندل قبلی کمتر یا مساوی سطح اصلاحی باشد (بسته شدن در 35% یا پایین‌تر)
        if (close_1 <= fibLevel)
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
        if (pivotHighForTracking.bar_index == -1) return false;

        SwingPoint current0Per;
        int startBar = iBarShift(_Symbol, _Period, pivotHighForTracking.time, false);
        // جستجو برای 0% فیبو از کندل 1 (بسته شده) تا نقطه 100% فیبو
        current0Per = FindExtremePrice(1, startBar, false);

        if (current0Per.bar_index == -1 || current0Per.price >= pivotHighForTracking.price) return false;

        double range = pivotHighForTracking.price - current0Per.price;
        double fibLevel = current0Per.price + (range * (fibUpdateLevel / 100.0));
        double close_1 = iClose(_Symbol, _Period, 1);

        // شرط تایید: کلوز کندل قبلی بیشتر یا مساوی سطح اصلاحی باشد (بسته شدن در 35% یا بالاتر)
        if (close_1 >= fibLevel)
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
//| تابع: ترسیم فیبوناچی متحرک (ردیابی)                         |
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

    // تنظیم سطوح مورد نیاز
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
//| توابع مدیریت نواحی FVG (Fair Value Gap) - منطق اصلاح شده         |
//+------------------------------------------------------------------+
bool IsStrongBody(int index)
{
    double open = iOpen(_Symbol, _Period, index);
    double close = iClose(_Symbol, _Period, index);
    double high = iHigh(_Symbol, _Period, index);
    double low = iLow(_Symbol, _Period, index);

    double body = MathAbs(open - close);
    double shadow = (high - low) - body;

    // شرط بدنه قوی: بادی باید بزرگتر از مجموع شدوها باشد
    return (body > shadow);
}

//+------------------------------------------------------------------+
//| تابع: شناسایی FVG جدید (بررسی کندل‌های 1، 2، 3)                  |
//+------------------------------------------------------------------+
bool IdentifyFVG()
{
   // جلوگیری از اجرای تکراری شناسایی FVG روی یک کندل بسته شده (کندل 1)
   if(lastFVGCheckTime == iTime(_Symbol, _Period, 1)) return false;
   lastFVGCheckTime = iTime(_Symbol, _Period, 1);

   // برای دسترسی به کندل 1، 2 و 3، به حداقل 4 کندل (0 تا 3) نیاز داریم.
   if(iBars(_Symbol, _Period) < 4) return false;

   // i = اندیس کندل میانی FVG که کندل شماره 2 است.
   int i = 2;

   //--- ۱. بررسی شرط بدنه‌های قوی در هر سه کندل
   if (!IsStrongBody(i-1) || !IsStrongBody(i) || !IsStrongBody(i+1)) return false;

   // High/Low کندل 1 (جدیدترین) و High/Low کندل 3 (قدیمی‌ترین)
   double high1 = iHigh(_Symbol, _Period, i - 1);
   double low1  = iLow(_Symbol, _Period, i - 1);
   double high3 = iHigh(_Symbol, _Period, i + 1);
   double low3  = iLow(_Symbol, _Period, i + 1);

   // FVG صعودی: کف کندل 1 (جدید) بالاتر از سقف کندل 3 (قدیم)
   if (low1 > high3)
   {
       // جلوگیری از ثبت FVG تکراری (برای یک زمان کندل میانی)
       for(int j=0; j<ArraySize(fvgArray); j++) { if(fvgArray[j].time == iTime(_Symbol, _Period, i) && fvgArray[j].isBullish) return false; }

       // ناحیه FVG بین High کندل 3 و Low کندل 1.
       AddFVG(true, high3, low1, iTime(_Symbol, _Period, i));
       return true;
   }

   // FVG نزولی: سقف کندل 1 (جدید) پایین‌تر از کف کندل 3 (قدیم)
   if (high1 < low3)
   {
       // جلوگیری از ثبت FVG تکراری
       for(int j=0; j<ArraySize(fvgArray); j++) { if(fvgArray[j].time == iTime(_Symbol, _Period, i) && !fvgArray[j].isBullish) return false; }

       // ناحیه FVG بین Low کندل 3 و High کندل 1.
       AddFVG(false, low3, high1, iTime(_Symbol, _Period, i));
       return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| تابع: اضافه کردن FVG جدید به آرایه (با رفع خطا)                   |
//+------------------------------------------------------------------+
void AddFVG(bool isBullish, double highPrice, double lowPrice, datetime time)
{
   // مدیریت ظرفیت: اگر از 30 عدد بیشتر شد، قدیمی‌ترین (آخرین اندیس در آرایه سری) حذف شود
   if(ArraySize(fvgArray) >= 30)
   {
      int lastIndex = ArraySize(fvgArray) - 1;
      string typeStrOld = fvgArray[lastIndex].isBullish ? "Bullish" : "Bearish";
      string objNameOld = "FVG_" + TimeToString(fvgArray[lastIndex].time) + "_" + typeStrOld;
      ObjectDelete(0, objNameOld);
      ObjectDelete(0, objNameOld + "_Text");
      ArrayRemove(fvgArray, lastIndex, 1);
   }

   // 1. یک نمونه جدید از FVG بساز و مقداردهی کن
   FVG newFVG;
   newFVG.isBullish = isBullish;
   newFVG.highPrice = highPrice;
   newFVG.lowPrice = lowPrice;
   newFVG.time = time;
   newFVG.consumed = false;

   // 2. نمونه جدید را در ابتدای آرایه (اندیس 0) درج کن
   int inserted_count = ArrayInsert(fvgArray, newFVG, 0);

   // 3. بررسی کن که آیا درج موفقیت آمیز بوده یا نه
   if(inserted_count <= 0)
   {
       LogEvent("خطا: نتوانست FVG جدید را در آرایه درج کند.");
       return;
   }

   // 4. حالا که عنصر جدید در اندیس 0 قرار دارد، آن را رسم کن
   drawFVG(fvgArray[0]);

   string typeStr = isBullish ? "Bullish" : "Bearish";
   LogEvent("FVG جدید از نوع " + typeStr + " در زمان " + TimeToString(time) + " شناسایی شد.");
}


//+------------------------------------------------------------------+
//| تابع: بررسی ابطال FVG در لحظه (با قیمت‌های ASK/BID)              |
//+------------------------------------------------------------------+
bool CheckFVGInvalidation()
{
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool invalidatedNow = false;

   // حلقه از جدیدترین (0) تا قدیمی‌ترین (ArraySize-1) می‌رود
   for(int i = 0; i < ArraySize(fvgArray); i++)
   {
      // فقط FVGهای فعال چک شوند.
      if(fvgArray[i].consumed) continue;

      bool isInvalidated = false;
      string typeStr = fvgArray[i].isBullish ? "Bullish" : "Bearish";

      // FVG صعودی: اگر قیمت Bid به زیر خط پایین FVG برسد (باطل می‌شود)
      if(fvgArray[i].isBullish && currentBid < fvgArray[i].lowPrice)
      {
          isInvalidated = true;
      }

      // FVG نزولی: اگر قیمت Ask به بالای خط بالای FVG برسد (باطل می‌شود)
      if(!fvgArray[i].isBullish && currentAsk > fvgArray[i].highPrice)
      {
          isInvalidated = true;
      }

      if(isInvalidated)
      {
         // حذف FVG ابطال شده
         string objName = "FVG_" + TimeToString(fvgArray[i].time) + "_" + typeStr;

         // پاک کردن FVG از روی چارت
         ObjectDelete(0, objName);
         ObjectDelete(0, objName + "_Text");

         LogEvent("FVG از نوع " + typeStr + " در زمان " + TimeToString(fvgArray[i].time) + " توسط قیمت لایو ابطال و حذف شد.");

         // حذف کامل عنصر ابطال شده از آرایه (حفظ فقط موارد سالم)
         ArrayRemove(fvgArray, i, 1);

         // چون یک عنصر حذف شد، باید اندیس را یکی کم کنیم تا عنصر بعدی از قلم نیفتد
         i--;
         invalidatedNow = true;
      }
   }
   return invalidatedNow;
}

//+------------------------------------------------------------------+
//| توابع مدیریت و ترسیم نقاط محوری (AddSwingHigh, AddSwingLow)       |
//+------------------------------------------------------------------+
void AddSwingHigh(double price, datetime time, int bar_index)
{
   // حفظ تنها 2 نقطه آخر در آرایه محاسباتی
   if(ArraySize(swingHighs_Array) >= 2)
   {
      ObjectDelete(0, "High_" + TimeToString(swingHighs_Array[1].time));
      ObjectDelete(0, "High_" + TimeToString(swingHighs_Array[1].time) + "_Text");
      ArrayRemove(swingHighs_Array, ArraySize(swingHighs_Array) - 1, 1);
   }

   int newSize = ArraySize(swingHighs_Array) + 1;
   // استفاده از ArrayResize و پر کردن اندیس 0 در این آرایه‌های کوچک ساده‌تر است
   ArrayResize(swingHighs_Array, newSize);
   swingHighs_Array[0].price = price;
   swingHighs_Array[0].time = time;
   swingHighs_Array[0].bar_index = bar_index;

   drawSwingPoint(swingHighs_Array[0], true);
}

void AddSwingLow(double price, datetime time, int bar_index)
{
   // حفظ تنها 2 نقطه آخر در آرایه محاسباتی
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


//+------------------------------------------------------------------+
//| توابع ترسیمی و نمایش اطلاعات روی چارت (Drawings)                  |
//+------------------------------------------------------------------+
bool UpdateTrendLabel()
{
   TREND_TYPE oldTrend = currentTrend;

   if(ArraySize(swingHighs_Array) >= 2 && ArraySize(swingLows_Array) >= 2)
   {
      SwingPoint lastHigh = swingHighs_Array[0];
      SwingPoint prevHigh = swingHighs_Array[1];
      SwingPoint lastLow  = swingLows_Array[0];
      SwingPoint prevLow  = swingLows_Array[1];

      if(lastHigh.price > prevHigh.price && lastLow.price > prevLow.price)
      {
          currentTrend = TREND_BULLISH;
      }
      else if(lastHigh.price < prevHigh.price && lastLow.price < prevLow.price)
      {
          currentTrend = TREND_BEARISH;
      }
      else
      {
          currentTrend = TREND_NONE;
      }
   }
   else currentTrend = TREND_NONE;

   // آپدیت گرافیکی لیبل روند
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

void drawFVG(const FVG &fvg)
{
   string typeStr = fvg.isBullish ? "Bullish" : "Bearish";
   string objName = "FVG_" + TimeToString(fvg.time) + "_" + typeStr;
   string textName = objName + "_Text";

   // رنگ سبز روشن شفاف برای صعودی و قرمز روشن شفاف برای نزولی
   color fvgColor = fvg.isBullish ? C'144,238,144' : C'255,160,160'; // LightGreen / LightCoral

   // ✨ اصلاح: استفاده صحیح از زمان کندل صفر (زمان فعلی) برای امتداد زون FVG به سمت راست
   datetime currentTime = iTime(_Symbol, _Period, 0);

   // گوشه اول: زمان شروع FVG (کندل 2)، قیمت بالا (High)
   // گوشه دوم: زمان فعلی (کندل 0)، قیمت پایین (Low)
   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, fvg.time, fvg.highPrice, currentTime, fvg.lowPrice);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, fvgColor);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);       // شفافیت (شیشه‌ای)
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);      // پشت کندل‌ها
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);

   // ✨ حذف OBJPROP_TIMEMAX که برای مستطیل‌ها نامعتبر است.
   // امتداد با استفاده از currentTime انجام شد.

   ObjectCreate(0, textName, OBJ_TEXT, 0, fvg.time, fvg.isBullish ? fvg.highPrice : fvg.lowPrice);
   ObjectSetString(0, textName, OBJPROP_TEXT, "FVG");
   ObjectSetInteger(0, textName, OBJPROP_COLOR, clrDimGray);
   ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, textName, OBJPROP_ANCHOR, fvg.isBullish ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
   ObjectSetInteger(0, textName, OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
}
//+------------------------------------------------------------------+
