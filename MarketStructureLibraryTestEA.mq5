
کدی نوشتی کامل نیست تمام پارا متر های ورودی وجود ندارد پس خطا میدهد
'NULL' - expression of 'void' type is illegal	test structur.mq5	150	8
من لیست تمام ورودی های اندیکاور اوردم انهارا به درستی در کد پیادهکن 




input group "Main"
input session_period Session                 = Daily;
input datetime       StartFromDate           = __DATE__;        // StartFromDate: lower priority.
input bool           StartFromCurrentSession = true;            // StartFromCurrentSession: higher priority.
input int            SessionsToCount         = 2;               // SessionsToCount: Number of sessions to count Market Profile.
input bool           SeamlessScrollingMode   = false;           // SeamlessScrollingMode: Show sessions on current screen.
input bool           EnableDevelopingPOC     = false;           // Enable Developing POC
input bool           EnableDevelopingVAHVAL  = false;           // Enable Developing VAH/VAL
input int            ValueAreaPercentage     = 70;              // ValueAreaPercentage: Percentage of TPO's inside Value Area.

input group "Colors and looks"
input color_scheme   ColorScheme              = Blue_to_Red;
input color          SingleColor              = clrBlue;        // SingleColor: if ColorScheme is set to Single Color.
input bool           ColorBullBear            = false;          // ColorBullBear: If true, colors are from bars' direction.
input color          MedianColor              = clrWhite;
input color          ValueAreaSidesColor      = clrWhite;
input color          ValueAreaHighLowColor    = clrWhite;
input ENUM_LINE_STYLE MedianStyle             = STYLE_SOLID;
input ENUM_LINE_STYLE MedianRayStyle          = STYLE_DASH;
input ENUM_LINE_STYLE ValueAreaSidesStyle     = STYLE_SOLID;
input ENUM_LINE_STYLE ValueAreaHighLowStyle   = STYLE_SOLID;
input ENUM_LINE_STYLE ValueAreaRayHighLowStyle= STYLE_DOT;
input int            MedianWidth              = 1;
input int            MedianRayWidth           = 1;
input int            ValueAreaSidesWidth      = 1;
input int            ValueAreaHighLowWidth    = 1;
input int            ValueAreaRayHighLowWidth = 1;
input sessions_to_draw_rays ShowValueAreaRays = None;           // ShowValueAreaRays: draw previous value area high/low rays.
input sessions_to_draw_rays ShowMedianRays    = None;           // ShowMedianRays: draw previous median rays.
input ways_to_stop_rays RaysUntilIntersection = Stop_No_Rays;   // RaysUntilIntersection: which rays stop when hit another MP.
input bool           HideRaysFromInvisibleSessions = false;     // HideRaysFromInvisibleSessions: hide rays from behind the screen.
input int            TimeShiftMinutes         = 0;              // TimeShiftMinutes: shift session + to the left, - to the right.
input bool           ShowKeyValues            = true;           // ShowKeyValues: print out VAH, VAL, POC on chart.
input color          KeyValuesColor           = clrWhite;       // KeyValuesColor: color for VAH, VAL, POC printout.
input int            KeyValuesSize            = 8;              // KeyValuesSize: font size for VAH, VAL, POC printout.
input single_print_type ShowSinglePrint       = No;             // ShowSinglePrint: mark Single Print profile levels.
input bool           SinglePrintRays          = false;          // SinglePrintRays: mark Single Print edges with rays.
input color          SinglePrintColor         = clrGold;
input ENUM_LINE_STYLE SinglePrintRayStyle     = STYLE_SOLID;
input int            SinglePrintRayWidth      = 1;
input color          ProminentMedianColor     = clrYellow;
input ENUM_LINE_STYLE ProminentMedianStyle    = STYLE_SOLID;
input int            ProminentMedianWidth     = 4;
input bool           ShowTPOCounts            = false;          // ShowTPOCounts: Show TPO counts above/below POC.
input color          TPOCountAboveColor       = clrHoneydew;    // TPOCountAboveColor: Color for TPO count above POC.
input color          TPOCountBelowColor       = clrMistyRose;   // TPOCountBelowColor: Color for TPO count below POC.
input bool           RightToLeft              = false;          // RightToLeft: Draw histogram from right to left.

