//+------------------------------------------------------------------+
//|                                        MementoTestEA.mq5         |
//|                                  Copyright 2025, Khajavi |
//|                                         Test Memento Structure   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi "
#property link      "https://www.HIPOALGORITM.com"
#property version   "1.03" // اتصال کامل Market Profile
#property description "تست کتابخانه MarketStructureLibrary با قابلیت MTF و اتصال کامل Market Profile"

#include <MarketStructureLibrary.mqh> // ایمپورت کتابخانه کلاس‌بندی شده

//+------------------------------------------------------------------+
//| ENUMهای سفارشی Market Profile (با فرض مقادیر عددی پیش‌فرض)        |
//+------------------------------------------------------------------+
enum session_period
{
   Intraday = 0,
   Daily    = 1,
   Weekly   = 2,
   Monthly  = 3,
   // ... بقیه موارد اندیکاتور
};

enum color_scheme
{
   Blue_to_Red     = 0,
   Single_Color    = 1,
   // ... بقیه موارد اندیکاتور
};

enum sessions_to_draw_rays
{
   None = 0,
   Last_Session_Only = 1,
   All_Visible_Sessions = 2,
   // ...
};

enum ways_to_stop_rays
{
   Stop_No_Rays = 0,
   Stop_All_Rays = 1,
   // ...
};

enum single_print_type
{
   No = 0,
   Value_Area_Edges = 1,
   // ...
};

enum alert_check_bar
{
   CheckCurrentBar = 0,
   CheckPreviousBar = 1,
   // ...
};

enum sat_sun_solution
{
   Saturday_Sunday_Normal_Days = 0,
   Ignore_Saturday_Sunday = 1,
   Append_Saturday_Sunday = 2,
};

//+------------------------------------------------------------------+
//| ورودی‌های عمومی EA و ساختار بازار                                |
//+------------------------------------------------------------------+
input bool Input_EnableLogging = true;    // [فعال/غیرفعال کردن] سیستم لاگ
input int  Input_FibUpdateLevel = 35;     // سطح اصلاح فیبو برای تایید
input int  Input_FractalLength = 10;      // طول فرکتال
input ENUM_TIMEFRAMES MTF_Timeframe = PERIOD_H4; // تایم فریم دوم برای تحلیل MTF
input bool ShowMTFDrawing = true;                 // نمایش ترسیمات تایم فریم دوم (MTF) روی چارت فعلی

//+------------------------------------------------------------------+
//| ورودی‌های کامل Market Profile (MP)                               |
//+------------------------------------------------------------------+
input group "Market Profile - Main"
input session_period MP_Session                 = Daily;
input datetime       MP_StartFromDate           = __DATE__;        // StartFromDate
input bool           MP_StartFromCurrentSession = true;            // StartFromCurrentSession
input int            MP_SessionsToCount         = 5;               // SessionsToCount (مقدار پیش‌فرض ما را حفظ کردیم)
input bool           MP_SeamlessScrollingMode   = false;           // SeamlessScrollingMode
input bool           MP_EnableDevelopingPOC     = false;           // Enable Developing POC
input bool           MP_EnableDevelopingVAHVAL  = false;           // Enable Developing VAH/VAL
input int            MP_ValueAreaPercentage     = 70;              // ValueAreaPercentage

