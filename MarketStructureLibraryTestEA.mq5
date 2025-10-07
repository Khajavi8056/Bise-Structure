//+------------------------------------------------------------------+
//|                                        MementoTestEA.mq5         |
//|                                  Copyright 2025, Khajavi |
//|                                         Test Memento Structure   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi "
#property link      "https://www.HIPOALGORITM.com"
#property version   "1.02" // آپدیت شده برای اتصال Market Profile
#property description "تست کتابخانه MarketStructureLibrary با قابلیت MTF و اتصال Market Profile"

#include <MarketStructureLibrary.mqh> // ایمپورت کتابخانه کلاس‌بندی شده

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
   double   POC;             // Point of Control - بافر 0
   double   VAH;             // Value Area High - بافر 1
   double   VAL;             // Value Area Low - بافر 2
   // برای داده‌های عمق رنگ (TPO Count) باید بافرهای دیگری در MarketProfile.mq5 تعریف و اینجا خوانده شوند.
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
void FetchMarketProfileData()
{
    if (MarketProfile_Handle == INVALID_HANDLE) return;

    // اندازه آرایه را بر اساس تعداد سشن‌های درخواستی تنظیم می‌کنیم.
    int sessions_to_fetch = MathMin(MP_SessionsToCount, 100); 
    ArrayResize(MP_DataArray, sessions_to_fetch);
    
    // آرایه‌های موقت برای دریافت داده‌های بافر (با فرض 0=POC, 1=VAH, 2=VAL)
    // آرایه‌ها باید حداقل به اندازه sessions_to_fetch باشند.
    double poc_data[100], vah_data[100], val_data[100];
    
    int copied_count = CopyBuffer(MarketProfile_Handle, 0, 0, sessions_to_fetch, poc_data);
    
    if (copied_count < 1) return; // اگر داده کافی نبود، برمی‌گردیم.
    
    // کپی داده‌های VAH و VAL
    CopyBuffer(MarketProfile_Handle, 1, 0, sessions_to_fetch, vah_data);
    CopyBuffer(MarketProfile_Handle, 2, 0, sessions_to_fetch, val_data);

    // --- ذخیره داده‌ها در آرایه داخلی EA ---
    for (int i = 0; i < copied_count; i++)
    {
        // زمان شروع سشن در MarketProfile.mq5 در یک بافر مجزا خروجی داده نمی‌شود، 
        // بنابراین از زمان بار فعلی/قبلی به عنوان یک مرجع تقریبی استفاده می‌کنیم.
        MP_DataArray[i].SessionStart = iTime(_Symbol, _Period, i); 
        MP_DataArray[i].POC = poc_data[i];
        MP_DataArray[i].VAH = vah_data[i];
        MP_DataArray[i].VAL = val_data[i];
    }
    
    // --- چاپ کردن داده‌های سشن جاری (اولین اندیس) ---
    if(Input_EnableLogging && copied_count > 0) 
    {
        Print("--- MP Data Fetch Successful ---");
        Print("Current Session MP Data | POC: ", DoubleToString(MP_DataArray[0].POC, _Digits),
              " | VAH: ", DoubleToString(MP_DataArray[0].VAH, _Digits),
              " | VAL: ", DoubleToString(MP_DataArray[0].VAL, _Digits));
        
        // چاپ سشن قبلی برای استفاده‌های معاملاتی
        if (copied_count > 1)
        {
             Print("Previous Session MP Data | POC: ", DoubleToString(MP_DataArray[1].POC, _Digits),
                  " | VAH: ", DoubleToString(MP_DataArray[1].VAH, _Digits),
                  " | VAL: ", DoubleToString(MP_DataArray[1].VAL, _Digits));
        }
    }
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
   // توجه: ترتیب پارامترها باید دقیقا با MarketProfile.mq5 مطابقت داشته باشد. 
   // ما فقط پارامترهای کلیدی که ورودی گرفتیم را وارد می‌کنیم و برای بقیه بر مقادیر پیش‌فرض اندیکاتور تکیه می‌کنیم.
   MarketProfile_Handle = iCustom(
       _Symbol,                      // نماد
       _Period,                      // تایم فریم
       "MarketProfile.mq5",          // نام فایل اندیکاتور
       MP_SessionType, 
       MP_SessionsToCount, 
       MP_PointMultiplier, 
       MP_ValueAreaPercentage, 
       // در اینجا باید بقیه پارامترهای اندیکاتور (حدود 30 مورد دیگر) به ترتیب آورده شوند.
       // اگر خطای پارامتر در زمان کامپایل رخ داد، باید لیست کامل پارامترها از MarketProfile.mq5 اینجا آورده شود.
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
      
      // --- ۳. به‌روزرسانی داده‌های Market Profile ---
      // این مغز جدید باید در هر کلوز کندل آپدیت شود.
      FetchMarketProfileData(); 

      // پردازش ساختار و FVG برای تایم فریم MTF (اگر کندل MTF بسته شده باشد)
      // توجه: این شرط باید مطمئن شود که کندل MTF واقعا بسته شده است.
      if (MTF_Structure != NULL && iTime(_Symbol, MTF_Timeframe, 1) > MTF_Structure.GetLastSwingLow().time && iTime(_Symbol, MTF_Timeframe, 1) > MTF_Structure.GetLastSwingHigh().time)
      {
         if (MTF_Structure.ProcessNewBar()) chartRedrawNeeded = true;
         if (MTF_FVG.ProcessNewBar()) chartRedrawNeeded = true;
      }
      
      // --- ۴. مثال استفاده از داده‌های Market Profile ---
      // داده‌های Market Profile سشن جاری در MP_DataArray[0] و سشن‌های قبلی در اندیس‌های بعدی ذخیره شده‌اند.
      if (ArraySize(MP_DataArray) > 0)
      {
          // حالا اکسپرت می‌تواند با این داده‌ها کار کند. مثلاً:
          // double LastPOC = MP_DataArray[1].POC; 
          // double CurrentVAH = MP_DataArray[0].VAH;
          
          // if (iClose(_Symbol, _Period, 0) > CurrentVAH) 
          // {
              // منطق Buy بر اساس شکست VAH
          // }
      }
   }
   
   if (chartRedrawNeeded)
   {
      ChartRedraw(ChartID());
   }
}
//+------------------------------------------------------------------+