input group "Performance"
input int            PointMultiplier          = 0;      // PointMultiplier: higher value = fewer objects. 0 - adaptive.
input int            ThrottleRedraw           = 0;      // ThrottleRedraw: delay (in seconds) for updating Market Profile.
input bool           DisableHistogram         = false;  // DisableHistogram: do not draw profile, VAH, VAL, and POC still visible.

input group "Alerts"
input bool           AlertNative              = false;           // AlertNative: issue native pop-up alerts.
input bool           AlertEmail               = false;           // AlertEmail: issue email alerts.
input bool           AlertPush                = false;           // AlertPush: issue push-notification alerts.
input bool           AlertArrows              = false;           // AlertArrows: draw chart arrows on alerts.
input alert_check_bar AlertCheckBar           = CheckPreviousBar;// AlertCheckBar: which bar to check for alerts?
input bool           AlertForValueArea        = false;           // AlertForValueArea: alerts for Value Area (VAH, VAL) rays.
input bool           AlertForMedian           = false;           // AlertForMedian: alerts for POC (Median) rays' crossing.
input bool           AlertForSinglePrint      = false;           // AlertForSinglePrint: alerts for single print rays' crossing.
input bool           AlertOnPriceBreak        = false;           // AlertOnPriceBreak: price breaking above/below the ray.
input bool           AlertOnCandleClose       = false;           // AlertOnCandleClose: candle closing above/below the ray.
input bool           AlertOnGapCross          = false;           // AlertOnGapCross: bar gap above/below the ray.
input int            AlertArrowCodePB         = 108;             // AlertArrowCodePB: arrow code for price break alerts.
input int            AlertArrowCodeCC         = 110;             // AlertArrowCodeCC: arrow code for candle close alerts.
input int            AlertArrowCodeGC         = 117;             // AlertArrowCodeGC: arrow code for gap crossover alerts.
input color          AlertArrowColorPB        = clrRed;          // AlertArrowColorPB: arrow color for price break alerts.
input color          AlertArrowColorCC        = clrBlue;         // AlertArrowColorCC: arrow color for candle close alerts.
input color          AlertArrowColorGC        = clrYellow;       // AlertArrowColorGC: arrow color for gap crossover alerts.
input int            AlertArrowWidthPB        = 1;               // AlertArrowWidthPB: arrow width for price break alerts.
input int            AlertArrowWidthCC        = 1;               // AlertArrowWidthCC: arrow width for candle close alerts.
input int            AlertArrowWidthGC        = 1;               // AlertArrowWidthGC: arrow width for gap crossover alerts.

input group "Intraday settings"
input bool           EnableIntradaySession1      = true;
input string         IntradaySession1StartTime   = "00:00";
input string         IntradaySession1EndTime     = "06:00";
input color_scheme   IntradaySession1ColorScheme = Blue_to_Red;

input bool           EnableIntradaySession2      = true;
input string         IntradaySession2StartTime   = "06:00";
input string         IntradaySession2EndTime     = "12:00";
input color_scheme   IntradaySession2ColorScheme = Red_to_Green;

input bool           EnableIntradaySession3      = true;
input string         IntradaySession3StartTime   = "12:00";
input string         IntradaySession3EndTime     = "18:00";
input color_scheme   IntradaySession3ColorScheme = Green_to_Blue;

input bool           EnableIntradaySession4      = true;
input string         IntradaySession4StartTime   = "18:00";
input string         IntradaySession4EndTime     = "00:00";
input color_scheme   IntradaySession4ColorScheme = Yellow_to_Cyan;

input group "Miscellaneous"
input sat_sun_solution SaturdaySunday                 = Saturday_Sunday_Normal_Days;
input bool             DisableAlertsOnWrongTimeframes = false;  // Disable alerts on wrong timeframes.
input int              ProminentMedianPercentage      = 101;    // Percentage of Median TPOs out of total for a Prominent one.




کد که سری قبل فرستادی رو در زیر میارم لطفا به درستی اصلاح کن تا کد بدون نقص و کامل باشد



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
