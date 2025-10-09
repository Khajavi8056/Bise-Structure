//+------------------------------------------------------------------+
//|                                         MarketProfileClass.mqh   |
//|                             Copyright © 2010-2025, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+

// تعریف enumها برای دسترسی عمومی
enum color_scheme
{
    Blue_to_Red,       // آبی به قرمز
    Red_to_Green,      // قرمز به سبز
    Green_to_Blue,     // سبز به آبی
    Yellow_to_Cyan,    // زرد به cyan
    Magenta_to_Yellow, // magenta به زرد
    Cyan_to_Magenta,   // cyan به magenta
    Single_Color       // رنگ تک
};

enum session_period
{
    Daily,       // روزانه
    Weekly,      // هفتگی
    Monthly,     // ماهانه
    Quarterly,   // سه ماهه
    Semiannual,  // شش ماهه
    Annual,      // سالانه
    Intraday,    // داخل روز
    Rectangle    // مستطیل
};

enum sat_sun_solution
{
    Saturday_Sunday_Normal_Days, // جلسات عادی
    Ignore_Saturday_Sunday,      // نادیده گرفتن شنبه و یکشنبه
    Append_Saturday_Sunday       // اضافه کردن شنبه و یکشنبه
};

enum sessions_to_draw_rays
{
    None,
    Previous,
    Current,
    PreviousCurrent, // قبلی و فعلی
    AllPrevious,     // همه قبلی
    All
};

enum ways_to_stop_rays
{
    Stop_No_Rays,                      // بدون توقف اشعه
    Stop_All_Rays,                     // توقف همه اشعه
    Stop_All_Rays_Except_Prev_Session, // توقف همه اشعه به جز جلسه قبلی
    Stop_Only_Previous_Session,        // توقف فقط جلسه قبلی
};

enum bar_direction
{
    Bullish,  // صعودی
    Bearish,  // نزولی
    Neutral   // خنثی
};

enum single_print_type
{
    No,
    Leftside,  // سمت چپ
    Rightside  // سمت راست
};

enum alert_check_bar
{
    CheckCurrentBar,  // فعلی
    CheckPreviousBar  // قبلی
};

enum alert_types
{
    PriceBreak,           // شکست قیمت
    CandleCloseCrossover, // عبور بسته شدن شمع
    GapCrossover          // عبور شکاف
};

// ساختار برای نگهداری تمام تنظیمات پروفایل بازار
struct CMarketProfileSettings
{
    //--- بخش اصلی
    session_period    Session;
    datetime          StartFromDate;
    bool              StartFromCurrentSession;
    int               SessionsToCount;
    bool              SeamlessScrollingMode;
    bool              EnableDevelopingPOC;
    bool              EnableDevelopingVAHVAL;
    int               ValueAreaPercentage;

    //--- بخش رنگ‌ها و ظاهر
    color_scheme      ColorScheme;
    color             SingleColor;
    bool              ColorBullBear;
    color             MedianColor;
    color             ValueAreaSidesColor;
    color             ValueAreaHighLowColor;
    ENUM_LINE_STYLE   MedianStyle;
    ENUM_LINE_STYLE   MedianRayStyle;
    ENUM_LINE_STYLE   ValueAreaSidesStyle;
    ENUM_LINE_STYLE   ValueAreaHighLowStyle;
    ENUM_LINE_STYLE   ValueAreaRayHighLowStyle;
    int               MedianWidth;
    int               MedianRayWidth;
    int               ValueAreaSidesWidth;
    int               ValueAreaHighLowWidth;
    int               ValueAreaRayHighLowWidth;
    sessions_to_draw_rays ShowValueAreaRays;
    sessions_to_draw_rays ShowMedianRays;
    ways_to_stop_rays RaysUntilIntersection;
    bool              HideRaysFromInvisibleSessions;
    int               TimeShiftMinutes;
    bool              ShowKeyValues;
    color             KeyValuesColor;
    int               KeyValuesSize;
    single_print_type ShowSinglePrint;
    bool              SinglePrintRays;
    color             SinglePrintColor;
    ENUM_LINE_STYLE   SinglePrintRayStyle;
    int               SinglePrintRayWidth;
    color             ProminentMedianColor;
    ENUM_LINE_STYLE   ProminentMedianStyle;
    int               ProminentMedianWidth;
    bool              ShowTPOCounts;
    color             TPOCountAboveColor;
    color             TPOCountBelowColor;
    bool              RightToLeft;
    
    //--- بخش عملکرد
    int               PointMultiplier;
    int               ThrottleRedraw;
    bool              DisableHistogram;
    
    //--- بخش هشدارها
    bool              AlertNative;
    bool              AlertEmail;
    bool              AlertPush;
    bool              AlertArrows;
    alert_check_bar   AlertCheckBar;
    bool              AlertForValueArea;
    bool              AlertForMedian;
    bool              AlertForSinglePrint;
    bool              AlertOnPriceBreak;
    bool              AlertOnCandleClose;
    bool              AlertOnGapCross;
    int               AlertArrowCodePB;
    int               AlertArrowCodeCC;
    int               AlertArrowCodeGC;
    color             AlertArrowColorPB;
    color             AlertArrowColorCC;
    color             AlertArrowColorGC;
    int               AlertArrowWidthPB;
    int               AlertArrowWidthCC;
    int               AlertArrowWidthGC;

    //--- بخش تنظیمات داخل روز
    bool              EnableIntradaySession1;
    string            IntradaySession1StartTime;
    string            IntradaySession1EndTime;
    color_scheme      IntradaySession1ColorScheme;
    bool              EnableIntradaySession2;
    string            IntradaySession2StartTime;
    string            IntradaySession2EndTime;
    color_scheme      IntradaySession2ColorScheme;
    bool              EnableIntradaySession3;
    string            IntradaySession3StartTime;
    string            IntradaySession3EndTime;
    color_scheme      IntradaySession3ColorScheme;
    bool              EnableIntradaySession4;
    string            IntradaySession4StartTime;
    string            IntradaySession4EndTime;
    color_scheme      IntradaySession4ColorScheme;

    //--- بخش متفرقه
    sat_sun_solution  SaturdaySunday;
    bool              DisableAlertsOnWrongTimeframes;
    int               ProminentMedianPercentage;

    //--- جداسازی رسم
    bool              enableDrawing; // فعال کردن رسم اشیاء روی چارت
};

//+------------------------------------------------------------------+
//| کلاس برای پروفایل بازار                                        |
//+------------------------------------------------------------------+
class CMarketProfile
{
private:
    CMarketProfileSettings m_settings; // تنظیمات شخصی

    int PointMultiplier_calculated; // محاسبه شده بر اساس ارقام قیمت اگر PointMultiplier 0 باشد
    int DigitsM; // تعداد ارقام نرمال شده
    bool InitFailed; // برای شکست راه‌اندازی نرم
    datetime StartDate; // تاریخ شروع
    double onetick; // یک تیک نرمال شده
    bool FirstRunDone; // آیا محاسبه اول اجرا شده
    string Suffix; // پسوند نام اشیاء
    color_scheme CurrentColorScheme; // طرح رنگ فعلی
    int Max_number_of_bars_in_a_session; // حداکثر بارها در جلسه
    int Timer; // تایمر برای محدود کردن به‌روزرسانی
    bool NeedToRestartDrawing; // نیاز به بازرسم
    int CleanedUpOn; // برای جلوگیری از پاک کردن مکرر
    double ValueAreaPercentage_double; // درصد ناحیه ارزش
    datetime LastAlertTime_CandleCross, LastAlertTime_GapCross; // زمان آخرین هشدارها
    datetime LastAlertTime; // زمان آخرین هشدار
    double Close_prev; // بسته قبلی برای هشدار شکست
    int ArrowsCounter; // شمارنده پیکان‌ها
    sat_sun_solution _SaturdaySunday; // راه‌حل شنبه/یکشنبه
    session_period _Session; // نوع جلسه
    string m_FileName; // نام فایل تنظیمات

    bar_direction CurrentBarDirection; // جهت بار فعلی
    bar_direction PreviousBarDirection; // جهت بار قبلی
    bool NeedToReviewColors; // نیاز به بررسی رنگ‌ها

    int IDStartHours[4]; // ساعت شروع داخل روز
    int IDStartMinutes[4]; // دقیقه شروع
    int IDStartTime[4]; // زمان شروع
    int IDEndHours[4]; // ساعت پایان
    int IDEndMinutes[4]; // دقیقه پایان
    int IDEndTime[4]; // زمان پایان
    color_scheme IDColorScheme[4]; // طرح رنگ داخل روز
    int IntradaySessionCount; // تعداد جلسات داخل روز
    int _SessionsToCount; // تعداد جلسات برای شمارش
    int IntradayCrossSessionDefined; // جلسه کراس داخل روز

    double RememberSessionMax[]; // حداکثر جلسه
    double RememberSessionMin[]; // حداقل جلسه
    datetime RememberSessionStart[]; // شروع جلسه
    datetime RememberSessionEnd[]; // پایان جلسه
    string RememberSessionSuffix[]; // پسوند جلسه
    int SessionsNumber; // تعداد جلسات

    class CRectangleMP
    {
    private:
        datetime prev_Time0; // زمان قبلی
        double prev_High, prev_Low; // بالا و پایین قبلی
        double prev_RectanglePriceMax, prev_RectanglePriceMin; // حداکثر و حداقل قیمت قبلی مستطیل
        int Number; // شماره مستطیل
    public:
        double RectanglePriceMax, RectanglePriceMin; // حداکثر و حداقل قیمت مستطیل
        datetime RectangleTimeMax, RectangleTimeMin; // حداکثر و حداقل زمان مستطیل
        datetime t1, t2; // زمان‌ها برای پردازش
        string name; // نام مستطیل
        CRectangleMP(string);
        ~CRectangleMP(void) {};
        void Process(int, const int rates_total, CMarketProfile* parent);
        void ResetPrevTime0() { prev_Time0 = 0; }
    };
    CRectangleMP* MPR_Array[]; // آرایه مستطیل‌ها
    int mpr_total; // تعداد مستطیل‌ها
    uint LastRecalculationTime; // زمان آخرین محاسبه

    double DevelopingPOC[]; // بافر POC در حال توسعه
    double DevelopingVAH[]; // بافر VAH در حال توسعه
    double DevelopingVAL[]; // بافر VAL در حال توسعه

    string _Symbol; // نماد
    ENUM_TIMEFRAMES _Timeframe; // تایم‌فریم
    long _ChartID; // شناسه چارت

    // توابع خصوصی
    int FindSessionStart(const int n, const int rates_total);
    int FindDayStart(const int n, const int rates_total);
    int FindWeekStart(const int n, const int rates_total);
    int FindMonthStart(const int n, const int rates_total);
    int FindQuarterStart(const int n, const int rates_total);
    int FindHalfyearStart(const int n, const int rates_total);
    int FindYearStart(const int n, const int rates_total);
    int FindSessionEndByDate(const datetime date, const int rates_total);
    int FindDayEndByDate(const datetime date, const int rates_total);
    int FindWeekEndByDate(const datetime date, const int rates_total);
    int FindMonthEndByDate(const datetime date, const int rates_total);
    int FindQuarterEndByDate(const datetime date, const int rates_total);
    int FindHalfyearEndByDate(const datetime date, const int rates_total);
    int FindYearEndByDate(const datetime date, const int rates_total);
    int SameWeek(const datetime date1, const datetime date2);
    int SameMonth(const datetime date1, const datetime date2);
    int SameQuarter(const datetime date1, const datetime date2);
    int SameHalfyear(const datetime date1, const datetime date2);
    int SameYear(const datetime date1, const datetime date2);
    datetime PutDot(const double price, const int start_bar, const int range, const int bar, string rectangle_prefix = "", datetime converted_time = 0);
    void ObjectCleanup(string rectangle_prefix = "");
    bool GetHoursAndMinutes(string time_string, int& hours, int& minutes, int& time);
    bool CheckIntradaySession(const bool enable, const string start_time, const string end_time, const color_scheme cs);
    bool ProcessSession(const int sessionstart, const int sessionend, const int i, const int rates_total, CRectangleMP* rectangle = NULL);
    bool ProcessIntradaySession(int sessionstart, int sessionend, const int i, const int rates_total);
    int TimeHour(const datetime time);
    int TimeMinute(const datetime time);
    int TimeDay(const datetime time);
    int TimeDayOfWeek(const datetime time);
    int TimeDayOfYear(const datetime time);
    int TimeMonth(const datetime time);
    int TimeYear(const datetime time);
    int TimeAbsoluteDay(const datetime time);
    void CheckRays();
    void ValuePrintOut(const string obj_name, const datetime time, const double price, const string tooltip, const ENUM_ANCHOR_POINT anchor = ANCHOR_RIGHT, color value_color = 0, const int value = 0);
    color CalculateProperColor();
    void CheckRectangles(const int rates_total);
    void PutSinglePrintMark(const double price, const int sessionstart, const string rectangle_prefix);
    void RemoveSinglePrintMark(const double price, const int sessionstart, const string rectangle_prefix);
    void PutSinglePrintRay(const double price, const int sessionstart, const string rectangle_prefix, const color spr_color);
    void RemoveSinglePrintRay(const double price, const int sessionstart, const string rectangle_prefix);
    void RedrawLastSession(const int rates_total);
    void CalculateDevelopingPOCVAHVAL(const int sessionstart, const int sessionend, CRectangleMP* rectangle = NULL);
    void DistributeBetweenTwoBuffers(double &buff1[], double &buff2[], int bar, double price);
    void OnTimer();
    void CheckAlerts();
    void DeleteArrowsByPrefix(const string prefix);
    bool FindAtLeastOneArrowForRay(const string ray_name);
    void CheckHistoricalArrowsForNonMPSPRRays(const int bar_start, const string ray_name);
    void CheckAndDrawArrow(const int n, const double level, const string ray_name);
    void CreateArrowObject(const string name, const datetime time, const double price, const int code, const color colour, const int width, const string tooltip);
    void CheckRayIntersections(const string object, const int start_j);
    void InitializeOnetick();
    bool SaveSettingsOnDisk();
    bool LoadSettingsFromDisk();
    bool DeleteSettingsFile();
    int Initialize();
    void Deinitialize();
    int OnCalculateMain(const int rates_total, const int prev_calculated);
    void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam);
    void DoAlerts(const alert_types alert_type, const string object_name);

public:
    CMarketProfile(void);
    ~CMarketProfile() { Deinit(0); }

    // API عمومی
    int Init(string symbol, ENUM_TIMEFRAMES timeframe, long chartId, const CMarketProfileSettings &settings);
    void Deinit(const int reason);
    int Calculate(const int rates_total, const int prev_calculated);
    double GetPOC(const int shift = 0) const;
    double GetVAH(const int shift = 0) const;
    double GetVAL(const int shift = 0) const;
};

//+------------------------------------------------------------------+
//| سازنده                                                          |
//+------------------------------------------------------------------+
CMarketProfile::CMarketProfile(void)
{
}

//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
int CMarketProfile::Init(string symbol, ENUM_TIMEFRAMES timeframe, long chartId, const CMarketProfileSettings &settings)
{
    m_settings = settings;

    if(symbol == "" || symbol == NULL) symbol = Symbol();
    if(timeframe == PERIOD_CURRENT) timeframe = Period();
    if(chartId == 0) chartId = ChartID();

    _Symbol = symbol;
    _Timeframe = timeframe;
    _ChartID = chartId;

    m_FileName = "MP_" + IntegerToString(_ChartID) + ".txt";

    if (!LoadSettingsFromDisk())
    {
        _Session = m_settings.Session;
    }

    return Initialize();
}

//+------------------------------------------------------------------+
//| Deinit                                                           |
//+------------------------------------------------------------------+
void CMarketProfile::Deinit(const int reason)
{
    Deinitialize();

    if (reason == REASON_PARAMETERS) GlobalVariableSet("MP-" + IntegerToString(_ChartID) + "-Parameters", 1);

    if ((reason == REASON_REMOVE) || (reason == REASON_CHARTCLOSE) || (reason == REASON_PROGRAM))
    {
        DeleteSettingsFile();
    }
    else
    {
        SaveSettingsOnDisk();
    }
}

//+------------------------------------------------------------------+
//| Calculate                                                        |
//+------------------------------------------------------------------+
int CMarketProfile::Calculate(const int rates_total, const int prev_calculated)
{
    if (InitFailed)
    {
        if (!m_settings.DisableAlertsOnWrongTimeframes) Print("Initialization failed. Please see the alert message for details.");
        return 0;
    }

    if (prev_calculated == 0)
    {
        InitializeOnetick();
    }

    return OnCalculateMain(rates_total, prev_calculated);
}

//+------------------------------------------------------------------+
//| GetPOC                                                           |
//+------------------------------------------------------------------+
double CMarketProfile::GetPOC(const int shift) const
{
    if(shift < 0 || shift >= ArraySize(DevelopingPOC)) return EMPTY_VALUE;
    return DevelopingPOC[shift];
}

//+------------------------------------------------------------------+
//| GetVAH                                                           |
//+------------------------------------------------------------------+
double CMarketProfile::GetVAH(const int shift) const
{
    if(shift < 0 || shift >= ArraySize(DevelopingVAH)) return EMPTY_VALUE;
    return DevelopingVAH[shift];
}

