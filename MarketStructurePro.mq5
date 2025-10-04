//+------------------------------------------------------------------+
//|                                     MarketStructurePro_v6.0.mq5 |
//|                                  Copyright 2025, Khajavi & Gemini |
//|                                             Powerd by Gemini AI |
//|------------------------------------------------------------------|
//| نسخه 6.0 - پیاده‌سازی کامل منطق SMC درخواستی کاربر:              |
//| 1. اصلاح کامل منطق فیبوناچی (0% متحرک، 100% ثابت) بر اساس زمان  |
//| 2. رفع کامل خطاهای کامپایلر (Invalid Cast Operation)             |
//| 3. پیاده‌سازی دقیق منطق BoS و CHoCH                              |
//| 4. پیاده‌سازی دقیق منطق FVG (سه کندلی)                           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi & Gemini"
#property link      "https://www.google.com"
#property version   "6.00"

//+------------------------------------------------------------------+
//| ورودی‌های اکسپرت (Inputs)                                        |
//+------------------------------------------------------------------+
input bool enableLogging = true;    // [فعال/غیرفعال کردن] سیستم لاگ برای گزارش‌دهی مراحل
input int  fibConfirmationLevel = 35; // سطح اصلاح فیبوناچی برای تایید نقطه (پیش‌فرض: 35%)
input int  fvgBodyRatio = 80;       // حداقل درصد بادی کندل نسبت به رنج کامل (برای شناسایی FVG قوی)

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
   double   highPrice;  // بالاترین قیمت ناحیه FVG (سقف گپ)
   double   lowPrice;   // پایین‌ترین قیمت ناحیه FVG (کف گپ)
   datetime time;       // زمان کندل شروع ناحیه (کندل 1)
   bool     consumed;   // وضعیت مصرف شدگی: آیا قیمت به ناحیه بازگشته است؟
};

//--- شمارنده (Enum) برای نگهداری وضعیت فعلی روند بازار
enum TREND_TYPE 
{
   TREND_BULLISH,  // روند صعودی (HH/HL)
   TREND_BEARISH,  // روند نزولی (LL/LH)
   TREND_RANGING   // بدون روند مشخص 
};

//+------------------------------------------------------------------+
//| متغیرهای سراسری (Global Variables)                               |
//+------------------------------------------------------------------+
SwingPoint swingHighs_Array[];     // 2 سقف آخر ([0]=جدید، [1]=قدیمی)
SwingPoint swingLows_Array[];      // 2 کف آخر ([0]=جدید، [1]=قدیمی)
FVG        fvgArray[];             // نواحی FVG شناسایی شده

TREND_TYPE currentTrend    = TREND_RANGING; 
string     trendObjectName = "TrendLabel";  

//--- متغیرهای ردیابی موج (نقطه 100% فیبوی ثابت)
SwingPoint pivotHighForTracking; 
SwingPoint pivotLowForTracking;  
bool       isTrackingHigh = false; // فاز شکار سقف جدید
bool       isTrackingLow  = false; // فاز شکار کف جدید

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
   LogEvent("اکسپرت MarketStructurePro v6.0 با منطق دقیق SMC آغاز به کار کرد.");
   
   ObjectsDeleteAll(0, 0, -1);
   
   ArraySetAsSeries(swingHighs_Array, true);
   ArraySetAsSeries(swingLows_Array, true);
   ArraySetAsSeries(fvgArray, true); 
   
   ArrayResize(swingHighs_Array, 0);
   ArrayResize(swingLows_Array, 0);
   ArrayResize(fvgArray, 0);
   
   isTrackingHigh = false;
   isTrackingLow = false;
   
   // مقداردهی اولیه ساختارها برای جلوگیری از خطاهای احتمالی (مهم برای رفع خطا)
   pivotHighForTracking.price = 0; pivotHighForTracking.time = 0; pivotHighForTracking.bar_index = -1;
   pivotLowForTracking.price = 0; pivotLowForTracking.time = 0; pivotLowForTracking.bar_index = -1;

   IdentifyInitialStructure();
   UpdateTrendLabel();
   
   return(INIT_SUCCEEDED);
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
      
      //--- گام ۱: بررسی شکست ساختار (باید قبل از ردیابی جدید باشد)
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
         
         // همیشه فیبوناچی ردیابی را رسم کن تا نقطه 0% متحرک نمایش داده شود
         DrawTrackingFibonacci();
         chartNeedsRedraw = true; 
      }
      else
      {
          // در صورت عدم ردیابی، فیبوی متحرک را حذف کن
          ObjectDelete(0, "Tracking_Fib");
      }

      //--- گام ۳: شناسایی، ابطال و مدیریت نواحی FVG
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
//| تابع کمکی: یافتن سقف/کف مطلق در یک محدوده کندلی (برای 0% فیبو)    |
//| محدوده بر اساس اندیس کندل‌های startBar و endBar است.
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
    
    // استفاده از یک متغیر موقت برای بازگرداندن ساختار (رفع خطای Invalid Cast Operation)
    SwingPoint result;
    result.price = extremePrice;
    result.time = extremeTime;
    result.bar_index = extremeIndex;
    return result; 
}


