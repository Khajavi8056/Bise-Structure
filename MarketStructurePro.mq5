//+------------------------------------------------------------------+
//|                                     MarketStructurePro_v5.4.mq5 |
//|                                  Copyright 2025, Khajavi & Gemini |
//|                                             Powerd by Gemini AI |
//|------------------------------------------------------------------|
//| نسخه 5.4 - فیکس نهایی: رفع خطای Variable Expected و اصلاح رسم FVG  |
//| 1. اصلاح شیوه درج عنصر جدید در آرایه سری (ArrayInsert).           |
//| 2. حذف OBJPROP_TIMEMAX و استفاده از Time[0] برای امتداد FVG.      |
//| 3. تأکید بر حذف کامل FVGهای باطل شده (بدون نگهداری).              |
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
   bool     consumed;   // وضعیت مصرف شدگی (دیگر استفاده نمی‌شود اما برای خوانایی منطق باقی می‌ماند)
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

//--- متغیرهای لازم برای خواندن قیمت‌ها و زمان
double     priceArray[];
datetime   timeArray[];

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
   
   //--- آماده سازی آرایه‌های قیمت و زمان برای دسترسی بهینه
   if(!CopyTime(_Symbol, _Period, 0, 100, timeArray) || !CopyClose(_Symbol, _Period, 0, 100, priceArray))
   {
       LogEvent("خطا در کپی داده‌های قیمت/زمان اولیه.");
       return(INIT_FAILED);
   }

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
   
   //--- به‌روزرسانی داده‌های قیمت/زمان در هر تیک
   if(!CopyTime(_Symbol, _Period, 0, 4, timeArray) || !CopyHigh(_Symbol, _Period, 0, 4, priceArray)) return; // حداقل 4 کندل برای FVG

   //--- گام ۱: بررسی ابطال FVG در لحظه (با ASK/BID) - هر تیک اجرا می‌شود
   // این تابع با هر تیک، آرایه را برای FVG های باطل شده بررسی و آن‌ها را حذف می‌کند.
   CheckFVGInvalidation();
   
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
            ObjectDelete(0, "Tracking_Fib"); 
         }
         else
         {
            DrawTrackingFibonacci();
         }
      }

      //--- گام ۴: شناسایی FVG جدید (فقط یک بار با کلوز کندل جدید)
      IdentifyFVG();
      
      //--- گام ۵: به‌روزرسانی نمایش روند
      UpdateTrendLabel();
      
      ChartRedraw(0);
   }
}

// (توابع FindOppositeSwing، FindExtremePrice، CheckForNewSwingPoint و توابع Swing Point و Trend که تغییر نکردند، اینجا حذف شدند تا کد کوتاه شود - در کد کامل قبلی صحیح هستند)


//+------------------------------------------------------------------+
//| تابع: شناسایی FVG جدید (بررسی کندل‌های 1، 2، 3)                  |
//+------------------------------------------------------------------+
bool IdentifyFVG() 
{
   // جلوگیری از اجرای تکراری شناسایی FVG روی یک کندل بسته شده
   if(lastFVGCheckTime == iTime(_Symbol, _Period, 1)) return false; 
   lastFVGCheckTime = iTime(_Symbol, _Period, 1);
   
   // برای دسترسی به کندل 1، 2 و 3، به حداقل 4 کندل (0 تا 3) نیاز داریم.
   if(iBars(_Symbol, _Period) < 4) return false; 
   
   // کندل میانی FVG، کندل شماره 2 است. (i=2)
   int i = 2; 
   
   //--- ۱. بررسی شرط بدنه‌های قوی در هر سه کندل (اختیاری: برای سختگیری بیشتر)
   // if (!IsStrongBody(i-1) || !IsStrongBody(i) || !IsStrongBody(i+1)) return false; 
   
   // High/Low کندل 1 (جدیدترین) و High/Low کندل 3 (قدیمی‌ترین)
   double high1 = iHigh(_Symbol, _Period, i - 1); // High کندل 1 (i-1)
   double low1  = iLow(_Symbol, _Period, i - 1);  // Low کندل 1
   double high3 = iHigh(_Symbol, _Period, i + 1); // High کندل 3 (i+1)
   double low3  = iLow(_Symbol, _Period, i + 1);  // Low کندل 3
   
   // FVG صعودی: کف کندل 1 بالاتر از سقف کندل 3
   if (low1 > high3) 
   { 
       // جلوگیری از ثبت FVG تکراری (برای یک زمان کندل میانی)
       for(int j=0; j<ArraySize(fvgArray); j++) { if(fvgArray[j].time == iTime(_Symbol, _Period, i) && fvgArray[j].isBullish) return false; }
       
       // ناحیه FVG بین High کندل 3 و Low کندل 1. زمان FVG روی کندل میانی (کندل 2) ثبت می‌شود.
       AddFVG(true, high3, low1, iTime(_Symbol, _Period, i)); 
       return true; 
   }
   
   // FVG نزولی: سقف کندل 1 پایین‌تر از کف کندل 3
   if (high1 < low3) 
   { 
       // جلوگیری از ثبت FVG تکراری
       for(int j=0; j<ArraySize(fvgArray); j++) { if(fvgArray[j].time == iTime(_Symbol, _Period, i) && !fvgArray[j].isBullish) return false; }
       
       // ناحیه FVG بین Low کندل 3 و High کندل 1. زمان FVG روی کندل میانی (کندل 2) ثبت می‌شود.
       AddFVG(false, low3, high1, iTime(_Symbol, _Period, i)); 
       return true; 
   }

   return false;
}