//+------------------------------------------------------------------+
//| GetVAL                                                           |
//+------------------------------------------------------------------+
double CMarketProfile::GetVAL(const int shift) const
{
    if(shift < 0 || shift >= ArraySize(DevelopingVAL)) return EMPTY_VALUE;
    return DevelopingVAL[shift];
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
int CMarketProfile::Initialize()
{
    InitFailed = false;

    FirstRunDone = false;
    Timer = 0;
    NeedToRestartDrawing = false;
    CleanedUpOn = 0;
    LastAlertTime_CandleCross = 0;
    LastAlertTime_GapCross = 0;
    LastAlertTime = 0;
    Close_prev = EMPTY_VALUE;
    ArrowsCounter = 0;
    CurrentBarDirection = Neutral;
    PreviousBarDirection = Neutral;
    NeedToReviewColors = false;
    IntradayCrossSessionDefined = -1;
    SessionsNumber = 0;
    mpr_total = 0;
    LastRecalculationTime = 0;

    ArrayResize(RememberSessionMax, 0);
    ArrayResize(RememberSessionMin, 0);
    ArrayResize(RememberSessionStart, 0);
    ArrayResize(RememberSessionEnd, 0);
    ArrayResize(RememberSessionSuffix, 0);
    ArrayResize(MPR_Array, 0);
    ArrayResize(DevelopingPOC, iBars(_Symbol, _Timeframe));
    ArrayResize(DevelopingVAH, iBars(_Symbol, _Timeframe));
    ArrayResize(DevelopingVAL, iBars(_Symbol, _Timeframe));
    ArrayInitialize(DevelopingPOC, EMPTY_VALUE);
    ArrayInitialize(DevelopingVAH, EMPTY_VALUE);
    ArrayInitialize(DevelopingVAL, EMPTY_VALUE);

    _SessionsToCount = m_settings.SessionsToCount;
    _SaturdaySunday = m_settings.SaturdaySunday;
    if (PeriodSeconds(_Timeframe) > PeriodSeconds(PERIOD_D1)) _SaturdaySunday = Saturday_Sunday_Normal_Days;

    // بررسی تنظیمات جلسه کاربر.
    if (_Session == Daily)
    {
        Suffix = "_D";
        if ((PeriodSeconds(_Timeframe) < PeriodSeconds(PERIOD_M5)) || (PeriodSeconds(_Timeframe) > PeriodSeconds(PERIOD_M30)))
        {
            string alert_text = "تایم‌فریم باید بین M5 و M30 برای جلسه روزانه باشد.";
            if (!m_settings.DisableAlertsOnWrongTimeframes) Alert(alert_text);
            else Print("راه‌اندازی شکست خورد: " + alert_text);
            InitFailed = true;
        }
    }
    else if (_Session == Weekly)
    {
        Suffix = "_W";
        if ((PeriodSeconds(_Timeframe) < PeriodSeconds(PERIOD_M30)) || (PeriodSeconds(_Timeframe) > PeriodSeconds(PERIOD_H4)))
        {
            string alert_text = "تایم‌فریم باید بین M30 و H4 برای جلسه هفتگی باشد.";
            if (!m_settings.DisableAlertsOnWrongTimeframes) Alert(alert_text);
            else Print("راه‌اندازی شکست خورد: " + alert_text);
            InitFailed = true;
        }
    }
    else if (_Session == Monthly)
    {
        Suffix = "_M";
        if ((PeriodSeconds(_Timeframe) < PeriodSeconds(PERIOD_H1)) || (PeriodSeconds(_Timeframe) > PeriodSeconds(PERIOD_D1)))
        {
            string alert_text = "تایم‌فریم باید بین H1 و D1 برای جلسه ماهانه باشد.";
            if (!m_settings.DisableAlertsOnWrongTimeframes) Alert(alert_text);
            else Print("راه‌اندازی شکست خورد: " + alert_text);
            InitFailed = true;
        }
    }
    else if (_Session == Quarterly)
    {
        Suffix = "_Q";
        if ((PeriodSeconds(_Timeframe) < PeriodSeconds(PERIOD_H4)) || (PeriodSeconds(_Timeframe) > PeriodSeconds(PERIOD_D1)))
        {
            string alert_text = "تایم‌فریم باید بین H4 و D1 برای جلسه سه ماهه باشد.";
            if (!m_settings.DisableAlertsOnWrongTimeframes) Alert(alert_text);
            else Print("راه‌اندازی شکست خورد: " + alert_text);
            InitFailed = true;
        }
    }
    else if (_Session == Semiannual)
    {
        Suffix = "_S";
        if ((PeriodSeconds(_Timeframe) < PeriodSeconds(PERIOD_H4)) || (PeriodSeconds(_Timeframe) > PeriodSeconds(PERIOD_W1)))
        {
            string alert_text = "تایم‌فریم باید بین H4 و W1 برای جلسه شش ماهه باشد.";
            if (!m_settings.DisableAlertsOnWrongTimeframes) Alert(alert_text);
            else Print("راه‌اندازی شکست خورد: " + alert_text);
            InitFailed = true;
        }
    }
    else if (_Session == Annual)
    {
        Suffix = "_A";
        if ((PeriodSeconds(_Timeframe) < PeriodSeconds(PERIOD_H4)) || (PeriodSeconds(_Timeframe) > PeriodSeconds(PERIOD_W1)))
        {
            string alert_text = "تایم‌فریم باید بین H4 و W1 برای جلسه سالانه باشد.";
            if (!m_settings.DisableAlertsOnWrongTimeframes) Alert(alert_text);
            else Print("راه‌اندازی شکست خورد: " + alert_text);
            InitFailed = true;
        }
    }
    else if (_Session == Intraday)
    {
        if (PeriodSeconds(_Timeframe) > PeriodSeconds(PERIOD_M30))
        {
            string alert_text = "تایم‌فریم نباید بالاتر از M30 برای جلسات داخل روز باشد.";
            if (!m_settings.DisableAlertsOnWrongTimeframes) Alert(alert_text);
            else Print("راه‌اندازی شکست خورد: " + alert_text);
            InitFailed = true;
        }

        IntradaySessionCount = 0;
        if (!CheckIntradaySession(m_settings.EnableIntradaySession1, m_settings.IntradaySession1StartTime, m_settings.IntradaySession1EndTime, m_settings.IntradaySession1ColorScheme)) return INIT_PARAMETERS_INCORRECT;
        if (!CheckIntradaySession(m_settings.EnableIntradaySession2, m_settings.IntradaySession2StartTime, m_settings.IntradaySession2EndTime, m_settings.IntradaySession2ColorScheme)) return INIT_PARAMETERS_INCORRECT;
        if (!CheckIntradaySession(m_settings.EnableIntradaySession3, m_settings.IntradaySession3StartTime, m_settings.IntradaySession3EndTime, m_settings.IntradaySession3ColorScheme)) return INIT_PARAMETERS_INCORRECT;
        if (!CheckIntradaySession(m_settings.EnableIntradaySession4, m_settings.IntradaySession4StartTime, m_settings.IntradaySession4EndTime, m_settings.IntradaySession4ColorScheme)) return INIT_PARAMETERS_INCORRECT;

        if (IntradaySessionCount == 0)
        {
            string alert_text = "حداقل یک جلسه داخل روز را فعال کنید اگر می‌خواهید از حالت داخل روز استفاده کنید.";
            if (!m_settings.DisableAlertsOnWrongTimeframes) Alert(alert_text);
            else Print("راه‌اندازی شکست خورد: " + alert_text);
            InitFailed = true;
        }
    }
    else if ((_Session == Rectangle) && (m_settings.SeamlessScrollingMode))
    {
        string alert_text = "حالت اسکرول بدون درز با جلسات مستطیل کار نمی‌کند.";
        if (!m_settings.DisableAlertsOnWrongTimeframes) Alert(alert_text);
        else Print("راه‌اندازی شکست خورد: " + alert_text);
        InitFailed = true;
    }

    // نام اندیکاتور.
    //IndicatorSetString(INDICATOR_SHORTNAME, "MarketProfile " + EnumToString(_Session)); // در کتابخانه لازم نیست

    if (m_settings.PointMultiplier == 0)
    {
        double quote;
        bool success = SymbolInfoDouble(_Symbol, SYMBOL_ASK, quote);
        if (!success)
        {
            Print("دریافت قیمت شکست خورد. خطا #", GetLastError(), ". استفاده از PointMultiplier = 1.");
            PointMultiplier_calculated = 1;
        }
        else
        {
            string s = DoubleToString(quote, _Digits);
            StringReplace(s, "-", "");
            int total_digits = StringLen(s);
            if (StringFind(s, ".") != -1) total_digits--;
            if (total_digits <= 5) PointMultiplier_calculated = 1;
            else PointMultiplier_calculated = (int)MathPow(10, total_digits - 5);
        }
    }
    else PointMultiplier_calculated = m_settings.PointMultiplier;

    DigitsM = _Digits - (StringLen(IntegerToString(PointMultiplier_calculated)) - 1);
    onetick = NormalizeDouble(_Point * PointMultiplier_calculated, DigitsM);

    double TickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    if (onetick < TickSize)
    {
        DigitsM = _Digits - (StringLen(IntegerToString((int)MathRound(TickSize / _Point))) - 1);
        onetick = NormalizeDouble(TickSize, DigitsM);
    }

    CurrentColorScheme = m_settings.ColorScheme;

    ObjectCleanup();

    if ((_Session == Rectangle) || (m_settings.RightToLeft) || (m_settings.HideRaysFromInvisibleSessions) || (m_settings.SeamlessScrollingMode))
    {
        EventSetMillisecondTimer(1000);
    }

    ValueAreaPercentage_double = m_settings.ValueAreaPercentage * 0.01;

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Deinitialize                                                     |
//+------------------------------------------------------------------+
void CMarketProfile::Deinitialize()
{
    if (_Session == Rectangle)
    {
        for (int i = 0; i < mpr_total; i++)
        {
            ObjectCleanup(MPR_Array[i].name + "_");
            delete MPR_Array[i];
        }
    }
    else ObjectCleanup();
}

//+------------------------------------------------------------------+
//| OnCalculateMain                                                  |
//+------------------------------------------------------------------+
int CMarketProfile::OnCalculateMain(const int rates_total, const int prev_calculated)
{
    if ((rates_total - prev_calculated > 1) && (CleanedUpOn != rates_total))
    {
        for (int i = prev_calculated; i < rates_total; i++)
        {
            DevelopingPOC[i] = EMPTY_VALUE;
            DevelopingVAH[i] = EMPTY_VALUE;
            DevelopingVAL[i] = EMPTY_VALUE;
        }
        if ((prev_calculated == 0) && (_Session == Rectangle))
        {
            for (int i = mpr_total - 1; i >= 0 ; i--)
            {
                MPR_Array[i].ResetPrevTime0();
            }
        }
        CleanedUpOn = rates_total;
    }

    CheckAlerts();

    if (m_settings.SeamlessScrollingMode)
    {
        int last_visible_bar = (int)ChartGetInteger(_ChartID, CHART_FIRST_VISIBLE_BAR) - (int)ChartGetInteger(_ChartID, CHART_WIDTH_IN_BARS) + 1;
        if (last_visible_bar < 0) last_visible_bar = 0;
        StartDate = iTime(_Symbol, _Timeframe, last_visible_bar);
    }
    else if (m_settings.StartFromCurrentSession) StartDate = iTime(_Symbol, _Timeframe, 0);
    else StartDate = m_settings.StartFromDate;

    if (_SaturdaySunday == Ignore_Saturday_Sunday)
    {
        if (TimeDayOfWeek(StartDate) == 6) StartDate -= 86400;
        else if (TimeDayOfWeek(StartDate) == 0) StartDate -= 2 * 86400;
    }

    if ((FirstRunDone) && (StartDate != iTime(_Symbol, _Timeframe, 0))) return rates_total;

    if ((m_settings.ThrottleRedraw > 0) && (Timer > 0))
    {
        if ((int)TimeLocal() - Timer < m_settings.ThrottleRedraw) return rates_total;
    }

    if (_Session == Rectangle)
    {
        CheckRectangles(rates_total);
        Timer = (int)TimeLocal();
        return rates_total;
    }

    if ((rates_total - prev_calculated > 1) || (NeedToRestartDrawing))
    {
        FirstRunDone = false;
        ObjectCleanup();
        NeedToRestartDrawing = false;
        if (m_settings.EnableDevelopingPOC)
        {
            ArrayInitialize(DevelopingPOC, EMPTY_VALUE);
        }
        if (m_settings.EnableDevelopingVAHVAL)
        {
            ArrayInitialize(DevelopingVAH, EMPTY_VALUE);
            ArrayInitialize(DevelopingVAL, EMPTY_VALUE);
        }
    }

    int sessionend = FindSessionEndByDate(StartDate, rates_total);
    int sessionstart = FindSessionStart(sessionend, rates_total);

    if (sessionstart == -1)
    {
        Print("چیزی اشتباه شد! منتظر بارگذاری داده.");
        return prev_calculated;
    }

    int SessionToStart = 0;
    if (FirstRunDone) SessionToStart = _SessionsToCount - 1;
    else
    {
        for (int i = 1; i < _SessionsToCount; i++)
        {
            sessionend = sessionstart + 1;
            if (sessionend >= rates_total) return prev_calculated;
            if (_SaturdaySunday == Ignore_Saturday_Sunday)
            {
                while ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend)) == 0) || (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend)) == 6))
                {
                    sessionend++;
                    if (sessionend >= rates_total) break;
                }
            }
            sessionstart = FindSessionStart(sessionend, rates_total);
        }
    }

    for (int i = SessionToStart; i < _SessionsToCount; i++)
    {
        if (_Session == Intraday)
        {
            if (!ProcessIntradaySession(sessionstart, sessionend, i, rates_total)) return prev_calculated;
        }
        else
        {
            if (_Session == Daily) Max_number_of_bars_in_a_session = PeriodSeconds(PERIOD_D1) / PeriodSeconds(_Timeframe);
            else if (_Session == Weekly) Max_number_of_bars_in_a_session = 604800 / PeriodSeconds(_Timeframe);
            else if (_Session == Monthly) Max_number_of_bars_in_a_session = 2678400 / PeriodSeconds(_Timeframe);
            else if (_Session == Quarterly) Max_number_of_bars_in_a_session = 8035200 / PeriodSeconds(_Timeframe);
            else if (_Session == Semiannual) Max_number_of_bars_in_a_session = 16070400 / PeriodSeconds(_Timeframe);
            else if (_Session == Annual) Max_number_of_bars_in_a_session = 31622400 / PeriodSeconds(_Timeframe);
            if (_SaturdaySunday == Append_Saturday_Sunday)
            {
                if (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart)) == 0) Max_number_of_bars_in_a_session += (24 * 3600 - (TimeHour(iTime(_Symbol, _Timeframe, sessionstart)) * 3600 + TimeMinute(iTime(_Symbol, _Timeframe, sessionstart)) * 60)) / PeriodSeconds(_Timeframe);
                if (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend)) == 6) Max_number_of_bars_in_a_session += ((TimeHour(iTime(_Symbol, _Timeframe, sessionend)) * 3600 + TimeMinute(iTime(_Symbol, _Timeframe, sessionend)) * 60)) / PeriodSeconds(_Timeframe) + 1;
            }
            if (!ProcessSession(sessionstart, sessionend, i, rates_total)) return prev_calculated;
        }

        if (_SessionsToCount - i > 1)
        {
            sessionstart = sessionend - 1;
            if (_SaturdaySunday == Ignore_Saturday_Sunday)
            {
                while ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart)) == 0) || (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart)) == 6))
                {
                    sessionstart--;
                    if (sessionstart == 0) break;
                }
            }
            sessionend = FindSessionEndByDate(iTime(_Symbol, _Timeframe, sessionstart), rates_total);
        }
    }

    if ((m_settings.ShowValueAreaRays != None) || (m_settings.ShowMedianRays != None) || ((m_settings.HideRaysFromInvisibleSessions) && (m_settings.SinglePrintRays))) CheckRays();

    FirstRunDone = true;

    Timer = (int)TimeLocal();

    return rates_total;
}

//+------------------------------------------------------------------+
//| OnTimer                                                          |
//+------------------------------------------------------------------+
void CMarketProfile::OnTimer()
{
    if (GetTickCount() - LastRecalculationTime < 500) return;

    int rates_total = iBars(_Symbol, _Timeframe);

    if (m_settings.HideRaysFromInvisibleSessions) CheckRays();

    if (_Session == Rectangle)
    {
        if (onetick == 0) InitializeOnetick();
        CheckRectangles(rates_total);
        return;
    }

    if ((m_settings.RightToLeft && !m_settings.SeamlessScrollingMode) || !FirstRunDone) return;

    static datetime prev_converted_time = 0;
    datetime converted_time = 0;

    int dummy_subwindow;
    double dummy_price;
    ChartXYToTimePrice(_ChartID, (int)ChartGetInteger(_ChartID, CHART_WIDTH_IN_PIXELS), 0, dummy_subwindow, converted_time, dummy_price);
    if (converted_time == prev_converted_time) return;
    prev_converted_time = converted_time;

    if (m_settings.SeamlessScrollingMode)
    {
        ObjectCleanup();
        if (_Session == Intraday) FirstRunDone = false;
        if ((m_settings.EnableDevelopingPOC) || (m_settings.EnableDevelopingVAHVAL))
        {
            for (int i = 0; i < Bars(_Symbol, _Timeframe); i++)
            {
                DevelopingPOC[i] = EMPTY_VALUE;
                DevelopingVAH[i] = EMPTY_VALUE;
                DevelopingVAL[i] = EMPTY_VALUE;
            }
        }
    }

    RedrawLastSession(rates_total);

    if ((m_settings.SeamlessScrollingMode) && (_Session == Intraday)) FirstRunDone = true;

    LastRecalculationTime = GetTickCount();
    ChartRedraw(_ChartID);
}

//+------------------------------------------------------------------+
//| OnChartEvent                                                     |
//+------------------------------------------------------------------+
void CMarketProfile::OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    if (id == CHARTEVENT_KEYDOWN)
    {
        if (lparam == 82) // 'r' key pressed.
        {
            if (_Session != Rectangle) return;
            // Find the next untaken MPR name.
            for (int i = 0; i < 1000; i++) // Won't be more than 1000 rectangles anyway!
            {
                string name = "MPR" + IntegerToString(i);
                if (ObjectFind(_ChartID, name) >= 0) continue;
                // If name not found, create a new rectangle.
                // Put it in the chart center with width and height equal to half the chart.
                int pixel_width = (int)ChartGetInteger(_ChartID, CHART_WIDTH_IN_PIXELS);
                int pixel_height = (int)ChartGetInteger(_ChartID, CHART_HEIGHT_IN_PIXELS);
                int half_width = pixel_width / 2;
                int half_height = pixel_height / 2;
                int x1 = half_width / 2;
                int x2 = int(half_width * 1.5);
                int y1 = half_height / 2;
                int y2 = int(half_height * 1.5);
                int dummy_subwindow;
                datetime time1, time2;
                double price1, price2;
                ChartXYToTimePrice(_ChartID, x1, y1, dummy_subwindow, time1, price1);
                ChartXYToTimePrice(_ChartID, x2, y2, dummy_subwindow, time2, price2);
                ObjectCreate(_ChartID, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
                ObjectSetInteger(_ChartID, name, OBJPROP_SELECTABLE, true);
                ObjectSetInteger(_ChartID, name, OBJPROP_HIDDEN, false);
                ObjectSetInteger(_ChartID, name, OBJPROP_SELECTED, true);
                ObjectSetInteger(_ChartID, name, OBJPROP_FILL, false);
                break;
            }
        }
        else if ((TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0) && (lparam == 49) && (_Session != Daily)) // Ctrl+1
        {
            Print("تغییر جلسه به روزانه");
            Deinitialize();
            _Session = Daily;
            Initialize();
            OnCalculateMain(iBars(_Symbol, _Timeframe), 0);
        }
        else if ((TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0) && (lparam == 50) && (_Session != Weekly)) // Ctrl+2
        {
            Print("تغییر جلسه به هفتگی");
            Deinitialize();
            _Session = Weekly;
            Initialize();
            OnCalculateMain(iBars(_Symbol, _Timeframe), 0);
        }
        else if ((TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0) && (lparam == 51) && (_Session != Monthly)) // Ctrl+3
        {
            Print("تغییر جلسه به ماهانه");
            Deinitialize();
            _Session = Monthly;
            Initialize();
            OnCalculateMain(iBars(_Symbol, _Timeframe), 0);
        }
        else if ((TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0) && (lparam == 52) && (_Session != Quarterly)) // Ctrl+4
        {
            Print("تغییر جلسه به سه ماهه");
            Deinitialize();
            _Session = Quarterly;
            Initialize();
            OnCalculateMain(iBars(_Symbol, _Timeframe), 0);
        }
        else if ((TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0) && (lparam == 53) && (_Session != Semiannual)) // Ctrl+5
        {
            Print("تغییر جلسه به شش ماهه");
            Deinitialize();
            _Session = Semiannual;
            Initialize();
            OnCalculateMain(iBars(_Symbol, _Timeframe), 0);
        }
        else if ((TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0) && (lparam == 54) && (_Session != Annual)) // Ctrl+6
        {
            Print("تغییر جلسه به سالانه");
            Deinitialize();
            _Session = Annual;
            Initialize();
            OnCalculateMain(iBars(_Symbol, _Timeframe), 0);
        }
        else if ((TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0) && (lparam == 55) && (_Session != Intraday)) // Ctrl+7
        {
            Print("تغییر جلسه به داخل روز");
            Deinitialize();
            _Session = Intraday;
            Initialize();
            OnCalculateMain(iBars(_Symbol, _Timeframe), 0);
        }
        else if ((TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0) && (lparam == 56) && (_Session != Rectangle)) // Ctrl+8
        {
            Print("تغییر جلسه به مستطیل");
            Deinitialize();
            _Session = Rectangle;
            Initialize();
            OnCalculateMain(iBars(_Symbol, _Timeframe), 0);
        }
    }
}

//+------------------------------------------------------------------+
//| CRectangleMP                                                     |
//+------------------------------------------------------------------+
CMarketProfile::CRectangleMP::CRectangleMP(string given_name)
{
    name = given_name;
    RectanglePriceMax = -DBL_MAX;
    RectanglePriceMin = DBL_MAX;
    prev_RectanglePriceMax = -DBL_MAX;
    prev_RectanglePriceMin = DBL_MAX;
    RectangleTimeMax = 0;
    RectangleTimeMin = D'31.12.3000';
    prev_Time0 = 0;
    prev_High = -DBL_MAX;
    prev_Low = DBL_MAX;
    Number = -1;
    t1 = 0;
    t2 = 0;
}

//+------------------------------------------------------------------+
//| CheckAlerts                                                      |
//+------------------------------------------------------------------+
void CMarketProfile::CheckAlerts()
{
    if ((!m_settings.AlertNative) && (!m_settings.AlertEmail) && (!m_settings.AlertPush) && (!m_settings.AlertArrows)) return;
    if ((!m_settings.AlertForMedian) && (!m_settings.AlertForValueArea) && (!m_settings.AlertForSinglePrint)) return;
    if ((!m_settings.AlertOnPriceBreak) && (!m_settings.AlertOnCandleClose) && (!m_settings.AlertOnGapCross)) return;
    if ((m_settings.AlertCheckBar == CheckPreviousBar) && (LastAlertTime == iTime(_Symbol, _Timeframe, 0))) return;

    int obj_total = ObjectsTotal(_ChartID, -1, OBJ_TREND);
    for (int i = 0; i < obj_total; i++)
    {
        string object_name = ObjectName(_ChartID, i, -1, OBJ_TREND);

        if (!((m_settings.AlertForMedian && (StringFind(object_name, "Median Ray") > -1)) ||
              (m_settings.AlertForValueArea && ((StringFind(object_name, "Value Area HighRay") > -1) || (StringFind(object_name, "Value Area LowRay") > -1))) ||
              (m_settings.AlertForSinglePrint && (StringFind(object_name, "MPSPR") > -1) && ((color)ObjectGetInteger(_ChartID, object_name, OBJPROP_COLOR) != clrNONE)))) continue;

        double level = NormalizeDouble(ObjectGetDouble(_ChartID, object_name, OBJPROP_PRICE, 0), _Digits);

        if (m_settings.AlertCheckBar == CheckCurrentBar)
        {
            if (m_settings.AlertOnPriceBreak)
            {
                if ((Close_prev != EMPTY_VALUE) && (((iClose(_Symbol, _Timeframe, 0) >= level) && (Close_prev < level)) || ((iClose(_Symbol, _Timeframe, 0) <= level) && (Close_prev > level))))
                {
                    DoAlerts(PriceBreak, object_name);
                    if (m_settings.AlertArrows) CreateArrowObject("ArrPB" + object_name, iTime(_Symbol, _Timeframe, 0), iClose(_Symbol, _Timeframe, 0), m_settings.AlertArrowCodePB, m_settings.AlertArrowColorPB, m_settings.AlertArrowWidthPB, "شکست قیمت");
                }
                Close_prev = iClose(_Symbol, _Timeframe, 0);
            }
            if (m_settings.AlertOnCandleClose)
            {
                if (((iClose(_Symbol, _Timeframe, 0) >= level) && (iClose(_Symbol, _Timeframe, 1) < level)) || ((iClose(_Symbol, _Timeframe, 0) <= level) && (iClose(_Symbol, _Timeframe, 1) > level)))
                {
                    DoAlerts(CandleCloseCrossover, object_name);
                    if (m_settings.AlertArrows) CreateArrowObject("ArrCC" + object_name, iTime(_Symbol, _Timeframe, 0), iClose(_Symbol, _Timeframe, 0), m_settings.AlertArrowCodeCC, m_settings.AlertArrowColorCC, m_settings.AlertArrowWidthCC, "عبور بسته شدن شمع");
                }
            }
            if (m_settings.AlertOnGapCross)
            {
                if (((iOpen(_Symbol, _Timeframe, 0) > level) && (iHigh(_Symbol, _Timeframe, 1) < level)) || ((iOpen(_Symbol, _Timeframe, 0) < level) && (iLow(_Symbol, _Timeframe, 1) > level)))
                {
                    DoAlerts(GapCrossover, object_name);
                    if (m_settings.AlertArrows) CreateArrowObject("ArrGC" + object_name, iTime(_Symbol, _Timeframe, 0), level, m_settings.AlertArrowCodeGC, m_settings.AlertArrowColorGC, m_settings.AlertArrowWidthGC, "عبور شکاف");
                }
            }
        }
        else
        {
            if (m_settings.AlertOnPriceBreak)
            {
                if (((iHigh(_Symbol, _Timeframe, 1) >= level) && (iClose(_Symbol, _Timeframe, 1) < level) && (iClose(_Symbol, _Timeframe, 2) < level)) || ((iLow(_Symbol, _Timeframe, 1) <= level) && (iClose(_Symbol, _Timeframe, 1) > level) && (iClose(_Symbol, _Timeframe, 2) > level)))
                {
                    DoAlerts(PriceBreak, object_name);
                    if (m_settings.AlertArrows) CreateArrowObject("ArrPB" + object_name, iTime(_Symbol, _Timeframe, 1), iClose(_Symbol, _Timeframe, 1), m_settings.AlertArrowCodePB, m_settings.AlertArrowColorPB, m_settings.AlertArrowWidthPB, "شکست قیمت");
                }
            }
            if (m_settings.AlertOnCandleClose)
            {
                if (((iClose(_Symbol, _Timeframe, 1) >= level) && (iClose(_Symbol, _Timeframe, 2) < level)) || ((iClose(_Symbol, _Timeframe, 1) <= level) && (iClose(_Symbol, _Timeframe, 2) > level)))
                {
                    DoAlerts(CandleCloseCrossover, object_name);
                    if (m_settings.AlertArrows) CreateArrowObject("ArrCC" + object_name, iTime(_Symbol, _Timeframe, 1), iClose(_Symbol, _Timeframe, 1), m_settings.AlertArrowCodeCC, m_settings.AlertArrowColorCC, m_settings.AlertArrowWidthCC, "عبور بسته شدن شمع");
                }
            }
            if (m_settings.AlertOnGapCross)
            {
                if (((iLow(_Symbol, _Timeframe, 1) > level) && (iHigh(_Symbol, _Timeframe, 2) < level)) || ((iLow(_Symbol, _Timeframe, 2) > level) && (iHigh(_Symbol, _Timeframe, 1) < level)))
                {
                    DoAlerts(GapCrossover, object_name);
                    if (m_settings.AlertArrows) CreateArrowObject("ArrGC" + object_name, iTime(_Symbol, _Timeframe, 1), level, m_settings.AlertArrowCodeGC, m_settings.AlertArrowColorGC, m_settings.AlertArrowWidthGC, "عبور شکاف");
                }
            }
            LastAlertTime = iTime(_Symbol, _Timeframe, 0);
        }
    }
}

//+------------------------------------------------------------------+
//| DoAlerts                                                         |
//+------------------------------------------------------------------+
void CMarketProfile::DoAlerts(const alert_types alert_type, const string object_name)
{
    if ((alert_type == CandleCloseCrossover) && (m_settings.AlertCheckBar == CheckCurrentBar) && (TimeCurrent() <= LastAlertTime_CandleCross)) return;

    if ((alert_type == GapCrossover) && (m_settings.AlertCheckBar == CheckCurrentBar) && (TimeCurrent() <= LastAlertTime_GapCross)) return;

    string Subject = "پروفایل بازار: " + _Symbol + " " + EnumToString(alert_type) + " روی " + object_name;

    if (m_settings.AlertNative)
    {
        string AlertText = Subject;
        Alert(AlertText);
    }
    if (m_settings.AlertEmail)
    {
        string EmailSubject = Subject;
        string EmailBody = AccountInfoString(ACCOUNT_COMPANY) + " - " + AccountInfoString(ACCOUNT_NAME) + " - " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "\r\n\r\n" + Subject;
        if (!SendMail(EmailSubject, EmailBody)) Print("خطا در ارسال ایمیل: " + IntegerToString(GetLastError()) + ".");
    }
    if (m_settings.AlertPush)
    {
        string AppText = Subject;
        if (!SendNotification(AppText)) Print("خطا در ارسال نوتیفیکیشن: " + IntegerToString(GetLastError()) + ".");
    }

    if ((alert_type == CandleCloseCrossover) && (m_settings.AlertCheckBar == CheckCurrentBar)) LastAlertTime_CandleCross = TimeCurrent();
    else if ((alert_type == GapCrossover) && (m_settings.AlertCheckBar == CheckCurrentBar)) LastAlertTime_GapCross = TimeCurrent();
}