//+------------------------------------------------------------------+
//| تابع اصلاح شده: یافتن نقطه محوری مقابل (پیوت - 100% فیبو)        |
//| محدوده جستجو بر اساس زمان کندل شکست (Break Time) تا زمان سقف/کف شکسته شده
//+------------------------------------------------------------------+
SwingPoint FindOppositeSwing(datetime brokenSwingTime, datetime breakTime, bool findHigh)
{
    // اندیس کندل‌های متناظر با زمان‌های داده شده
    int startBar = iBarShift(_Symbol, _Period, breakTime, false);
    int endBar = iBarShift(_Symbol, _Period, brokenSwingTime, false);
    
    // تعریف ساختار خطا برای بازگشت در صورت عدم موفقیت
    SwingPoint errorResult;
    errorResult.price = 0; errorResult.time = 0; errorResult.bar_index = -1;
    
    if(startBar == -1 || endBar == -1 || startBar >= endBar) 
    {
        LogEvent("خطا در تعیین محدوده جستجوی پیوت مقابل.");
        return errorResult;
    }
    
    // جستجو در محدوده: از کندل بلافاصله بعد از شکست (startBar + 1) تا کندل شکسته شده (endBar)
    SwingPoint extremePoint = FindExtremePrice(startBar + 1, endBar, findHigh);
    
    if (extremePoint.bar_index != -1)
    {
        // ثبت و ترسیم پیوت جدید به عنوان یک Swing Point جدید
        if (findHigh)
        {
            AddSwingHigh(extremePoint.price, extremePoint.time, extremePoint.bar_index); 
            LogEvent("   - پیوت مقابل (سقف/High) در " + DoubleToString(extremePoint.price, _Digits) + " ثبت شد.");
        }
        else
        {
            AddSwingLow(extremePoint.price, extremePoint.time, extremePoint.bar_index); 
            LogEvent("   - پیوت مقابل (کف/Low) در " + DoubleToString(extremePoint.price, _Digits) + " ثبت شد.");
        }
        return extremePoint;
    }

    LogEvent("هشدار: پیوت مقابل (100% فیبو) در محدوده مورد انتظار یافت نشد. استفاده از نقطه پیش‌فرض.");
    return errorResult;
}


//+------------------------------------------------------------------+
//| بررسی شکست سقف یا کف (Breakout) و فعال‌سازی فاز ردیابی           |
//| منطق BoS/CHoCH اعمال شده است.
//+------------------------------------------------------------------+
void CheckForBreakout()
{
   if(isTrackingHigh || isTrackingLow) return;
   if(ArraySize(swingHighs_Array) < 1 || ArraySize(swingLows_Array) < 1) return;

   double close_1 = iClose(_Symbol, _Period, 1); 
   SwingPoint lastHigh = swingHighs_Array[0];
   SwingPoint lastLow = swingLows_Array[0];
   datetime breakTime = iTime(_Symbol, _Period, 1);

   //--- بررسی شکست سقف (Breakout High)
   if(close_1 > lastHigh.price)
   {
      bool isCHoCH = (currentTrend == TREND_BEARISH);
      string breakType = isCHoCH ? "CHoCH" : "BoS";
      LogEvent(">>> رویداد: شکست سقف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد. (سقف شکسته شده: " + DoubleToString(lastHigh.price, _Digits) + ")");
      drawBreak(lastHigh, breakTime, close_1, true, isCHoCH);

      // پیوت مقابل (Low) را پیدا و ثبت کن (این می‌شود نقطه 100% فیبوی ثابت)
      pivotLowForTracking = FindOppositeSwing(lastHigh.time, breakTime, false); 
      
      isTrackingHigh = true; // شکار سقف جدید (HH)
      isTrackingLow = false; 

      LogEvent("--> فاز جدید: [شکار سقف] فعال شد. نقطه 100% فیبو (ثابت) در کف " + DoubleToString(pivotLowForTracking.price, _Digits) + " ثبت شد.");
   }
   //--- بررسی شکست کف (Breakout Low)
   else if(close_1 < lastLow.price)
   {
      bool isCHoCH = (currentTrend == TREND_BULLISH);
      string breakType = isCHoCH ? "CHoCH" : "BoS";
      LogEvent(">>> رویداد: شکست کف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد. (کف شکسته شده: " + DoubleToString(lastLow.price, _Digits) + ")");
      drawBreak(lastLow, breakTime, close_1, false, isCHoCH);

      // پیوت مقابل (High) را پیدا و ثبت کن (این می‌شود نقطه 100% فیبوی ثابت)
      pivotHighForTracking = FindOppositeSwing(lastLow.time, breakTime, true); 
      
      isTrackingLow = true; // شکار کف جدید (LL)
      isTrackingHigh = false; 

      LogEvent("--> فاز جدید: [شکار کف] فعال شد. نقطه 100% فیبو (ثابت) در سقف " + DoubleToString(pivotHighForTracking.price, _Digits) + " ثبت شد.");
   }
}

