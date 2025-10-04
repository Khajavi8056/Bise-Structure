//+------------------------------------------------------------------+
//|                                              MarketStructurePro.mq5 |
//|                                  Copyright 2025, Khajavi & Gemini |
//|                                        Powerd by Gemini AI        |
//|------------------------------------------------------------------|
//| توضیح: این ماژول ساختار بازار را بر اساس SMC و با تمرکز بر مدیریت  |
//|       سقف/کف (Swing Point) و شکست‌ها (BoS/CHoCH) تحلیل می‌کند.    |
//|       **منطق تشخیص Swing Point جدید** با استفاده از **اصلاح 35٪ فیبوناچی**|
//|       (بر مبنای کلوز کندل) پیاده‌سازی شده است.                    |
//|       **فیبوناچی صرفاً ابزار محاسباتی است و به هیچ عنوان رسم نمی‌شود.**|
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi & Gemini"
#property link      "https://www.google.com"
#property version   "3.05" // ورژن به روز شد

//+------------------------------------------------------------------+
//| ساختار داده‌ها و شمارنده‌ها (Enums & Structs)                     |
//+------------------------------------------------------------------+

//--- ساختار برای نگهداری اطلاعات یک نقطه سقف یا کف (Swing Point)
struct SwingPoint
{
   double   price;      // قیمت سقف یا کف
   datetime time;       // زمان کندلی که سقف یا کف در آن تشکیل شده
   int      bar_index;  // اندیس کندلی از دید متاتریدر
};

//--- ساختار برای نگهداری اطلاعات یک ناحیه شکاف ارزش منصفانه (FVG)
struct FVG 
{
   bool     isBullish;  // نوع FVG: True برای صعودی، False برای نزولی
   double   highPrice;  // بالاترین قیمت زون FVG
   double   lowPrice;   // پایین‌ترین قیمت زون FVG
   datetime time;       // زمان کندل شروع زون
   bool     consumed;   // وضعیت ابطال/مصرف
};

//--- شمارنده برای نگهداری وضعیت فعلی روند بازار
enum TREND_TYPE 
{
   TREND_BULLISH,  // روند صعودی
   TREND_BEARISH,  // روند نزولی
   TREND_NONE      // بدون روند مشخص
};

//+------------------------------------------------------------------+
//| متغیرهای سراسری (Global Variables)                               |
//+------------------------------------------------------------------+
SwingPoint swingHighs_Array[];   // آرایه سقف‌ها ([0] جدید، [1] قدیمی)
SwingPoint swingLows_Array[];    // آرایه کف‌ها ([0] جدید، [1] قدیمی)
FVG        fvgArray[];           // آرایه ناحیه‌های FVG ([0] جدیدترین)

TREND_TYPE currentTrend = TREND_NONE;    // وضعیت روند فعلی بازار
string     trendObjectName = "TrendLabel"; // نام شیء متنی برای نمایش وضعیت روند

//--- متغیرهای ردیابی موج جدید برای منطق فیبوناچی
// این نقاط، Swing Point ای هستند که به محض شکست پیدا شده و نقش نقطه 100% فیبو را دارند.
SwingPoint pivotHighForTracking; // نقطه 100% فیبو در موج نزولی (سقف)
SwingPoint pivotLowForTracking;  // نقطه 100% فیبو در موج صعودی (کف)
bool       isTrackingHigh = false; // آیا در حال ردیابی سقف جدید (HH/LH) هستیم؟
bool       isTrackingLow = false;  // آیا در حال ردیابی کف جدید (LL/HL) هستیم؟