//+------------------------------------------------------------------+
//| InitializeOnetick                                               |
//+------------------------------------------------------------------+
void CMarketProfile::InitializeOnetick()
{
    if (m_settings.PointMultiplier == 0)
    {
        double quote;
        bool success = SymbolInfoDouble(_Symbol, SYMBOL_ASK, quote);
        if (!success)
        {
            Print("دریافت قیمت شکست خورد. خطا #", GetLastError(), ". استفاده از PointMultiplier = 1.");
            PointMultiplier_calculated = 1;
        }
        else
        {
            double chart_height = (double)ChartGetInteger(_ChartID, CHART_HEIGHT_IN_PIXELS);
            double chart_price_max = ChartGetDouble(_ChartID, CHART_PRICE_MAX);
            double chart_price_min = ChartGetDouble(_ChartID, CHART_PRICE_MIN);
            double price_diff = chart_price_max - chart_price_min;
            if ((chart_height == 0) || (price_diff <= 0))
            {
                string s = DoubleToString(quote, _Digits);
                int total_digits = StringLen(s);
                if (StringFind(s, ".") != -1) total_digits--;
                if (total_digits <= 5) PointMultiplier_calculated = 1;
                else PointMultiplier_calculated = (int)MathPow(10, total_digits - 5);
            }
            else
            {
                double price_per_pixel = price_diff / chart_height;
                PointMultiplier_calculated = (int)MathRound(price_per_pixel / _Point);
            }
        }
    }
    else PointMultiplier_calculated = m_settings.PointMultiplier;

    DigitsM = _Digits - (StringLen(IntegerToString(PointMultiplier_calculated)) - 1);
    onetick = NormalizeDouble(_Point * PointMultiplier_calculated, DigitsM);

    double TickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    if (onetick < TickSize)
    {
        DigitsM = _Digits - (StringLen(IntegerToString((int)MathRound(TickSize / _Point))) - 1);
        onetick = NormalizeDouble(TickSize, DigitsM);
    }
}

//+------------------------------------------------------------------+
//| SaveSettingsOnDisk                                               |
//+------------------------------------------------------------------+
bool CMarketProfile::SaveSettingsOnDisk()
{
    int fh = FileOpen("MP_Settings\\" + m_FileName, FILE_CSV | FILE_WRITE);
    if (fh == INVALID_HANDLE)
    {
        Print("باز کردن فایل برای نوشتن شکست خورد: MP_Settings\\" + m_FileName + ". خطا: " + IntegerToString(GetLastError()));
        return false;
    }

    FileWrite(fh, "Session");
    FileWrite(fh, IntegerToString(_Session));

    if (GlobalVariableGet("MP-" + IntegerToString(_ChartID) + "-Parameters") > 0)
    {
        FileWrite(fh, "Parameter_Session");
        FileWrite(fh, IntegerToString(m_settings.Session));
    }

    FileClose(fh);

    Print("تنظیمات در فایل ذخیره شد.");
    return true;
}

//+------------------------------------------------------------------+
//| LoadSettingsFromDisk                                             |
//+------------------------------------------------------------------+
bool CMarketProfile::LoadSettingsFromDisk()
{
    int fh;

    if (FileIsExist("MP_Settings\\" + m_FileName))
    {
        fh = FileOpen("MP_Settings\\" + m_FileName, FILE_CSV | FILE_READ);
        if (fh == INVALID_HANDLE)
        {
            Print("باز کردن فایل برای خواندن شکست خورد: MP_Settings\\" + m_FileName + ". خطا: " + IntegerToString(GetLastError()));
            return false;
        }
    }
    else return false;

    while (!FileIsEnding(fh))
    {
        string var_name = FileReadString(fh);
        string var_content = FileReadString(fh);
        if (var_name == "Session")
            _Session = (session_period)StringToInteger(var_content);
        else if (GlobalVariableGet("MP-" + IntegerToString(_ChartID) + "-Parameters") > 0)
        {
            if (var_name == "Parameter_Session")
            {
                if ((session_period)StringToInteger(var_content) != m_settings.Session) _Session = m_settings.Session;
            }
        }
    }

    FileClose(fh);
    Print("تنظیمات از فایل بارگذاری شد.");

    if (GlobalVariableGet("MP-" + IntegerToString(_ChartID) + "-Parameters") > 0) GlobalVariableDel("MP-" + IntegerToString(_ChartID) + "-Parameters");

    return true;
}

//+------------------------------------------------------------------+
//| DeleteSettingsFile                                               |
//+------------------------------------------------------------------+
bool CMarketProfile::DeleteSettingsFile()
{
    string fn_with_path = "MP_Settings\\" + m_FileName;
    if (!FileIsExist(fn_with_path)) return false;
    if (!FileDelete(fn_with_path))
    {
        Print("حذف فایل تنظیمات شکست خورد: " + m_FileName + ". خطا: " + IntegerToString(GetLastError()));
        return false;
    }
    Print("فایل تنظیمات حذف شد.");
    return true;
}

//+------------------------------------------------------------------+
//| TimeHour                                                         |
//+------------------------------------------------------------------+
int CMarketProfile::TimeHour(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.hour;
}

//+------------------------------------------------------------------+
//| TimeMinute                                                       |
//+------------------------------------------------------------------+
int CMarketProfile::TimeMinute(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.min;
}

//+------------------------------------------------------------------+
//| TimeDay                                                          |
//+------------------------------------------------------------------+
int CMarketProfile::TimeDay(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.day;
}

//+------------------------------------------------------------------+
//| TimeDayOfWeek                                                    |
//+------------------------------------------------------------------+
int CMarketProfile::TimeDayOfWeek(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.day_of_week;
}

//+------------------------------------------------------------------+
//| TimeDayOfYear                                                    |
//+------------------------------------------------------------------+
int CMarketProfile::TimeDayOfYear(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.day_of_year;
}

//+------------------------------------------------------------------+
//| TimeMonth                                                        |
//+------------------------------------------------------------------+
int CMarketProfile::TimeMonth(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.mon;
}

//+------------------------------------------------------------------+
//| TimeYear                                                         |
//+------------------------------------------------------------------+
int CMarketProfile::TimeYear(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.year;
}

//+------------------------------------------------------------------+
//| TimeAbsoluteDay                                                  |
//+------------------------------------------------------------------+
int CMarketProfile::TimeAbsoluteDay(const datetime time)
{
    return ((int)time / 86400);
}