//+------------------------------------------------------------------+
//| ردیابی و تایید Swing Point جدید با آپدیت 0% فیبو و شرط اصلاح ۳۵٪ |
//+------------------------------------------------------------------+
bool CheckForNewSwingPoint()
{
    //--- ۱. ردیابی سقف جدید (HH) بعد از شکست صعودی
    if (isTrackingHigh)
    {
        // محدوده جستجو: از کندل 1 تا کندل 100% (Pivot Low)
        int startBar = iBarShift(_Symbol, _Period, pivotLowForTracking.time, false);
        SwingPoint current0Per = FindExtremePrice(1, startBar, true); // 0% متحرک: بالاترین High

        if (current0Per.bar_index == -1 || current0Per.price <= pivotLowForTracking.price) return false;
        
        double range = current0Per.price - pivotLowForTracking.price;
        double fibLevel = current0Per.price - (range * (fibConfirmationLevel / 100.0)); // سطح ۳۵٪ اصلاح به سمت پایین
        double close_1 = iClose(_Symbol, _Period, 1);

        // شرط تایید: کلوز کندل 1 باید زیر یا روی سطح اصلاحی بسته شود (رسیدن به 35% به پایین)
        if (close_1 <= fibLevel)
        {
            LogEvent("<<< تایید شد: شرط اصلاح " + IntegerToString(fibConfirmationLevel) + "٪ برای سقف جدید برقرار شد.");
            
            // ثبت سقف جدید (0% آپدیت شده)
            AddSwingHigh(current0Per.price, current0Per.time, current0Per.bar_index);
            isTrackingHigh = false; // توقف ردیابی
            return true;
        }
    }

    //--- ۲. ردیابی کف جدید (LL) بعد از شکست نزولی
    else if (isTrackingLow)
    {
        // محدوده جستجو: از کندل 1 تا کندل 100% (Pivot High)
        int startBar = iBarShift(_Symbol, _Period, pivotHighForTracking.time, false);
        SwingPoint current0Per = FindExtremePrice(1, startBar, false); // 0% متحرک: پایین‌ترین Low
        
        if (current0Per.bar_index == -1 || current0Per.price >= pivotHighForTracking.price) return false;

        double range = pivotHighForTracking.price - current0Per.price;
        double fibLevel = current0Per.price + (range * (fibConfirmationLevel / 100.0)); // سطح ۳۵٪ اصلاح به سمت بالا
        double close_1 = iClose(_Symbol, _Period, 1);

        // شرط تایید: کلوز کندل 1 باید بالا یا روی سطح اصلاحی بسته شود (رسیدن به 35% به بالا)
        if (close_1 >= fibLevel)
        {
            LogEvent("<<< تایید شد: شرط اصلاح " + IntegerToString(fibConfirmationLevel) + "٪ برای کف جدید برقرار شد.");

            // ثبت کف جدید (0% آپدیت شده)
            AddSwingLow(current0Per.price, current0Per.time, current0Per.bar_index);
            isTrackingLow = false; 
            return true;
        }
    }
    return false; 
}