//+------------------------------------------------------------------+
//| تابع مقداردهی اولیه اکسپرت (OnInit)                               |
//+------------------------------------------------------------------+
int OnInit() 
{
   //--- پاکسازی چارت و تنظیم آرایه‌ها به صورت سری زمانی (جدیدترین در اندیس 0)
   ObjectsDeleteAll(0, 0, -1);
   ArraySetAsSeries(swingHighs_Array, true);
   ArraySetAsSeries(swingLows_Array, true);
   ArraySetAsSeries(fvgArray, true); 
   ArrayResize(swingHighs_Array, 0);
   ArrayResize(swingLows_Array, 0);
   ArrayResize(fvgArray, 0);
   
   //--- مقداردهی اولیه متغیرهای ردیابی
   isTrackingHigh = false;
   isTrackingLow = false;
   
   //--- شناسایی ساختار اولیه بازار (سقف/کف‌های اولیه)
   IdentifyInitialStructure();
   
   //--- به‌روزرسانی و نمایش برچسب روند 
   UpdateTrendLabel();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| تابع خاتمه اکسپرت (OnDeinit)                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
{
   //--- پاکسازی کامل اشیاء گرافیکی
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
   //--- منطق تشخیص کندل جدید (فقط یک بار اجرا در هر کندل بسته شده)
   static datetime prevTime = 0;
   datetime currentTime = iTime(_Symbol, _Period, 0);
   
   if(currentTime != prevTime) 
   {
      prevTime = currentTime;
      
      //--- 1. بررسی شکست ساختار (باید قبل از تشخیص Swing Point جدید باشد)
      if(ArraySize(swingHighs_Array) >= 1 && ArraySize(swingLows_Array) >= 1)
      {
         CheckForBreakout(); 
      }
      
      //--- 2. ردیابی و تایید Swing Point جدید با منطق فیبوناچی (فقط زمانی که ردیابی فعال است)
      CheckForNewSwingPoint();

      //--- 3. شناسایی، ابطال و مدیریت FVG ها
      IdentifyFVG();
      CheckConsumedFVGs();
      
      //--- 4. به‌روزرسانی نمایش روند
      UpdateTrendLabel();
   }
}

//+------------------------------------------------------------------+
//| تابع شناسایی ساختار اولیه بازار (سقف/کف اولیه بر مبنای فرکتال)   |
//+------------------------------------------------------------------+
void IdentifyInitialStructure()
{
   // این منطق ثابت برای پیدا کردن 2 سقف و 2 کف اولیه برای شروع سیستم است.
   bool highFound = false;
   bool lowFound = false;
   int fractalLength = 10; 
   int barsCount = iBars(_Symbol, _Period);

   for(int i = fractalLength; i < barsCount - fractalLength; i++)
   {
      if(highFound && lowFound) break;

      bool isSwingHigh = true;
      bool isSwingLow = true;
      
      if(!highFound)
      {
         for(int j = 1; j <= fractalLength; j++)
         {
            if(iHigh(_Symbol, _Period, i) < iHigh(_Symbol, _Period, i - j) || 
               iHigh(_Symbol, _Period, i) < iHigh(_Symbol, _Period, i + j))
            {
               isSwingHigh = false;
               break;
            }
         }
      }

      if(!lowFound)
      {
         for(int j = 1; j <= fractalLength; j++)
         {
            if(iLow(_Symbol, _Period, i) > iLow(_Symbol, _Period, i - j) || 
               iLow(_Symbol, _Period, i) > iLow(_Symbol, _Period, i + j))
            {
               isSwingLow = false;
               break;
            }
         }
      }

      if(isSwingHigh && !highFound)
      {
         AddSwingHigh(iHigh(_Symbol, _Period, i), iTime(_Symbol, _Period, i), i);
         highFound = true; 
      }
      
      if(isSwingLow && !lowFound)
      {
         AddSwingLow(iLow(_Symbol, _Period, i), iTime(_Symbol, _Period, i), i);
         lowFound = true;
      }
      
      if(highFound && lowFound) break;
   }
}

//+------------------------------------------------------------------+
//| تابع بررسی شکست سقف یا کف (Breakout)                             |
//+------------------------------------------------------------------+
void CheckForBreakout()
{
   if(ArraySize(swingHighs_Array) < 1 || ArraySize(swingLows_Array) < 1) return;

   double close_1 = iClose(_Symbol, _Period, 1); // کلوز کندل قبل
   SwingPoint lastHigh = swingHighs_Array[0];
   SwingPoint lastLow = swingLows_Array[0];

   //--- بررسی شکست سقف (Breakout High)
   if(close_1 > lastHigh.price)
   {
      bool isCHoCH = (currentTrend == TREND_BEARISH);
      string breakType = isCHoCH ? "CHoCH" : "BoS";
      Print("شکست سقف (", breakType, ") در قیمت ", close_1);
      
      drawBreak(lastHigh, iTime(_Symbol, _Period, 1), close_1, true, isCHoCH);

      //--- گام 1: نقطه مقابل (پیوت/Low متناظر) را در بازه شکست پیدا کن و **فوری ثبت کن**
      // این Low جدید، نقطه 100% فیبوی ما برای لگ صعودی بعدی خواهد بود.
      FindOppositeSwingAndAddNew(lastHigh.bar_index, 1, false); // false = یافتن Low
      
      //--- گام 2: ردیابی برای سقف جدید را فعال کن و Low جدید را به عنوان 100% فیبو ذخیره کن
      pivotLowForTracking = swingLows_Array[0]; // **آخرین Low ثبت شده**
      isTrackingHigh = true; 
      isTrackingLow = false; 
   }
   //--- بررسی شکست کف (Breakout Low)
   else if(close_1 < lastLow.price)
   {
      bool isCHoCH = (currentTrend == TREND_BULLISH);
      string breakType = isCHoCH ? "CHoCH" : "BoS";
      Print("شکست کف (", breakType, ") در قیمت ", close_1);
      
      drawBreak(lastLow, iTime(_Symbol, _Period, 1), close_1, false, isCHoCH);

      //--- گام 1: نقطه مقابل (پیوت/High متناظر) را در بازه شکست پیدا کن و **فوری ثبت کن**
      // این High جدید، نقطه 100% فیبوی ما برای لگ نزولی بعدی خواهد بود.
      FindOppositeSwingAndAddNew(lastLow.bar_index, 1, true); // true = یافتن High
      
      //--- گام 2: ردیابی برای کف جدید را فعال کن و High جدید را به عنوان 100% فیبو ذخیره کن
      pivotHighForTracking = swingHighs_Array[0]; // **آخرین High ثبت شده**
      isTrackingLow = true;
      isTrackingHigh = false; 
   }
}

//+------------------------------------------------------------------+
//| تابع یافتن نقطه مقابل (پیوت) پس از شکست و افزودن آن به آرایه     |
//| این تابع Low/High درگیر در شکست را پیدا کرده و به عنوان Swing Point ثبت می‌کند. |
//+------------------------------------------------------------------+
void FindOppositeSwingAndAddNew(int brokenSwingIndex, int breakBarIndex, bool findHigh)
{
    double extremePrice = findHigh ? 0 : DBL_MAX; 
    datetime extremeTime;
    int extremeIndex = -1;

    // جستجو از کندل شکست (index=1) تا کندل شکسته شده (brokenSwingIndex)
    for (int i = breakBarIndex; i <= brokenSwingIndex; i++)
    {
        if (findHigh) // یافتن بالاترین High
        {
            double currentHigh = iHigh(_Symbol, _Period, i);
            if (currentHigh > extremePrice)
            {
                extremePrice = currentHigh;
                extremeTime = iTime(_Symbol, _Period, i);
                extremeIndex = i;
            }
        }
        else // یافتن پایین‌ترین Low
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
    }
}


//+------------------------------------------------------------------+
//| تابع: بررسی Swing Point جدید با منطق فیبوناچی 35٪ (نقطه 0% متحرک) |
//| تنها در صورت فعال بودن isTrackingHigh/Low اجرا می‌شود.          |
//| شرط تایید: کلوز کندل 1، حداقل 35٪ اصلاح کند.                      |
//+------------------------------------------------------------------+
void CheckForNewSwingPoint()
{
    //--- 1. ردیابی سقف جدید (HH/LH) بعد از شکست صعودی
    if (isTrackingHigh)
    {
        double currentHigh = 0;
        datetime highTime;
        int highIndex = -1;
        
        // پیدا کردن **High متحرک (نقطه 0% فیبو)** در بازه Low Pivot (100%) تا کندل 1
        // بازه جستجو: از کندل 1 تا اندیس Low Pivot (pivotLowForTracking.bar_index)
        for (int i = 1; i <= pivotLowForTracking.bar_index; i++)
        {
            if (iHigh(_Symbol, _Period, i) > currentHigh)
            {
                currentHigh = iHigh(_Symbol, _Period, i);
                highTime = iTime(_Symbol, _Period, i);
                highIndex = i;
            }
        }

        // اگر هنوز موجی تشکیل نشده یا High جدیدی بالاتر از High قبلی ثبت نشده
        if (highIndex == -1 || currentHigh <= pivotLowForTracking.price) return;
        
        // Low Pivot: 100% فیبو. Current High: 0% فیبو
        double range = currentHigh - pivotLowForTracking.price;
        // سطح 35٪ اصلاح (از 0% به سمت 100%)
        double fib35Level = currentHigh - (range * 0.35); 

        double close_1 = iClose(_Symbol, _Period, 1);

        //--- شرط تایید: اگر کلوز کندل 1، پایین‌تر از سطح 35٪ اصلاح باشد
        if (close_1 < fib35Level)
        {
            // High متحرک پیدا شده، سقف جدید ماست.
            Print("سقف جدید (HH/LH) بر اساس اصلاح 35٪ فیبوناچی (کلوز) شناسایی شد: ", currentHigh);
            AddSwingHigh(currentHigh, highTime, highIndex);
            
            // توقف ردیابی و تنظیم سقف جدید (HH/LH) به عنوان High Array[0]
            isTrackingHigh = false;
        }
    }

    //--- 2. ردیابی کف جدید (LL/HL) بعد از شکست نزولی
    if (isTrackingLow)
    {
        double currentLow = DBL_MAX;
        datetime lowTime;
        int lowIndex = -1;
        
        // پیدا کردن **Low متحرک (نقطه 0% فیبو)** در بازه High Pivot (100%) تا کندل 1
        // بازه جستجو: از کندل 1 تا اندیس High Pivot (pivotHighForTracking.bar_index)
        for (int i = 1; i <= pivotHighForTracking.bar_index; i++)
        {
            if (iLow(_Symbol, _Period, i) < currentLow)
            {
                currentLow = iLow(_Symbol, _Period, i);
                lowTime = iTime(_Symbol, _Period, i);
                lowIndex = i;
            }
        }

        // اگر هنوز موجی تشکیل نشده یا Low جدیدی پایین‌تر از Low قبلی ثبت نشده
        if (lowIndex == -1 || currentLow >= pivotHighForTracking.price) return;

        // High Pivot: 100% فیبو. Current Low: 0% فیبو
        double range = pivotHighForTracking.price - currentLow;
        // سطح 35٪ اصلاح از Low به بالا (معادل 65٪ فیبوی استاندارد)
        double fib65Level = currentLow + (range * 0.35); 

        double close_1 = iClose(_Symbol, _Period, 1);

        //--- شرط تایید: اگر کلوز کندل 1، بالاتر از سطح 65٪ (35٪ اصلاح) باشد
        if (close_1 > fib65Level)
        {
            // Low متحرک پیدا شده، کف جدید ماست.
            Print("کف جدید (LL/HL) بر اساس اصلاح 35٪ فیبوناچی (کلوز) شناسایی شد: ", currentLow);
            AddSwingLow(currentLow, lowTime, lowIndex);
            
            // توقف ردیابی و تنظیم کف جدید (LL/HL) به عنوان Low Array[0]
            isTrackingLow = false;
        }
    }
}


//+------------------------------------------------------------------+
//| توابع مدیریت آرایه (AddSwingHigh/Low) - بهینه و تمیز              |
//+------------------------------------------------------------------+
void AddSwingHigh(double price, datetime time, int bar_index) 
{
   if(ArraySize(swingHighs_Array) >= 2) 
   {
      // حذف شیء قدیمی و حذف عنصر آخر آرایه (چون AsSeries است، قدیمی در آخر است)
      ObjectDelete(0, "High_" + TimeToString(swingHighs_Array[1].time)); 
      ObjectDelete(0, "High_" + TimeToString(swingHighs_Array[1].time) + "_Text");
      ArrayRemove(swingHighs_Array, ArraySize(swingHighs_Array) - 1, 1); 
   }
   
   // افزایش سایز و مقداردهی مستقیم به اندیس 0 (جدیدترین)
   int newSize = ArraySize(swingHighs_Array) + 1;
   ArrayResize(swingHighs_Array, newSize); 
   
   swingHighs_Array[0].price = price;
   swingHighs_Array[0].time = time;
   swingHighs_Array[0].bar_index = bar_index;
   
   //--- رسم روی چارت
   drawSwingPoint(swingHighs_Array[0], true);
}

void AddSwingLow(double price, datetime time, int bar_index) 
{
   if(ArraySize(swingLows_Array) >= 2) 
   {
      // حذف شیء قدیمی و حذف عنصر آخر آرایه
      ObjectDelete(0, "Low_" + TimeToString(swingLows_Array[1].time)); 
      ObjectDelete(0, "Low_" + TimeToString(swingLows_Array[1].time) + "_Text");
      ArrayRemove(swingLows_Array, ArraySize(swingLows_Array) - 1, 1); 
   }
   
   // افزایش سایز و مقداردهی مستقیم به اندیس 0 (جدیدترین)
   int newSize = ArraySize(swingLows_Array) + 1;
   ArrayResize(swingLows_Array, newSize); 

   swingLows_Array[0].price = price;
   swingLows_Array[0].time = time;
   swingLows_Array[0].bar_index = bar_index;

   //--- رسم روی چارت
   drawSwingPoint(swingLows_Array[0], false);
}


//+------------------------------------------------------------------+
//| توابع FVG، Trend Label و Draw (بدون تغییر منطقی)                  |
//+------------------------------------------------------------------+
void IdentifyFVG() 
{
   if(iBars(_Symbol, _Period) < 23) return;
   int i = 1; 
   double high1 = iHigh(_Symbol, _Period, i);
   double low1  = iLow(_Symbol, _Period, i);
   double high3 = iHigh(_Symbol, _Period, i + 2);
   double low3  = iLow(_Symbol, _Period, i + 2);
   double avgRange = 0;
   for (int j = i; j < i + 20; j++) avgRange += iHigh(_Symbol, _Period, j) - iLow(_Symbol, _Period, j);
   avgRange /= 20.0;
   bool isStrong1 = (high1 - low1) > avgRange * 0.8; 
   bool isStrong3 = (high3 - low3) > avgRange * 0.8; 
   if (isStrong1 && isStrong3) 
   {
      if (low1 > high3) AddFVG(true, low1, high3, iTime(_Symbol, _Period, i));
      if (high1 < low3) AddFVG(false, low3, high1, iTime(_Symbol, _Period, i));
   }
}

void AddFVG(bool isBullish, double highPrice, double lowPrice, datetime time) 
{
   if(ArraySize(fvgArray) >= 30) 
   {
      int lastIndex = ArraySize(fvgArray) - 1;
      string typeStrOld = fvgArray[lastIndex].isBullish ? "Bullish" : "Bearish";
      string objNameOld = "FVG_" + TimeToString(fvgArray[lastIndex].time) + "_" + typeStrOld;
      ObjectDelete(0, objNameOld);
      ObjectDelete(0, objNameOld + "_Text");
      ArrayRemove(fvgArray, lastIndex, 1); 
   }
   int newSize = ArraySize(fvgArray) + 1;
   ArrayResize(fvgArray, newSize); 
   fvgArray[0].isBullish = isBullish;
   fvgArray[0].highPrice = highPrice;
   fvgArray[0].lowPrice = lowPrice;
   fvgArray[0].time = time;
   fvgArray[0].consumed = false;
   drawFVG(fvgArray[0]);
}

void CheckConsumedFVGs() 
{
   double high1 = iHigh(_Symbol, _Period, 1);
   double low1 = iLow(_Symbol, _Period, 1);
   for(int i = 0; i < ArraySize(fvgArray); i++) 
   {
      if(!fvgArray[i].consumed) 
      {
         bool isConsumed = false;
         if(fvgArray[i].isBullish) 
         {
             if(low1 <= fvgArray[i].highPrice) isConsumed = true;
         } 
         else 
         {
             if(high1 >= fvgArray[i].lowPrice) isConsumed = true;
         }
         if(isConsumed)
         {
            fvgArray[i].consumed = true;
            string typeStr = fvgArray[i].isBullish ? "Bullish" : "Bearish";
            string objName = "FVG_" + TimeToString(fvgArray[i].time) + "_" + typeStr;
            ObjectDelete(0, objName);
            ObjectDelete(0, objName + "_Text");
         }
      }
   }
}

void UpdateTrendLabel() 
{
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
   
   ObjectDelete(0, trendObjectName);
   string trendText;
   color trendColor;
   switch(currentTrend) 
   {
      case TREND_BULLISH:
         trendText = "Bullish Trend (HH/HL)";
         trendColor = clrDeepSkyBlue;
         break;
      case TREND_BEARISH:
         trendText = "Bearish Trend (LL/LH)";
         trendColor = clrOrangeRed;
         break;
      default:
         trendText = "No Trend";
         trendColor = clrGray;
   }
   ObjectCreate(0, trendObjectName, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, trendObjectName, OBJPROP_TEXT, trendText);
   ObjectSetInteger(0, trendObjectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, trendObjectName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, trendObjectName, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, trendObjectName, OBJPROP_COLOR, trendColor);
   ObjectSetInteger(0, trendObjectName, OBJPROP_FONTSIZE, 12);
   ObjectSetString(0, trendObjectName, OBJPROP_FONT, "Arial");
   ChartRedraw(0);
}

//--- توابع ترسیم (Drawings)
void drawSwingPoint(const SwingPoint &sp, bool isHigh) 
{
   string objName = (isHigh ? "High_" : "Low_") + TimeToString(sp.time);
   if(ObjectFind(0, objName) >= 0) ObjectDelete(0, objName); 
   ObjectCreate(0, objName, OBJ_ARROW, 0, sp.time, sp.price);
   ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 77); 
   ObjectSetInteger(0, objName, OBJPROP_COLOR, isHigh ? clrDodgerBlue : clrRed);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, isHigh ? ANCHOR_BOTTOM : ANCHOR_TOP);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false); 
   string text = isHigh ? "H" : "L";
   string textName = objName + "_Text";
   if(ObjectFind(0, textName) >= 0) ObjectDelete(0, textName);
   ObjectCreate(0, textName, OBJ_TEXT, 0, sp.time, sp.price);
   ObjectSetString(0, textName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, textName, OBJPROP_COLOR, isHigh ? clrDodgerBlue : clrRed);
   ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, textName, OBJPROP_ANCHOR, isHigh ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, textName, OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
   ChartRedraw(0);
}