//+------------------------------------------------------------------+
//| CheckRays                                                        |
//+------------------------------------------------------------------+
void CMarketProfile::CheckRays()
{
    for (int i = 0; i < SessionsNumber; i++)
    {
        string last_name = " " + TimeToString(RememberSessionStart[i]);
        string suffix = RememberSessionSuffix[i];
        string rec_name = "";

        if (_Session == Rectangle) rec_name = MPR_Array[i].name + "_";

        // Process single print rays to hide those that should not be visible.
        if ((m_settings.HideRaysFromInvisibleSessions) && (m_settings.SinglePrintRays))
        {
            int obj_total = ObjectsTotal(_ChartID, 0, OBJ_TREND);
            for (int j = 0; j < obj_total; j++)
            {
                string obj_name = ObjectName(_ChartID, j, 0, OBJ_TREND);
                if (StringSubstr(obj_name, 0, StringLen(rec_name + "MPSPR" + suffix + last_name)) != rec_name + "MPSPR" + suffix + last_name) continue; // Not a single print ray.
                if (iTime(_Symbol, _Timeframe, (int)ChartGetInteger(_ChartID, CHART_FIRST_VISIBLE_BAR)) >= RememberSessionStart[i]) // Too old.
                {
                    ObjectSetInteger(_ChartID, obj_name, OBJPROP_COLOR, clrNONE); // Hide.
                }
                else {ObjectSetInteger(_ChartID, obj_name, OBJPROP_COLOR, m_settings.SinglePrintColor);} // Unhide.
            }
        }

        // If median rays should be created for the given trading session:
        if (((m_settings.ShowMedianRays == AllPrevious) && (SessionsNumber - i >= 2)) ||
            (((m_settings.ShowMedianRays == Previous) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i == 2)) ||
            (((m_settings.ShowMedianRays == Current) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i == 1)) ||
            (m_settings.ShowMedianRays == All))
        {
            double median_price = ObjectGetDouble(_ChartID, rec_name + "Median" + suffix + last_name, OBJPROP_PRICE, 0);
            datetime median_time = (datetime)ObjectGetInteger(_ChartID, rec_name + "Median" + suffix + last_name, OBJPROP_TIME, 1);

            // Create rays only if the median doesn't end behind the screen's left edge.
            if (!((m_settings.HideRaysFromInvisibleSessions) && (iTime(_Symbol, _Timeframe, (int)ChartGetInteger(_ChartID, CHART_FIRST_VISIBLE_BAR)) >= median_time)))
            {
                // Draw new median ray.
                if (ObjectFind(_ChartID, rec_name + "Median Ray" + suffix + last_name) < 0)
                {
                    ObjectCreate(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJ_TREND, 0, RememberSessionStart[i], median_price, median_time, median_price);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_COLOR, m_settings.MedianColor);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_STYLE, m_settings.MedianRayStyle);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_WIDTH, m_settings.MedianRayWidth);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_BACK, false);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_SELECTABLE, false);
                    if ((m_settings.RightToLeft) && (i == SessionsNumber - 1) && (_Session != Rectangle))
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_LEFT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_RIGHT, false);
                    }
                    else
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_LEFT, false);
                    }
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_HIDDEN, true);
                    ObjectSetString(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_TOOLTIP, "اشعه میانه");
                }
                else
                {
                    ObjectMove(_ChartID, rec_name + "Median Ray" + suffix + last_name, 0, RememberSessionStart[i], median_price);
                    ObjectMove(_ChartID, rec_name + "Median Ray" + suffix + last_name, 1, median_time, median_price);
                }
            }
            else ObjectDelete(_ChartID, rec_name + "Median Ray" + suffix + last_name); // Delete a ray that starts from behind the screen.
        }

        // Should also delete obsolete rays that should not exist anymore.
        if ((((m_settings.ShowMedianRays == Previous) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i > 2)) ||
            ((m_settings.ShowMedianRays == Current) && (SessionsNumber - i > 1)))
        {
            ObjectDelete(_ChartID, rec_name + "Median Ray" + suffix + last_name);
        }

        // If value area rays should be created for the given trading session:
        if (((m_settings.ShowValueAreaRays == AllPrevious) && (SessionsNumber - i >= 2)) ||
            (((m_settings.ShowValueAreaRays == Previous) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i == 2)) ||
            (((m_settings.ShowValueAreaRays == Current) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i == 1)) ||
            (m_settings.ShowValueAreaRays == All))
        {
            double va_high_price = ObjectGetDouble(_ChartID, rec_name + "VA_Top" + suffix + last_name, OBJPROP_PRICE, 0);
            double va_low_price = ObjectGetDouble(_ChartID, rec_name + "VA_Bottom" + suffix + last_name, OBJPROP_PRICE, 0);
            datetime va_time = (datetime)ObjectGetInteger(_ChartID, rec_name + "VA_Top" + suffix + last_name, OBJPROP_TIME, 1);
            // Create rays only if the value area doesn't end behind the screen's left edge.
            if (!((m_settings.HideRaysFromInvisibleSessions) && (iTime(_Symbol, _Timeframe, (int)ChartGetInteger(_ChartID, CHART_FIRST_VISIBLE_BAR)) >= va_time)))
            {
                // Draw new value area high ray.
                if (ObjectFind(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name) < 0)
                {
                    ObjectCreate(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJ_TREND, 0, RememberSessionStart[i], va_high_price, va_time, va_high_price);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_COLOR, m_settings.ValueAreaHighLowColor);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_STYLE, m_settings.ValueAreaRayHighLowStyle);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_WIDTH, m_settings.ValueAreaRayHighLowWidth);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_BACK, false);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_SELECTABLE, false);
                    if ((m_settings.RightToLeft) && (i == SessionsNumber - 1) && (_Session != Rectangle))
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_LEFT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_RIGHT, false);
                    }
                    else
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_LEFT, false);
                    }
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_HIDDEN, true);
                    ObjectSetString(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_TOOLTIP, "اشعه بالای ناحیه ارزش");
                }
                else
                {
                    ObjectMove(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, 0, RememberSessionStart[i], va_high_price);
                    ObjectMove(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, 1, va_time, va_high_price);
                }

                // Draw new value area low ray.
                if (ObjectFind(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name) < 0)
                {
                    ObjectCreate(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJ_TREND, 0, RememberSessionStart[i], va_low_price, va_time, va_low_price);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_COLOR, m_settings.ValueAreaHighLowColor);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_STYLE, m_settings.ValueAreaRayHighLowStyle);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_WIDTH, m_settings.ValueAreaRayHighLowWidth);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_BACK, false);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_SELECTABLE, false);
                    if ((m_settings.RightToLeft) && (i == SessionsNumber - 1) && (_Session != Rectangle))
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_LEFT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_RIGHT, false);
                    }
                    else
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_LEFT, false);
                    }
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_HIDDEN, true);
                    ObjectSetString(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_TOOLTIP, "اشعه پایین ناحیه ارزش");
                }
                else
                {
                    ObjectMove(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, 0, RememberSessionStart[i], va_low_price);
                    ObjectMove(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, 1, va_time, va_low_price);
                }
            }
            else
            {
                ObjectDelete(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name);
                ObjectDelete(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name);
            }
        }

        // Should also delete obsolete rays that should not exist anymore.
        if ((((m_settings.ShowValueAreaRays == Previous) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i > 2)) ||
            ((m_settings.ShowValueAreaRays == Current) && (SessionsNumber - i > 1)))
        {
            ObjectDelete(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name);
            ObjectDelete(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name);
        }

        // Ray intersections.
        if (m_settings.RaysUntilIntersection != Stop_No_Rays)
        {
            if ((((m_settings.ShowMedianRays == Previous) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i == 2)) || (((m_settings.ShowMedianRays == AllPrevious) || (m_settings.ShowMedianRays == All)) && (SessionsNumber - i >= 2)))
            {
                if ((m_settings.RaysUntilIntersection == Stop_All_Rays)
                        || ((m_settings.RaysUntilIntersection == Stop_All_Rays_Except_Prev_Session) && (SessionsNumber - i > 2))
                        || ((m_settings.RaysUntilIntersection == Stop_Only_Previous_Session) && (SessionsNumber - i == 2)))
                    CheckRayIntersections(rec_name + "Median Ray" + suffix + last_name, i + 1);
            }
            if ((((m_settings.ShowValueAreaRays == Previous) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i == 2)) || (((m_settings.ShowValueAreaRays == AllPrevious) || (m_settings.ShowValueAreaRays == All)) && (SessionsNumber - i >= 2)))
            {
                if ((m_settings.RaysUntilIntersection == Stop_All_Rays)
                        || ((m_settings.RaysUntilIntersection == Stop_All_Rays_Except_Prev_Session) && (SessionsNumber - i > 2))
                        || ((m_settings.RaysUntilIntersection == Stop_Only_Previous_Session) && (SessionsNumber - i == 2)))
                {
                    CheckRayIntersections(rec_name + "Value Area HighRay" + suffix + last_name, i + 1);
                    CheckRayIntersections(rec_name + "Value Area LowRay" + suffix + last_name, i + 1);
                }
            }
        }

        if (m_settings.AlertArrows)
        {
            int bar_start = iBarShift(_Symbol, _Timeframe, RememberSessionEnd[i]) - 1;

            if (m_settings.AlertForSinglePrint)
            {
                int obj_total = ObjectsTotal(_ChartID, 0, OBJ_TREND);
                for (int j = 0; j < obj_total; j++)
                {
                    string obj_name = ObjectName(_ChartID, j, 0, OBJ_TREND);
                    string obj_prefix = rec_name + "MPSPR" + suffix + last_name;
                    if (StringSubstr(obj_name, 0, StringLen(obj_prefix)) != obj_prefix) continue;
                    if ((color)ObjectGetInteger(_ChartID, obj_name, OBJPROP_COLOR) != clrNONE)
                    {
                        if (!FindAtLeastOneArrowForRay(obj_prefix))
                        {
                            for (int k = bar_start; k >= 0; k--)
                            {
                                CheckAndDrawArrow(k, ObjectGetDouble(_ChartID, obj_name, OBJPROP_PRICE, 0), obj_prefix);
                            }
                        }
                    }
                    else
                    {
                        DeleteArrowsByPrefix(obj_prefix);
                    }
                }
            }

            if (m_settings.AlertForValueArea)
            {
                string obj_prefix = rec_name + "Value Area HighRay" + suffix + last_name;
                if (ObjectFind(_ChartID, obj_prefix) >= 0)
                {
                    if (!FindAtLeastOneArrowForRay(obj_prefix)) CheckHistoricalArrowsForNonMPSPRRays(bar_start, obj_prefix);
                }
                else
                {
                    DeleteArrowsByPrefix(obj_prefix);
                }

                obj_prefix = rec_name + "Value Area LowRay" + suffix + last_name;
                if (ObjectFind(_ChartID, obj_prefix) >= 0)
                {
                    if (!FindAtLeastOneArrowForRay(obj_prefix)) CheckHistoricalArrowsForNonMPSPRRays(bar_start, obj_prefix);
                }
                else
                {
                    DeleteArrowsByPrefix(obj_prefix);
                }
            }

            if (m_settings.AlertForMedian)
            {
                string obj_prefix = rec_name + "Median Ray" + suffix + last_name;
                if (ObjectFind(_ChartID, obj_prefix) >= 0)
                {
                    if (!FindAtLeastOneArrowForRay(obj_prefix)) CheckHistoricalArrowsForNonMPSPRRays(bar_start, obj_prefix);
                }
                else
                {
                    DeleteArrowsByPrefix(obj_prefix);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| DeleteArrowsByPrefix                                             |
//+------------------------------------------------------------------+
void CMarketProfile::DeleteArrowsByPrefix(const string prefix)
{
    ObjectsDeleteAll(_ChartID, "ArrPB" + prefix, 0, OBJ_ARROW);
    ObjectsDeleteAll(_ChartID, "ArrCC" + prefix, 0, OBJ_ARROW);
    ObjectsDeleteAll(_ChartID, "ArrGC" + prefix, 0, OBJ_ARROW);
}

//+------------------------------------------------------------------+
//| FindAtLeastOneArrowForRay                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::FindAtLeastOneArrowForRay(const string ray_name)
{
    int objects_total = ObjectsTotal(_ChartID, 0, OBJ_ARROW);
    for (int i = 0; i < objects_total; i++)
    {
        string obj_name = ObjectName(_ChartID, i, 0, OBJ_ARROW);
        if (StringFind(obj_name, ray_name) != -1) return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| CheckHistoricalArrowsForNonMPSPRRays                             |
//+------------------------------------------------------------------+
void CMarketProfile::CheckHistoricalArrowsForNonMPSPRRays(const int bar_start, const string ray_name)
{
    int end_bar = 0;
    if (ObjectGetInteger(_ChartID, ray_name, OBJPROP_RAY_RIGHT) != true)
    {
        datetime end_time = (datetime)ObjectGetInteger(_ChartID, ray_name, OBJPROP_TIME, 1);
        end_bar = iBarShift(_Symbol, _Timeframe, end_time) + 1;
    }
    for (int k = bar_start; k >= end_bar; k--)
    {
        CheckAndDrawArrow(k, ObjectGetDouble(_ChartID, ray_name, OBJPROP_PRICE, 0), ray_name);
    }
}

//+------------------------------------------------------------------+
//| CheckAndDrawArrow                                                |
//+------------------------------------------------------------------+
void CMarketProfile::CheckAndDrawArrow(const int n, const double level, const string ray_name)
{
    if (m_settings.AlertOnPriceBreak)
    {
        if (((iHigh(_Symbol, _Timeframe, n) >= level) && (iClose(_Symbol, _Timeframe, n) < level) && (iClose(_Symbol, _Timeframe, n + 1) < level)) || ((iLow(_Symbol, _Timeframe, n) <= level) && (iClose(_Symbol, _Timeframe, n) > level) && (iClose(_Symbol, _Timeframe, n + 1) > level)))
        {
            string obj_name = "ArrPB" + ray_name;
            CreateArrowObject(obj_name, iTime(_Symbol, _Timeframe, n), iClose(_Symbol, _Timeframe, n), m_settings.AlertArrowCodePB, m_settings.AlertArrowColorPB, m_settings.AlertArrowWidthPB, "شکست قیمت");
        }
    }
    if (m_settings.AlertOnCandleClose)
    {
        if (((iClose(_Symbol, _Timeframe, n) >= level) && (iClose(_Symbol, _Timeframe, n + 1) < level)) || ((iClose(_Symbol, _Timeframe, n) <= level) && (iClose(_Symbol, _Timeframe, n + 1) > level)))
        {
            string obj_name = "ArrCC" + ray_name;
            CreateArrowObject(obj_name, iTime(_Symbol, _Timeframe, n), iClose(_Symbol, _Timeframe, n), m_settings.AlertArrowCodeCC, m_settings.AlertArrowColorCC, m_settings.AlertArrowWidthCC, "عبور بسته شدن شمع");
        }
    }
    if (m_settings.AlertOnGapCross)
    {
        if (((iLow(_Symbol, _Timeframe, n) > level) && (iHigh(_Symbol, _Timeframe, n + 1) < level)) || ((iLow(_Symbol, _Timeframe, n + 1) > level) && (iHigh(_Symbol, _Timeframe, n) < level)))
        {
            string obj_name = "ArrGC" + ray_name;
            CreateArrowObject(obj_name, iTime(_Symbol, _Timeframe, n), level, m_settings.AlertArrowCodeGC, m_settings.AlertArrowColorGC, m_settings.AlertArrowWidthGC, "عبور شکاف");
        }
    }
}

//+------------------------------------------------------------------+
//| CreateArrowObject                                                |
//+------------------------------------------------------------------+
void CMarketProfile::CreateArrowObject(const string name, const datetime time, const double price, const int code, const color colour, const int width, const string tooltip)
{
    string obj_name = name + IntegerToString(ArrowsCounter);
    ArrowsCounter++;
    ObjectCreate(_ChartID, obj_name, OBJ_ARROW, 0, time, price);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_ARROWCODE, code);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_COLOR, colour);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_WIDTH, width);
    ObjectSetString(_ChartID, obj_name, OBJPROP_TOOLTIP, tooltip);
}

//+------------------------------------------------------------------+
//| CheckRayIntersections                                            |
//+------------------------------------------------------------------+
void CMarketProfile::CheckRayIntersections(const string object, const int start_j)
{
    if (ObjectFind(_ChartID, object) < 0) return;

    double price = ObjectGetDouble(_ChartID, object, OBJPROP_PRICE, 0);
    for (int j = start_j; j < SessionsNumber; j++)
    {
        if ((price <= RememberSessionMax[j]) && (price >= RememberSessionMin[j]))
        {
            ObjectSetInteger(_ChartID, object, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(_ChartID, object, OBJPROP_TIME, 1, RememberSessionStart[j]);
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| CalculateDevelopingPOCVAHVAL                                     |
//+------------------------------------------------------------------+
void CMarketProfile::CalculateDevelopingPOCVAHVAL(const int sessionstart, const int sessionend, CRectangleMP* rectangle)
{
    for (int max_bar = sessionstart; max_bar >= sessionend; max_bar--)
    {
        if ((DevelopingPOC[max_bar] != EMPTY_VALUE) && (max_bar > 1)) continue;

        double LocalMin =  iLow(_Symbol, _Timeframe, iLowest(_Symbol, _Timeframe, MODE_LOW,  sessionstart - max_bar + 1, max_bar));
        double LocalMax = iHigh(_Symbol, _Timeframe, iHighest(_Symbol, _Timeframe, MODE_HIGH, sessionstart - max_bar + 1, max_bar));

        if (_Session == Rectangle)
        {
            if (LocalMax > rectangle->RectanglePriceMax) LocalMax = NormalizeDouble(rectangle->RectanglePriceMax, DigitsM);
            if (LocalMin < rectangle->RectanglePriceMin) LocalMin = NormalizeDouble(rectangle->RectanglePriceMin, DigitsM);
        }

        double DistanceToCenter = DBL_MAX;
        int DevMaxRange = 0;
        double PriceOfMaxRange = EMPTY_VALUE;

        int TotalTPO = 0;
        int TPOperPrice[];
        int max = (int)MathRound((LocalMax - LocalMin) / onetick + 2);
        ArrayResize(TPOperPrice, max);
        ArrayInitialize(TPOperPrice, 0);

        for (double price = LocalMax; price >= LocalMin; price -= onetick)
        {
            price = NormalizeDouble(price, DigitsM);
            int range = 0;
            for (int bar = sessionstart; bar >= max_bar; bar--)
            {
                if ((price >= iLow(_Symbol, _Timeframe, bar)) && (price <= iHigh(_Symbol, _Timeframe, bar)))
                {
                    if ((DevMaxRange < range) || ((DevMaxRange == range) && (MathAbs(price - (LocalMin + (LocalMax - LocalMin) / 2)) < DistanceToCenter)))
                    {
                        DevMaxRange = range;
                        PriceOfMaxRange = price;
                        DistanceToCenter = MathAbs(price - (LocalMin + (LocalMax - LocalMin) / 2));
                    }
                    int index = (int)MathRound((price - LocalMin) / onetick);
                    TPOperPrice[index]++;
                    TotalTPO++;
                    range++;
                }
            }
        }
        if (m_settings.EnableDevelopingVAHVAL)
        {
            double TotalTPOdouble = TotalTPO;
            int ValueControlTPO = (int)MathRound(TotalTPOdouble * ValueAreaPercentage_double);
            int index = (int)((PriceOfMaxRange - LocalMin) / onetick);
            if (index < 0) continue;
            int TPOcount = TPOperPrice[index];

            int up_offset = 1;
            int down_offset = 1;
            while (TPOcount < ValueControlTPO)
            {
                double abovePrice = PriceOfMaxRange + up_offset * onetick;
                double belowPrice = PriceOfMaxRange - down_offset * onetick;
                index = (int)MathRound((abovePrice - LocalMin) / onetick);
                int index2 = (int)MathRound((belowPrice - LocalMin) / onetick);
                if (((belowPrice < LocalMin) || (TPOperPrice[index] >= TPOperPrice[index2])) && (abovePrice <= LocalMax))
                {
                    TPOcount += TPOperPrice[index];
                    up_offset++;
                }
                else if (belowPrice >= LocalMin)
                {
                    TPOcount += TPOperPrice[index2];
                    down_offset++;
                }
                else if (TPOcount < ValueControlTPO)
                {
                    break;
                }
            }
            DevelopingVAH[max_bar] = PriceOfMaxRange + up_offset * onetick;
            DevelopingVAL[max_bar] = PriceOfMaxRange - down_offset * onetick + onetick;
        }
        if (m_settings.EnableDevelopingPOC) DevelopingPOC[max_bar] = PriceOfMaxRange;
    }
}

//+------------------------------------------------------------------+
//| DistributeBetweenTwoBuffers                                      |
//+------------------------------------------------------------------+
void CMarketProfile::DistributeBetweenTwoBuffers(double &buff1[], double &buff2[], int bar, double price)
{
    if ((buff1[bar + 1] == EMPTY_VALUE) && (buff2[bar + 1] == EMPTY_VALUE))
    {
        buff1[bar] = price;
        buff2[bar] = EMPTY_VALUE;
    }
    else if (buff1[bar + 1] != EMPTY_VALUE)
    {
        if (buff1[bar + 1] != price)
        {
            buff2[bar] = price;
            buff1[bar] = EMPTY_VALUE;
        }    
        else
        {
            buff1[bar] = price;
            buff2[bar] = EMPTY_VALUE;
        }
    }
    else
    {
        if (buff2[bar + 1] != price)
        {
            buff1[bar] = price;
            buff2[bar] = EMPTY_VALUE;
        }
        else
        {
            buff2[bar] = price;
            buff1[bar] = EMPTY_VALUE;
        }
    }
}

//+------------------------------------------------------------------+
//| OnTimer                                                          |
//+------------------------------------------------------------------+
void CMarketProfile::OnTimer()
{
    if (GetTickCount() - LastRecalculationTime < 500) return;

    int rates_total = iBars(_Symbol, _Timeframe);

    if (m_settings.HideRaysFromInvisibleSessions) CheckRays();

    if (_Session == Rectangle)
    {
        if (onetick == 0) InitializeOnetick();
        CheckRectangles(rates_total);
        return;
    }

    if ((m_settings.RightToLeft && !m_settings.SeamlessScrollingMode) || !FirstRunDone) return;

    static datetime prev_converted_time = 0;
    datetime converted_time = 0;

    int dummy_subwindow;
    double dummy_price;
    ChartXYToTimePrice(_ChartID, (int)ChartGetInteger(_ChartID, CHART_WIDTH_IN_PIXELS), 0, dummy_subwindow, converted_time, dummy_price);
    if (converted_time == prev_converted_time) return;
    prev_converted_time = converted_time;

    if (m_settings.SeamlessScrollingMode)
    {
        ObjectCleanup();
        if (_Session == Intraday) FirstRunDone = false;
        if ((m_settings.EnableDevelopingPOC) || (m_settings.EnableDevelopingVAHVAL))
        {
            for (int i = 0; i < Bars(_Symbol, _Timeframe); i++)
            {
                DevelopingPOC[i] = EMPTY_VALUE;
                DevelopingVAH[i] = EMPTY_VALUE;
                DevelopingVAL[i] = EMPTY_VALUE;
            }
        }
    }

    RedrawLastSession(rates_total);

    if ((m_settings.SeamlessScrollingMode) && (_Session == Intraday)) FirstRunDone = true;

    LastRecalculationTime = GetTickCount();
    ChartRedraw(_ChartID);
}

//+------------------------------------------------------------------+
//| OnChartEvent                                                     |
//+------------------------------------------------------------------+
void CMarketProfile::OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    if (id == CHARTEVENT_KEYDOWN)
    {
        if (lparam == 82) // 'r' key pressed.
        {
            if (_Session != Rectangle) return;
            // Find the next untaken MPR name.
            for (int i = 0; i < 1000; i++) // Won't be more than 1000 rectangles anyway!
            {
                string name = "MPR" + IntegerToString(i);
                if (ObjectFind(_ChartID, name) >= 0) continue;
                // If name not found, create a new rectangle.
                // Put it in the chart center with width and height equal to half the chart.
                int pixel_width = (int)ChartGetInteger(_ChartID, CHART_WIDTH_IN_PIXELS);
                int pixel_height = (int)ChartGetInteger(_ChartID, CHART_HEIGHT_IN_PIXELS);
                int half_width = pixel_width / 2;
                int half_height = pixel_height / 2;
                int x1 = half_width / 2;
                int x2 = int(half_width * 1.5);
                int y1 = half_height / 2;
                int y2 = int(half_height * 1.5);
                int dummy_subwindow;
                datetime time1, time2;
                double price1, price2;
                ChartXYToTimePrice(_ChartID, x1, y1, dummy_subwindow, time1, price1);
                ChartXYToTimePrice(_ChartID, x2, y2, dummy_subwindow, time2, price2);
                ObjectCreate(_ChartID, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
                ObjectSetInteger(_ChartID, name, OBJPROP_SELECTABLE, true);
                ObjectSetInteger(_ChartID, name, OBJPROP_HIDDEN, false);
                ObjectSetInteger(_ChartID, name, OBJPROP_SELECTED, true);
                ObjectSetInteger(_ChartID, name, OBJPROP_FILL, false);
                break;
            }
        }
        else if ((TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0) && (lparam == 49) && (_Session != Daily)) // Ctrl+1
        {
            Print("تغییر جلسه به روزانه");
            Deinitialize();
            _Session = Daily;
            Initialize();
            OnCalculateMain(iBars(_Symbol, _Timeframe), 0);
        }
        // ... (بقیه کلیدها به همین ترتیب)
    }
}

//+------------------------------------------------------------------+
//| CRectangleMP::Process                                            |
//+------------------------------------------------------------------+
void CMarketProfile::CRectangleMP::Process(int i, const int rates_total, CMarketProfile* parent)
{
    double p1 = ObjectGetDouble(parent->_ChartID, name, OBJPROP_PRICE, 0);
    double p2 = ObjectGetDouble(parent->_ChartID, name, OBJPROP_PRICE, 1);

    if (Number == -1) Number = i;

    // محاسبه زمان و قیمت واقعی مرزهای جلسه مستطیل.
    int sessionstart = iBarShift(parent->_Symbol, parent->_Timeframe, (datetime)MathMin(t1, t2), true);
    int sessionend = iBarShift(parent->_Symbol, parent->_Timeframe, (datetime)MathMax(t1, t2), true);

    bool rectangle_changed = false;
    bool rectangle_time_changed = false;
    bool rectangle_price_changed = false;

    if ((RectangleTimeMax != MathMax(t1, t2)) || (RectangleTimeMin != MathMin(t1, t2)))
    {
        rectangle_changed = true;
        rectangle_time_changed = true;
    }
    if ((RectanglePriceMax != MathMax(p1, p2)) || (RectanglePriceMin != MathMin(p1, p2)))
    {
        rectangle_changed = true;
        rectangle_price_changed = true;
    }

    bool need_to_clean_up_dots = false;
    bool rectangle_changed_and_recalc_is_due = false;

    if (rectangle_changed)
    {
        if (rectangle_price_changed)
        {
            int max_index = iHighest(parent->_Symbol, parent->_Timeframe, MODE_HIGH, sessionstart - sessionend, sessionend);
            int min_index = iLowest(parent->_Symbol, parent->_Timeframe, MODE_LOW, sessionstart - sessionend, sessionend);
            if ((max_index != -1) && (min_index != -1))
            {
                if ((RectanglePriceMax > iHigh(parent->_Symbol, parent->_Timeframe, max_index)) && (RectanglePriceMin < iLow(parent->_Symbol, parent->_Timeframe, min_index)) && (prev_RectanglePriceMax > iHigh(parent->_Symbol, parent->_Timeframe, max_index)) && (prev_RectanglePriceMin < iLow(parent->_Symbol, parent->_Timeframe, min_index))) rectangle_changed_and_recalc_is_due = false;
                else
                {
                    need_to_clean_up_dots = true;
                    rectangle_changed_and_recalc_is_due = true;
                }
            }
        }
        if (rectangle_time_changed)
        {
            need_to_clean_up_dots = true;
            if (sessionstart >= 0) rectangle_changed_and_recalc_is_due = true;
        }
    }

    prev_RectanglePriceMax = RectanglePriceMax;
    prev_RectanglePriceMin = RectanglePriceMin;

    if (need_to_clean_up_dots) parent->ObjectCleanup(name + "_");
    if (sessionstart < 0) return;

    parent->RememberSessionStart[i] = RectangleTimeMin;
    if (iTime(parent->_Symbol, parent->_Timeframe, 0) < RectangleTimeMax) parent->RememberSessionEnd[i] = iTime(parent->_Symbol, parent->_Timeframe, 0);
    else parent->RememberSessionEnd[i] = RectangleTimeMax;

    if ((!new_bars_are_not_within_rectangle) || (current_bar_changed_within_boundaries) || (rectangle_changed_and_recalc_is_due) || ((Number != i) && ((m_settings.RaysUntilIntersection != Stop_No_Rays) && ((m_settings.ShowMedianRays != None) || (m_settings.ShowValueAreaRays != None))))) parent->ProcessSession(sessionstart, sessionend, i, rates_total, this);

    Number = i;
}

//+------------------------------------------------------------------+
//| PutSinglePrintMark                                               |
//+------------------------------------------------------------------+
void CMarketProfile::PutSinglePrintMark(const double price, const int sessionstart, const string rectangle_prefix)
{
    int t1 = sessionstart + 1, t2 = sessionstart;
    bool fill = true;
    if (m_settings.ShowSinglePrint == Rightside)
    {
        t1 = sessionstart;
        t2 = sessionstart - 1;
        fill = false;
    }
    string LastNameStart = " " + TimeToString(iTime(_Symbol, _Timeframe, t1)) + " ";
    string LastName = LastNameStart + DoubleToString(price, _Digits);

    if (ObjectFind(_ChartID, rectangle_prefix + "MPSP" + Suffix + LastName) >= 0) return;
    ObjectCreate(_ChartID, rectangle_prefix + "MPSP" + Suffix + LastName, OBJ_RECTANGLE, 0, iTime(_Symbol, _Timeframe, t1), price, iTime(_Symbol, _Timeframe, t2), price - onetick);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSP" + Suffix + LastName, OBJPROP_COLOR, m_settings.SinglePrintColor);

    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSP" + Suffix + LastName, OBJPROP_FILL, fill);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSP" + Suffix + LastName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSP" + Suffix + LastName, OBJPROP_HIDDEN, true);
    ObjectSetString(_ChartID, rectangle_prefix + "MPSP" + Suffix + LastName, OBJPROP_TOOLTIP, "علامت پرینت تک");
}

//+------------------------------------------------------------------+
//| RemoveSinglePrintMark                                            |
//+------------------------------------------------------------------+
void CMarketProfile::RemoveSinglePrintMark(const double price, const int sessionstart, const string rectangle_prefix)
{
    int t = sessionstart + 1;
    if (m_settings.ShowSinglePrint == Rightside) t = sessionstart;

    string LastNameStart = " " + TimeToString(iTime(_Symbol, _Timeframe, t)) + " ";
    string LastName = LastNameStart + DoubleToString(price, _Digits);

    ObjectDelete(_ChartID, rectangle_prefix + "MPSP" + Suffix + LastName);
}

//+------------------------------------------------------------------+
//| PutSinglePrintRay                                                |
//+------------------------------------------------------------------+
void CMarketProfile::PutSinglePrintRay(const double price, const int sessionstart, const string rectangle_prefix, const color spr_color)
{
    datetime t1 = iTime(_Symbol, _Timeframe, sessionstart), t2;
    if (sessionstart - 1 >= 0) t2 = iTime(_Symbol, _Timeframe, sessionstart - 1);
    else t2 = iTime(_Symbol, _Timeframe, sessionstart) + 1;

    if (m_settings.ShowSinglePrint == Rightside)
    {
        t1 = iTime(_Symbol, _Timeframe, sessionstart);
        t2 = iTime(_Symbol, _Timeframe, sessionstart + 1);
    }

    string LastNameStart = " " + TimeToString(t1) + " ";
    string LastName = LastNameStart + DoubleToString(price, _Digits);

    if (ObjectFind(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName) >= 0) return;
    ObjectCreate(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName, OBJ_TREND, 0, t1, price, t2, price);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName, OBJPROP_COLOR, spr_color);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName, OBJPROP_STYLE, m_settings.SinglePrintRayStyle);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName, OBJPROP_WIDTH, m_settings.SinglePrintRayWidth);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName, OBJPROP_RAY_RIGHT, true);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName, OBJPROP_HIDDEN, true);
    ObjectSetString(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName, OBJPROP_TOOLTIP, "اشعه پرینت تک");
}

//+------------------------------------------------------------------+
//| RemoveSinglePrintRay                                             |
//+------------------------------------------------------------------+
void CMarketProfile::RemoveSinglePrintRay(const double price, const int sessionstart, const string rectangle_prefix)
{
    datetime t = iTime(_Symbol, _Timeframe, sessionstart);

    string LastNameStart = " " + TimeToString(t) + " ";
    string LastName = LastNameStart + DoubleToString(price, _Digits);

    ObjectDelete(_ChartID, rectangle_prefix + "MPSPR" + Suffix + LastName);
}

//+------------------------------------------------------------------+
//| RedrawLastSession                                                |
//+------------------------------------------------------------------+
void CMarketProfile::RedrawLastSession(const int rates_total)
{
    if (m_settings.SeamlessScrollingMode)
    {
        int last_visible_bar = (int)ChartGetInteger(_ChartID, CHART_FIRST_VISIBLE_BAR) - (int)ChartGetInteger(_ChartID, CHART_WIDTH_IN_BARS) + 1;
        if (last_visible_bar < 0) last_visible_bar = 0;
        StartDate = iTime(_Symbol, _Timeframe, last_visible_bar);
    }
    else if (m_settings.StartFromCurrentSession) StartDate = iTime(_Symbol, _Timeframe, 0);
    else StartDate = m_settings.StartFromDate;

    int sessionend = FindSessionEndByDate(StartDate, rates_total);

    int sessionstart = FindSessionStart(sessionend, rates_total);
    if (sessionstart == -1)
    {
        Print("چیزی اشتباه شد! منتظر بارگذاری داده.");
        return;
    }

    int SessionToStart = 0;
    if (!m_settings.SeamlessScrollingMode) SessionToStart = _SessionsToCount - 1;
    else
    {
        for (int i = 1; i < _SessionsToCount; i++)
        {
            sessionend = sessionstart + 1;
            if (sessionend >= rates_total) return;
            if (_SaturdaySunday == Ignore_Saturday_Sunday)
            {
                while ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend)) == 0) || (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend)) == 6))
                {
                    sessionend++;
                    if (sessionend >= rates_total) break;
                }
            }
            sessionstart = FindSessionStart(sessionend, rates_total);
        }
        SessionsNumber = 0;
    }

    for (int i = SessionToStart; i < _SessionsToCount; i++)
    {
        if (_Session == Intraday)
        {
            if (!ProcessIntradaySession(sessionstart, sessionend, i, rates_total)) return;
        }
        else
        {
            if (_Session == Daily) Max_number_of_bars_in_a_session = PeriodSeconds(PERIOD_D1) / PeriodSeconds(_Timeframe);
            else if (_Session == Weekly) Max_number_of_bars_in_a_session = 604800 / PeriodSeconds(_Timeframe);
            else if (_Session == Monthly) Max_number_of_bars_in_a_session = 2678400 / PeriodSeconds(_Timeframe);
            else if (_Session == Quarterly) Max_number_of_bars_in_a_session = 8035200 / PeriodSeconds(_Timeframe);
            else if (_Session == Semiannual) Max_number_of_bars_in_a_session = 16070400 / PeriodSeconds(_Timeframe);
            else if (_Session == Annual) Max_number_of_bars_in_a_session = 31622400 / PeriodSeconds(_Timeframe);
            if (_SaturdaySunday == Append_Saturday_Sunday)
            {
                if (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart)) == 0) Max_number_of_bars_in_a_session += (24 * 3600 - (TimeHour(iTime(_Symbol, _Timeframe, sessionstart)) * 3600 + TimeMinute(iTime(_Symbol, _Timeframe, sessionstart)) * 60)) / PeriodSeconds(_Timeframe);
                if (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend)) == 6) Max_number_of_bars_in_a_session += ((TimeHour(iTime(_Symbol, _Timeframe, sessionend)) * 3600 + TimeMinute(iTime(_Symbol, _Timeframe, sessionend)) * 60)) / PeriodSeconds(_Timeframe) + 1;
            }
            if (!ProcessSession(sessionstart, sessionend, i, rates_total)) return;
        }
        if (_SessionsToCount - i > 1)
        {
            sessionstart = sessionend - 1;
            if (_SaturdaySunday == Ignore_Saturday_Sunday)
            {
                while ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart)) == 0) || (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart)) == 6))
                {
                    sessionstart--;
                    if (sessionstart == 0) break;
                }
            }
            sessionend = FindSessionEndByDate(iTime(_Symbol, _Timeframe, sessionstart), rates_total);
        }
    }

    if ((m_settings.ShowValueAreaRays != None) || (m_settings.ShowMedianRays != None) || ((m_settings.HideRaysFromInvisibleSessions) && (m_settings.SinglePrintRays))) CheckRays();
}

//+------------------------------------------------------------------+
//| SaveSettingsOnDisk                                               |
//+------------------------------------------------------------------+
bool CMarketProfile::SaveSettingsOnDisk()
{
    int fh = FileOpen("MP_Settings\\" + m_FileName, FILE_CSV | FILE_WRITE);
    if (fh == INVALID_HANDLE)
    {
        Print("باز کردن فایل برای نوشتن شکست خورد: MP_Settings\\" + m_FileName + ". خطا: " + IntegerToString(GetLastError()));
        return false;
    }

    FileWrite(fh, "Session");
    FileWrite(fh, IntegerToString(_Session));

    if (GlobalVariableGet("MP-" + IntegerToString(_ChartID) + "-Parameters") > 0)
    {
        FileWrite(fh, "Parameter_Session");
        FileWrite(fh, IntegerToString(m_settings.Session));
    }

    FileClose(fh);

    Print("تنظیمات در فایل ذخیره شد.");
    return true;
}

//+------------------------------------------------------------------+
//| LoadSettingsFromDisk                                             |
//+------------------------------------------------------------------+
bool CMarketProfile::LoadSettingsFromDisk()
{
    int fh;

    if (FileIsExist("MP_Settings\\" + m_FileName))
    {
        fh = FileOpen("MP_Settings\\" + m_FileName, FILE_CSV | FILE_READ);
        if (fh == INVALID_HANDLE)
        {
            Print("باز کردن فایل برای خواندن شکست خورد: MP_Settings\\" + m_FileName + ". خطا: " + IntegerToString(GetLastError()));
            return false;
        }
    }
    else return false;

    while (!FileIsEnding(fh))
    {
        string var_name = FileReadString(fh);
        string var_content = FileReadString(fh);
        if (var_name == "Session")
            _Session = (session_period)StringToInteger(var_content);
        else if (GlobalVariableGet("MP-" + IntegerToString(_ChartID) + "-Parameters") > 0)
        {
            if (var_name == "Parameter_Session")
            {
                if ((session_period)StringToInteger(var_content) != m_settings.Session) _Session = m_settings.Session;
            }
        }
    }

    FileClose(fh);
    Print("تنظیمات از فایل بارگذاری شد.");

    if (GlobalVariableGet("MP-" + IntegerToString(_ChartID) + "-Parameters") > 0) GlobalVariableDel("MP-" + IntegerToString(_ChartID) + "-Parameters");

    return true;
}

//+------------------------------------------------------------------+
//| DeleteSettingsFile                                               |
//+------------------------------------------------------------------+
bool CMarketProfile::DeleteSettingsFile()
{
    string fn_with_path = "MP_Settings\\" + m_FileName;
    if (!FileIsExist(fn_with_path)) return false;
    if (!FileDelete(fn_with_path))
    {
        Print("حذف فایل تنظیمات شکست خورد: " + m_FileName + ". خطا: " + IntegerToString(GetLastError()));
        return false;
    }
    Print("فایل تنظیمات حذف شد.");
    return true;
}

//+------------------------------------------------------------------+
//| TimeHour                                                         |
//+------------------------------------------------------------------+
int CMarketProfile::TimeHour(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.hour;
}

//+------------------------------------------------------------------+
//| TimeMinute                                                       |
//+------------------------------------------------------------------+
int CMarketProfile::TimeMinute(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.min;
}

//+------------------------------------------------------------------+
//| TimeDay                                                          |
//+------------------------------------------------------------------+
int CMarketProfile::TimeDay(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.day;
}

//+------------------------------------------------------------------+
//| TimeDayOfWeek                                                    |
//+------------------------------------------------------------------+
int CMarketProfile::TimeDayOfWeek(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.day_of_week;
}

//+------------------------------------------------------------------+
//| TimeDayOfYear                                                    |
//+------------------------------------------------------------------+
int CMarketProfile::TimeDayOfYear(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.day_of_year;
}

//+------------------------------------------------------------------+
//| TimeMonth                                                        |
//+------------------------------------------------------------------+
int CMarketProfile::TimeMonth(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.mon;
}

//+------------------------------------------------------------------+
//| TimeYear                                                         |
//+------------------------------------------------------------------+
int CMarketProfile::TimeYear(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.year;
}

