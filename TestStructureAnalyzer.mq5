//+------------------------------------------------------------------+
//|                                           StructureTestEA.mq5   |
//|                  Copyright 2025, xAI - Built by Grok             |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, xAI - Built by Grok"
#property link      ""
#property version   "1.00"
#property strict

// شامل کتابخانه اصلی - StructureAnalyzer.mqh برای استفاده از کلاس تحلیل
#include "StructureAnalyzer.mqh"

// ورودی‌های اکسپرت - برای تنظیم پارامترهای کتابخانه از طریق پنل ورودی‌ها
input int LookbackCandles = 100;          // تعداد کندل‌های گذشته برای سطوح اولیه (ورودی کاربر)
input double RetracementPercent = 25.0;   // درصد حداقل اصلاح (ورودی کاربر)
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT; // تایم فریم تحلیل (ورودی کاربر)
input int MaxStructures = 30;             // حداکثر ساختارها برای ذخیره (ورودی کاربر)
input bool EnableGraphics = true;         // فعال بودن نمایش گرافیکی (ورودی کاربر)

// instance کلاس - برای اجرای تحلیل ساختار قیمت
StructureAnalyzer *analyzer;

//+------------------------------------------------------------------+
//| اولیه‌سازی اکسپرت - ایجاد instance کلاس و فراخوانی Init برای شروع تحلیل |
//+------------------------------------------------------------------+
int OnInit()
  {
   // ایجاد instance جدید کلاس با ورودی‌های کاربر برای سفارشی‌سازی
   analyzer = new StructureAnalyzer(LookbackCandles, RetracementPercent, Timeframe, _Symbol, MaxStructures, EnableGraphics);
   analyzer.Init();                      // فراخوانی تابع اولیه‌سازی کلاس برای تنظیم سطوح اولیه
   return(INIT_SUCCEEDED);               // بازگشت موفقیت‌آمیز برای ادامه اجرای اکسپرت
  }

//+------------------------------------------------------------------+
//| پاک‌سازی اکسپرت - حذف instance کلاس برای آزاد کردن حافظه     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete analyzer;                      // حذف instance کلاس برای پاک‌سازی و جلوگیری از نشت حافظه
  }

//+------------------------------------------------------------------+
//| تیک اصلی: فراخوانی Update کلاس برای چک هر کندل جدید و آپدیت تحلیل |
//+------------------------------------------------------------------+
void OnTick()
  {
   analyzer.Update();                    // فراخوانی تابع آپدیت کلاس در هر تیک برای چک کندل جدید
  }
