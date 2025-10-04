//+------------------------------------------------------------------+
//|                                     MarketStructurePro_v4.0.mq5 |
//|                                  Copyright 2025, Khajavi & Gemini |
//|                                             Powerd by Gemini AI |
//|------------------------------------------------------------------|
//| نسخه 4.0 - بازنویسی کامل با تمرکز بر:                           |
//| 1. رفع کامل هشدارهای کامپایلر                                   |
//| 2. سیستم لاگ پیشرفته و هوشمند فارسی                              |
//| 3. کامنت‌گذاری جامع فارسی برای تمام بخش‌ها                      |
//| 4. بهینه‌سازی عملکرد و پایداری اکسپرت                            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi & Gemini"
#property link      "https://www.google.com"
#property version   "4.00"

//+------------------------------------------------------------------+
//| ورودی‌های اکسپرت (Inputs)                                        |
//+------------------------------------------------------------------+
input bool enableLogging = true; // [فعال/غیرفعال کردن] سیستم لاگ برای گزارش‌دهی مراحل

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
SwingPoint pivotHighForTracking; // در یک شکست نزولی، این متغیر آخرین سقف (نقطه 100% فیبو) را نگه می‌دارد
SwingPoint pivotLowForTracking;  // در یک شکست صعودی، این متغیر آخرین کف (نقطه 100% فیبو) را نگه می‌دارد
bool       isTrackingHigh = false; // فلگ وضعیت: آیا در فاز "شکار سقف جدید" هستیم؟
bool       isTrackingLow  = false; // فلگ وضعیت: آیا در فاز "شکار کف جدید" هستیم؟