//+------------------------------------------------------------------+
//| TimeAbsoluteDay                                                  |
//+------------------------------------------------------------------+
int CMarketProfile::TimeAbsoluteDay(const datetime time)
{
    return ((int)time / 86400);
}

//+------------------------------------------------------------------+
//| CheckRays                                                        |
//+------------------------------------------------------------------+
void CMarketProfile::CheckRays()
{
    for (int i = 0; i < SessionsNumber; i++)
    {
        string last_name = " " + TimeToString(RememberSessionStart[i]);
        string suffix = RememberSessionSuffix[i];
        string rec_name = "";

        if (_Session == Rectangle) rec_name = MPR_Array[i].name + "_";

        // Process single print rays to hide those that should not be visible.
        if ((m_settings.HideRaysFromInvisibleSessions) && (m_settings.SinglePrintRays))
        {
            int obj_total = ObjectsTotal(_ChartID, 0, OBJ_TREND);
            for (int j = 0; j < obj_total; j++)
            {
                string obj_name = ObjectName(_ChartID, j, 0, OBJ_TREND);
                if (StringSubstr(obj_name, 0, StringLen(rec_name + "MPSPR" + suffix + last_name)) != rec_name + "MPSPR" + suffix + last_name) continue; // Not a single print ray.
                if (iTime(_Symbol, _Timeframe, (int)ChartGetInteger(_ChartID, CHART_FIRST_VISIBLE_BAR)) >= RememberSessionStart[i]) // Too old.
                {
                    ObjectSetInteger(_ChartID, obj_name, OBJPROP_COLOR, clrNONE); // Hide.
                }
                else {ObjectSetInteger(_ChartID, obj_name, OBJPROP_COLOR, m_settings.SinglePrintColor);} // Unhide.
            }
        }

        // If median rays should be created for the given trading session:
        if (((m_settings.ShowMedianRays == AllPrevious) && (SessionsNumber - i >= 2)) ||
            (((m_settings.ShowMedianRays == Previous) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i == 2)) ||
            (((m_settings.ShowMedianRays == Current) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i == 1)) ||
            (m_settings.ShowMedianRays == All))
        {
            double median_price = ObjectGetDouble(_ChartID, rec_name + "Median" + suffix + last_name, OBJPROP_PRICE, 0);
            datetime median_time = (datetime)ObjectGetInteger(_ChartID, rec_name + "Median" + suffix + last_name, OBJPROP_TIME, 1);

            // Create rays only if the median doesn't end behind the screen's left edge.
            if (!((m_settings.HideRaysFromInvisibleSessions) && (iTime(_Symbol, _Timeframe, (int)ChartGetInteger(_ChartID, CHART_FIRST_VISIBLE_BAR)) >= median_time)))
            {
                // Draw new median ray.
                if (ObjectFind(_ChartID, rec_name + "Median Ray" + suffix + last_name) < 0)
                {
                    ObjectCreate(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJ_TREND, 0, RememberSessionStart[i], median_price, median_time, median_price);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_COLOR, m_settings.MedianColor);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_STYLE, m_settings.MedianRayStyle);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_WIDTH, m_settings.MedianRayWidth);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_BACK, false);
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_SELECTABLE, false);
                    if ((m_settings.RightToLeft) && (i == SessionsNumber - 1) && (_Session != Rectangle))
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_LEFT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_RIGHT, false);
                    }
                    else
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_LEFT, false);
                    }
                    ObjectSetInteger(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_HIDDEN, true);
                    ObjectSetString(_ChartID, rec_name + "Median Ray" + suffix + last_name, OBJPROP_TOOLTIP, "اشعه میانه");
                }
                else
                {
                    ObjectMove(_ChartID, rec_name + "Median Ray" + suffix + last_name, 0, RememberSessionStart[i], median_price);
                    ObjectMove(_ChartID, rec_name + "Median Ray" + suffix + last_name, 1, median_time, median_price);
                }
            }
            else ObjectDelete(_ChartID, rec_name + "Median Ray" + suffix + last_name); // Delete a ray that starts from behind the screen.
        }

        // Should also delete obsolete rays that should not exist anymore.
        if ((((m_settings.ShowMedianRays == Previous) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i > 2)) ||
            ((m_settings.ShowMedianRays == Current) && (SessionsNumber - i > 1)))
        {
            ObjectDelete(_ChartID, rec_name + "Median Ray" + suffix + last_name);
        }

        // If value area rays should be created for the given trading session:
        if (((m_settings.ShowValueAreaRays == AllPrevious) && (SessionsNumber - i >= 2)) ||
            (((m_settings.ShowValueAreaRays == Previous) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i == 2)) ||
            (((m_settings.ShowValueAreaRays == Current) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i == 1)) ||
            (m_settings.ShowValueAreaRays == All))
        {
            double va_high_price = ObjectGetDouble(_ChartID, rec_name + "VA_Top" + suffix + last_name, OBJPROP_PRICE, 0);
            double va_low_price = ObjectGetDouble(_ChartID, rec_name + "VA_Bottom" + suffix + last_name, OBJPROP_PRICE, 0);
            datetime va_time = (datetime)ObjectGetInteger(_ChartID, rec_name + "VA_Top" + suffix + last_name, OBJPROP_TIME, 1);
            // Create rays only if the value area doesn't end behind the screen's left edge.
            if (!((m_settings.HideRaysFromInvisibleSessions) && (iTime(_Symbol, _Timeframe, (int)ChartGetInteger(_ChartID, CHART_FIRST_VISIBLE_BAR)) >= va_time)))
            {
                // Draw new value area high ray.
                if (ObjectFind(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name) < 0)
                {
                    ObjectCreate(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJ_TREND, 0, RememberSessionStart[i], va_high_price, va_time, va_high_price);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_COLOR, m_settings.ValueAreaHighLowColor);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_STYLE, m_settings.ValueAreaRayHighLowStyle);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_WIDTH, m_settings.ValueAreaRayHighLowWidth);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_BACK, false);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_SELECTABLE, false);
                    if ((m_settings.RightToLeft) && (i == SessionsNumber - 1) && (_Session != Rectangle))
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_LEFT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_RIGHT, false);
                    }
                    else
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_LEFT, false);
                    }
                    ObjectSetInteger(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_HIDDEN, true);
                    ObjectSetString(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_TOOLTIP, "اشعه بالای ناحیه ارزش");
                }
                else
                {
                    ObjectMove(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, 0, RememberSessionStart[i], va_high_price);
                    ObjectMove(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name, 1, va_time, va_high_price);
                }

                // Draw new value area low ray.
                if (ObjectFind(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name) < 0)
                {
                    ObjectCreate(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJ_TREND, 0, RememberSessionStart[i], va_low_price, va_time, va_low_price);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_COLOR, m_settings.ValueAreaHighLowColor);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_STYLE, m_settings.ValueAreaRayHighLowStyle);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_WIDTH, m_settings.ValueAreaRayHighLowWidth);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_BACK, false);
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_SELECTABLE, false);
                    if ((m_settings.RightToLeft) && (i == SessionsNumber - 1) && (_Session != Rectangle))
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_LEFT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_RIGHT, false);
                    }
                    else
                    {
                        ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_LEFT, false);
                    }
                    ObjectSetInteger(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_HIDDEN, true);
                    ObjectSetString(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_TOOLTIP, "اشعه پایین ناحیه ارزش");
                }
                else
                {
                    ObjectMove(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, 0, RememberSessionStart[i], va_low_price);
                    ObjectMove(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name, 1, va_time, va_low_price);
                }
            }
            else
            {
                ObjectDelete(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name);
                ObjectDelete(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name);
            }
        }

        // Should also delete obsolete rays that should not exist anymore.
        if ((((m_settings.ShowValueAreaRays == Previous) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i > 2)) ||
            ((m_settings.ShowValueAreaRays == Current) && (SessionsNumber - i > 1)))
        {
            ObjectDelete(_ChartID, rec_name + "Value Area HighRay" + suffix + last_name);
            ObjectDelete(_ChartID, rec_name + "Value Area LowRay" + suffix + last_name);
        }

        // Ray intersections.
        if (m_settings.RaysUntilIntersection != Stop_No_Rays)
        {
            if ((((m_settings.ShowMedianRays == Previous) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i == 2)) || (((m_settings.ShowMedianRays == AllPrevious) || (m_settings.ShowMedianRays == All)) && (SessionsNumber - i >= 2)))
            {
                if ((m_settings.RaysUntilIntersection == Stop_All_Rays)
                        || ((m_settings.RaysUntilIntersection == Stop_All_Rays_Except_Prev_Session) && (SessionsNumber - i > 2))
                        || ((m_settings.RaysUntilIntersection == Stop_Only_Previous_Session) && (SessionsNumber - i == 2)))
                    CheckRayIntersections(rec_name + "Median Ray" + suffix + last_name, i + 1);
            }
            if ((((m_settings.ShowValueAreaRays == Previous) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i == 2)) || (((m_settings.ShowValueAreaRays == AllPrevious) || (m_settings.ShowValueAreaRays == All)) && (SessionsNumber - i >= 2)))
            {
                if ((m_settings.RaysUntilIntersection == Stop_All_Rays)
                        || ((m_settings.RaysUntilIntersection == Stop_All_Rays_Except_Prev_Session) && (SessionsNumber - i > 2))
                        || ((m_settings.RaysUntilIntersection == Stop_Only_Previous_Session) && (SessionsNumber - i == 2)))
                {
                    CheckRayIntersections(rec_name + "Value Area HighRay" + suffix + last_name, i + 1);
                    CheckRayIntersections(rec_name + "Value Area LowRay" + suffix + last_name, i + 1);
                }
            }
        }

        if (m_settings.AlertArrows)
        {
            int bar_start = iBarShift(_Symbol, _Timeframe, RememberSessionEnd[i]) - 1;

            if (m_settings.AlertForSinglePrint)
            {
                int obj_total = ObjectsTotal(_ChartID, 0, OBJ_TREND);
                for (int j = 0; j < obj_total; j++)
                {
                    string obj_name = ObjectName(_ChartID, j, 0, OBJ_TREND);
                    string obj_prefix = rec_name + "MPSPR" + suffix + last_name;
                    if (StringSubstr(obj_name, 0, StringLen(obj_prefix)) != obj_prefix) continue;
                    if ((color)ObjectGetInteger(_ChartID, obj_name, OBJPROP_COLOR) != clrNONE)
                    {
                        if (!FindAtLeastOneArrowForRay(obj_prefix))
                        {
                            for (int k = bar_start; k >= 0; k--)
                            {
                                CheckAndDrawArrow(k, ObjectGetDouble(_ChartID, obj_name, OBJPROP_PRICE, 0), obj_prefix);
                            }
                        }
                    }
                    else
                    {
                        DeleteArrowsByPrefix(obj_prefix);
                    }
                }
            }

            if (m_settings.AlertForValueArea)
            {
                string obj_prefix = rec_name + "Value Area HighRay" + suffix + last_name;
                if (ObjectFind(_ChartID, obj_prefix) >= 0)
                {
                    if (!FindAtLeastOneArrowForRay(obj_prefix)) CheckHistoricalArrowsForNonMPSPRRays(bar_start, obj_prefix);
                }
                else
                {
                    DeleteArrowsByPrefix(obj_prefix);
                }

                obj_prefix = rec_name + "Value Area LowRay" + suffix + last_name;
                if (ObjectFind(_ChartID, obj_prefix) >= 0)
                {
                    if (!FindAtLeastOneArrowForRay(obj_prefix)) CheckHistoricalArrowsForNonMPSPRRays(bar_start, obj_prefix);
                }
                else
                {
                    DeleteArrowsByPrefix(obj_prefix);
                }
            }

            if (m_settings.AlertForMedian)
            {
                string obj_prefix = rec_name + "Median Ray" + suffix + last_name;
                if (ObjectFind(_ChartID, obj_prefix) >= 0)
                {
                    if (!FindAtLeastOneArrowForRay(obj_prefix)) CheckHistoricalArrowsForNonMPSPRRays(bar_start, obj_prefix);
                }
                else
                {
                    DeleteArrowsByPrefix(obj_prefix);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| DeleteArrowsByPrefix                                             |
//+------------------------------------------------------------------+
void CMarketProfile::DeleteArrowsByPrefix(const string prefix)
{
    ObjectsDeleteAll(_ChartID, "ArrPB" + prefix, 0, OBJ_ARROW);
    ObjectsDeleteAll(_ChartID, "ArrCC" + prefix, 0, OBJ_ARROW);
    ObjectsDeleteAll(_ChartID, "ArrGC" + prefix, 0, OBJ_ARROW);
}

//+------------------------------------------------------------------+
//| FindAtLeastOneArrowForRay                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::FindAtLeastOneArrowForRay(const string ray_name)
{
    int objects_total = ObjectsTotal(_ChartID, 0, OBJ_ARROW);
    for (int i = 0; i < objects_total; i++)
    {
        string obj_name = ObjectName(_ChartID, i, 0, OBJ_ARROW);
        if (StringFind(obj_name, ray_name) != -1) return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| CheckHistoricalArrowsForNonMPSPRRays                             |
//+------------------------------------------------------------------+
void CMarketProfile::CheckHistoricalArrowsForNonMPSPRRays(const int bar_start, const string ray_name)
{
    int end_bar = 0;
    if (ObjectGetInteger(_ChartID, ray_name, OBJPROP_RAY_RIGHT) != true)
    {
        datetime end_time = (datetime)ObjectGetInteger(_ChartID, ray_name, OBJPROP_TIME, 1);
        end_bar = iBarShift(_Symbol, _Timeframe, end_time) + 1;
    }
    for (int k = bar_start; k >= end_bar; k--)
    {
        CheckAndDrawArrow(k, ObjectGetDouble(_ChartID, ray_name, OBJPROP_PRICE, 0), ray_name);
    }
}

//+------------------------------------------------------------------+
//| CheckAndDrawArrow                                                |
//+------------------------------------------------------------------+
void CMarketProfile::CheckAndDrawArrow(const int n, const double level, const string ray_name)
{
    if (m_settings.AlertOnPriceBreak)
    {
        if (((iHigh(_Symbol, _Timeframe, n) >= level) && (iClose(_Symbol, _Timeframe, n) < level) && (iClose(_Symbol, _Timeframe, n + 1) < level)) || ((iLow(_Symbol, _Timeframe, n) <= level) && (iClose(_Symbol, _Timeframe, n) > level) && (iClose(_Symbol, _Timeframe, n + 1) > level)))
        {
            string obj_name = "ArrPB" + ray_name;
            CreateArrowObject(obj_name, iTime(_Symbol, _Timeframe, n), iClose(_Symbol, _Timeframe, n), m_settings.AlertArrowCodePB, m_settings.AlertArrowColorPB, m_settings.AlertArrowWidthPB, "شکست قیمت");
        }
    }
    if (m_settings.AlertOnCandleClose)
    {
        if (((iClose(_Symbol, _Timeframe, n) >= level) && (iClose(_Symbol, _Timeframe, n + 1) < level)) || ((iClose(_Symbol, _Timeframe, n) <= level) && (iClose(_Symbol, _Timeframe, n + 1) > level)))
        {
            string obj_name = "ArrCC" + ray_name;
            CreateArrowObject(obj_name, iTime(_Symbol, _Timeframe, n), iClose(_Symbol, _Timeframe, n), m_settings.AlertArrowCodeCC, m_settings.AlertArrowColorCC, m_settings.AlertArrowWidthCC, "عبور بسته شدن شمع");
        }
    }
    if (m_settings.AlertOnGapCross)
    {
        if (((iLow(_Symbol, _Timeframe, n) > level) && (iHigh(_Symbol, _Timeframe, n + 1) < level)) || ((iLow(_Symbol, _Timeframe, n + 1) > level) && (iHigh(_Symbol, _Timeframe, n) < level)))
        {
            string obj_name = "ArrGC" + ray_name;
            CreateArrowObject(obj_name, iTime(_Symbol, _Timeframe, n), level, m_settings.AlertArrowCodeGC, m_settings.AlertArrowColorGC, m_settings.AlertArrowWidthGC, "عبور شکاف");
        }
    }
}

//+------------------------------------------------------------------+
//| CreateArrowObject                                                |
//+------------------------------------------------------------------+
void CMarketProfile::CreateArrowObject(const string name, const datetime time, const double price, const int code, const color colour, const int width, const string tooltip)
{
    string obj_name = name + IntegerToString(ArrowsCounter);
    ArrowsCounter++;
    ObjectCreate(_ChartID, obj_name, OBJ_ARROW, 0, time, price);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_ARROWCODE, code);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_COLOR, colour);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_WIDTH, width);
    ObjectSetString(_ChartID, obj_name, OBJPROP_TOOLTIP, tooltip);
}

//+------------------------------------------------------------------+
//| CheckRayIntersections                                            |
//+------------------------------------------------------------------+
void CMarketProfile::CheckRayIntersections(const string object, const int start_j)
{
    if (ObjectFind(_ChartID, object) < 0) return;

    double price = ObjectGetDouble(_ChartID, object, OBJPROP_PRICE, 0);
    for (int j = start_j; j < SessionsNumber; j++)
    {
        if ((price <= RememberSessionMax[j]) && (price >= RememberSessionMin[j]))
        {
            ObjectSetInteger(_ChartID, object, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(_ChartID, object, OBJPROP_TIME, 1, RememberSessionStart[j]);
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| FindQuarterStart                                                 |
//+------------------------------------------------------------------+
int CMarketProfile::FindQuarterStart(const int n, const int rates_total)
{
    if (n >= rates_total) return -1;
    int x = n;
    int time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    int time_n_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, n) + m_settings.TimeShiftMinutes * 60);
    int time_n_month = TimeMonth(iTime(_Symbol, _Timeframe, n) + m_settings.TimeShiftMinutes * 60);
    int time_n_day = TimeDay(iTime(_Symbol, _Timeframe, n) + m_settings.TimeShiftMinutes * 60);
    bool first_day_of_quarter = false;
    if (time_n_day == 1)
    {
        if ((time_n_month == 1) || (time_n_month == 4) || (time_n_month == 7) || (time_n_month == 10)) first_day_of_quarter = true;
    }

    while (((time_n_month - 1) / 3 == (TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) - 1) / 3) || ((_SaturdaySunday == Append_Saturday_Sunday) && ((time_x_day_of_week == 0) || ((time_n_day_of_week == 6) && (first_day_of_quarter)))))
    {
        int month_distance = time_n_month - TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        if (month_distance < 0) month_distance = 12 + month_distance;
        if (month_distance > 3) break;

        bool x_first_day_of_quarter = false;
        int time_x_day = TimeDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        int time_x_month = TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        if (time_x_day == 1)
        {
            if ((time_x_month == 1) || (time_x_month == 4) || (time_x_month == 7) || (time_x_month == 10)) x_first_day_of_quarter = true;
        }

        if (_SaturdaySunday == Append_Saturday_Sunday)
        {
            if ((time_x_day_of_week == 6) && (x_first_day_of_quarter) && (!first_day_of_quarter)) break;
        }

        bool x_first_or_second_day_of_quarter = false;
        time_x_day = TimeDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        time_x_month = TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        if ((time_x_day == 1) || (time_x_day == 2))
        {
            if ((time_x_month == 1) || (time_x_month == 4) || (time_x_month == 7) || (time_x_month == 10)) x_first_or_second_day_of_quarter = true;
        }  
        if (_SaturdaySunday == Ignore_Saturday_Sunday)
        {
            if (((time_x_day_of_week == 0) || (time_x_day_of_week == 6)) && (x_first_or_second_day_of_quarter)) break;
        }
        x++;
        if (x >= rates_total) break;
        time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    }

    return (x - 1);
}

//+------------------------------------------------------------------+
//| FindHalfyearStart                                                |
//+------------------------------------------------------------------+
int CMarketProfile::FindHalfyearStart(const int n, const int rates_total)
{
    if (n >= rates_total) return -1;
    int x = n;
    int time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    int time_n_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, n) + m_settings.TimeShiftMinutes * 60);
    int time_n_month = TimeMonth(iTime(_Symbol, _Timeframe, n) + m_settings.TimeShiftMinutes * 60);
    int time_n_day = TimeDay(iTime(_Symbol, _Timeframe, n) + m_settings.TimeShiftMinutes * 60);
    bool first_day_of_halfyear = false;
    if (time_n_day == 1)
    {
        if ((time_n_month == 1) || (time_n_month == 7)) first_day_of_halfyear = true;
    }

    while (((time_n_month - 1) / 6 == (TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) - 1) / 6) || ((_SaturdaySunday == Append_Saturday_Sunday) && ((time_x_day_of_week == 0) || ((time_n_day_of_week == 6) && (first_day_of_halfyear)))))
    {
        int month_distance = time_n_month - TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        if (month_distance < 0) month_distance = 12 + month_distance;
        if (month_distance > 6) break;

        bool x_first_day_of_halfyear = false;
        int time_x_day = TimeDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        int time_x_month = TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        if (time_x_day == 1)
        {
            if ((time_x_month == 1) || (time_x_month == 7)) x_first_day_of_halfyear = true;
        }

        if (_SaturdaySunday == Append_Saturday_Sunday)
        {
            if ((time_x_day_of_week == 6) && (x_first_day_of_halfyear) && (!first_day_of_halfyear)) break;
        }

        bool x_first_or_second_day_of_halfyear = false;
        time_x_day = TimeDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        time_x_month = TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        if ((time_x_day == 1) || (time_x_day == 2))
        {
            if ((time_x_month == 1) || (time_x_month == 7)) x_first_or_second_day_of_halfyear = true;
        }  
        if (_SaturdaySunday == Ignore_Saturday_Sunday)
        {
            if (((time_x_day_of_week == 0) || (time_x_day_of_week == 6)) && (x_first_or_second_day_of_halfyear)) break;
        }
        x++;
        if (x >= rates_total) break;
        time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    }

    return (x - 1);
}

//+------------------------------------------------------------------+
//| FindYearStart                                                    |
//+------------------------------------------------------------------+
int CMarketProfile::FindYearStart(const int n, const int rates_total)
{
    if (n >= rates_total) return -1;
    int x = n;
    int time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    int time_n_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, n) + m_settings.TimeShiftMinutes * 60);
    int time_n_day_of_year = TimeDayOfYear(iTime(_Symbol, _Timeframe, n) + m_settings.TimeShiftMinutes * 60);
    int time_n_year = TimeYear(iTime(_Symbol, _Timeframe, n) + m_settings.TimeShiftMinutes * 60);

    while ((time_n_year == TimeYear(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60)) || ((_SaturdaySunday == Append_Saturday_Sunday) && ((time_x_day_of_week == 0) || ((time_n_day_of_week == 6) && (time_n_day_of_year == 1)))))
    {
        int year_distance = time_n_year - TimeYear(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        if (year_distance > 1) break;

        int time_x_day_of_year = TimeDayOfYear(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);

        if (_SaturdaySunday == Append_Saturday_Sunday)
        {
            if ((time_x_day_of_week == 6) && (time_x_day_of_year == 1) && (time_n_day_of_year != 1)) break;
        }

        bool x_first_or_second_day_of_year = false;
        int time_x_day = TimeDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        int time_x_day_of_year = TimeDayOfYear(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
        if ((time_x_day == 1) || (time_x_day == 2))
        {
            if (time_x_day_of_year == 1 || time_x_day_of_year == 2) x_first_or_second_day_of_year = true;
        }  
        if (_SaturdaySunday == Ignore_Saturday_Sunday)
        {
            if (((time_x_day_of_week == 0) || (time_x_day_of_week == 6)) && x_first_or_second_day_of_year) break;
        }
        x++;
        if (x >= rates_total) break;
        time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    }

    return (x - 1);
}

//+------------------------------------------------------------------+
//| FindSessionEndByDate                                             |
//+------------------------------------------------------------------+
int CMarketProfile::FindSessionEndByDate(const datetime date, const int rates_total)
{
    if (_Session == Daily) return FindDayEndByDate(date, rates_total);
    else if (_Session == Weekly) return FindWeekEndByDate(date, rates_total);
    else if (_Session == Monthly) return FindMonthEndByDate(date, rates_total);
    else if (_Session == Quarterly) return FindQuarterEndByDate(date, rates_total);
    else if (_Session == Semiannual) return FindHalfyearEndByDate(date, rates_total);
    else if (_Session == Annual) return FindYearEndByDate(date, rates_total);
    else if (_Session == Intraday)
    {
        // A special case when Append_Saturday_Sunday is on and the date is on Sunday.
        if ((_SaturdaySunday == Append_Saturday_Sunday) && (TimeDayOfWeek(date + m_settings.TimeShiftMinutes * 60) == 0))
        {
            // One of the intraday sessions should start at 00:00 or have end < start.
            for (int intraday_i = 0; intraday_i < IntradaySessionCount; intraday_i++)
            {
                if ((IDStartTime[intraday_i] == 0) || (IDStartTime[intraday_i] > IDEndTime[intraday_i]))
                {
                    // Find the last bar of this intraday session and return it as sessionend.
                    int x = 0;
                    int abs_day = TimeAbsoluteDay(date + m_settings.TimeShiftMinutes * 60);
                    // TimeAbsoluteDay is used for cases when the given date is Dec 30 (#364) and the current date is Jan 1 (#1) for example.
                    while ((x < rates_total) && (abs_day < TimeAbsoluteDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60))) // It's Sunday.
                    {
                        // On Monday.
                        if (TimeAbsoluteDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) == abs_day + 1)
                        {
                            // Inside the session.
                            if (TimeHour(iTime(_Symbol, _Timeframe, x)) * 60 +  TimeMinute(iTime(_Symbol, _Timeframe, x)) < IDEndTime[intraday_i]) break;
                            // Break out earlier (on Monday's end bar) if working with 00:00-XX:XX session.
                            if (IDStartTime[intraday_i] == 0) break;
                        }
                        x++;
                    }
                    return x;
                }
            }
        }
        return FindDayEndByDate(date, rates_total);
    }

    return -1;
}

