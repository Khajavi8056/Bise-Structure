//+------------------------------------------------------------------+
//|                                MarketStructureLibraryTestEA.mq5  |
//|                                  Copyright 2025, Khajavi |
//|                                         Test Memento Structure   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi "
#property link      "https://www.HIPOALGORITM.com"
#property version   "1.02" // به‌روزرسانی برای اتصال Market Profile
#property description "تست کتابخانه MarketStructureLibrary با قابلیت MTF و اتصال Market Profile"

#include <MarketStructureLibrary.mqh> // ایمپورت کتابخانه ساختار بازار

//+------------------------------------------------------------------+
//| ورودی‌های عمومی EA و ساختار بازار                                |
//+------------------------------------------------------------------+
input bool Input_EnableLogging = true;    // [فعال/غیرفعال کردن] سیستم لاگ
input int  Input_FibUpdateLevel = 35;     // سطح اصلاح فیبو برای تایید
input int  Input_FractalLength = 10;      // طول فرکتال

input ENUM_TIMEFRAMES MTF_Timeframe = PERIOD_H4; // تایم فریم دوم برای تحلیل MTF
input bool ShowMTFDrawing = true;                 // نمایش ترسیمات تایم فریم دوم (MTF) روی چارت فعلی

//+------------------------------------------------------------------+
//| ورودی‌های Market Profile (MP) - برای تنظیم اندیکاتور            |
//+------------------------------------------------------------------+
input group "Market Profile Settings"
input int  MP_SessionType = 1;          // 1=Daily, 2=Weekly, 0=Intraday
input int  MP_SessionsToCount = 5;      // تعداد سشن‌های گذشته برای ذخیره و نمایش
input int  MP_ValueAreaPercentage = 70; // درصد ناحیه ارزش (VAH/VAL)
input double MP_PointMultiplier = 0.0;    // ضریب اندازه بلوک TPO (0.0 = اتوماتیک)
input bool MP_ShowLines = true;         // نمایش خطوط POC/VAH/VAL توسط اندیکاتور

//+------------------------------------------------------------------+
//| ساختار داده‌ای برای ذخیره اطلاعات کلیدی Market Profile هر سشن    |
//+------------------------------------------------------------------+
struct MarketProfileSessionData
{
   datetime SessionStart;    // زمان شروع سشن
   double   POC;             // Point of Control
   double   VAH;             // Value Area High
   double   VAL;             // Value Area Low
   // اینجا می‌توان آرایه‌هایی برای ذخیره TPO Count هر سطح (عمق رنگ) اضافه کرد
   // اما نیاز به اصلاح MarketProfile.mq5 برای خروجی دادن این بافرها است.
};

//+------------------------------------------------------------------+
//| آبجکت‌های سراسری (Instances of Classes & Indicators)             |
//+------------------------------------------------------------------+
MarketStructure           *Chart_Structure = NULL; // ساختار برای تایم فریم فعلی چارت
FVGManager                *Chart_FVG = NULL;       // FVG برای تایم فریم فعلی چارت

MarketStructure           *MTF_Structure = NULL;   // ساختار برای تایم فریم MTF (مثلاً H4)
FVGManager                *MTF_FVG = NULL;         // FVG برای تایم فریم MTF (مثلاً H4)

int                       MarketProfile_Handle = INVALID_HANDLE; // هندل اندیکاتور
MarketProfileSessionData  MP_DataArray[];                        // آرایه برای ذخیره داده‌های N سشن گذشته