void drawBreak(const SwingPoint &brokenSwing, datetime breakTime, double breakPrice, bool isHighBreak, bool isCHoCH)
{
    string breakType = isCHoCH ? "CHoCH" : "BoS";
    color breakColor = isCHoCH ? clrCrimson : (isHighBreak ? clrSeaGreen : clrOrange);
    string objName = "Break_" + TimeToString(brokenSwing.time);
    ObjectCreate(0, objName, OBJ_TREND, 0, brokenSwing.time, brokenSwing.price, breakTime, brokenSwing.price);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, breakColor);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
    ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
    string textName = objName + "_Text";
    ObjectCreate(0, textName, OBJ_TEXT, 0, breakTime, breakPrice);
    ObjectSetString(0, textName, OBJPROP_TEXT, breakType);
    ObjectSetInteger(0, textName, OBJPROP_COLOR, breakColor);
    ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 11);
    ObjectSetInteger(0, textName, OBJPROP_ANCHOR, isHighBreak ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, textName, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
    ChartRedraw(0);
}

void drawFVG(const FVG &fvg) 
{
   string typeStr = fvg.isBullish ? "Bullish" : "Bearish";
   string objName = "FVG_" + TimeToString(fvg.time) + "_" + typeStr;
   if(ObjectFind(0, objName) >= 0) return; 
   color fvgColor = fvg.isBullish ? C'173,216,230' : C'255,192,203'; 
   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, fvg.time, fvg.highPrice, iTime(_Symbol, _Period, 0) + PeriodSeconds()*10, fvg.lowPrice);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, fvgColor);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true); 
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   string textName = objName + "_Text";
   ObjectCreate(0, textName, OBJ_TEXT, 0, fvg.time, fvg.isBullish ? fvg.highPrice : fvg.lowPrice);
   ObjectSetString(0, textName, OBJPROP_TEXT, "FVG");
   ObjectSetInteger(0, textName, OBJPROP_COLOR, clrDimGray);
   ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, textName, OBJPROP_ANCHOR, fvg.isBullish ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
   ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
   ChartRedraw(0);
}
//+------------------------------------------------------------------+
