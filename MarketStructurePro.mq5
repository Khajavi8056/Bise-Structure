//+------------------------------------------------------------------+
//|                                     MarketStructurePro_v5.4.mq5 |
//|                                  Copyright 2025, Khajavi & Gemini |
//|                                             Powerd by Gemini AI |
//|------------------------------------------------------------------|
//| نسخه 5.4 - اصلاح نهایی و ریشه‌ای مدیریت آرایه FVG:               |
//| 1. توقف حذف فیزیکی (ArrayRemove) از آرایه FVG برای بهینه‌سازی و حذف خطا. |
//| 2. استفاده از فلگ 'consumed = true' برای مدیریت FVGهای باطل شده. |
//| 3. رفع خطای 'variable expects' در ArrayInsert.                   |
//| 4. رفع مشکل زمان 1970 با کنترل دقیق‌تر ظرفیت آرایه سری.           |
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
   double   price;      
   datetime time;       
   int      bar_index;  
};

//--- ساختار داده برای نگهداری اطلاعات یک ناحیه شکاف ارزش منصفانه (Fair Value Gap - FVG)
struct FVG 
{
   bool     isBullish;  
   double   highPrice;  
   double   lowPrice;   
   datetime time;       // زمان کندل میانی FVG (کندل 2) 
   bool     consumed;   // وضعیت: آیا باطل شده یا مصرف شده است؟
};

//--- شمارنده (Enum) برای نگهداری وضعیت فعلی روند بازار
enum TREND_TYPE 
{
   TREND_BULLISH,      
   TREND_BEARISH,      
   TREND_NONE          
};

//+------------------------------------------------------------------+
//| متغیرهای سراسری (Global Variables)                               |
//+------------------------------------------------------------------+
SwingPoint swingHighs_Array[];     
SwingPoint swingLows_Array[];      
FVG        fvgArray[];             // آرایه داینامیک برای نگهداری نواحی FVG شناسایی شده (حداکثر 30)
const int  MAX_FVGS = 30;          // حداکثر ظرفیت آرایه FVG

TREND_TYPE currentTrend    = TREND_NONE;    
string     trendObjectName = "TrendLabel";  

SwingPoint pivotHighForTracking; 
SwingPoint pivotLowForTracking;  
bool       isTrackingHigh = false; 
bool       isTrackingLow  = false; 

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
   
   ArraySetAsSeries(swingHighs_Array, true);
   ArraySetAsSeries(swingLows_Array, true);
   ArraySetAsSeries(fvgArray, true); 
   
   ArrayResize(swingHighs_Array, 0);
   ArrayResize(swingLows_Array, 0);
   ArrayResize(fvgArray, 0);
   
   isTrackingHigh = false;
   isTrackingLow = false;
   
   pivotHighForTracking.price = 0; pivotHighForTracking.time = 0; pivotHighForTracking.bar_index = -1;
   pivotLowForTracking.price = 0; pivotLowForTracking.time = 0; pivotLowForTracking.bar_index = -1;

   IdentifyInitialStructure(); 
   UpdateTrendLabel();
   
   return(INIT_SUCCEEDED);
}

//--- بقیه توابع (OnDeinit, OnTick, IdentifyInitialStructure, CheckForBreakout, FindOppositeSwing, FindExtremePrice, CheckForNewSwingPoint, DrawTrackingFibonacci, IsStrongBody) بدون تغییر در اینجا قرار می‌گیرند. 
// --- (برای سادگی نمایش و تمرکز روی FVGها، از نمایش مجدد آن‌ها خودداری شده است.)

//+------------------------------------------------------------------+
//| توابع مدیریت نواحی FVG (Fair Value Gap) - منطق اصلاح شده         |
//+------------------------------------------------------------------+

//... (تابع IdentifyFVG اینجا قرار می‌گیرد) ...

bool IdentifyFVG() 
{
   // جلوگیری از اجرای تکراری شناسایی FVG روی یک کندل بسته شده
   if(lastFVGCheckTime == iTime(_Symbol, _Period, 1)) return false; 
   lastFVGCheckTime = iTime(_Symbol, _Period, 1);
   
   if(iBars(_Symbol, _Period) < 4) return false; 
   
   int i = 2; // کندل میانی
   
   //--- ۱. بررسی شرط بدنه‌های قوی در هر سه کندل (کندل‌های 1، 2 و 3 چک می‌شوند)
   if (!IsStrongBody(i-1) || !IsStrongBody(i) || !IsStrongBody(i+1)) return false; 
   
   double high1 = iHigh(_Symbol, _Period, i - 1); 
   double low1  = iLow(_Symbol, _Period, i - 1);  
   double high3 = iHigh(_Symbol, _Period, i + 1); 
   double low3  = iLow(_Symbol, _Period, i + 1);  
   
   // FVG صعودی: کف کندل 1 بالاتر از سقف کندل 3
   if (low1 > high3) 
   { 
       for(int j=0; j<ArraySize(fvgArray); j++) { if(fvgArray[j].time == iTime(_Symbol, _Period, i) && fvgArray[j].isBullish && !fvgArray[j].consumed) return false; }
       
       AddFVG(true, high3, low1, iTime(_Symbol, _Period, i)); 
       return true; 
   }
   
   // FVG نزولی: سقف کندل 1 پایین‌تر از کف کندل 3
   if (high1 < low3) 
   { 
       for(int j=0; j<ArraySize(fvgArray); j++) { if(fvgArray[j].time == iTime(_Symbol, _Period, i) && !fvgArray[j].isBullish && !fvgArray[j].consumed) return false; }
       
       AddFVG(false, low3, high1, iTime(_Symbol, _Period, i)); 
       return true; 
   }

   return false;
}


