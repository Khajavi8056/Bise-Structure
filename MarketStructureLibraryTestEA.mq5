//+------------------------------------------------------------------+
//|                                   MarketStructureLibraryTestEA.mq5         |
//|                                  Copyright 2025, Khajavi |
//|                                         Test Memento Structure   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi "
#property link      "https://www.HIPOALGORITM.com"
#property version   "1.01"
#property description "تست کتابخانه MarketStructureLibrary با قابلیت MTF"

#include <MarketStructureLibrary.mqh> // ایمپورت کتابخانه کلاس‌بندی شده

//+------------------------------------------------------------------+
//| ورودی‌های اکسپرت (Inputs) - نامگذاری جدید برای جلوگیری از تداخل  |
//+------------------------------------------------------------------+
input bool Input_EnableLogging = true;    // [فعال/غیرفعال کردن] سیستم لاگ
input int  Input_FibUpdateLevel = 35;     // سطح اصلاح فیبو برای تایید
input int  Input_FractalLength = 10;      // طول فرکتال

input ENUM_TIMEFRAMES MTF_Timeframe = PERIOD_H4; // تایم فریم دوم برای تحلیل MTF
input bool ShowMTFDrawing = true;                 // نمایش ترسیمات تایم فریم دوم (MTF) روی چارت فعلی

//+------------------------------------------------------------------+
//| آبجکت‌های سراسری (Instances of Classes)                           |
//+------------------------------------------------------------------+
MarketStructure   *Chart_Structure = NULL; // ساختار برای تایم فریم فعلی چارت
FVGManager        *Chart_FVG = NULL;       // FVG برای تایم فریم فعلی چارت

MarketStructure   *MTF_Structure = NULL;   // ساختار برای تایم فریم MTF (مثلاً H4)
FVGManager        *MTF_FVG = NULL;         // FVG برای تایم فریم MTF (مثلاً H4)

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
//| تابع مقداردهی اولیه اکسپرت (OnInit)                               |
//+------------------------------------------------------------------+
int OnInit()
{
   // ۱. ساخت آبجکت‌های مربوط به تایم فریم چارت فعلی
   // (تنظیم نمایش Chart_Structure روی true و Chart_FVG روی true)
   Chart_Structure = new MarketStructure(_Symbol, _Period, ChartID(), Input_EnableLogging, true, Input_FibUpdateLevel, Input_FractalLength);
   Chart_FVG = new FVGManager(_Symbol, _Period, ChartID(), Input_EnableLogging, true);
   
   // ۲. ساخت آبجکت‌های مربوط به تایم فریم MTF
   // (تنظیم نمایش MTF بر اساس ورودی ShowMTFDrawing)
   MTF_Structure = new MarketStructure(_Symbol, MTF_Timeframe, ChartID(), Input_EnableLogging, ShowMTFDrawing, Input_FibUpdateLevel, Input_FractalLength);
   MTF_FVG = new FVGManager(_Symbol, MTF_Timeframe, ChartID(), Input_EnableLogging, ShowMTFDrawing);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| تابع خاتمه اکسپرت (OnDeinit)                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // حذف ایمن آبجکت‌ها 
   if (Chart_Structure != NULL) delete Chart_Structure;
   if (Chart_FVG != NULL) delete Chart_FVG;
   if (MTF_Structure != NULL) delete MTF_Structure;
   if (MTF_FVG != NULL) delete MTF_FVG;
}

//+------------------------------------------------------------------+
//| تابع اصلی که با هر تیک قیمت اجرا می‌شود (OnTick)                 |
//+------------------------------------------------------------------+
void OnTick()
{
   bool chartRedrawNeeded = false;
   
   //--- ۱. اجرای منطق FVG در هر تیک (برای ابطال لحظه‌ای)
   // این پردازش برای هر دو آبجکت اجرا می‌شود
   if (Chart_FVG != NULL && Chart_FVG.ProcessNewTick()) chartRedrawNeeded = true;
   if (MTF_FVG != NULL && MTF_FVG.ProcessNewTick()) chartRedrawNeeded = true;
   
   //--- ۲. اجرای منطق ساختار و FVG فقط در کلوز کندل جدید چارت فعلی
   if (IsNewBar())
   {
      // پردازش ساختار و FVG برای تایم فریم چارت فعلی (PERIOD_CURRENT)
      if (Chart_Structure != NULL && Chart_Structure.ProcessNewBar()) chartRedrawNeeded = true;
      if (Chart_FVG != NULL && Chart_FVG.ProcessNewBar()) chartRedrawNeeded = true;

      // پردازش ساختار و FVG برای تایم فریم MTF (مثلاً H4)
      // شرط: اگر کندل جدیدی در تایم فریم MTF بسته شده باشد.
      if (MTF_Structure != NULL && iTime(_Symbol, MTF_Timeframe, 1) > MTF_Structure.GetLastSwingLow().time && iTime(_Symbol, MTF_Timeframe, 1) > MTF_Structure.GetLastSwingHigh().time)
      {
         if (MTF_Structure.ProcessNewBar()) chartRedrawNeeded = true;
         if (MTF_FVG.ProcessNewBar()) chartRedrawNeeded = true;
      }
      
      // مثال: دسترسی به اطلاعات ساختار H4
      if (MTF_Structure != NULL && MTF_Structure.GetCurrentTrend() == TREND_BULLISH)
      {
         // اینجا منطق معاملاتی بر اساس روند H4 (MTF) نوشته می‌شود.
         // SwingPoint lastH4High = MTF_Structure.GetLastSwingHigh();
      }
   }
   
   if (chartRedrawNeeded)
   {
      ChartRedraw(ChartID());
   }
}
//+------------------------------------------------------------------+