//+------------------------------------------------------------------+
//| FindDayEndByDate                                                 |
//+------------------------------------------------------------------+
int CMarketProfile::FindDayEndByDate(const datetime date, const int rates_total)
{
    int x = 0;

    // TimeAbsoluteDay is used for cases when the given date is Dec 30 (#364) and the current date is Jan 1 (#1) for example.
    while ((x < rates_total) && (TimeAbsoluteDay(date + m_settings.TimeShiftMinutes * 60) < TimeAbsoluteDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60)))
    {
        // Check if Append_Saturday_Sunday is on and if the found end of the day is on Saturday and the given date is the previous Friday; or it is a Monday and the sought date is the previous Sunday.
        if (_SaturdaySunday == Append_Saturday_Sunday)
        {
            if (((TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) == 6) || (TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) == 1)) && (TimeAbsoluteDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) - TimeAbsoluteDay(date + m_settings.TimeShiftMinutes * 60) == 1)) break;
        }
        x++;
    }

    return x;
}

//+------------------------------------------------------------------+
//| FindWeekEndByDate                                                |
//+------------------------------------------------------------------+
int CMarketProfile::FindWeekEndByDate(const datetime date, const int rates_total)
{
    int x = 0;

    int time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);

    // Condition should pass also if Append_Saturday_Sunday is on and it is Sunday; and also if Ignore_Saturday_Sunday is on and it is Saturday or Sunday.
    while ((SameWeek(date + m_settings.TimeShiftMinutes * 60, iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) != true) || ((_SaturdaySunday == Append_Saturday_Sunday) && (time_x_day_of_week == 0)) || ((_SaturdaySunday == Ignore_Saturday_Sunday) && ((time_x_day_of_week == 0) || (time_x_day_of_week == 6))))
    {
        x++;
        if (x >= rates_total) break;
        time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    }

    return x;
}

//+------------------------------------------------------------------+
//| FindMonthEndByDate                                               |
//+------------------------------------------------------------------+
int CMarketProfile::FindMonthEndByDate(const datetime date, const int rates_total)
{
    int x = 0;

    int time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);

    // Condition should pass also if Append_Saturday_Sunday is on and it is Sunday; and also if Ignore_Saturday_Sunday is on and it is Saturday or Sunday.
    while ((SameMonth(date + m_settings.TimeShiftMinutes * 60, iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) != true) || ((_SaturdaySunday == Append_Saturday_Sunday) && (time_x_day_of_week == 0)) || ((_SaturdaySunday == Ignore_Saturday_Sunday) && ((time_x_day_of_week == 0) || (time_x_day_of_week == 6))))
    {
        // Check if Append_Saturday_Sunday is on.
        if (_SaturdaySunday == Append_Saturday_Sunday)
        {
            // Today is Saturday the 1st day of the next month. Despite it being in a next month, it should be appended to the current month.
            if ((time_x_day_of_week == 6) && (TimeDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) == 1) && (TimeYear(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) * 12 + TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) - TimeYear(date + m_settings.TimeShiftMinutes * 60) * 12 - TimeMonth(date + m_settings.TimeShiftMinutes * 60) == 1)) break;
            // Given date is Sunday of a previous month. It was rejected in the previous month and should be appended to beginning of this one.
            // Works because date here can be only the end or the beginning of the month.
            if ((TimeDayOfWeek(date + m_settings.TimeShiftMinutes * 60) == 0) && (TimeYear(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) * 12 + TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) - TimeYear(date + m_settings.TimeShiftMinutes * 60) * 12 - TimeMonth(date + m_settings.TimeShiftMinutes * 60) == 1)) break;
        }
        x++;
        if (x >= rates_total) break;
        time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    }

    return x;
}

//+------------------------------------------------------------------+
//| FindQuarterEndByDate                                             |
//+------------------------------------------------------------------+
int CMarketProfile::FindQuarterEndByDate(const datetime date, const int rates_total)
{
    int x = 0;

    int time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);

    // Condition should pass also if Append_Saturday_Sunday is on and it is Sunday; and also if Ignore_Saturday_Sunday is on and it is Saturday or Sunday.
    while ((SameQuarter(date + m_settings.TimeShiftMinutes * 60, iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) != true) || ((_SaturdaySunday == Append_Saturday_Sunday) && (time_x_day_of_week == 0)) || ((_SaturdaySunday == Ignore_Saturday_Sunday) && ((time_x_day_of_week == 0) || (time_x_day_of_week == 6))))
    {
        // Check if Append_Saturday_Sunday is on.
        if (_SaturdaySunday == Append_Saturday_Sunday)
        {
            bool x_first_day_of_quarter = false;
            int time_x_day = TimeDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
            int time_x_month = TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
            if (time_x_day == 1)
            {
                if ((time_x_month == 1) || (time_x_month == 4) || (time_x_month == 7) || (time_x_month == 10)) x_first_day_of_quarter = true;
            }    
            int quarter_distance = (TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) - 1) / 3 - (TimeMonth(date + m_settings.TimeShiftMinutes * 60) - 1) / 3;
            if (quarter_distance < 0) quarter_distance = 4 + quarter_distance;
            // Today is Saturday the 1st day of the next quarter. Despite it being in a next quarter, it should be appended to the current quarter.
            if ((time_x_day_of_week == 6) && (x_first_day_of_quarter) && (quarter_distance == 1)) break;
            // Given date is Sunday of a previous quarter. It was rejected in the previous quarter and should be appended to beginning of this one.
            // Works because date here can be only the end or the beginning of the quarter.
            if ((TimeDayOfWeek(date + m_settings.TimeShiftMinutes * 60) == 0) && (quarter_distance == 1)) break;
        }
        x++;
        if (x >= rates_total) break;
        time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    }

    return x;
}

//+------------------------------------------------------------------+
//| FindHalfyearEndByDate                                            |
//+------------------------------------------------------------------+
int CMarketProfile::FindHalfyearEndByDate(const datetime date, const int rates_total)
{
    int x = 0;

    int time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);

    // Condition should pass also if Append_Saturday_Sunday is on and it is Sunday; and also if Ignore_Saturday_Sunday is on and it is Saturday or Sunday.
    while ((SameHalfyear(date + m_settings.TimeShiftMinutes * 60, iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) != true) || ((_SaturdaySunday == Append_Saturday_Sunday) && (time_x_day_of_week == 0)) || ((_SaturdaySunday == Ignore_Saturday_Sunday) && ((time_x_day_of_week == 0) || (time_x_day_of_week == 6))))
    {
        // Check if Append_Saturday_Sunday is on.
        if (_SaturdaySunday == Append_Saturday_Sunday)
        {
            bool x_first_day_of_halfyear = false;
            int time_x_day = TimeDay(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
            int time_x_month = TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
            if (time_x_day == 1)
            {
                if ((time_x_month == 1) || (time_x_month == 7)) x_first_day_of_halfyear = true;
            }    
            int halfyear_distance = (TimeMonth(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) - 1) / 6 - (TimeMonth(date + m_settings.TimeShiftMinutes * 60) - 1) / 6;
            if (halfyear_distance < 0) halfyear_distance = 2 + halfyear_distance;
            // Today is Saturday the 1st day of the next half-year. Despite it being in a next half-year, it should be appended to the current half-year.
            if ((time_x_day_of_week == 6) && (x_first_day_of_halfyear) && (halfyear_distance == 1)) break;
            // Given date is Sunday of a previous half-year. It was rejected in the previous half-year and should be appended to beginning of this one.
            // Works because date here can be only the end or the beginning of the half-year.
            if ((TimeDayOfWeek(date + m_settings.TimeShiftMinutes * 60) == 0) && (halfyear_distance == 1)) break;
        }
        x++;
        if (x >= rates_total) break;
        time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    }

    return x;
}

//+------------------------------------------------------------------+
//| FindYearEndByDate                                                |
//+------------------------------------------------------------------+
int CMarketProfile::FindYearEndByDate(const datetime date, const int rates_total)
{
    int x = 0;

    int time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);

    // Condition should pass also if Append_Saturday_Sunday is on and it is Sunday; and also if Ignore_Saturday_Sunday is on and it is Saturday or Sunday.
    while ((SameYear(date + m_settings.TimeShiftMinutes * 60, iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) != true) || ((_SaturdaySunday == Append_Saturday_Sunday) && (time_x_day_of_week == 0))  || ((_SaturdaySunday == Ignore_Saturday_Sunday) && ((time_x_day_of_week == 0) || (time_x_day_of_week == 6))))
    {
        // Check if Append_Saturday_Sunday is on.
        if (_SaturdaySunday == Append_Saturday_Sunday)
        {
            int time_x_day_of_year = TimeDayOfYear(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
            int year_distance = TimeYear(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60) - TimeYear(date + m_settings.TimeShiftMinutes * 60);
            // Today is Saturday the 1st day of the next year. Despite it being in a next year, it should be appended to the current year.
            if ((time_x_day_of_week == 6) && (time_x_day_of_year == 1) && (year_distance == 1)) break;
            // Given date is Sunday of a previous year. It was rejected in the previous year and should be appended to beginning of this one.
            // Works because date here can be only the end or the beginning of the year.
            if ((TimeDayOfWeek(date + m_settings.TimeShiftMinutes * 60) == 0) && (year_distance == 1)) break;
        }
        x++;
        if (x >= rates_total) break;
        time_x_day_of_week = TimeDayOfWeek(iTime(_Symbol, _Timeframe, x) + m_settings.TimeShiftMinutes * 60);
    }

    return x;
}

//+------------------------------------------------------------------+
//| SameWeek                                                         |
//+------------------------------------------------------------------+
int CMarketProfile::SameWeek(const datetime date1, const datetime date2)
{
    MqlDateTime dt1, dt2;

    TimeToStruct(date1, dt1);
    TimeToStruct(date2, dt2);

    int seconds_from_start = dt1.day_of_week * 24 * 3600 + dt1.hour * 3600 + dt1.min * 60 + dt1.sec;

    if (date1 == date2) return true;
    else if (date2 < date1)
    {
        if (date1 - date2 <= seconds_from_start) return true;
    }
    else if (date2 - date1 < 604800 - seconds_from_start) return true;

    return false;
}

//+------------------------------------------------------------------+
//| SameMonth                                                        |
//+------------------------------------------------------------------+
int CMarketProfile::SameMonth(const datetime date1, const datetime date2)
{
    MqlDateTime dt1, dt2;

    TimeToStruct(date1, dt1);
    TimeToStruct(date2, dt2);

    if ((dt1.mon == dt2.mon) && (dt1.year == dt2.year)) return true;
    return false;
}

//+------------------------------------------------------------------+
//| SameQuarter                                                      |
//+------------------------------------------------------------------+
int CMarketProfile::SameQuarter(const datetime date1, const datetime date2)
{
    if (((TimeMonth(date1) - 1) / 3 == (TimeMonth(date2) - 1) / 3) && (TimeYear(date1) == TimeYear(date2))) return true;
    return false;
}

//+------------------------------------------------------------------+
//| SameHalfyear                                                     |
//+------------------------------------------------------------------+
int CMarketProfile::SameHalfyear(const datetime date1, const datetime date2)
{
    if (((TimeMonth(date1) - 1) / 6 == (TimeMonth(date2) - 1) / 6) && (TimeYear(date1) == TimeYear(date2))) return true;
    return false;
}

//+------------------------------------------------------------------+
//| SameYear                                                         |
//+------------------------------------------------------------------+
int CMarketProfile::SameYear(const datetime date1, const datetime date2)
{
    if (TimeYear(date1) == TimeYear(date2)) return true;
    return false;
}

//+------------------------------------------------------------------+
//| PutDot                                                           |
//+------------------------------------------------------------------+
datetime CMarketProfile::PutDot(const double price, const int start_bar, const int range, const int bar, string rectangle_prefix = "", datetime converted_time = 0)
{
    double divisor, color_shift;
    color colour = -1;

    string LastNameStart = " " + TimeToString(iTime(_Symbol, _Timeframe, bar + start_bar)) + " ";
    string LastName = LastNameStart + DoubleToString(price, _Digits);

    if (m_settings.ColorBullBear) colour = CalculateProperColor();

    if (NeedToReviewColors)
    {
        int obj_total = ObjectsTotal(_ChartID, -1, OBJ_RECTANGLE);
        for (int i = obj_total - 1; i >= 0; i--)
        {
            string obj = ObjectName(_ChartID, i, -1, OBJ_RECTANGLE);
            if (StringSubstr(obj, 0, StringLen(rectangle_prefix + "MP" + Suffix)) != rectangle_prefix + "MP" + Suffix) continue;
            if (StringSubstr(obj, 0, StringLen(rectangle_prefix + "MP" + Suffix + LastNameStart)) != rectangle_prefix + "MP" + Suffix + LastNameStart) break;
            ObjectSetInteger(_ChartID, obj, OBJPROP_COLOR, colour);
        }
    }

    if (ObjectFind(_ChartID, rectangle_prefix + "MP" + Suffix + LastName) >= 0)
    {
        if ((!m_settings.RightToLeft) || (converted_time == 0)) return 0;
    }

    datetime time_end, time_start;
    datetime prev_time = converted_time;
    if (converted_time != 0)
    {
        static datetime prev_time_start_bar = 0;
        if ((iTime(_Symbol, _Timeframe, start_bar) != prev_time_start_bar) && (prev_time_start_bar != 0))
        {
            NeedToRestartDrawing = true;
        }
        prev_time_start_bar = iTime(_Symbol, _Timeframe, start_bar);

        int x = -1;
        for (int i = range + 1; i > 0; i--)
        {
            prev_time = converted_time;
            if (converted_time == iTime(_Symbol, _Timeframe, 0))
            {
                x = i + 1;
                converted_time = iTime(_Symbol, _Timeframe, 1);
            }
            else if (converted_time < iTime(_Symbol, _Timeframe, 0))
            {
                if (x == -1) x = iBarShift(_Symbol, _Timeframe, converted_time) + i + 1;
                converted_time = iTime(_Symbol, _Timeframe, x - i);
            }
            else converted_time -= PeriodSeconds(_Timeframe);
        }
        time_end = converted_time;
        time_start = prev_time;
    }
    else
    {
        if (start_bar - (range + 1) < 0) time_end = iTime(_Symbol, _Timeframe, 0) + PeriodSeconds(_Timeframe);
        else time_end = iTime(_Symbol, _Timeframe, start_bar - (range + 1));
        time_start = iTime(_Symbol, _Timeframe, start_bar - range);
    }

    if (ObjectFind(_ChartID, rectangle_prefix + "MP" + Suffix + LastName) >= 0) // Need to move the rectangle.
    {
        ObjectSetInteger(_ChartID, rectangle_prefix  + "MP" + Suffix + LastName, OBJPROP_TIME, 0, time_start);
        ObjectSetInteger(_ChartID, rectangle_prefix  + "MP" + Suffix + LastName, OBJPROP_TIME, 1, time_end);
    }
    else ObjectCreate(_ChartID, rectangle_prefix + "MP" + Suffix + LastName, OBJ_RECTANGLE, 0, time_start, price, time_end, price - onetick);

    if (!m_settings.ColorBullBear) // Otherwise, colour is already calculated.
    {
        int offset1, offset2;
        switch (CurrentColorScheme)
        {
        case Blue_to_Red:
            colour = 0x00FF0000; // clrBlue;
            offset1 = 0x00010000;
            offset2 = 0x00000001;
            break;
        case Red_to_Green:
            colour = 0x000000FF; // clrDarkRed;
            offset1 = 0x00000001;
            offset2 = 0x00000100;
            break;
        case Green_to_Blue:
            colour = 0x0000FF00; // clrDarkGreen;
            offset1 = 0x00000100;
            offset2 = 0x00010000;
            break;
        case Yellow_to_Cyan:
            colour = 0x0000FFFF; // clrYellow;
            offset1 = 0x00000001;
            offset2 = 0x00010000;
            break;
        case Magenta_to_Yellow:
            colour = 0x00FF00FF; // clrMagenta;
            offset1 = 0x00010000;
            offset2 = 0x00000100;
            break;
        case Cyan_to_Magenta:
            colour = 0x00FFFF00; // clrCyan;
            offset1 = 0x00000100;
            offset2 = 0x00000001;
            break;
        case Single_Color:
            colour = m_settings.SingleColor;
            offset1 = 0;
            offset2 = 0;
            break;
        default:
            colour = m_settings.SingleColor;
            offset1 = 0;
            offset2 = 0;
            break;
        }

        if (CurrentColorScheme != Single_Color)
        {
            divisor = 1.0 / 0xFF * (double)Max_number_of_bars_in_a_session;

            color_shift = MathFloor((double)bar / divisor);
            if ((int)color_shift < -255) color_shift = -255;

            colour += color((int)color_shift * offset1);
            colour -= color((int)color_shift * offset2);
        }
    }

    ObjectSetInteger(_ChartID, rectangle_prefix + "MP" + Suffix + LastName, OBJPROP_COLOR, colour);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MP" + Suffix + LastName, OBJPROP_FILL, true);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MP" + Suffix + LastName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "MP" + Suffix + LastName, OBJPROP_HIDDEN, true);

    return time_end;
}

//+------------------------------------------------------------------+
//| ObjectCleanup                                                    |
//+------------------------------------------------------------------+
void CMarketProfile::ObjectCleanup(string rectangle_prefix = "")
{
    ObjectsDeleteAll(_ChartID, rectangle_prefix + "MP" + Suffix, 0, OBJ_RECTANGLE);
    ObjectsDeleteAll(_ChartID, rectangle_prefix + "Median" + Suffix, 0, OBJ_TREND);
    ObjectsDeleteAll(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix, 0, OBJ_TREND);
    ObjectsDeleteAll(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix, 0, OBJ_TREND);
    ObjectsDeleteAll(_ChartID, rectangle_prefix + "VA_Top" + Suffix, 0, OBJ_TREND);
    ObjectsDeleteAll(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix, 0, OBJ_TREND);
    if (m_settings.ShowValueAreaRays != None)
    {
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "Value Area HighRay" + Suffix, 0, OBJ_TREND);
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "Value Area LowRay" + Suffix, 0, OBJ_TREND);
    }
    if (m_settings.ShowMedianRays != None)
    {
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "Median Ray" + Suffix, 0, OBJ_TREND);
    }
    if (m_settings.ShowKeyValues)
    {
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "VAH" + Suffix, 0, OBJ_TEXT);
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "VAL" + Suffix, 0, OBJ_TEXT);
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "POC" + Suffix, 0, OBJ_TEXT);
    }
    if (m_settings.ShowSinglePrint != No)
    {
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "MPSP" + Suffix, 0, OBJ_RECTANGLE);
    }
    if (m_settings.SinglePrintRays)
    {
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "MPSPR" + Suffix, 0, OBJ_TREND);
    }
    if (m_settings.AlertArrows)
    {
        DeleteArrowsByPrefix(rectangle_prefix);
    }
    if (m_settings.ShowTPOCounts)
    {
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "TPOCA" + Suffix, 0, OBJ_TEXT);
        ObjectsDeleteAll(_ChartID, rectangle_prefix + "TPOCB" + Suffix, 0, OBJ_TEXT);
    }
}

//+------------------------------------------------------------------+
//| GetHoursAndMinutes                                               |
//+------------------------------------------------------------------+
bool CMarketProfile::GetHoursAndMinutes(string time_string, int& hours, int& minutes, int& time)
{
    if (StringLen(time_string) == 4) time_string = "0" + time_string;

    if (
        (StringLen(time_string) != 5) ||
        (time_string[2] != ':') ||
        ((time_string[0] < '0') || (time_string[0] > '2')) ||
        (((time_string[0] == '0') || (time_string[0] == '1')) && ((time_string[1] < '0') || (time_string[1] > '9'))) ||
        ((time_string[0] == '2') && ((time_string[1] < '0') || (time_string[1] > '3'))) ||
        ((time_string[3] < '0') || (time_string[3] > '5')) ||
        ((time_string[4] < '0') || (time_string[4] > '9'))
    )
    {
        Print("رشته زمان اشتباه: ", time_string, ". لطفاً از فرمت HH:MM استفاده کنید.");
        return false;
    }

    string result[];
    int number_of_substrings = StringSplit(time_string, ':', result);
    hours = (int)StringToInteger(result[0]);
    minutes = (int)StringToInteger(result[1]);
    time = hours * 60 + minutes;

    return true;
}

//+------------------------------------------------------------------+
//| CheckIntradaySession                                             |
//+------------------------------------------------------------------+
bool CMarketProfile::CheckIntradaySession(const bool enable, const string start_time, const string end_time, const color_scheme cs)
{
    if (enable)
    {
        if (!GetHoursAndMinutes(start_time, IDStartHours[IntradaySessionCount], IDStartMinutes[IntradaySessionCount], IDStartTime[IntradaySessionCount]))
        {
            Alert("فرمت رشته زمان اشتباه: ", start_time, ".");
            return false;
        }
        if (!GetHoursAndMinutes(end_time, IDEndHours[IntradaySessionCount], IDEndMinutes[IntradaySessionCount], IDEndTime[IntradaySessionCount]))
        {
            Alert("فرمت رشته زمان اشتباه: ", end_time, ".");
            return false;
        }
        if (IDEndTime[IntradaySessionCount] == 0)
        {
            IDEndHours[IntradaySessionCount] = 24;
            IDEndMinutes[IntradaySessionCount] = 0;
            IDEndTime[IntradaySessionCount] = 24 * 60;
        }

        IDColorScheme[IntradaySessionCount] = cs;

        if (IDEndTime[IntradaySessionCount] < IDStartTime[IntradaySessionCount]) IntradayCrossSessionDefined = IntradaySessionCount;

        IntradaySessionCount++;
    }
    return true;
}