input group "Market Profile - Colors and Looks"
input color_scheme   MP_ColorScheme              = Blue_to_Red;
input color          MP_SingleColor              = clrBlue;
input bool           MP_ColorBullBear            = false;
input color          MP_MedianColor              = clrWhite;
input color          MP_ValueAreaSidesColor      = clrWhite;
input color          MP_ValueAreaHighLowColor    = clrWhite;
input ENUM_LINE_STYLE MP_MedianStyle             = STYLE_SOLID;
input ENUM_LINE_STYLE MP_MedianRayStyle          = STYLE_DASH;
input ENUM_LINE_STYLE MP_ValueAreaSidesStyle     = STYLE_SOLID;
input ENUM_LINE_STYLE MP_ValueAreaHighLowStyle   = STYLE_SOLID;
input ENUM_LINE_STYLE MP_ValueAreaRayHighLowStyle= STYLE_DOT;
input int            MP_MedianWidth              = 1;
input int            MP_MedianRayWidth           = 1;
input int            MP_ValueAreaSidesWidth      = 1;
input int            MP_ValueAreaHighLowWidth    = 1;
input int            MP_ValueAreaRayHighLowWidth = 1;
input sessions_to_draw_rays MP_ShowValueAreaRays = None;           // ShowValueAreaRays
input sessions_to_draw_rays MP_ShowMedianRays    = None;           // ShowMedianRays
input ways_to_stop_rays MP_RaysUntilIntersection = Stop_No_Rays;   // RaysUntilIntersection
input bool           MP_HideRaysFromInvisibleSessions = false;     // HideRaysFromInvisibleSessions
input int            MP_TimeShiftMinutes         = 0;              // TimeShiftMinutes
input bool           MP_ShowKeyValues            = true;           // ShowKeyValues
input color          MP_KeyValuesColor           = clrWhite;       // KeyValuesColor
input int            MP_KeyValuesSize            = 8;              // KeyValuesSize
input single_print_type MP_ShowSinglePrint       = No;             // ShowSinglePrint
input bool           MP_SinglePrintRays          = false;          // SinglePrintRays
input color          MP_SinglePrintColor         = clrGold;
input ENUM_LINE_STYLE MP_SinglePrintRayStyle     = STYLE_SOLID;
input int            MP_SinglePrintRayWidth      = 1;
input color          MP_ProminentMedianColor     = clrYellow;
input ENUM_LINE_STYLE MP_ProminentMedianStyle    = STYLE_SOLID;
input int            MP_ProminentMedianWidth     = 4;
input bool           MP_ShowTPOCounts            = false;          // ShowTPOCounts
input color          MP_TPOCountAboveColor       = clrHoneydew;    // TPOCountAboveColor
input color          MP_TPOCountBelowColor       = clrMistyRose;   // TPOCountBelowColor
input bool           MP_RightToLeft              = false;          // RightToLeft

input group "Market Profile - Performance and Alerts"
input int            MP_PointMultiplier          = 0;              // PointMultiplier
input int            MP_ThrottleRedraw           = 0;              // ThrottleRedraw
input bool           MP_DisableHistogram         = false;          // DisableHistogram
input bool           MP_AlertNative              = false;           // AlertNative
input bool           MP_AlertEmail               = false;           // AlertEmail
input bool           MP_AlertPush                = false;           // AlertPush
input bool           MP_AlertArrows              = false;           // AlertArrows
input alert_check_bar MP_AlertCheckBar           = CheckPreviousBar;// AlertCheckBar
input bool           MP_AlertForValueArea        = false;           // AlertForValueArea
input bool           MP_AlertForMedian           = false;           // AlertForMedian
input bool           MP_AlertForSinglePrint      = false;           // AlertForSinglePrint
input bool           MP_AlertOnPriceBreak        = false;           // AlertOnPriceBreak
input bool           MP_AlertOnCandleClose       = false;           // AlertOnCandleClose
input bool           MP_AlertOnGapCross          = false;           // AlertOnGapCross
input int            MP_AlertArrowCodePB         = 108;             // AlertArrowCodePB
input int            MP_AlertArrowCodeCC         = 110;             // AlertArrowCodeCC
input int            MP_AlertArrowCodeGC         = 117;             // AlertArrowCodeGC
input color          MP_AlertArrowColorPB        = clrRed;          // AlertArrowColorPB
input color          MP_AlertArrowColorCC        = clrBlue;         // AlertArrowColorCC
input color          MP_AlertArrowColorGC        = clrYellow;       // AlertArrowColorGC
input int            MP_AlertArrowWidthPB        = 1;               // AlertArrowWidthPB
input int            MP_AlertArrowWidthCC        = 1;               // AlertArrowWidthCC
input int            MP_AlertArrowWidthGC        = 1;               // AlertArrowWidthGC

input group "Market Profile - Intraday"
input bool           MP_EnableIntradaySession1      = true;
input string         MP_IntradaySession1StartTime   = "00:00";
input string         MP_IntradaySession1EndTime     = "06:00";
input color_scheme   MP_IntradaySession1ColorScheme = Blue_to_Red;