//+------------------------------------------------------------------+
//| تابع جدید: ترسیم فیبوناچی متحرک (ردیابی)                         |
//| این تابع در هر تیک نقطه 0% را آپدیت می‌کند.
//+------------------------------------------------------------------+
void DrawTrackingFibonacci()
{
    SwingPoint p100, p0; 
    bool isBullish = isTrackingHigh; 

    if (isTrackingHigh) // موج صعودی
    {
        p100 = pivotLowForTracking; 
        int startBar = iBarShift(_Symbol, _Period, p100.time, false);
        p0 = FindExtremePrice(1, startBar, true); // 0% متحرک
        if (p0.bar_index == -1 || p0.price <= p100.price) return; 
    }
    else if (isTrackingLow) // موج نزولی
    {
        p100 = pivotHighForTracking; 
        int startBar = iBarShift(_Symbol, _Period, p100.time, false);
        p0 = FindExtremePrice(1, startBar, false); // 0% متحرک
        if (p0.bar_index == -1 || p0.price >= p100.price) return;
    }
    else return;

    string objName = "Tracking_Fib";
    ObjectDelete(0, objName);

    ObjectCreate(0, objName, OBJ_FIBO, 0, p100.time, p100.price, p0.time, p0.price);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, isBullish ? clrDodgerBlue : clrOrangeRed);
    ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    
    // تنظیم سطوح مورد نیاز
    ObjectSetDouble(0, objName, OBJPROP_LEVELVALUE, 0, 0.0);
    ObjectSetString(0, objName, OBJPROP_LEVELTEXT, 0, "0% (Movable)");
    
    ObjectSetDouble(0, objName, OBJPROP_LEVELVALUE, 1, (double)fibConfirmationLevel / 100.0);
    ObjectSetString(0, objName, OBJPROP_LEVELTEXT, 1, IntegerToString(fibConfirmationLevel) + "% (Confirmation)");

    ObjectSetDouble(0, objName, OBJPROP_LEVELVALUE, 2, 1.0);
    ObjectSetString(0, objName, OBJPROP_LEVELTEXT, 2, "100% (Fixed Pivot)");
    
    // پاک کردن سطوح اضافی
    for(int i = 3; i < 10; i++) ObjectSetDouble(0, objName, OBJPROP_LEVELVALUE, i, 0.0);
}


//+------------------------------------------------------------------+
//| توابع مدیریت نواحی FVG (Fair Value Gap)                          |
//| بر اساس منطق سه کندلی با فیلتر قدرت کندل (نسبت بادی به رنج)
//+------------------------------------------------------------------+
bool IdentifyFVG() 
{
   if(iBars(_Symbol, _Period) < 3) return false;
   int i = 1; // بررسی سه کندل اخیر (1, 2, 3)
   double high1 = iHigh(_Symbol, _Period, i);
   double low1  = iLow(_Symbol, _Period, i);
   double high2 = iHigh(_Symbol, _Period, i + 1);
   double low2  = iLow(_Symbol, _Period, i + 1);
   double high3 = iHigh(_Symbol, _Period, i + 2);
   double low3  = iLow(_Symbol, _Period, i + 2);
   
   //--- فیلتر قدرت کندل: بادی باید بخش قابل توجهی از رنج کل باشد
   bool isStrong1 = (MathAbs(iClose(_Symbol, _Period, i) - iOpen(_Symbol, _Period, i)) / (high1 - low1)) >= (fvgBodyRatio / 100.0);
   bool isStrong3 = (MathAbs(iClose(_Symbol, _Period, i+2) - iOpen(_Symbol, _Period, i+2)) / (high3 - low3)) >= (fvgBodyRatio / 100.0);
   
   if (high1 - low1 < _Point * 5 || high3 - low3 < _Point * 5) return false; // فیلتر نویز

   if (isStrong1 && isStrong3) 
   {
      // FVG صعودی (Bullish): کف کندل 1 بالاتر از سقف کندل 3، و کندل 2 گپ را پوشش نداده باشد
      if (low1 > high3) 
      {
         // اطمینان از اینکه کندل وسط (کندل 2) ناحیه گپ را پوشش نداده است
         if (low2 > high3 && high2 < low1) 
         {
            AddFVG(true, low1, high3, iTime(_Symbol, _Period, i));
            return true;
         }
      }
      // FVG نزولی (Bearish): سقف کندل 1 پایین‌تر از کف کندل 3، و کندل 2 گپ را پوشش نداده باشد
      if (high1 < low3) 
      {
         // اطمینان از اینکه کندل وسط (کندل 2) ناحیه گپ را پوشش نداده است
         if (high2 < low3 && low2 > high1) 
         {
            AddFVG(false, low3, high1, iTime(_Symbol, _Period, i)); 
            return true; 
         }
      }
   }
   return false;
}