//+------------------------------------------------------------------+
//| ProcessSession                                                   |
//+------------------------------------------------------------------+
bool CMarketProfile::ProcessSession(const int sessionstart, const int sessionend, const int i, const int rates_total, CRectangleMP* rectangle = NULL)
{
    string rectangle_prefix = "";

    if (sessionstart >= rates_total) return false;
    if (onetick == 0) return false;

    double SessionMax = DBL_MIN, SessionMin = DBL_MAX;

    for (int bar = sessionstart; bar >= sessionend; bar--)
    {
        if (iHigh(_Symbol, _Timeframe, bar) > SessionMax) SessionMax = iHigh(_Symbol, _Timeframe, bar);
        if (iLow(_Symbol, _Timeframe, bar) < SessionMin) SessionMin = iLow(_Symbol, _Timeframe, bar);
    }
    SessionMax = NormalizeDouble(SessionMax, DigitsM);
    SessionMin = NormalizeDouble(SessionMin, DigitsM);

    int session_counter = i;

    if (_Session == Rectangle)
    {
        rectangle_prefix = rectangle->name + "_";
        if (SessionMax > rectangle->RectanglePriceMax) SessionMax = NormalizeDouble(rectangle->RectanglePriceMax, DigitsM);
        if (SessionMin < rectangle->RectanglePriceMin) SessionMin = NormalizeDouble(rectangle->RectanglePriceMin, DigitsM);
    }
    else
    {
        bool need_to_increment = true;

        for (int j = 0; j < SessionsNumber; j++)
        {
            if (RememberSessionStart[j] == iTime(_Symbol, _Timeframe, sessionstart))
            {
                need_to_increment = false;
                session_counter = j;
                break;
            }
        }
        if (need_to_increment)
        {
            SessionsNumber++;
            session_counter = SessionsNumber - 1;
            ArrayResize(RememberSessionMax, SessionsNumber);
            ArrayResize(RememberSessionMin, SessionsNumber);
            ArrayResize(RememberSessionStart, SessionsNumber);
            ArrayResize(RememberSessionSuffix, SessionsNumber);
            ArrayResize(RememberSessionEnd, SessionsNumber);
        }
    }

    SessionMax = NormalizeDouble(MathRound(SessionMax / onetick) * onetick, DigitsM);
    SessionMin = NormalizeDouble(MathRound(SessionMin / onetick) * onetick, DigitsM);

    RememberSessionMax[session_counter] = SessionMax;
    RememberSessionMin[session_counter] = SessionMin;
    RememberSessionStart[session_counter] = iTime(_Symbol, _Timeframe, sessionstart);
    RememberSessionSuffix[session_counter] = Suffix;
    RememberSessionEnd[session_counter] = iTime(_Symbol, _Timeframe, sessionend);

    static double PreviousSessionMax = DBL_MIN;
    static datetime PreviousSessionStartTime = 0;
    if (iTime(_Symbol, _Timeframe, sessionstart) > PreviousSessionStartTime)
    {
        PreviousSessionMax = DBL_MIN;
        PreviousSessionStartTime = iTime(_Symbol, _Timeframe, sessionstart);
    }
    if ((FirstRunDone) && (i == _SessionsToCount - 1) && (PointMultiplier_calculated > 1))
    {
        if (SessionMax - PreviousSessionMax < onetick)
        {
            SessionMax = PreviousSessionMax;
        }
        else
        {
            if (PreviousSessionMax != DBL_MIN)
            {
                double nc = (SessionMax - PreviousSessionMax) / onetick;
                SessionMax = NormalizeDouble(PreviousSessionMax + MathRound(nc) * onetick, DigitsM);
            }
            PreviousSessionMax = SessionMax;
        }
    }

    int TPOperPrice[];
    int max = (int)MathRound((SessionMax - SessionMin) / onetick + 2);
    ArrayResize(TPOperPrice, max);
    ArrayInitialize(TPOperPrice, 0);

    bool SinglePrintTracking_array[];
    if (m_settings.SinglePrintRays)
    {
        ArrayResize(SinglePrintTracking_array, max);
        ArrayInitialize(SinglePrintTracking_array, false);
    }

    int MaxRange = 0;
    double PriceOfMaxRange = 0;
    double DistanceToCenter = DBL_MAX;

    datetime converted_time = 0;
    datetime converted_end_time = 0;
    datetime min_converted_end_time = UINT_MAX;
    if ((m_settings.RightToLeft) && ((sessionend == 0) || (_Session == Rectangle)))
    {
        int dummy_subwindow;
        double dummy_price;
        if (_Session == Rectangle) converted_time = rectangle->RectangleTimeMax;
        else ChartXYToTimePrice(_ChartID, (int)ChartGetInteger(_ChartID, CHART_WIDTH_IN_PIXELS), 0, dummy_subwindow, converted_time, dummy_price);
    }

    int TotalTPO = 0;

    for (double price = SessionMax; price >= SessionMin; price -= onetick)
    {
        price = NormalizeDouble(price, DigitsM);
        int range = 0;

        for (int bar = sessionstart; bar >= sessionend; bar--)
        {
            if ((price >= iLow(_Symbol, _Timeframe, bar)) && (price <= iHigh(_Symbol, _Timeframe, bar)))
            {
                if ((MaxRange < range) || ((MaxRange == range) && (MathAbs(price - (SessionMin + (SessionMax - SessionMin) / 2)) < DistanceToCenter)))
                {
                    MaxRange = range;
                    PriceOfMaxRange = price;
                    DistanceToCenter = MathAbs(price - (SessionMin + (SessionMax - SessionMin) / 2));
                }

                if (!m_settings.DisableHistogram && m_settings.enableDrawing)
                {
                    if (m_settings.ColorBullBear)
                    {
                        double close = iClose(_Symbol, _Timeframe, bar);
                        double open = iOpen(_Symbol, _Timeframe, bar);
                        if (close == open) CurrentBarDirection = Neutral;
                        else if (close > open) CurrentBarDirection = Bullish;
                        else if (close < open) CurrentBarDirection = Bearish;

                        if (bar == 0)
                        {
                            if (PreviousBarDirection == CurrentBarDirection) NeedToReviewColors = false;
                            else
                            {
                                NeedToReviewColors = true;
                                PreviousBarDirection = CurrentBarDirection;
                            }
                        }
                    }

                    if (!m_settings.RightToLeft) PutDot(price, sessionstart, range, bar - sessionstart, rectangle_prefix);
                    else
                    {
                        converted_end_time = PutDot(price, sessionstart, range, bar - sessionstart, rectangle_prefix, converted_time);
                        if (converted_end_time < min_converted_end_time) min_converted_end_time = converted_end_time;
                    }
                }

                int index = (int)MathRound((price - SessionMin) / onetick);
                TPOperPrice[index]++;
                range++;
                TotalTPO++;
            }
        }
        if (m_settings.ShowSinglePrint != No && m_settings.enableDrawing)
        {
            if (range == 1) PutSinglePrintMark(price, sessionstart, rectangle_prefix);
            else if (range > 1) RemoveSinglePrintMark(price, sessionstart, rectangle_prefix);
        }

        if (m_settings.SinglePrintRays)
        {
            int index = (int)MathRound((price - SessionMin) / onetick);
            if (range == 1) SinglePrintTracking_array[index] = true;
            else SinglePrintTracking_array[index] = false;
        }
    }

    if (m_settings.SinglePrintRays && m_settings.enableDrawing)
    {
        color spr_color = m_settings.SinglePrintColor;
        if ((m_settings.HideRaysFromInvisibleSessions) && (iTime(_Symbol, _Timeframe, (int)ChartGetInteger(_ChartID, CHART_FIRST_VISIBLE_BAR)) >= iTime(_Symbol, _Timeframe, sessionstart))) spr_color = clrNONE;

        for (double price = SessionMax; price >= SessionMin; price -= onetick)
        {
            price = NormalizeDouble(price, DigitsM);
            int index = (int)MathRound((price - SessionMin) / onetick);
            if (SinglePrintTracking_array[index])
            {
                if (price == SessionMax)
                {
                    PutSinglePrintRay(price, sessionstart, rectangle_prefix, spr_color);
                }
                else
                {
                    if (SinglePrintTracking_array[index + 1] == false)
                    {
                        PutSinglePrintRay(price, sessionstart, rectangle_prefix, spr_color);
                    }
                    else
                    {
                        RemoveSinglePrintRay(price, sessionstart, rectangle_prefix);
                    }
                }
                if (price == SessionMin)
                {
                    PutSinglePrintRay(price - onetick, sessionstart, rectangle_prefix, spr_color);
                }
                else
                {
                    if (SinglePrintTracking_array[index - 1] == false)
                    {
                        PutSinglePrintRay(price - onetick, sessionstart, rectangle_prefix, spr_color);
                    }
                    else
                    {
                        RemoveSinglePrintRay(price - onetick, sessionstart, rectangle_prefix);
                    }
                }
            }
            else
            {
                RemoveSinglePrintRay(price - onetick, sessionstart, rectangle_prefix);
            }
        }
    }

    if ((m_settings.EnableDevelopingPOC) || (m_settings.EnableDevelopingVAHVAL)) CalculateDevelopingPOCVAHVAL(sessionstart, sessionend, rectangle);

    int ValueControlTPO = (int)((double)TotalTPO * ValueAreaPercentage_double);
    index = (int)((PriceOfMaxRange - SessionMin) / onetick);
    if (index < 0) return false;
    int TPOcount = TPOperPrice[index];

    int up_offset = 1;
    int down_offset = 1;
    while (TPOcount < ValueControlTPO)
    {
        double abovePrice = PriceOfMaxRange + up_offset * onetick;
        double belowPrice = PriceOfMaxRange - down_offset * onetick;
        index = (int)MathRound((abovePrice - SessionMin) / onetick);
        int index2 = (int)MathRound((belowPrice - SessionMin) / onetick);
        if (((belowPrice < SessionMin) || (TPOperPrice[index] >= TPOperPrice[index2])) && (abovePrice <= SessionMax))
        {
            TPOcount += TPOperPrice[index];
            up_offset++;
        }
        else if (belowPrice >= SessionMin)
        {
            TPOcount += TPOperPrice[index2];
            down_offset++;
        }
        else if (TPOcount < ValueControlTPO)
        {
            break;
        }
    }
    string LastName = " " + TimeToString(iTime(_Symbol, _Timeframe, sessionstart));
    ObjectDelete(_ChartID, rectangle_prefix + "Median" + Suffix + LastName);
    index = (int)MathMax(sessionstart - MaxRange - 1, 0);
    datetime time_start, time_end;
    if ((m_settings.RightToLeft) && ((sessionend == 0) || (_Session == Rectangle)))
    {
        time_end = min_converted_end_time;
        time_start = converted_time;
    }
    else
    {
        time_end = iTime(_Symbol, _Timeframe, index);
        time_start = iTime(_Symbol, _Timeframe, sessionstart);
    }
    ObjectCreate(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJ_TREND, 0, time_start, PriceOfMaxRange, time_end, PriceOfMaxRange);
    color mc = m_settings.MedianColor;
    if ((double)(sessionstart - index) / (double)Max_number_of_bars_in_a_session * 100 >= m_settings.ProminentMedianPercentage)
    {
        mc = m_settings.ProminentMedianColor;
        ObjectSetInteger(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_WIDTH, m_settings.ProminentMedianWidth);
        ObjectSetInteger(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_STYLE, m_settings.ProminentMedianStyle);
    }
    else
    {
        ObjectSetInteger(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_WIDTH, m_settings.MedianWidth);
        ObjectSetInteger(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_STYLE, m_settings.MedianStyle);
    }
    ObjectSetInteger(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_COLOR, mc);
    ObjectSetInteger(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_BACK, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_RAY, false);
    ObjectSetString(_ChartID, rectangle_prefix + "Median" + Suffix + LastName, OBJPROP_TOOLTIP, "میانه (POC)");

    ObjectDelete(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName);
    ObjectCreate(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName, OBJ_TREND, 0, time_start, PriceOfMaxRange + up_offset * onetick, time_start, PriceOfMaxRange - down_offset * onetick + onetick);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName, OBJPROP_COLOR, m_settings.ValueAreaSidesColor);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName, OBJPROP_STYLE, m_settings.ValueAreaSidesStyle);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName, OBJPROP_WIDTH, m_settings.ValueAreaSidesWidth);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName, OBJPROP_BACK, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName, OBJPROP_RAY, false);
    ObjectSetString(_ChartID, rectangle_prefix + "VA_LeftSide" + Suffix + LastName, OBJPROP_TOOLTIP, "طرف چپ ناحیه ارزش");
    ObjectDelete(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName);
    ObjectCreate(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName, OBJ_TREND, 0, time_end, PriceOfMaxRange + up_offset * onetick, time_end, PriceOfMaxRange - down_offset * onetick + onetick);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName, OBJPROP_COLOR, m_settings.ValueAreaSidesColor);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName, OBJPROP_STYLE, m_settings.ValueAreaSidesStyle);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName, OBJPROP_WIDTH, m_settings.ValueAreaSidesWidth);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName, OBJPROP_BACK, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName, OBJPROP_RAY, false);
    ObjectSetString(_ChartID, rectangle_prefix + "VA_RightSide" + Suffix + LastName, OBJPROP_TOOLTIP, "طرف راست ناحیه ارزش");

    ObjectDelete(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName);
    ObjectCreate(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName, OBJ_TREND, 0, time_start, PriceOfMaxRange + up_offset * onetick, time_end, PriceOfMaxRange + up_offset * onetick);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName, OBJPROP_COLOR, m_settings.ValueAreaHighLowColor);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName, OBJPROP_STYLE, m_settings.ValueAreaHighLowStyle);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName, OBJPROP_WIDTH, m_settings.ValueAreaHighLowWidth);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName, OBJPROP_BACK, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName, OBJPROP_RAY, false);
    ObjectSetString(_ChartID, rectangle_prefix + "VA_Top" + Suffix + LastName, OBJPROP_TOOLTIP, "بالای ناحیه ارزش");
    ObjectDelete(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName);
    ObjectCreate(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName, OBJ_TREND, 0, time_start, PriceOfMaxRange - down_offset * onetick + onetick, time_end, PriceOfMaxRange - down_offset * onetick + onetick);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName, OBJPROP_COLOR, m_settings.ValueAreaHighLowColor);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName, OBJPROP_STYLE, m_settings.ValueAreaHighLowStyle);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName, OBJPROP_WIDTH, m_settings.ValueAreaHighLowWidth);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName, OBJPROP_BACK, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName, OBJPROP_RAY, false);
    ObjectSetString(_ChartID, rectangle_prefix + "VA_Bottom" + Suffix + LastName, OBJPROP_TOOLTIP, "پایین ناحیه ارزش");

    if (m_settings.ShowKeyValues)
    {
        datetime value_time = time_start;
        ENUM_ANCHOR_POINT anchor_poc = ANCHOR_RIGHT, anchor_va = ANCHOR_RIGHT;
        if ((m_settings.RightToLeft) && ((sessionend == 0) || (_Session == Rectangle)))
        {
            value_time = time_end;
            if (((_Session != Rectangle) && ((m_settings.ShowValueAreaRays == All) || (m_settings.ShowValueAreaRays == Current) || (m_settings.ShowValueAreaRays == PreviousCurrent))) ||
                ((_Session == Rectangle) && (((m_settings.ShowValueAreaRays == AllPrevious) && (SessionsNumber - session_counter >= 2)) ||
                 (((m_settings.ShowValueAreaRays == Previous) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - session_counter == 2)) ||
                 (((m_settings.ShowValueAreaRays == Current) || (m_settings.ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - session_counter == 1)) ||
                 (m_settings.ShowValueAreaRays == All))))
            {
                anchor_va = ANCHOR_RIGHT_LOWER;
            }
            if (((_Session != Rectangle) && ((m_settings.ShowMedianRays == All) || (m_settings.ShowMedianRays == Current) || (m_settings.ShowMedianRays == PreviousCurrent))) ||
                ((_Session == Rectangle) && (((m_settings.ShowMedianRays == AllPrevious) && (SessionsNumber - session_counter >= 2)) ||
                 (((m_settings.ShowMedianRays == Previous) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - session_counter == 2)) ||
                 (((m_settings.ShowMedianRays == Current) || (m_settings.ShowMedianRays == PreviousCurrent)) && (SessionsNumber - session_counter == 1)) ||
                 (m_settings.ShowMedianRays == All))))
            {
                anchor_poc = ANCHOR_RIGHT_LOWER;
            }
        }
        ValuePrintOut(rectangle_prefix + "VAH" + Suffix + LastName, value_time, PriceOfMaxRange + up_offset * onetick, "قیمت بالای ناحیه ارزش: " + DoubleToString(PriceOfMaxRange + up_offset * onetick, _Digits), anchor_va);
        ValuePrintOut(rectangle_prefix + "VAL" + Suffix + LastName, value_time, PriceOfMaxRange - down_offset * onetick, "قیمت پایین ناحیه ارزش: " + DoubleToString(PriceOfMaxRange - down_offset * onetick, _Digits), anchor_va);
        ValuePrintOut(rectangle_prefix + "POC" + Suffix + LastName, value_time, PriceOfMaxRange, "قیمت POC (میانه): " + DoubleToString(PriceOfMaxRange, _Digits), anchor_poc);
    }

    if (m_settings.ShowTPOCounts)
    {
        int TPOCountAbove = 0;
        for (double abovePrice = PriceOfMaxRange + onetick; abovePrice <= SessionMax; abovePrice += onetick)
        {
            index = (int)MathRound((abovePrice - SessionMin) / onetick);
            TPOCountAbove += TPOperPrice[index];
        }
        int TPOCountBelow = 0;
        for (double belowPrice = PriceOfMaxRange - onetick; belowPrice >= SessionMin; belowPrice -= onetick)
        {
            index = (int)MathRound((belowPrice - SessionMin) / onetick);
            TPOCountBelow += TPOperPrice[index];
        }
        ENUM_ANCHOR_POINT anchor_tpoca = ANCHOR_LEFT_LOWER, anchor_tpocb = ANCHOR_LEFT_UPPER;
        datetime value_time = time_end;
        if ((m_settings.RightToLeft) && ((sessionend == 0) || (_Session == Rectangle)))
        {
            value_time = time_start;
            anchor_tpoca = ANCHOR_RIGHT_LOWER;
            anchor_tpocb = ANCHOR_RIGHT_UPPER;
        }
        ValuePrintOut(rectangle_prefix + "TPOCA" + Suffix + LastName, value_time, PriceOfMaxRange, "تعداد TPOها بالای POC: " + IntegerToString(TPOCountAbove), anchor_tpoca, m_settings.TPOCountAboveColor, TPOCountAbove);
        ValuePrintOut(rectangle_prefix + "TPOCB" + Suffix + LastName, value_time, PriceOfMaxRange, "تعداد TPOها پایین POC: " + IntegerToString(TPOCountBelow), anchor_tpocb, m_settings.TPOCountBelowColor, TPOCountBelow);
    }

    return true;
}