input bool           MP_EnableIntradaySession2      = true;
input string         MP_IntradaySession2StartTime   = "06:00";
input string         MP_IntradaySession2EndTime     = "12:00";
input color_scheme   MP_IntradaySession2ColorScheme = Red_to_Green;

input bool           MP_EnableIntradaySession3      = true;
input string         MP_IntradaySession3StartTime   = "12:00";
input string         MP_IntradaySession3EndTime     = "18:00";
input color_scheme   MP_IntradaySession3ColorScheme = Green_to_Blue;

input bool           MP_EnableIntradaySession4      = true;
input string         MP_IntradaySession4StartTime   = "18:00";
input string         MP_IntradaySession4EndTime     = "00:00";
input color_scheme   MP_IntradaySession4ColorScheme = Yellow_to_Cyan;

input group "Market Profile - Miscellaneous"
input sat_sun_solution MP_SaturdaySunday             = Saturday_Sunday_Normal_Days;
input bool           MP_DisableAlertsOnWrongTimeframes = false;  // Disable alerts on wrong timeframes.
input int            MP_ProminentMedianPercentage = 101;    // ProminentMedianPercentage

//+------------------------------------------------------------------+
//| ساختار داده‌ای برای ذخیره اطلاعات کلیدی Market Profile هر سشن    |
//+------------------------------------------------------------------+
struct MarketProfileSessionData
{
   datetime SessionStart;    // زمان شروع سشن
   double   POC;             // Point of Control - بافر 0
   double   VAH;             // Value Area High - بافر 1
   double   VAL;             // Value Area Low - بافر 2
};

//+------------------------------------------------------------------+
//| آبجکت‌های سراسری (Instances of Classes & Indicators)             |
//+------------------------------------------------------------------+
MarketStructure           *Chart_Structure = NULL; 
FVGManager                *Chart_FVG = NULL;       
MarketStructure           *MTF_Structure = NULL;   
FVGManager                *MTF_FVG = NULL;         