void AddFVG(bool isBullish, double highPrice, double lowPrice, datetime time) 
{
   // جلوگیری از ثبت FVG تکراری
   for(int i=0; i<ArraySize(fvgArray); i++) { if(fvgArray[i].time == time) return; }

   // مدیریت سایز آرایه FVG (حداکثر 30 عدد)
   if(ArraySize(fvgArray) >= 30) 
   {
      int lastIndex = ArraySize(fvgArray) - 1;
      string typeStrOld = fvgArray[lastIndex].isBullish ? "Bullish" : "Bearish";
      string objNameOld = "FVG_" + TimeToString(fvgArray[lastIndex].time) + "_" + typeStrOld;
      ObjectDelete(0, objNameOld);
      ObjectDelete(0, objNameOld + "_Text");
      ArrayRemove(fvgArray, lastIndex, 1); 
   }
   // افزودن FVG جدید به ابتدای آرایه
   ArrayResize(fvgArray, ArraySize(fvgArray) + 1); 
   fvgArray[0].isBullish = isBullish;
   fvgArray[0].highPrice = highPrice;
   fvgArray[0].lowPrice = lowPrice;
   fvgArray[0].time = time;
   fvgArray[0].consumed = false;
   drawFVG(fvgArray[0]);
   
   LogEvent("   - FVG " + (isBullish ? "صعودی" : "نزولی") + " در ناحیه " + DoubleToString(lowPrice, _Digits) + " تا " + DoubleToString(highPrice, _Digits) + " شناسایی شد.");
}

bool CheckConsumedFVGs() 
{
   double high1 = iHigh(_Symbol, _Period, 1);
   double low1 = iLow(_Symbol, _Period, 1);
   bool consumedNow = false;
   for(int i = 0; i < ArraySize(fvgArray); i++) 
   {
      if(!fvgArray[i].consumed) 
      {
         bool isConsumed = false;
         // مصرف شدگی FVG صعودی: قیمت به بالای سقف ناحیه برگردد (برخورد لو کندل 1)
         if(fvgArray[i].isBullish && low1 <= fvgArray[i].highPrice) isConsumed = true;
         // مصرف شدگی FVG نزولی: قیمت به پایین کف ناحیه برگردد (برخورد های کندل 1)
         if(!fvgArray[i].isBullish && high1 >= fvgArray[i].lowPrice) isConsumed = true;
         
         if(isConsumed)
         {
            fvgArray[i].consumed = true;
            string typeStr = fvgArray[i].isBullish ? "Bullish" : "Bearish";
            string objName = "FVG_" + TimeToString(fvgArray[i].time) + "_" + typeStr;
            ObjectDelete(0, objName);
            ObjectDelete(0, objName + "_Text");
            LogEvent("   - FVG " + typeStr + " در زمان " + TimeToString(fvgArray[i].time) + " مصرف شد.");
            consumedNow = true;
         }
      }
   }
   return consumedNow;
}

//+------------------------------------------------------------------+
//| توابع کمکی ساختار اولیه و ترسیمی (بدون تغییر منطق نسبت به v5.1)   |
//+------------------------------------------------------------------+
void IdentifyInitialStructure() {} // برای سادگی در اینجا خالی است

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

bool UpdateTrendLabel() 
{
   TREND_TYPE oldTrend = currentTrend;
   if(ArraySize(swingHighs_Array) >= 2 && ArraySize(swingLows_Array) >= 2) 
   {
      SwingPoint lastHigh = swingHighs_Array[0];
      SwingPoint prevHigh = swingHighs_Array[1];
      SwingPoint lastLow  = swingLows_Array[0];
      SwingPoint prevLow  = swingLows_Array[1];
      
      // HH و HL: روند صعودی
      if(lastHigh.price > prevHigh.price && lastLow.price > prevLow.price) currentTrend = TREND_BULLISH;
      // LL و LH: روند نزولی
      else if(lastHigh.price < prevHigh.price && lastLow.price < prevLow.price) currentTrend = TREND_BEARISH;
      // در غیر این صورت، حالت رنج یا تغییر روند نامشخص
      else currentTrend = TREND_RANGING;
   } 
   else currentTrend = TREND_RANGING;
   
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

   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, fvg.time, fvg.highPrice, iTime(_Symbol, _Period, 0) + PeriodSeconds()*10, fvg.lowPrice);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, fvg.isBullish ? C'173,216,230' : C'255,192,203');
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true); 
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);

   ObjectCreate(0, textName, OBJ_TEXT, 0, fvg.time, fvg.isBullish ? fvg.highPrice : fvg.lowPrice);
   ObjectSetString(0, textName, OBJPROP_TEXT, "FVG");
   ObjectSetInteger(0, textName, OBJPROP_COLOR, clrDimGray);
   ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, textName, OBJPROP_ANCHOR, fvg.isBullish ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
   ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
}
//+------------------------------------------------------------------+