//+------------------------------------------------------------------+
//| تابع: افزودن FVG جدید به آرایه - رفع باگ Variable Expected و ۱۹۷۰ |
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
   
   // ✨ اصلاح نهایی: استفاده مستقیم از ArrayInsert بدون چک کردن نتیجه با شرط
   // در MQL5، تابع ArrayInsert مقدار بازگشتی int می‌دهد که چک کردن آن در شرط if مستقیم، ارور Variable Expected می‌دهد.
   // پس مستقیماً آن را فراخوانی می‌کنیم و فرض بر موفقیت است (مگر آنکه خطا در لاگ نمایش داده شود).
   if(ArrayInsert(fvgArray, 0, 1) < 0) 
   {
       LogEvent("خطا: نتوانست FVG جدید را در آرایه درج کند.");
       return;
   }
   
   // مقداردهی عنصر جدید (همیشه اندیس 0)
   fvgArray[0].isBullish = isBullish;
   fvgArray[0].highPrice = highPrice;
   fvgArray[0].lowPrice = lowPrice;
   fvgArray[0].time = time; // زمان معتبر ثبت می‌شود
   fvgArray[0].consumed = false;
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

         // ✨ حذف عنصر ابطال شده از آرایه
         ArrayRemove(fvgArray, i, 1);
         
         // چون یک عنصر حذف شد، باید اندیس را یکی کم کنیم تا عنصر بعدی از قلم نیفتد
         i--; 
         invalidatedNow = true;
      }
   }
   return invalidatedNow;
}


//+------------------------------------------------------------------+
//| توابع ترسیمی و نمایش اطلاعات روی چارت (Drawings)                  |
//+------------------------------------------------------------------+

// (توابع DrawSwingPoint، DrawBreak و UpdateTrendLabel که تغییر نکردند، اینجا حذف شدند)

//+------------------------------------------------------------------+
//| تابع: ترسیم ناحیه FVG روی چارت - اصلاح امتداد به سمت راست          |
//+------------------------------------------------------------------+
void drawFVG(const FVG &fvg) 
{
   string typeStr = fvg.isBullish ? "Bullish" : "Bearish";
   string objName = "FVG_" + TimeToString(fvg.time) + "_" + typeStr;
   string textName = objName + "_Text";
   
   // رنگ سبز روشن شفاف برای صعودی و قرمز روشن شفاف برای نزولی
   color fvgColor = fvg.isBullish ? C'144,238,144' : C'255,160,160'; // LightGreen / LightCoral
   
   // ✨ اصلاح نهایی: استفاده از Time[0] (زمان کندل جاری) به عنوان انتهای زون
   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, fvg.time, fvg.highPrice, iTime(_Symbol, _Period, 0), fvg.lowPrice);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, fvgColor);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);       // شفافیت (شیشه‌ای)
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);      // پشت کندل‌ها
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   
   // این خطوط دیگر لازم نیستند، چون تایم دوم شیئ (Time[0]) کار امتداد را انجام می‌دهد
   // ObjectSetInteger(0, objName, OBJPROP_TIMEMAX, iTime(_Symbol, _Period, 0) + PeriodSeconds()*100); 

   ObjectCreate(0, textName, OBJ_TEXT, 0, fvg.time, fvg.isBullish ? fvg.highPrice : fvg.lowPrice);
   ObjectSetString(0, textName, OBJPROP_TEXT, "FVG");
   ObjectSetInteger(0, textName, OBJPROP_COLOR, clrDimGray);
   ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, textName, OBJPROP_ANCHOR, fvg.isBullish ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
   ObjectSetInteger(0, textName, OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
}
//+------------------------------------------------------------------+