//+------------------------------------------------------------------+
//| تابع کمکی برای لاگ‌گیری (Helper Function for Logging)             |
//+------------------------------------------------------------------+
void LogEvent(string message)
{
   // فقط در صورتی لاگ ثبت کن که در ورودی اکسپرت فعال شده باشد
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
   LogEvent("اکسپرت MarketStructurePro v4.0 با موفقیت آغاز به کار کرد.");
   
   //--- پاکسازی چارت از اشیاء قدیمی در شروع کار
   ObjectsDeleteAll(0, 0, -1);
   
   //--- تنظیم آرایه‌ها به صورت سری زمانی (داده جدید در اندیس 0 قرار می‌گیرد)
   ArraySetAsSeries(swingHighs_Array, true);
   ArraySetAsSeries(swingLows_Array, true);
   ArraySetAsSeries(fvgArray, true); 
   
   //--- اطمینان از خالی بودن آرایه‌ها در ابتدای کار
   ArrayResize(swingHighs_Array, 0);
   ArrayResize(swingLows_Array, 0);
   ArrayResize(fvgArray, 0);
   
   //--- مقداردهی اولیه متغیرهای ردیابی وضعیت
   isTrackingHigh = false;
   isTrackingLow = false;
   
   //--- شناسایی ساختار اولیه بازار برای داشتن نقطه شروع
   IdentifyInitialStructure();
   
   //--- به‌روزرسانی و نمایش اولیه برچسب روند 
   UpdateTrendLabel();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| تابع خاتمه اکسپرت (OnDeinit)                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
{
   LogEvent("اکسپرت متوقف شد. تمام اشیاء از روی چارت پاکسازی می‌شوند.");
   //--- پاکسازی کامل اشیاء گرافیکی در زمان حذف اکسپرت از چارت
   ObjectsDeleteAll(0, 0, -1);
   ArrayFree(swingHighs_Array);
   ArrayFree(swingLows_Array);
   ArrayFree(fvgArray);
}

//+------------------------------------------------------------------+
//| تابع اصلی که با هر تیک قیمت اجرا می‌شود (OnTick)                 |
//+------------------------------------------------------------------+
void OnTick() 
{
   //--- منطق استاندارد برای اجرای کد فقط یک بار در هر کندل جدید
   static datetime prevTime = 0;
   datetime currentTime = iTime(_Symbol, _Period, 0);
   
   if(currentTime != prevTime) 
   {
      prevTime = currentTime;
      bool chartNeedsRedraw = false; // فلگ بهینه‌سازی برای جلوگیری از رفرش مکرر چارت

      //--- شرط پایداری: اگر تعداد کندل‌ها کم است، برای جلوگیری از خطا هیچ کاری نکن
      if(iBars(_Symbol, _Period) < 50)
      {
         return;
      }
      
      //--- گام ۱: بررسی شکست ساختار (این گام باید قبل از تشخیص نقاط جدید باشد)
      if(ArraySize(swingHighs_Array) >= 1 && ArraySize(swingLows_Array) >= 1)
      {
         // اگر شکستی رخ دهد، این تابع فلگ ردیابی را فعال می‌کند
         CheckForBreakout(); 
      }
      
      //--- گام ۲: ردیابی و تایید نقطه محوری جدید (فقط زمانی که یک فلگ ردیابی فعال باشد)
      if(isTrackingHigh || isTrackingLow)
      {
         if(CheckForNewSwingPoint())
         {
            chartNeedsRedraw = true; // اگر نقطه جدیدی تایید شد، چارت نیاز به رفرش دارد
         }
      }

      //--- گام ۳: شناسایی، ابطال و مدیریت نواحی FVG
      if(IdentifyFVG()) chartNeedsRedraw = true;
      if(CheckConsumedFVGs()) chartNeedsRedraw = true;
      
      //--- گام ۴: به‌روزرسانی نمایش روند
      if(UpdateTrendLabel()) chartNeedsRedraw = true;
      
      //--- بهینه‌سازی: فقط در صورت نیاز، چارت را یک بار در انتهای تیک رفرش کن
      if(chartNeedsRedraw)
      {
         ChartRedraw(0);
      }
   }
}

//+------------------------------------------------------------------+
//| شناسایی ساختار اولیه بازار (بر مبنای فرکتال ساده)                  |
//+------------------------------------------------------------------+
void IdentifyInitialStructure()
{
   int fractalLength = 10; 
   int barsCount = iBars(_Symbol, _Period);

   // اطمینان از وجود کندل کافی برای تحلیل اولیه
   if(barsCount < fractalLength * 2) return;

   //--- جستجو برای یافتن اولین سقف معتبر
   for(int i = fractalLength; i < barsCount - fractalLength; i++)
   {
      bool isSwingHigh = true;
      for(int j = 1; j <= fractalLength; j++)
      {
         if(iHigh(_Symbol, _Period, i) < iHigh(_Symbol, _Period, i - j) || iHigh(_Symbol, _Period, i) < iHigh(_Symbol, _Period, i + j))
         {
            isSwingHigh = false;
            break;
         }
      }
      if(isSwingHigh)
      {
         AddSwingHigh(iHigh(_Symbol, _Period, i), iTime(_Symbol, _Period, i), i);
         LogEvent("ساختار اولیه: اولین سقف در قیمت " + DoubleToString(iHigh(_Symbol, _Period, i), _Digits) + " شناسایی شد.");
         break; 
      }
   }
   
   //--- جستجو برای یافتن اولین کف معتبر
   for(int i = fractalLength; i < barsCount - fractalLength; i++)
   {
      bool isSwingLow = true;
      for(int j = 1; j <= fractalLength; j++)
      {
         if(iLow(_Symbol, _Period, i) > iLow(_Symbol, _Period, i - j) || iLow(_Symbol, _Period, i) > iLow(_Symbol, _Period, i + j))
         {
            isSwingLow = false;
            break;
         }
      }
      if(isSwingLow)
      {
         AddSwingLow(iLow(_Symbol, _Period, i), iTime(_Symbol, _Period, i), i);
         LogEvent("ساختار اولیه: اولین کف در قیمت " + DoubleToString(iLow(_Symbol, _Period, i), _Digits) + " شناسایی شد.");
         break;
      }
   }
}


//+------------------------------------------------------------------+
//| بررسی شکست سقف یا کف (Breakout) و فعال‌سازی فاز ردیابی           |
//+------------------------------------------------------------------+
void CheckForBreakout()
{
   // اگر هنوز در فاز ردیابی هستیم، به دنبال شکست جدید نباش
   if(isTrackingHigh || isTrackingLow) return;
   if(ArraySize(swingHighs_Array) < 1 || ArraySize(swingLows_Array) < 1) return;

   double close_1 = iClose(_Symbol, _Period, 1); // قیمت بسته شدن کندل تکمیل شده قبلی
   SwingPoint lastHigh = swingHighs_Array[0];
   SwingPoint lastLow = swingLows_Array[0];

   //--- بررسی شکست سقف (Breakout High)
   if(close_1 > lastHigh.price)
   {
      bool isCHoCH = (currentTrend == TREND_BEARISH);
      string breakType = isCHoCH ? "CHoCH" : "BoS";
      LogEvent(">>> رویداد: شکست سقف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد. (سقف شکسته شده: " + DoubleToString(lastHigh.price, _Digits) + ")");
      
      drawBreak(lastHigh, iTime(_Symbol, _Period, 1), close_1, true, isCHoCH);

      // گام ۱: پیدا کردن کفِ موجی که باعث شکست شده و ثبت فوری آن
      FindOppositeSwingAndAddNew(lastHigh.bar_index, 1, false); // false = یافتن Low
      
      // گام ۲: فعال کردن فاز "شکار سقف جدید"
      pivotLowForTracking = swingLows_Array[0]; // این کف جدید، نقطه 100% فیبوی ماست
      isTrackingHigh = true; 
      isTrackingLow = false; 
      
      // لاگ ورود به فاز جدید با جزئیات کامل
      LogEvent("--> فاز جدید: [شکار سقف] فعال شد. منتظر اصلاح ۳۵٪ هستیم.\n" +
               "    - نقطه ۱۰۰٪ فیبو (کف پیوت): " + DoubleToString(pivotLowForTracking.price, _Digits) + "\n" +
               "    - نقطه ۰٪ فیبو (سقف اولیه شکست): " + DoubleToString(lastHigh.price, _Digits));
   }
   //--- بررسی شکست کف (Breakout Low)
   else if(close_1 < lastLow.price)
   {
      bool isCHoCH = (currentTrend == TREND_BULLISH);
      string breakType = isCHoCH ? "CHoCH" : "BoS";
      LogEvent(">>> رویداد: شکست کف (" + breakType + ") در قیمت " + DoubleToString(close_1, _Digits) + " رخ داد. (کف شکسته شده: " + DoubleToString(lastLow.price, _Digits) + ")");
      
      drawBreak(lastLow, iTime(_Symbol, _Period, 1), close_1, false, isCHoCH);

      // گام ۱: پیدا کردن سقفِ موجی که باعث شکست شده و ثبت فوری آن
      FindOppositeSwingAndAddNew(lastLow.bar_index, 1, true); // true = یافتن High
      
      // گام ۲: فعال کردن فاز "شکار کف جدید"
      pivotHighForTracking = swingHighs_Array[0]; // این سقف جدید، نقطه 100% فیبوی ماست
      isTrackingLow = true;
      isTrackingHigh = false; 

      // لاگ ورود به فاز جدید با جزئیات کامل
      LogEvent("--> فاز جدید: [شکار کف] فعال شد. منتظر اصلاح ۳۵٪ هستیم.\n" +
               "    - نقطه ۱۰۰٪ فیبو (سقف پیوت): " + DoubleToString(pivotHighForTracking.price, _Digits) + "\n" +
               "    - نقطه ۰٪ فیبو (کف اولیه شکست): " + DoubleToString(lastLow.price, _Digits));
   }
}


//+------------------------------------------------------------------+
//| یافتن نقطه محوری مقابل (پیوت) پس از شکست و افزودن آن به آرایه     |
//+------------------------------------------------------------------+
void FindOppositeSwingAndAddNew(int brokenSwingIndex, int breakBarIndex, bool findHigh)
{
    double extremePrice = findHigh ? 0 : DBL_MAX; 
    datetime extremeTime = 0; // رفع هشدار: مقداردهی اولیه
    int extremeIndex = -1;

    // جستجو از کندل شکست (breakBarIndex) تا کندل ساختار شکسته شده (brokenSwingIndex)
    for (int i = breakBarIndex; i <= brokenSwingIndex; i++)
    {
        if (findHigh) // در جستجوی بالاترین قیمت (سقف)
        {
            double currentHigh = iHigh(_Symbol, _Period, i);
            if (currentHigh > extremePrice)
            {
                extremePrice = currentHigh;
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
        else // در جستجوی پایین‌ترین قیمت (کف)
        {
            double currentLow = iLow(_Symbol, _Period, i);
            if (currentLow < extremePrice)
            {
                extremePrice = currentLow;
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
    }

    // اگر نقطه معتبری پیدا شد، آن را به آرایه مربوطه اضافه کن
    if (extremeIndex != -1)
    {
        if (findHigh)
        {
            AddSwingHigh(extremePrice, extremeTime, extremeIndex);
            LogEvent("   - پیوت مقابل (سقف) در قیمت " + DoubleToString(extremePrice, _Digits) + " برای موج نزولی جدید ثبت شد.");
        }
        else
        {
            AddSwingLow(extremePrice, extremeTime, extremeIndex);
            LogEvent("   - پیوت مقابل (کف) در قیمت " + DoubleToString(extremePrice, _Digits) + " برای موج صعودی جدید ثبت شد.");
        }
    }
}


//+------------------------------------------------------------------+
//| ردیابی و تایید Swing Point جدید با منطق اصلاح ۳۵٪ فیبوناچی        |
//+------------------------------------------------------------------+
bool CheckForNewSwingPoint()
{
    //--- ۱. ردیابی سقف جدید (HH/LH) بعد از شکست صعودی
    if (isTrackingHigh)
    {
        double currentHigh = 0;
        datetime highTime = 0;   // رفع هشدار: مقداردهی اولیه
        int highIndex = -1;
        
        // جستجو برای یافتن بالاترین قیمت در محدوده موج فعلی (این نقطه 0% فیبوی متحرک ماست)
        for (int i = 1; i <= pivotLowForTracking.bar_index; i++)
        {
            if (iHigh(_Symbol, _Period, i) > currentHigh)
            {
                currentHigh = iHigh(_Symbol, _Period, i);
                highTime = iTime(_Symbol, _Period, i);
                highIndex = i;
            }
        }

        // اگر هنوز موج معناداری تشکیل نشده، از تابع خارج شو
        if (highIndex == -1 || currentHigh <= pivotLowForTracking.price) return false;
        
        double range = currentHigh - pivotLowForTracking.price;
        double fib35Level = currentHigh - (range * 0.35); // سطح ۳۵٪ اصلاح از سقف به سمت کف
        double close_1 = iClose(_Symbol, _Period, 1);

        //--- شرط تایید: آیا کلوز کندل قبلی به اندازه کافی (۳۵٪) اصلاح کرده است؟
        if (close_1 < fib35Level)
        {
            LogEvent("<<< تایید شد: شرط اصلاح ۳۵٪ برای سقف جدید برقرار شد.\n" +
                     "    - کلوز کندل (" + DoubleToString(close_1, _Digits) + ") پایین‌تر از سطح اصلاحی (" + DoubleToString(fib35Level, _Digits) + ") است.");
            LogEvent("    - سقف جدید در قیمت " + DoubleToString(currentHigh, _Digits) + " تایید و ثبت می‌شود.");
            
            AddSwingHigh(currentHigh, highTime, highIndex);
            isTrackingHigh = false; // توقف فاز ردیابی
            return true;
        }
    }

    //--- ۲. ردیابی کف جدید (LL/HL) بعد از شکست نزولی
    if (isTrackingLow)
    {
        double currentLow = DBL_MAX;
        datetime lowTime = 0; // رفع هشدار: مقداردهی اولیه
        int lowIndex = -1;
        
        // جستجو برای یافتن پایین‌ترین قیمت در محدوده موج فعلی (این نقطه 0% فیبوی متحرک ماست)
        for (int i = 1; i <= pivotHighForTracking.bar_index; i++)
        {
            if (iLow(_Symbol, _Period, i) < currentLow)
            {
                currentLow = iLow(_Symbol, _Period, i);
                lowTime = iTime(_Symbol, _Period, i);
                lowIndex = i;
            }
        }

        // اگر هنوز موج معناداری تشکیل نشده، از تابع خارج شو
        if (lowIndex == -1 || currentLow >= pivotHighForTracking.price) return false;

        double range = pivotHighForTracking.price - currentLow;
        double fib35Level = currentLow + (range * 0.35); // سطح ۳۵٪ اصلاح از کف به سمت سقف
        double close_1 = iClose(_Symbol, _Period, 1);

        //--- شرط تایید: آیا کلوز کندل قبلی به اندازه کافی (۳۵٪) اصلاح کرده است؟
        if (close_1 > fib35Level)
        {
            LogEvent("<<< تایید شد: شرط اصلاح ۳۵٪ برای کف جدید برقرار شد.\n" +
                     "    - کلوز کندل (" + DoubleToString(close_1, _Digits) + ") بالاتر از سطح اصلاحی (" + DoubleToString(fib35Level, _Digits) + ") است.");
            LogEvent("    - کف جدید در قیمت " + DoubleToString(currentLow, _Digits) + " تایید و ثبت می‌شود.");

            AddSwingLow(currentLow, lowTime, lowIndex);
            isTrackingLow = false; // توقف فاز ردیابی
            return true;
        }
    }
    return false; // هیچ نقطه جدیدی در این تیک تایید نشد
}


//+------------------------------------------------------------------+
//| توابع مدیریت آرایه‌ها (افزودن سقف/کف جدید)                       |
//+------------------------------------------------------------------+
void AddSwingHigh(double price, datetime time, int bar_index) 
{
   // برای حفظ سایز آرایه روی ۲، قدیمی‌ترین داده حذف می‌شود
   if(ArraySize(swingHighs_Array) >= 2) 
   {
      ObjectDelete(0, "High_" + TimeToString(swingHighs_Array[1].time)); 
      ObjectDelete(0, "High_" + TimeToString(swingHighs_Array[1].time) + "_Text");
      ArrayRemove(swingHighs_Array, ArraySize(swingHighs_Array) - 1, 1); 
   }
   
   // افزودن داده جدید به ابتدای آرایه (اندیس 0)
   int newSize = ArraySize(swingHighs_Array) + 1;
   ArrayResize(swingHighs_Array, newSize); 
   swingHighs_Array[0].price = price;
   swingHighs_Array[0].time = time;
   swingHighs_Array[0].bar_index = bar_index;
   
   drawSwingPoint(swingHighs_Array[0], true);
}

void AddSwingLow(double price, datetime time, int bar_index) 
{
   // برای حفظ سایز آرایه روی ۲، قدیمی‌ترین داده حذف می‌شود
   if(ArraySize(swingLows_Array) >= 2) 
   {
      ObjectDelete(0, "Low_" + TimeToString(swingLows_Array[1].time)); 
      ObjectDelete(0, "Low_" + TimeToString(swingLows_Array[1].time) + "_Text");
      ArrayRemove(swingLows_Array, ArraySize(swingLows_Array) - 1, 1); 
   }
   
   // افزودن داده جدید به ابتدای آرایه (اندیس 0)
   int newSize = ArraySize(swingLows_Array) + 1;
   ArrayResize(swingLows_Array, newSize); 
   swingLows_Array[0].price = price;
   swingLows_Array[0].time = time;
   swingLows_Array[0].bar_index = bar_index;

   drawSwingPoint(swingLows_Array[0], false);
}


//+------------------------------------------------------------------+
//| توابع مدیریت نواحی FVG                                          |
//+------------------------------------------------------------------+
bool IdentifyFVG() 
{
   if(iBars(_Symbol, _Period) < 23) return false;
   int i = 1; // بررسی سه کندل اخیر (1, 2, 3)
   double high1 = iHigh(_Symbol, _Period, i);
   double low1  = iLow(_Symbol, _Period, i);
   double high3 = iHigh(_Symbol, _Period, i + 2);
   double low3  = iLow(_Symbol, _Period, i + 2);
   
   // فیلتر: FVG فقط در کندل‌های قوی شناسایی شود
   double avgRange = 0;
   for (int j = i; j < i + 20; j++) avgRange += iHigh(_Symbol, _Period, j) - iLow(_Symbol, _Period, j);
   avgRange /= 20.0;
   bool isStrong1 = (high1 - low1) > avgRange * 0.8; 
   bool isStrong3 = (iHigh(_Symbol, _Period, i+2) - iLow(_Symbol, _Period, i+2)) > avgRange * 0.8; 

   if (isStrong1 && isStrong3) 
   {
      // FVG صعودی: کف کندل 1 بالاتر از سقف کندل 3
      if (low1 > high3) { AddFVG(true, low1, high3, iTime(_Symbol, _Period, i)); return true; }
      // FVG نزولی: سقف کندل 1 پایین‌تر از کف کندل 3
      if (high1 < low3) { AddFVG(false, low3, high1, iTime(_Symbol, _Period, i)); return true; }
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
         if(fvgArray[i].isBullish && low1 <= fvgArray[i].highPrice) isConsumed = true;
         if(!fvgArray[i].isBullish && high1 >= fvgArray[i].lowPrice) isConsumed = true;
         
         if(isConsumed)
         {
            fvgArray[i].consumed = true;
            string typeStr = fvgArray[i].isBullish ? "Bullish" : "Bearish";
            string objName = "FVG_" + TimeToString(fvgArray[i].time) + "_" + typeStr;
            ObjectDelete(0, objName);
            ObjectDelete(0, objName + "_Text");
            consumedNow = true;
         }
      }
   }
   return consumedNow;
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
      if(lastHigh.price > prevHigh.price && lastLow.price > prevLow.price) currentTrend = TREND_BULLISH;
      else if(lastHigh.price < prevHigh.price && lastLow.price < prevLow.price) currentTrend = TREND_BEARISH;
      else currentTrend = TREND_NONE;
   } 
   else currentTrend = TREND_NONE;
   
   // فقط در صورت تغییر وضعیت، لاگ و شیء را آپدیت کن
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