int                       MarketProfile_Handle = INVALID_HANDLE; 
MarketProfileSessionData  MP_DataArray[];                       

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
    double poc_data[100], vah_data[100], val_data[100];
    
    int copied_count = CopyBuffer(MarketProfile_Handle, 0, 0, sessions_to_fetch, poc_data);
    
    if (copied_count < 1) return; 
    
    CopyBuffer(MarketProfile_Handle, 1, 0, sessions_to_fetch, vah_data);
    CopyBuffer(MarketProfile_Handle, 2, 0, sessions_to_fetch, val_data);

    // --- ذخیره داده‌ها در آرایه داخلی EA ---
    for (int i = 0; i < copied_count; i++)
    {
        MP_DataArray[i].SessionStart = iTime(_Symbol, _Period, i); // زمان تقریبی مرجع
        MP_DataArray[i].POC = poc_data[i];
        MP_DataArray[i].VAH = vah_data[i];
        MP_DataArray[i].VAL = val_data[i];
    }
    
    // --- چاپ کردن داده‌های سشن جاری و قبلی در لاگ ---
    if(Input_EnableLogging && copied_count > 0) 
    {
        Print("--- Market Profile Data Fetched ---");
        
        // سشن جاری (0)
        Print("Current MP | Time: ", TimeToString(MP_DataArray[0].SessionStart, TIME_DATE|TIME_MINUTES),
              " | POC: ", DoubleToString(MP_DataArray[0].POC, _Digits),
              " | VAH: ", DoubleToString(MP_DataArray[0].VAH, _Digits),
              " | VAL: ", DoubleToString(MP_DataArray[0].VAL, _Digits));
        
        // سشن گذشته (1)
        if (copied_count > 1)
        {
             Print("Previous MP | Time: ", TimeToString(MP_DataArray[1].SessionStart, TIME_DATE|TIME_MINUTES),
                  " | POC: ", DoubleToString(MP_DataArray[1].POC, _Digits),
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
   
   // --- ۲. فراخوانی Market Profile با تمام پارامترها (اتصال کامل پتانسیل) ---
   MarketProfile_Handle = iCustom(
       _Symbol,                     
       _Period,                     
       "MarketProfile.mq5",         
       
       // Main Group
       (int)MP_Session,                  // 1. session_period Session
       MP_StartFromDate,                 // 2. datetime StartFromDate
       MP_StartFromCurrentSession,       // 3. bool StartFromCurrentSession
       MP_SessionsToCount,               // 4. int SessionsToCount
       MP_SeamlessScrollingMode,         // 5. bool SeamlessScrollingMode
       MP_EnableDevelopingPOC,           // 6. bool EnableDevelopingPOC
       MP_EnableDevelopingVAHVAL,        // 7. bool EnableDevelopingVAHVAL
       MP_ValueAreaPercentage,           // 8. int ValueAreaPercentage

       // Colors and Looks Group
       (int)MP_ColorScheme,              // 9. color_scheme ColorScheme
       MP_SingleColor,                   // 10. color SingleColor
       MP_ColorBullBear,                 // 11. bool ColorBullBear
       MP_MedianColor,                   // 12. color MedianColor
       MP_ValueAreaSidesColor,           // 13. color ValueAreaSidesColor
       MP_ValueAreaHighLowColor,         // 14. color ValueAreaHighLowColor
       (int)MP_MedianStyle,              // 15. ENUM_LINE_STYLE MedianStyle
       (int)MP_MedianRayStyle,           // 16. ENUM_LINE_STYLE MedianRayStyle
       (int)MP_ValueAreaSidesStyle,      // 17. ENUM_LINE_STYLE ValueAreaSidesStyle
       (int)MP_ValueAreaHighLowStyle,    // 18. ENUM_LINE_STYLE ValueAreaHighLowStyle
       (int)MP_ValueAreaRayHighLowStyle, // 19. ENUM_LINE_STYLE ValueAreaRayHighLowStyle
       MP_MedianWidth,                   // 20. int MedianWidth
       MP_MedianRayWidth,                // 21. int MedianRayWidth
       MP_ValueAreaSidesWidth,           // 22. int ValueAreaSidesWidth
       MP_ValueAreaHighLowWidth,         // 23. int ValueAreaHighLowWidth
       MP_ValueAreaRayHighLowWidth,      // 24. int ValueAreaRayHighLowWidth
       (int)MP_ShowValueAreaRays,        // 25. sessions_to_draw_rays ShowValueAreaRays
       (int)MP_ShowMedianRays,           // 26. sessions_to_draw_rays ShowMedianRays
       (int)MP_RaysUntilIntersection,    // 27. ways_to_stop_rays RaysUntilIntersection
       MP_HideRaysFromInvisibleSessions, // 28. bool HideRaysFromInvisibleSessions
       MP_TimeShiftMinutes,              // 29. int TimeShiftMinutes
       MP_ShowKeyValues,                 // 30. bool ShowKeyValues
       MP_KeyValuesColor,                // 31. color KeyValuesColor
       MP_KeyValuesSize,                 // 32. int KeyValuesSize
       (int)MP_ShowSinglePrint,          // 33. single_print_type ShowSinglePrint
       MP_SinglePrintRays,               // 34. bool SinglePrintRays
       MP_SinglePrintColor,              // 35. color SinglePrintColor
       (int)MP_SinglePrintRayStyle,      // 36. ENUM_LINE_STYLE SinglePrintRayStyle
       MP_SinglePrintRayWidth,           // 37. int SinglePrintRayWidth
       MP_ProminentMedianColor,          // 38. color ProminentMedianColor
       (int)MP_ProminentMedianStyle,     // 39. ENUM_LINE_STYLE ProminentMedianStyle
       MP_ProminentMedianWidth,          // 40. int ProminentMedianWidth
       MP_ShowTPOCounts,                 // 41. bool ShowTPOCounts
       MP_TPOCountAboveColor,            // 42. color TPOCountAboveColor
       MP_TPOCountBelowColor,            // 43. color TPOCountBelowColor
       MP_RightToLeft,                   // 44. bool RightToLeft

       // Performance Group
       MP_PointMultiplier,               // 45. int PointMultiplier
       MP_ThrottleRedraw,                // 46. int ThrottleRedraw
       MP_DisableHistogram,              // 47. bool DisableHistogram

       // Alerts Group
       MP_AlertNative,                   // 48. bool AlertNative
       MP_AlertEmail,                    // 49. bool AlertEmail
       MP_AlertPush,                     // 50. bool AlertPush
       MP_AlertArrows,                   // 51. bool AlertArrows
       (int)MP_AlertCheckBar,            // 52. alert_check_bar AlertCheckBar
       MP_AlertForValueArea,             // 53. bool AlertForValueArea
       MP_AlertForMedian,                // 54. bool AlertForMedian
       MP_AlertForSinglePrint,           // 55. bool AlertForSinglePrint
       MP_AlertOnPriceBreak,             // 56. bool AlertOnPriceBreak
       MP_AlertOnCandleClose,            // 57. bool AlertOnCandleClose
       MP_AlertOnGapCross,               // 58. bool AlertOnGapCross
       MP_AlertArrowCodePB,              // 59. int AlertArrowCodePB
       MP_AlertArrowCodeCC,              // 60. int AlertArrowCodeCC
       MP_AlertArrowCodeGC,              // 61. int AlertArrowCodeGC
       MP_AlertArrowColorPB,             // 62. color AlertArrowColorPB
       MP_AlertArrowColorCC,             // 63. color AlertArrowColorCC
       MP_AlertArrowColorGC,             // 64. color AlertArrowColorGC
       MP_AlertArrowWidthPB,             // 65. int AlertArrowWidthPB
       MP_AlertArrowWidthCC,             // 66. int AlertArrowWidthCC
       MP_AlertArrowWidthGC,             // 67. int AlertArrowWidthGC

       // Intraday settings Group
       MP_EnableIntradaySession1,        // 68. bool EnableIntradaySession1
       MP_IntradaySession1StartTime,     // 69. string IntradaySession1StartTime
       MP_IntradaySession1EndTime,       // 70. string IntradaySession1EndTime
       (int)MP_IntradaySession1ColorScheme, // 71. color_scheme IntradaySession1ColorScheme
       MP_EnableIntradaySession2,        // 72. bool EnableIntradaySession2
       MP_IntradaySession2StartTime,     // 73. string IntradaySession2StartTime
       MP_IntradaySession2EndTime,       // 74. string IntradaySession2EndTime
       (int)MP_IntradaySession2ColorScheme, // 75. color_scheme IntradaySession2ColorScheme
       MP_EnableIntradaySession3,        // 76. bool EnableIntradaySession3
       MP_IntradaySession3StartTime,     // 77. string IntradaySession3StartTime
       MP_IntradaySession3EndTime,       // 78. string IntradaySession3EndTime
       (int)MP_IntradaySession3ColorScheme, // 79. color_scheme IntradaySession3ColorScheme
       MP_EnableIntradaySession4,        // 80. bool EnableIntradaySession4
       MP_IntradaySession4StartTime,     // 81. string IntradaySession4StartTime
       MP_IntradaySession4EndTime,       // 82. string IntradaySession4EndTime
       (int)MP_IntradaySession4ColorScheme, // 83. color_scheme IntradaySession4ColorScheme

       // Miscellaneous Group
       (int)MP_SaturdaySunday,           // 84. sat_sun_solution SaturdaySunday
       MP_DisableAlertsOnWrongTimeframes, // 85. bool DisableAlertsOnWrongTimeframes
       MP_ProminentMedianPercentage,     // 86. int ProminentMedianPercentage

       // پایان لیست
       0.0 // MQL5 requires the variable argument list to be terminated by a double.
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
      FetchMarketProfileData(); 

      // پردازش ساختار و FVG برای تایم فریم MTF 
      if (MTF_Structure != NULL && iTime(_Symbol, MTF_Timeframe, 1) > MTF_Structure.GetLastSwingLow().time && iTime(_Symbol, MTF_Timeframe, 1) > MTF_Structure.GetLastSwingHigh().time)
      {
         if (MTF_Structure.ProcessNewBar()) chartRedrawNeeded = true;
         if (MTF_FVG.ProcessNewBar()) chartRedrawNeeded = true;
      }
      
      // --- ۴. EA حالا می‌تواند از MP_DataArray برای تصمیم‌گیری استفاده کند.
   }
   
   if (chartRedrawNeeded)
   {
      ChartRedraw(ChartID());
   }
}
//+------------------------------------------------------------------+
