//+------------------------------------------------------------------+
//|                                        MementoTestEA.mq5         |
//|                                  Copyright 2025, Khajavi & Gemini|
//|                                         Test Memento Structure   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi & Gemini"
#property link      "https://www.google.com"
#property version   "1.00"
#property description "تست کتابخانه MarketStructureLibrary با قابلیت MTF"
#property indicator_separate_window

#include <MarketStructureLibrary.mqh> // ایمپورت کتابخانه کلاس‌بندی شده

//+------------------------------------------------------------------+
//| ورودی‌های اکسپرت (Inputs)                                        |
//+------------------------------------------------------------------+
input bool enableLogging = true;    // [فعال/غیرفعال کردن] سیستم لاگ
input int  fibUpdateLevel = 35;     // سطح اصلاح فیبو برای تایید
input int  fractalLength = 10;      // طول فرکتال

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
   Chart_Structure = new MarketStructure(_Symbol, _Period, ChartID(), enableLogging, true, fibUpdateLevel, fractalLength);
   Chart_FVG = new FVGManager(_Symbol, _Period, ChartID(), enableLogging, true);
   
   // ۲. ساخت آبجکت‌های مربوط به تایم فریم MTF
   MTF_Structure = new MarketStructure(_Symbol, MTF_Timeframe, ChartID(), enableLogging, ShowMTFDrawing, fibUpdateLevel, fractalLength);
   MTF_FVG = new FVGManager(_Symbol, MTF_Timeframe, ChartID(), enableLogging, ShowMTFDrawing);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| تابع خاتمه اکسپرت (OnDeinit)                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // حذف آبجکت‌ها هنگام خاتمه اکسپرت (فراخوانی Destructor ها)
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
   if (Chart_FVG != NULL && Chart_FVG.ProcessNewTick()) chartRedrawNeeded = true;
   if (MTF_FVG != NULL && MTF_FVG.ProcessNewTick()) chartRedrawNeeded = true;
   
   //--- ۲. اجرای منطق ساختار و FVG فقط در کلوز کندل جدید چارت فعلی
   if (IsNewBar())
   {
      // پردازش ساختار و FVG برای تایم فریم چارت فعلی
      if (Chart_Structure != NULL && Chart_Structure.ProcessNewBar()) chartRedrawNeeded = true;
      if (Chart_FVG != NULL && Chart_FVG.ProcessNewBar()) chartRedrawNeeded = true;

      // پردازش ساختار و FVG برای تایم فریم MTF (باید چک کنیم که کندل آن تایم فریم هم بسته شده باشد)
      if (MTF_Structure != NULL && iTime(_Symbol, MTF_Timeframe, 1) > MTF_Structure.GetLastSwingHigh().time)
      {
         if (MTF_Structure.ProcessNewBar()) chartRedrawNeeded = true;
         if (MTF_FVG.ProcessNewBar()) chartRedrawNeeded = true;
      }
      
      // مثال: استفاده از داده‌های MTF در اکسپرت
      if (MTF_Structure != NULL && MTF_Structure.GetCurrentTrend() == TREND_BULLISH)
      {
         // اینجا منطق معاملاتی بر اساس روند H4 (MTF) نوشته می‌شود.
      }
   }
   
   if (chartRedrawNeeded)
   {
      ChartRedraw(ChartID());
   }
}
//+------------------------------------------------------------------+