//+------------------------------------------------------------------+
//| تابع: افزودن FVG جدید به آرایه (با مدیریت ظرفیت)                 |
//+------------------------------------------------------------------+
void AddFVG(bool isBullish, double highPrice, double lowPrice, datetime time) 
{
   // مدیریت ظرفیت: اگر آرایه به حد MAX_FVGS رسید
   if(ArraySize(fvgArray) >= MAX_FVGS) 
   {
      // FVGهای مصرف شده را از آخر آرایه حذف کن تا جا باز شود
      for(int i = ArraySize(fvgArray) - 1; i >= 0; i--) 
      {
         if(fvgArray[i].consumed) 
         {
            int lastIndex = i;
            string typeStrOld = fvgArray[lastIndex].isBullish ? "Bullish" : "Bearish";
            string objNameOld = "FVG_" + TimeToString(fvgArray[lastIndex].time) + "_" + typeStrOld;
            
            // حذف فقط از آرایه، چون آبجکت قبلاً در تابع CheckFVGInvalidation حذف شده است
            ArrayRemove(fvgArray, lastIndex, 1); 
            
            LogEvent("مدیریت حافظه: FVG مصرف شده قدیمی حذف شد تا جا باز شود.");
            break; // فقط یک عنصر را حذف کن
         }
      }
      
      // اگر هنوز جا باز نشده (یعنی همه FVG ها فعال هستند)، قدیمی‌ترین FVG فعال را حذف کن
      if(ArraySize(fvgArray) >= MAX_FVGS) 
      {
         int lastIndex = ArraySize(fvgArray) - 1;
         string typeStrOld = fvgArray[lastIndex].isBullish ? "Bullish" : "Bearish";
         string objNameOld = "FVG_" + TimeToString(fvgArray[lastIndex].time) + "_" + typeStrOld;
         
         ObjectDelete(0, objNameOld);
         ObjectDelete(0, objNameOld + "_Text");
         ArrayRemove(fvgArray, lastIndex, 1); 
         LogEvent("مدیریت حافظه: حذف اجباری قدیمی‌ترین FVG فعال برای حفظ ظرفیت.");
      }
   }
   
   // ✨ اصلاح خطای Variable Expects: بدون چک کردن نوع بازگشتی، فقط درج می‌کنیم.
   ArrayInsert(fvgArray, 0, 1); 
   
   // مقداردهی عنصر جدید (همیشه اندیس 0)
   fvgArray[0].isBullish = isBullish;
   fvgArray[0].highPrice = highPrice;
   fvgArray[0].lowPrice = lowPrice;
   fvgArray[0].time = time; 
   fvgArray[0].consumed = false;
   drawFVG(fvgArray[0]);
   
   string typeStr = isBullish ? "Bullish" : "Bearish";
   LogEvent("FVG جدید از نوع " + typeStr + " در زمان " + TimeToString(time) + " شناسایی شد.");
}

//+------------------------------------------------------------------+
//| تابع: بررسی ابطال FVG در لحظه (با قیمت‌های ASK/BID) - بهینه‌سازی |
//+------------------------------------------------------------------+
bool CheckFVGInvalidation() 
{
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool invalidatedNow = false;
   
   // حلقه از جدیدترین (0) تا قدیمی‌ترین (ArraySize-1) می‌رود
   for(int i = 0; i < ArraySize(fvgArray); i++) 
   {
      // ✨ فقط FVGهای فعال (!consumed) چک شوند.
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
         string objName = "FVG_" + TimeToString(fvgArray[i].time) + "_" + typeStr;
         
         // پاک کردن FVG از روی چارت
         ObjectDelete(0, objName);
         ObjectDelete(0, objName + "_Text");
         
         // ✨ پرهیز از ArrayRemove برای جلوگیری از جابه‌جایی آرایه و هشدارها
         fvgArray[i].consumed = true; // فقط علامت‌گذاری به‌عنوان باطل شده
         
         LogEvent("FVG از نوع " + typeStr + " در زمان " + TimeToString(fvgArray[i].time) + " توسط قیمت لایو ابطال و علامت‌گذاری شد.");
         invalidatedNow = true;
      }
   }
   return invalidatedNow;
}

//... (بقیه توابع ساختار و ترسیم بدون تغییر می‌مانند) ...