//+--------------------------------------------------------------------------+
//| A cycle through intraday sessions for a given day with necessary checks. |
//| Returns true on success, false - on failure.                             |
//+--------------------------------------------------------------------------+
bool CMarketProfile::ProcessIntradaySession(int sessionstart, int sessionend, const int i, const int rates_total)
{
    int remember_sessionstart = sessionstart;
    int remember_sessionend = sessionend;

    if (remember_sessionend >= rates_total) return false;

    bool ContinuePreventionFlag = false;

    int IntradaySessionCount_tmp = IntradaySessionCount;
    if ((_SaturdaySunday == Ignore_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) == 1) && (IntradayCrossSessionDefined > -1))
    {
        IntradaySessionCount_tmp++;
    }

    for (int intraday_i = 0; intraday_i < IntradaySessionCount_tmp; intraday_i++)
    {
        if (ContinuePreventionFlag) break;
        if (intraday_i == IntradaySessionCount)
        {
            intraday_i = IntradayCrossSessionDefined;
            ContinuePreventionFlag = true;
        }
        Suffix = "_ID" + IntegerToString(intraday_i);
        CurrentColorScheme = IDColorScheme[intraday_i];
        Max_number_of_bars_in_a_session = IDEndTime[intraday_i] - IDStartTime[intraday_i];
        if (Max_number_of_bars_in_a_session < 0)
        {
            Max_number_of_bars_in_a_session = 24 * 60 + Max_number_of_bars_in_a_session;
            if (_SaturdaySunday == Ignore_Saturday_Sunday)
            {
                if ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) == 1) && (!ContinuePreventionFlag))
                {
                    Max_number_of_bars_in_a_session -= 24 * 60 - IDStartTime[intraday_i];
                }
                else if (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) == 5)
                {
                    Max_number_of_bars_in_a_session -= IDEndTime[intraday_i];
                }
            }
        }

        if (_SaturdaySunday == Append_Saturday_Sunday)
        {
            if (((IDStartTime[intraday_i] == 0) || (IDStartTime[intraday_i] > IDEndTime[intraday_i])) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) == 0))
            {
                Max_number_of_bars_in_a_session += 24 * 60 - (TimeHour(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60));
                if (IDStartTime[intraday_i] > IDEndTime[intraday_i]) Max_number_of_bars_in_a_session -= 24 * 60 - IDStartTime[intraday_i];
            }
            else if (((IDEndTime[intraday_i] == 24 * 60) || (IDStartTime[intraday_i] > IDEndTime[intraday_i])) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) == 5))
            {
                Max_number_of_bars_in_a_session += 24 * 60;
                if (IDStartTime[intraday_i] > IDEndTime[intraday_i]) Max_number_of_bars_in_a_session -= 24 * 60 - IDEndTime[intraday_i];
            }
        }

        Max_number_of_bars_in_a_session = Max_number_of_bars_in_a_session / (PeriodSeconds(_Timeframe) / 60);

        int hour, minute, time;
        if (FirstRunDone)
        {
            hour = TimeHour(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60);
            minute = TimeMinute(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60);
            time = hour * 60 + minute;

            if (IDStartTime[intraday_i] < IDEndTime[intraday_i])
            {
                if (_SaturdaySunday == Append_Saturday_Sunday)
                {
                    if ((IDStartTime[intraday_i] != 0) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 0)) continue;
                    if ((IDEndTime[intraday_i] != 24 * 60) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 6)) continue;
                }
                if ((_SaturdaySunday == Append_Saturday_Sunday) && (IDStartTime[intraday_i] == 0) && ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 0) || ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 1) && (time < IDEndTime[intraday_i]))))
                {
                    sessionstart = remember_sessionstart;
                }
                else if (((time < IDEndTime[intraday_i]) && (time >= IDStartTime[intraday_i]))
                         || ((_SaturdaySunday == Append_Saturday_Sunday) && (IDEndTime[intraday_i] == 24 * 60) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 6)))
                {
                    sessionstart = 0;
                    int sessiontime = TimeHour(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60);
                    while (((sessiontime > IDStartTime[intraday_i])
                            && ((TimeDayOfYear(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == TimeDayOfYear(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60)) || ((_SaturdaySunday == Append_Saturday_Sunday) && (IDEndTime[intraday_i] == 24 * 60) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 6))))
                            || ((_SaturdaySunday == Append_Saturday_Sunday) && (IDEndTime[intraday_i] == 24 * 60) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 6)))
                    {
                        sessionstart++;
                        sessiontime = TimeHour(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60);
                    }
                    if (sessionstart > remember_sessionstart) sessionstart = remember_sessionstart;
                }
                else continue;
            }
            else if (IDStartTime[intraday_i] > IDEndTime[intraday_i])
            {
                if ((_SaturdaySunday == Append_Saturday_Sunday) && ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 0) || ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 1) && (time < IDEndTime[intraday_i]))))
                {
                    sessionstart = remember_sessionstart;
                }
                else if ((_SaturdaySunday == Ignore_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 1) && (time < IDEndTime[intraday_i]))
                {
                    sessionstart = remember_sessionstart;
                }
                else if (((time < IDEndTime[intraday_i]) || (time >= IDStartTime[intraday_i]))
                         || ((_SaturdaySunday == Append_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60) == 6)))
                {
                    sessionstart = 0;
                    int sessiontime = TimeHour(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60);
                    while (((sessiontime > IDStartTime[intraday_i]) && (iTime(_Symbol, _Timeframe, 0) - iTime(_Symbol, _Timeframe, sessionstart) <= 3600 * 24))
                            || ((sessiontime < IDEndTime[intraday_i]) && (TimeDayOfYear(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == TimeDayOfYear(iTime(_Symbol, _Timeframe, 0) + m_settings.TimeShiftMinutes * 60)))
                            || ((_SaturdaySunday == Append_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 6)))
                    {
                        sessionstart++;
                        sessiontime = TimeHour(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60);
                    }
                    if (iTime(_Symbol, _Timeframe, 0) - iTime(_Symbol, _Timeframe, sessionstart) > 3600 * 24) sessionstart--;
                }
                else continue;
            }
            else continue;

            sessionend = 0;

            if (!ProcessSession(sessionstart, sessionend, i, rates_total)) return false;
        }
        else
        {
            sessionend = remember_sessionend;

            if (IDStartTime[intraday_i] < IDEndTime[intraday_i])
            {
                if ((_SaturdaySunday == Append_Saturday_Sunday)/* && (IDEndTime[intraday_i] == 24 * 60)*/ && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60) == 6) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) == 5))
                {
                }
                else if (TimeHour(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60) < IDStartTime[intraday_i]) continue;
                if ((_SaturdaySunday == Append_Saturday_Sunday) && (((IDStartTime[intraday_i] == 0) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60) == 0)) || ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60) == 1) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) == 0))))
                {
                }
                else if (TimeHour(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) >= IDEndTime[intraday_i]) continue;
                if ((_SaturdaySunday == Append_Saturday_Sunday) && (IDEndTime[intraday_i] == 24 * 60) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 5))
                {
                }
                else if ((_SaturdaySunday == Append_Saturday_Sunday) && (IDStartTime[intraday_i] == 0) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60) == 0))
                {
                }
                else while ((sessionend < rates_total) && ((TimeHour(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60) >= IDEndTime[intraday_i]) || ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60) == 6) && (_SaturdaySunday == Append_Saturday_Sunday))))
                {
                    sessionend++;
                }
                if (sessionend == rates_total) sessionend--;

                if ((_SaturdaySunday == Append_Saturday_Sunday) && (IDStartTime[intraday_i] == 0) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 0))
                {
                    sessionstart = remember_sessionstart;
                }
                else
                {
                    sessionstart = sessionend;
                    while ((sessionstart < rates_total) && (((TimeHour(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) >= IDStartTime[intraday_i])
                                                            && ((TimeDayOfYear(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == TimeDayOfYear(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60)) || ((_SaturdaySunday == Append_Saturday_Sunday) && (IDEndTime[intraday_i] == 24 * 60) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60) == 6))))
                                                            || ((_SaturdaySunday == Append_Saturday_Sunday) && (IDEndTime[intraday_i] == 24 * 60) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 6))
                                                           ))
                    {
                        sessionstart++;
                    }
                    sessionstart--;
                }
            }
            else if (IDStartTime[intraday_i] > IDEndTime[intraday_i])
            {
                if ((_SaturdaySunday == Append_Saturday_Sunday) && (((TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 5) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60) == 6)) || ((TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 0) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60) == 1))))
                {
                }
                else if (TimeHour(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60) < IDStartTime[intraday_i]) continue;

                if ((_SaturdaySunday == Append_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 0))
                {
                    sessionstart = remember_sessionstart;
                }
                else if ((_SaturdaySunday == Ignore_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) == 1) && (!ContinuePreventionFlag))
                {
                    sessionstart = remember_sessionstart;
                    if (TimeHour(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) >= IDEndTime[intraday_i]) continue;
                }
                else
                {
                    sessionstart = remember_sessionend;
                    while ((sessionstart < rates_total) && (((TimeHour(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) >= IDStartTime[intraday_i])
                                                            && ((TimeDayOfYear(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == TimeDayOfYear(iTime(_Symbol, _Timeframe, remember_sessionend) + m_settings.TimeShiftMinutes * 60)) || (TimeDayOfYear(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == TimeDayOfYear(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60)))
                                                            || ((_SaturdaySunday == Append_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 6))
                                                           ))
                    {
                        sessionstart++;
                    }
                    sessionstart--;
                }

                int sessionlength;
                if ((_SaturdaySunday == Append_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60) == 6))
                {
                }
                else if ((_SaturdaySunday == Append_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 0))
                {
                    while ((sessionend < rates_total) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60) == 1) && (TimeHour(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60) * 60 + TimeMinute(iTime(_Symbol, _Timeframe, sessionend) + m_settings.TimeShiftMinutes * 60) >= IDEndTime[intraday_i]))
                    {
                        sessionend++;
                    }
                }
                else if ((_SaturdaySunday == Ignore_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, remember_sessionstart) + m_settings.TimeShiftMinutes * 60) == 5))
                {
                    sessionend = remember_sessionend;
                }
                else
                {
                    sessionend = sessionstart;
                    sessionlength = (24 * 60 - IDStartTime[intraday_i] + IDEndTime[intraday_i]) * 60;
                    if ((_SaturdaySunday == Ignore_Saturday_Sunday) && (TimeDayOfWeek(iTime(_Symbol, _Timeframe, sessionstart) + m_settings.TimeShiftMinutes * 60) == 1) && (!ContinuePreventionFlag)) sessionlength -= (24 * 60 - IDStartTime[intraday_i]) * 60;
                    while ((sessionend >= 0) && (iTime(_Symbol, _Timeframe, sessionend) - iTime(_Symbol, _Timeframe, sessionstart) < sessionlength))
                    {
                        sessionend--;
                    }
                    sessionend++;
                }
            }
            else continue;

            if (sessionend == sessionstart) continue;

            if (!ProcessSession(sessionstart, sessionend, i, rates_total)) return false;
        }
    }
    Suffix = "_ID";

    return true;
}

//+------------------------------------------------------------------+
//| TimeHour                                                         |
//+------------------------------------------------------------------+
int TimeHour(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.hour;
}

//+------------------------------------------------------------------+
//| TimeMinute                                                       |
//+------------------------------------------------------------------+
int TimeMinute(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.min;
}

//+------------------------------------------------------------------+
//| TimeDay                                                          |
//+------------------------------------------------------------------+
int TimeDay(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.day;
}

//+------------------------------------------------------------------+
//| TimeDayOfWeek                                                    |
//+------------------------------------------------------------------+
int TimeDayOfWeek(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.day_of_week;
}

//+------------------------------------------------------------------+
//| TimeDayOfYear                                                    |
//+------------------------------------------------------------------+
int TimeDayOfYear(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.day_of_year;
}

//+------------------------------------------------------------------+
//| TimeMonth                                                        |
//+------------------------------------------------------------------+
int TimeMonth(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.mon;
}

//+------------------------------------------------------------------+
//| TimeYear                                                         |
//+------------------------------------------------------------------+
int TimeYear(const datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return dt.year;
}

//+------------------------------------------------------------------+
//| TimeAbsoluteDay                                                  |
//+------------------------------------------------------------------+
int TimeAbsoluteDay(const datetime time)
{
    return ((int)time / 86400);
}

//+------------------------------------------------------------------+
//| CheckRays                                                        |
//+------------------------------------------------------------------+
void CheckRays()
{
    for (int i = 0; i < SessionsNumber; i++)
    {
        string last_name = " " + TimeToString(RememberSessionStart[i]);
        string suffix = RememberSessionSuffix[i];
        string rec_name = "";

        if (_Session == Rectangle) rec_name = MPR_Array[i].name + "_";

        // Process single print rays to hide those that should not be visible.
        if ((HideRaysFromInvisibleSessions) && (SinglePrintRays))
        {
            int obj_total = ObjectsTotal(ChartID(), 0, OBJ_TREND);
            for (int j = 0; j < obj_total; j++)
            {
                string obj_name = ObjectName(ChartID(), j, 0, OBJ_TREND);
                if (StringSubstr(obj_name, 0, StringLen(rec_name + "MPSPR" + suffix + last_name)) != rec_name + "MPSPR" + suffix + last_name) continue; // Not a single print ray.
                if (iTime(Symbol(), Period(), (int)ChartGetInteger(ChartID(), CHART_FIRST_VISIBLE_BAR)) >= RememberSessionStart[i]) // Too old.
                {
                    ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, clrNONE); // Hide.
                }
                else {ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, SinglePrintColor);} // Unhide.
            }
        }

        // If median rays should be created for the given trading session:
        if (((ShowMedianRays == AllPrevious) && (SessionsNumber - i >= 2)) ||
            (((ShowMedianRays == Previous) || (ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i == 2)) ||
            (((ShowMedianRays == Current) || (ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i == 1)) ||
            (ShowMedianRays == All))
        {
            double median_price = ObjectGetDouble(ChartID(), rec_name + "Median" + suffix + last_name, OBJPROP_PRICE, 0);
            datetime median_time = (datetime)ObjectGetInteger(ChartID(), rec_name + "Median" + suffix + last_name, OBJPROP_TIME, 1);

            // Create rays only if the median doesn't end behind the screen's left edge.
            if (!((HideRaysFromInvisibleSessions) && (iTime(Symbol(), Period(), (int)ChartGetInteger(ChartID(), CHART_FIRST_VISIBLE_BAR)) >= median_time)))
            {
                // Draw new median ray.
                if (ObjectFind(ChartID(), rec_name + "Median Ray" + suffix + last_name) < 0)
                {
                    ObjectCreate(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJ_TREND, 0, RememberSessionStart[i], median_price, median_time, median_price);
                    ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_COLOR, MedianColor);
                    ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_STYLE, MedianRayStyle);
                    ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_WIDTH, MedianRayWidth);
                    ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_BACK, false);
                    ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_SELECTABLE, false);
                    if ((RightToLeft) && (i == SessionsNumber - 1) && (_Session != Rectangle))
                    {
                        ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_LEFT, true);
                        ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_RIGHT, false);
                    }
                    else
                    {
                        ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_RAY_LEFT, false);
                    }
                    ObjectSetInteger(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_HIDDEN, true);
                    ObjectSetString(ChartID(), rec_name + "Median Ray" + suffix + last_name, OBJPROP_TOOLTIP, "اشعه میانه");
                }
                else
                {
                    ObjectMove(ChartID(), rec_name + "Median Ray" + suffix + last_name, 0, RememberSessionStart[i], median_price);
                    ObjectMove(ChartID(), rec_name + "Median Ray" + suffix + last_name, 1, median_time, median_price);
                }
            }
            else ObjectDelete(ChartID(), rec_name + "Median Ray" + suffix + last_name); // Delete a ray that starts from behind the screen.
        }

        // Should also delete obsolete rays that should not exist anymore.
        if ((((ShowMedianRays == Previous) || (ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i > 2)) ||
            ((ShowMedianRays == Current) && (SessionsNumber - i > 1)))
        {
            ObjectDelete(ChartID(), rec_name + "Median Ray" + suffix + last_name);
        }

        // If value area rays should be created for the given trading session:
        if (((ShowValueAreaRays == AllPrevious) && (SessionsNumber - i >= 2)) ||
            (((ShowValueAreaRays == Previous) || (ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i == 2)) ||
            (((ShowValueAreaRays == Current) || (ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i == 1)) ||
            (ShowValueAreaRays == All))
        {
            double va_high_price = ObjectGetDouble(ChartID(), rec_name + "VA_Top" + suffix + last_name, OBJPROP_PRICE, 0);
            double va_low_price = ObjectGetDouble(ChartID(), rec_name + "VA_Bottom" + suffix + last_name, OBJPROP_PRICE, 0);
            datetime va_time = (datetime)ObjectGetInteger(ChartID(), rec_name + "VA_Top" + suffix + last_name, OBJPROP_TIME, 1);
            // Create rays only if the value area doesn't end behind the screen's left edge.
            if (!((HideRaysFromInvisibleSessions) && (iTime(Symbol(), Period(), (int)ChartGetInteger(ChartID(), CHART_FIRST_VISIBLE_BAR)) >= va_time)))
            {
                // Draw new value area high ray.
                if (ObjectFind(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name) < 0)
                {
                    ObjectCreate(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJ_TREND, 0, RememberSessionStart[i], va_high_price, va_time, va_high_price);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_COLOR, ValueAreaHighLowColor);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_STYLE, ValueAreaRayHighLowStyle);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_WIDTH, ValueAreaRayHighLowWidth);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_BACK, false);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_SELECTABLE, false);
                    if ((RightToLeft) && (i == SessionsNumber - 1) && (_Session != Rectangle))
                    {
                        ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_LEFT, true);
                        ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_RIGHT, false);
                    }
                    else
                    {
                        ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_RAY_LEFT, false);
                    }
                    ObjectSetInteger(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_HIDDEN, true);
                    ObjectSetString(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, OBJPROP_TOOLTIP, "اشعه بالای ناحیه ارزش");
                }
                else
                {
                    ObjectMove(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, 0, RememberSessionStart[i], va_high_price);
                    ObjectMove(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name, 1, va_time, va_high_price);
                }

                // Draw new value area low ray.
                if (ObjectFind(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name) < 0)
                {
                    ObjectCreate(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJ_TREND, 0, RememberSessionStart[i], va_low_price, va_time, va_low_price);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_COLOR, ValueAreaHighLowColor);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_STYLE, ValueAreaRayHighLowStyle);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_WIDTH, ValueAreaRayHighLowWidth);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_BACK, false);
                    ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_SELECTABLE, false);
                    if ((RightToLeft) && (i == SessionsNumber - 1) && (_Session != Rectangle))
                    {
                        ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_LEFT, true);
                        ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_RIGHT, false);
                    }
                    else
                    {
                        ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_RIGHT, true);
                        ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_RAY_LEFT, false);
                    }
                    ObjectSetInteger(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_HIDDEN, true);
                    ObjectSetString(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, OBJPROP_TOOLTIP, "اشعه پایین ناحیه ارزش");
                }
                else
                {
                    ObjectMove(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, 0, RememberSessionStart[i], va_low_price);
                    ObjectMove(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name, 1, va_time, va_low_price);
                }
            }
            else
            {
                ObjectDelete(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name);
                ObjectDelete(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name);
            }
        }

        // Should also delete obsolete rays that should not exist anymore.
        if ((((ShowValueAreaRays == Previous) || (ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i > 2)) ||
            ((ShowValueAreaRays == Current) && (SessionsNumber - i > 1)))
        {
            ObjectDelete(ChartID(), rec_name + "Value Area HighRay" + suffix + last_name);
            ObjectDelete(ChartID(), rec_name + "Value Area LowRay" + suffix + last_name);
        }

        // Ray intersections.
        if (RaysUntilIntersection != Stop_No_Rays)
        {
            if ((((ShowMedianRays == Previous) || (ShowMedianRays == PreviousCurrent)) && (SessionsNumber - i == 2)) || (((ShowMedianRays == AllPrevious) || (ShowMedianRays == All)) && (SessionsNumber - i >= 2)))
            {
                if ((RaysUntilIntersection == Stop_All_Rays)
                        || ((RaysUntilIntersection == Stop_All_Rays_Except_Prev_Session) && (SessionsNumber - i > 2))
                        || ((RaysUntilIntersection == Stop_Only_Previous_Session) && (SessionsNumber - i == 2)))
                    CheckRayIntersections(rec_name + "Median Ray" + suffix + last_name, i + 1);
            }
            if ((((ShowValueAreaRays == Previous) || (ShowValueAreaRays == PreviousCurrent)) && (SessionsNumber - i == 2)) || (((ShowValueAreaRays == AllPrevious) || (ShowValueAreaRays == All)) && (SessionsNumber - i >= 2)))
            {
                if ((RaysUntilIntersection == Stop_All_Rays)
                        || ((RaysUntilIntersection == Stop_All_Rays_Except_Prev_Session) && (SessionsNumber - i > 2))
                        || ((RaysUntilIntersection == Stop_Only_Previous_Session) && (SessionsNumber - i == 2)))
                {
                    CheckRayIntersections(rec_name + "Value Area HighRay" + suffix + last_name, i + 1);
                    CheckRayIntersections(rec_name + "Value Area LowRay" + suffix + last_name, i + 1);
                }
            }
        }

        if (AlertArrows)
        {
            int bar_start = iBarShift(Symbol(), Period(), RememberSessionEnd[i]) - 1;

            if (AlertForSinglePrint)
            {
                int obj_total = ObjectsTotal(ChartID(), 0, OBJ_TREND);
                for (int j = 0; j < obj_total; j++)
                {
                    string obj_name = ObjectName(ChartID(), j, 0, OBJ_TREND);
                    string obj_prefix = rec_name + "MPSPR" + suffix + last_name;
                    if (StringSubstr(obj_name, 0, StringLen(obj_prefix)) != obj_prefix) continue;
                    if ((color)ObjectGetInteger(ChartID(), obj_name, OBJPROP_COLOR) != clrNONE)
                    {
                        if (!FindAtLeastOneArrowForRay(obj_prefix))
                        {
                            for (int k = bar_start; k >= 0; k--)
                            {
                                CheckAndDrawArrow(k, ObjectGetDouble(ChartID(), obj_name, OBJPROP_PRICE, 0), obj_prefix);
                            }
                        }
                    }
                    else
                    {
                        DeleteArrowsByPrefix(obj_prefix);
                    }
                }
            }

            if (AlertForValueArea)
            {
                string obj_prefix = rec_name + "Value Area HighRay" + suffix + last_name;
                if (ObjectFind(ChartID(), obj_prefix) >= 0)
                {
                    if (!FindAtLeastOneArrowForRay(obj_prefix)) CheckHistoricalArrowsForNonMPSPRRays(bar_start, obj_prefix);
                }
                else
                {
                    DeleteArrowsByPrefix(obj_prefix);
                }

                obj_prefix = rec_name + "Value Area LowRay" + suffix + last_name;
                if (ObjectFind(ChartID(), obj_prefix) >= 0)
                {
                    if (!FindAtLeastOneArrowForRay(obj_prefix)) CheckHistoricalArrowsForNonMPSPRRays(bar_start, obj_prefix);
                }
                else
                {
                    DeleteArrowsByPrefix(obj_prefix);
                }
            }

            if (AlertForMedian)
            {
                string obj_prefix = rec_name + "Median Ray" + suffix + last_name;
                if (ObjectFind(ChartID(), obj_prefix) >= 0)
                {
                    if (!FindAtLeastOneArrowForRay(obj_prefix)) CheckHistoricalArrowsForNonMPSPRRays(bar_start, obj_prefix);
                }
                else
                {
                    DeleteArrowsByPrefix(obj_prefix);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| DeleteArrowsByPrefix                                             |
//+------------------------------------------------------------------+
void CMarketProfile::DeleteArrowsByPrefix(const string prefix)
{
    ObjectsDeleteAll(_ChartID, "ArrPB" + prefix, 0, OBJ_ARROW);
    ObjectsDeleteAll(_ChartID, "ArrCC" + prefix, 0, OBJ_ARROW);
    ObjectsDeleteAll(_ChartID, "ArrGC" + prefix, 0, OBJ_ARROW);
}

//+------------------------------------------------------------------+
//| FindAtLeastOneArrowForRay                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::FindAtLeastOneArrowForRay(const string ray_name)
{
    int objects_total = ObjectsTotal(_ChartID, 0, OBJ_ARROW);
    for (int i = 0; i < objects_total; i++)
    {
        string obj_name = ObjectName(_ChartID, i, 0, OBJ_ARROW);
        if (StringFind(obj_name, ray_name) != -1) return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| CheckHistoricalArrowsForNonMPSPRRays                             |
//+------------------------------------------------------------------+
void CMarketProfile::CheckHistoricalArrowsForNonMPSPRRays(const int bar_start, const string ray_name)
{
    int end_bar = 0;
    if (ObjectGetInteger(_ChartID, ray_name, OBJPROP_RAY_RIGHT) != true)
    {
        datetime end_time = (datetime)ObjectGetInteger(_ChartID, ray_name, OBJPROP_TIME, 1);
        end_bar = iBarShift(_Symbol, _Timeframe, end_time) + 1;
    }
    for (int k = bar_start; k >= end_bar; k--)
    {
        CheckAndDrawArrow(k, ObjectGetDouble(_ChartID, ray_name, OBJPROP_PRICE, 0), ray_name);
    }
}

//+------------------------------------------------------------------+
//| CheckAndDrawArrow                                                |
//+------------------------------------------------------------------+
void CMarketProfile::CheckAndDrawArrow(const int n, const double level, const string ray_name)
{
    if (m_settings.AlertOnPriceBreak)
    {
        if (((iHigh(_Symbol, _Timeframe, n) >= level) && (iClose(_Symbol, _Timeframe, n) < level) && (iClose(_Symbol, _Timeframe, n + 1) < level)) || ((iLow(_Symbol, _Timeframe, n) <= level) && (iClose(_Symbol, _Timeframe, n) > level) && (iClose(_Symbol, _Timeframe, n + 1) > level)))
        {
            string obj_name = "ArrPB" + ray_name;
            CreateArrowObject(obj_name, iTime(_Symbol, _Timeframe, n), iClose(_Symbol, _Timeframe, n), m_settings.AlertArrowCodePB, m_settings.AlertArrowColorPB, m_settings.AlertArrowWidthPB, "شکست قیمت");
        }
    }
    if (m_settings.AlertOnCandleClose)
    {
        if (((iClose(_Symbol, _Timeframe, n) >= level) && (iClose(_Symbol, _Timeframe, n + 1) < level)) || ((iClose(_Symbol, _Timeframe, n) <= level) && (iClose(_Symbol, _Timeframe, n + 1) > level)))
        {
            string obj_name = "ArrCC" + ray_name;
            CreateArrowObject(obj_name, iTime(_Symbol, _Timeframe, n), iClose(_Symbol, _Timeframe, n), m_settings.AlertArrowCodeCC, m_settings.AlertArrowColorCC, m_settings.AlertArrowWidthCC, "عبور بسته شدن شمع");
        }
    }
    if (m_settings.AlertOnGapCross)
    {
        if (((iLow(_Symbol, _Timeframe, n) > level) && (iHigh(_Symbol, _Timeframe, n + 1) < level)) || ((iLow(_Symbol, _Timeframe, n + 1) > level) && (iHigh(_Symbol, _Timeframe, n) < level)))
        {
            string obj_name = "ArrGC" + ray_name;
            CreateArrowObject(obj_name, iTime(_Symbol, _Timeframe, n), level, m_settings.AlertArrowCodeGC, m_settings.AlertArrowColorGC, m_settings.AlertArrowWidthGC, "عبور شکاف");
        }
    }
}

//+------------------------------------------------------------------+
//| CreateArrowObject                                                |
//+------------------------------------------------------------------+
void CMarketProfile::CreateArrowObject(const string name, const datetime time, const double price, const int code, const color colour, const int width, const string tooltip)
{
    string obj_name = name + IntegerToString(ArrowsCounter);
    ArrowsCounter++;
    ObjectCreate(_ChartID, obj_name, OBJ_ARROW, 0, time, price);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_ARROWCODE, code);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_COLOR, colour);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
    ObjectSetInteger(_ChartID, obj_name, OBJPROP_WIDTH, width);
    ObjectSetString(_ChartID, obj_name, OBJPROP_TOOLTIP, tooltip);
}

//+------------------------------------------------------------------+
//| CheckRayIntersections                                            |
//+------------------------------------------------------------------+
void CMarketProfile::CheckRayIntersections(const string object, const int start_j)
{
    if (ObjectFind(_ChartID, object) < 0) return;

    double price = ObjectGetDouble(_ChartID, object, OBJPROP_PRICE, 0);
    for (int j = start_j; j < SessionsNumber; j++)
    {
        if ((price <= RememberSessionMax[j]) && (price >= RememberSessionMin[j]))
        {
            ObjectSetInteger(_ChartID, object, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(_ChartID, object, OBJPROP_TIME, 1, RememberSessionStart[j]);
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| The end of the class.                                            |
//+------------------------------------------------------------------+
