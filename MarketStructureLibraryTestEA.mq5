//+------------------------------------------------------------------+
//| MementoTestEA.mq5 |
//| Copyright 2025, Khajavi & Gemini|
//| Test  Structure |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi "
#property link "https://www.google.com"
#property version "1.04"
#property description "تست کتابخانه MarketStructureLibrary با قابلیت MTF و کلاس MinorStructure"
#include <MarketStructureLibrary.mqh> // ایمپورت کتابخانه کلاس‌بندی شده
//+------------------------------------------------------------------+
//| ورودی‌های اکسپرت (Inputs) - نامگذاری جدید برای جلوگیری از تداخل |
//+------------------------------------------------------------------+
input bool Input_EnableLogging = true; // [فعال/غیرفعال کردن] سیستم لاگ
input int Input_FibUpdateLevel = 21; // سطح اصلاح فیبو برای تایید
input int Input_FractalLength = 5; // طول فرکتال
input int Input_AOFractalLength = 7; //  برای MinorStructu5re
input ENUM_TIMEFRAMES MTF_Timeframe = PERIOD_H4; // تایم فریم دوم برای تحلیل MTF
input bool ShowMTFDrawing = true; // نمایش ترسیمات تایم فریم دوم (MTF) روی چارت فعلی
//+------------------------------------------------------------------+
//| آبجکت‌های سراسری (Instances of Classes) |
//+------------------------------------------------------------------+
MarketStructure *Chart_Structure = NULL; // ساختار برای تایم فریم فعلی چارت
FVGManager *Chart_FVG = NULL; // FVG برای تایم فریم فعلی چارت
MinorStructure *Chart_Minor = NULL; // ساختار مینور برای تایم فریم فعلی چارت
MarketStructure *MTF_Structure = NULL; // ساختار برای تایم فریم MTF (مثلاً H4)
FVGManager *MTF_FVG = NULL; // FVG برای تایم فریم MTF (مثلاً H4)
MinorStructure *MTF_Minor = NULL; // ساختار مینور برای تایم فریم MTF (مثلاً H4)
//+------------------------------------------------------------------+
//| تابع کمکی: بررسی تشکیل کندل جدید برای تایم فریم فعلی |
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
//| تابع کمکی: بررسی تشکیل کندل جدید برای تایم فریم MTF |
//+------------------------------------------------------------------+
bool IsNewBarMTF(ENUM_TIMEFRAMES tf)
{
   static datetime lastBarTimeMTF = 0;
   datetime currentTime = iTime(_Symbol, tf, 0);
  
   if (currentTime > lastBarTimeMTF)
   {
      lastBarTimeMTF = currentTime;
      return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//| تابع مقداردهی اولیه اکسپرت (OnInit) |
//+------------------------------------------------------------------+
int OnInit()
{
   // ۱. ساخت آبجکت‌های مربوط به تایم فریم چارت فعلی
   // (تنظیم نمایش روی true برای همه کلاس‌ها در تایم فریم فعلی)
   Chart_Structure = new MarketStructure(_Symbol, _Period, ChartID(), Input_EnableLogging, true, Input_FibUpdateLevel, Input_FractalLength);
   Chart_FVG = new FVGManager(_Symbol, _Period, ChartID(), Input_EnableLogging, true);
   Chart_Minor = new MinorStructure(_Symbol, _Period, ChartID(), Input_EnableLogging, true, Input_AOFractalLength);
    // غیرفعال کردن گرید چارت
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   
   // تنظیم رنگ کندل‌ها
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrGreen);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrRed);
   ChartSetInteger(0, CHART_COLOR_CHART_UP, clrGreen);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrRed);
   
   // ۲. ساخت آبجکت‌های مربوط به تایم فریم MTF
   // (تنظیم نمایش MTF بر اساس ورودی ShowMTFDrawing)
   MTF_Structure = new MarketStructure(_Symbol, MTF_Timeframe, ChartID(), Input_EnableLogging, ShowMTFDrawing, Input_FibUpdateLevel, Input_FractalLength);
   MTF_FVG = new FVGManager(_Symbol, MTF_Timeframe, ChartID(), Input_EnableLogging, ShowMTFDrawing);
   MTF_Minor = new MinorStructure(_Symbol, MTF_Timeframe, ChartID(), Input_EnableLogging, ShowMTFDrawing, Input_AOFractalLength);
  
   ChartRedraw(ChartID());
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| تابع خاتمه اکسپرت (OnDeinit) |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // حذف ایمن آبجکت‌ها
   if (Chart_Structure != NULL) delete Chart_Structure;
   if (Chart_FVG != NULL) delete Chart_FVG;
   if (Chart_Minor != NULL) delete Chart_Minor;
   if (MTF_Structure != NULL) delete MTF_Structure;
   if (MTF_FVG != NULL) delete MTF_FVG;
   if (MTF_Minor != NULL) delete MTF_Minor;
}
//+------------------------------------------------------------------+
//| تابع اصلی که با هر تیک قیمت اجرا می‌شود (OnTick) |
//+------------------------------------------------------------------+
void OnTick()
{
   bool chartRedrawNeeded = false;
  
   //--- ۱. اجرای منطق FVG در هر تیک (برای ابطال لحظه‌ای)
   // این پردازش برای هر دو آبجکت FVG اجرا می‌شود
   if (Chart_FVG != NULL && Chart_FVG.ProcessNewTick()) chartRedrawNeeded = true;
   if (MTF_FVG != NULL && MTF_FVG.ProcessNewTick()) chartRedrawNeeded = true;
  
   //--- ۲. اجرای منطق ساختارها فقط در کلوز کندل جدید مربوطه
   if (IsNewBar())
   {
      // پردازش برای تایم فریم چارت فعلی (PERIOD_CURRENT)
    //  if (Chart_Structure != NULL && Chart_Structure.ProcessNewBar()) chartRedrawNeeded = true;
      if (Chart_FVG != NULL && Chart_FVG.ProcessNewBar()) chartRedrawNeeded = true;
      if (Chart_Minor != NULL && Chart_Minor.ProcessNewBar()) chartRedrawNeeded = true;
   }
  
   if (IsNewBarMTF(MTF_Timeframe))
   {
      // پردازش برای تایم فریم MTF (مثلاً H4)
      if (MTF_Structure != NULL && MTF_Structure.ProcessNewBar()) chartRedrawNeeded = true;
     // if (MTF_FVG != NULL && MTF_FVG.ProcessNewBar()) chartRedrawNeeded = true;
     // if (MTF_Minor != NULL && MTF_Minor.ProcessNewBar()) chartRedrawNeeded = true;
   }///
  
   //--- مثال دسترسی به داده‌های کلاس جدید MinorStructure (برای لاگ یا منطق معاملاتی)
   if (MTF_Minor != NULL && MTF_Minor.GetMinorHighsCount() > 0)
   {
      // اینجا می‌توانید از داده‌های مینور استفاده کنید، مثلاً آخرین سقف مینور
      // SwingPoint lastMTFMinorHigh = MTF_Minor.GetMinorSwingHigh(0);
   }
  
   if (chartRedrawNeeded)
   {
      ChartRedraw(ChartID());
   }
}
//+------------------------------------------------------------------+
