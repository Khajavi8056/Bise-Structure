//+------------------------------------------------------------------+
//|                                           StructureTestEA.mq5   |
//|                  Copyright 2025, xAI - Built by Grok             |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, xAI - Built by Grok"
#property link      ""
#property version   "1.00"
#property strict

// شامل کتابخانه اصلی - StructureAnalyzer.mqh
#include "StructureAnalyzer.mqh"

// ورودی‌های اکسپرت - برای تنظیم پارامترهای کتابخانه
input int LookbackCandles = 100;          // تعداد کندل‌های گذشته برای سطوح اولیه
input double RetracementPercent = 25.0;   // درصد حداقل اصلاح
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT; // تایم فریم تحلیل
input int MaxStructures = 30;             // حداکثر ساختارها برای ذخیره
input bool EnableGraphics = true;         // فعال بودن نمایش گرافیکی

// instance کلاس - برای اجرای تحلیل
StructureAnalyzer *analyzer;

//+------------------------------------------------------------------+
//| اولیه‌سازی اکسپرت - ایجاد instance کلاس و فراخوانی Init      |
//+------------------------------------------------------------------+
int OnInit()
  {
   // ایجاد instance جدید کلاس با ورودی‌های کاربر
   analyzer = new StructureAnalyzer(LookbackCandles, RetracementPercent, Timeframe, _Symbol, MaxStructures, EnableGraphics);
   analyzer.Init();                      // فراخوانی تابع اولیه‌سازی کلاس
   return(INIT_SUCCEEDED);               // بازگشت موفقیت‌آمیز
  }

//+------------------------------------------------------------------+
//| پاک‌سازی اکسپرت - حذف instance کلاس                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete analyzer;                      // حذف instance برای آزاد کردن حافظه
  }

//+------------------------------------------------------------------+
//| تیک اصلی: فراخوانی Update کلاس برای چک هر کندل جدید          |
//+------------------------------------------------------------------+
void OnTick()
  {
   analyzer.Update();                    // فراخوانی تابع آپدیت کلاس
  }