//+------------------------------------------------------------------+
//| تابع کمکی: بررسی تشکیل کندل جدید (برای اجرای منطق کلوز کندل)      |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime lastBarTime = 0;
   datetime currentTime = iTime(_Symbol, _Period, 0);
   
   if (currentTime > lastBarTime)
   {
      lastBarTime = currentTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| تابع: استخراج و ذخیره داده‌های Market Profile از اندیکاتور        |
//+------------------------------------------------------------------+
bool FetchMarketProfileData()
{
    if (MarketProfile_Handle == INVALID_HANDLE) return false;

    // اندازه‌گیری آرایه داخلی بر اساس تعداد سشن‌های درخواستی
    int sessions_to_fetch = MathMin(MP_SessionsToCount, 100); // محدودیت به ۱۰۰ سشن
    ArrayResize(MP_DataArray, sessions_to_fetch);
    
    // آرایه‌های موقت برای دریافت داده‌های بافر (با فرض 0=POC, 1=VAH, 2=VAL)
    // اندیکاتور MarketProfile.mq5 باید این بافرها را خروجی دهد.
    double poc_data[100], vah_data[100], val_data[100];
    
    // فرض می‌کنیم که اندیکاتور داده‌ها را به صورت سری (از جدیدترین به قدیمی‌ترین) ذخیره کرده است.
    int copied_count = CopyBuffer(MarketProfile_Handle, 0, 0, sessions_to_fetch, poc_data);
    
    if (copied_count < 1)
    {
        // Print("خطا: نتوانست داده‌های POC را کپی کند.");
        return false;
    }
    
    // کپی بافرهای VAH و VAL
    CopyBuffer(MarketProfile_Handle, 1, 0, sessions_to_fetch, vah_data);
    CopyBuffer(MarketProfile_Handle, 2, 0, sessions_to_fetch, val_data);

    // --- ذخیره داده‌ها در آرایه داخلی EA (از جدیدترین سشن تا قدیمی‌ترین) ---
    for (int i = 0; i < copied_count; i++)
    {
        // محاسبه تقریبی زمان شروع سشن (SessionTime باید از اندیکاتور گرفته شود، اینجا از POC استفاده می‌کنیم)
        // برای دقت بیشتر، اندیکاتور باید زمان شروع سشن را در یک بافر مجزا (مثلاً بافر ۳) خروجی دهد.
        // ما اینجا زمان کندل فعلی را به عنوان زمان مرجع می‌گیریم.
        MP_DataArray[i].SessionStart = iTime(_Symbol, _Period, i); // زمان تقریبی
        MP_DataArray[i].POC = poc_data[i];
        MP_DataArray[i].VAH = vah_data[i];
        MP_DataArray[i].VAL = val_data[i];
        
        // نکته: برای دسترسی به داده‌های TPO/عمق رنگ، باید اندیکاتور MarketProfile.mq5 را اصلاح کرد 
        // تا بافرهای مورد نظر (مثلاً TPO Count و TPO Price) را خروجی دهد و در اینجا با CopyBuffer خوانده شود.
        // تا زمانی که این اصلاح انجام نشده، EA به صورت کامل فقط به POC/VAH/VAL دسترسی دارد.
    }
    
    if(Input_EnableLogging) Print("Market Profile Data: ", copied_count, " sessions fetched. Current POC: ", DoubleToString(MP_DataArray[0].POC, _Digits));
    
    return true;
}


//+------------------------------------------------------------------+
//| تابع مقداردهی اولیه اکسپرت (OnInit)                               |
//+------------------------------------------------------------------+
int OnInit()
{
   // ۱. ساخت آبجکت‌های ساختار و FVG
   Chart_Structure = new MarketStructure(_Symbol, _Period, ChartID(), Input_EnableLogging, true, Input_FibUpdateLevel, Input_FractalLength);
   Chart_FVG = new FVGManager(_Symbol, _Period, ChartID(), Input_EnableLogging, true);
   MTF_Structure = new MarketStructure(_Symbol, MTF_Timeframe, ChartID(), Input_EnableLogging, ShowMTFDrawing, Input_FibUpdateLevel, Input_FractalLength);
   MTF_FVG = new FVGManager(_Symbol, MTF_Timeframe, ChartID(), Input_EnableLogging, ShowMTFDrawing);
   
   // --- ۲. فراخوانی و تنظیم Market Profile (وصل کردن مغز) ---
   // (توجه: MarketProfile.mq5 باید در پوشه MQL5/Indicators/ باشد)
   MarketProfile_Handle = iCustom(
       _Symbol,                      // نماد
       _Period,                      // تایم فریم
       "MarketProfile.mq5",          // نام فایل اندیکاتور
       // پارامترها باید دقیقا به ترتیبی که در فایل اندیکاتور تعریف شده‌اند، بیایند.
       MP_SessionType, 
       MP_SessionsToCount, 
       MP_PointMultiplier, 
       MP_ValueAreaPercentage, 
       // ما اینجا فقط پارامترهای اصلی را قرار می‌دهیم. اگر اندیکاتور پارامترهای بیشتری داشته باشد، باید اینجا اضافه شوند.
       0,                            // 5. Time Shift Minutes (فرض بر 0)
       0,                            // 6. Saturday Sunday Mode (فرض بر 0 = Normal)
       true,                         // 7. Show Profile 
       MP_ShowLines,                 // 8. Show Lines
       true,                         // 9. Show Values
       // ... (بقیه پارامترهای اندیکاتور)
       NULL // اتمام لیست پارامترها
   );

   if (MarketProfile_Handle == INVALID_HANDLE)
   {
       Print("خطا: نتوانست اندیکاتور MarketProfile.mq5 را فراخوانی کند. Error: ", GetLastError());
       return(INIT_FAILED);
   }
   
   Print("اندیکاتور Market Profile با موفقیت فراخوانی شد. Handle: ", MarketProfile_Handle);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| تابع خاتمه اکسپرت (OnDeinit)                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // حذف ایمن آبجکت‌ها و هندل‌ها
   if (Chart_Structure != NULL) delete Chart_Structure;
   if (Chart_FVG != NULL) delete Chart_FVG;
   if (MTF_Structure != NULL) delete MTF_Structure;
   if (MTF_FVG != NULL) delete MTF_FVG;
   
   if (MarketProfile_Handle != INVALID_HANDLE) IndicatorRelease(MarketProfile_Handle);
}

//+------------------------------------------------------------------+
//| تابع اصلی که با هر تیک قیمت اجرا می‌شود (OnTick)                 |
//+------------------------------------------------------------------+
void OnTick()
{
   bool chartRedrawNeeded = false;
   
   //--- ۱. اجرای منطق FVG در هر تیک (برای ابطال لحظه‌ای)
   if (Chart_FVG != NULL && Chart_FVG.ProcessNewTick()) chartRedrawNeeded = true;
   if (MTF_FVG != NULL && MTF_FVG.ProcessNewTick()) chartRedrawNeeded = true;
   
   //--- ۲. اجرای منطق در کلوز کندل جدید
   if (IsNewBar())
   {
      // پردازش ساختار و FVG برای تایم فریم چارت فعلی
      if (Chart_Structure != NULL && Chart_Structure.ProcessNewBar()) chartRedrawNeeded = true;
      if (Chart_FVG != NULL && Chart_FVG.ProcessNewBar()) chartRedrawNeeded = true;
      
      // پردازش Market Profile و ذخیره داده‌ها در آرایه داخلی MP_DataArray
      FetchMarketProfileData(); 

      // پردازش ساختار و FVG برای تایم فریم MTF (اگر کندل MTF بسته شده باشد)
      if (MTF_Structure != NULL && iTime(_Symbol, MTF_Timeframe, 1) > MTF_Structure.GetLastSwingLow().time && iTime(_Symbol, MTF_Timeframe, 1) > MTF_Structure.GetLastSwingHigh().time)
      {
         if (MTF_Structure.ProcessNewBar()) chartRedrawNeeded = true;
         if (MTF_FVG.ProcessNewBar()) chartRedrawNeeded = true;
      }
      
      // --- ۳. مثال استفاده از داده‌های Market Profile ---
      if (ArraySize(MP_DataArray) > 0)
      {
          // استفاده از POC سشن گذشته (MP_DataArray[1]) به عنوان سطح هدف یا حمایت/مقاومت
          double LastPOC = MP_DataArray[1].POC;
          double CurrentVAH = MP_DataArray[0].VAH;
          
          if(CurrentVAH > 0 && iClose(_Symbol, _Period, 0) > CurrentVAH)
          {
              // این یک شکست (Breakout) از ناحیه ارزش فعلی است
              // LogEvent("قیمت از VAH فعلی شکست، آماده پوزیشن Buy باش!", Input_EnableLogging, "[TRADE]");
          }
      }
   }
   
   if (chartRedrawNeeded)
   {
      ChartRedraw(ChartID());
   }
}
//+------------------------------------------------------------------+
