undeclared identifier	PatternManager.mqh	152	48
undeclared identifier	PatternManager.mqh	169	48
cannot access to private member 'm_swingHighs_Array' declared in class 'MarketStructure'	PatternManager.mqh	233	41
   see declaration of variable 'MarketStructure::m_swingHighs_Array'	MarketStructureLibrary.mqh	411	21
cannot access to private member 'm_swingHighs_Array' declared in class 'MarketStructure'	PatternManager.mqh	235	49
   see declaration of variable 'MarketStructure::m_swingHighs_Array'	MarketStructureLibrary.mqh	411	21
cannot access to private member 'm_swingHighs_Array' declared in class 'MarketStructure'	PatternManager.mqh	236	58
   see declaration of variable 'MarketStructure::m_swingHighs_Array'	MarketStructureLibrary.mqh	411	21
cannot access to private member 'm_swingLows_Array' declared in class 'MarketStructure'	PatternManager.mqh	293	41
   see declaration of variable 'MarketStructure::m_swingLows_Array'	MarketStructureLibrary.mqh	412	21
cannot access to private member 'm_swingLows_Array' declared in class 'MarketStructure'	PatternManager.mqh	295	49
   see declaration of variable 'MarketStructure::m_swingLows_Array'	MarketStructureLibrary.mqh	412	21
cannot access to private member 'm_swingLows_Array' declared in class 'MarketStructure'	PatternManager.mqh	296	58
   see declaration of variable 'MarketStructure::m_swingLows_Array'	MarketStructureLibrary.mqh	412	21
'MarketStructure::FindOppositeSw…' - cannot access private member function	PatternManager.mqh	465	53
   see declaration of function 'MarketStructure::FindOppositeSwing'	MarketStructureLibrary.mqh	598	15
'MarketStructure::FindOppositeSw…' - cannot access private member function	PatternManager.mqh	469	53
   see declaration of function 'MarketStructure::FindOppositeSwing'	MarketStructureLibrary.mqh	598	15
'MarketStructure::FindOppositeSw…' - cannot access private member function	PatternManager.mqh	470	53
   see declaration of function 'MarketStructure::FindOppositeSwing'	MarketStructureLibrary.mqh	598	15
11 errors, 0 warnings		11	0








//+------------------------------------------------------------------+
//|                                           PatternManager.mqh       |
//|                                  Copyright 2025, Khajavi         |
//|                                        Powerd by HIPOALGORITM      |
//|------------------------------------------------------------------|
//|                بلوپرینت پروژه Memento: موتور شکار الگو             |
//|------------------------------------------------------------------|
//| فلسفه:                                                            |
//| این کتابخانه به عنوان یک ماژول هوشمند و خودکفا برای شناسایی        |
//| الگوهای Double Top/Bottom و Head & Shoulders عمل می‌کند.           |
//| سیستم بر اساس معماری "غلاف‌های ایزوله" طراحی شده و هر نمونه       |
//| (instance) از کلاس PatternManager برای یک تایم فریم خاص، یک       |
//| تحلیلگر کاملاً مستقل است.                                         |
//|                                                                  |
//| نحوه عملکرد:                                                      |
//| ۱. کمین (ایجاد فرضیه): با ثبت هر سقف/کف ساختاری جدید توسط کتابخانه |
//|    MarketStructure، سیستم یک یا چند "فرضیه الگو" ایجاد می‌کند.    |
//| ۲. مانیتورینگ: سیستم به صورت کندل به کندل، هر فرضیه فعال را زیر   |
//|    نظر می‌گیرد.                                                   |
//| ۳. تایید یا ابطال: بر اساس قوانین قیمتی دقیق و شخصی‌سازی شده،      |
//|    بازار تکلیف هر فرضیه را مشخص می‌کند. فرضیه یا تایید شده و به    |
//|    یک الگوی قابل معامله تبدیل می‌شود، یا باطل شده و از حافظه      |
//|    پاک می‌گردد.                                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Khajavi _ HipoAlgoritm"
#property link      "https://www.HipoAlgoritm.com"
#property version   "2.0" // نسخه منطبق بر بلوپرینت نهایی

#include "MarketStructureLibrary.mqh"

//+------------------------------------------------------------------+
//| شمارنده‌ها و ساختارهای داده (Enums & Structs)                     |
//+------------------------------------------------------------------+

//--- انواع الگوهای قابل شناسایی
enum ENUM_PATTERN_TYPE
{
   PATTERN_NONE,
   PATTERN_DOUBLE_TOP,
   PATTERN_DOUBLE_BOTTOM,
   PATTERN_HEAD_AND_SHOULDERS,
   PATTERN_INVERSE_HEAD_AND_SHOULDERS
};

//--- وضعیت یک فرضیه الگو (برای استفاده داخلی)
enum ENUM_HYPOTHESIS_STATUS
{
   STATUS_MONITORING,    // در حال نظارت
   STATUS_CONFIRMED,     // تایید شده
   STATUS_INVALIDATED    // باطل شده
};

//--- ساختار داده برای نگهداری اطلاعات یک "فرضیه" یا کمین فعال
struct PatternHypothesis
{
   ENUM_PATTERN_TYPE       type;                 // نوع الگوی فرضی
   ENUM_HYPOTHESIS_STATUS  status;               // وضعیت فعلی فرضیه
   
   //--- نقاط کلیدی ساختاری
   SwingPoint              p1;                   // قله/دره ۱ (مثلاً قله اول در DT یا شانه چپ در H&S)
   SwingPoint              p2;                   // قله/دره ۲ (مثلاً سر در H&S)
   
   //--- زون واکنش (محدوده تصمیم‌گیری)
   double                  reaction_zone_high;   // سقف زون
   double                  reaction_zone_low;    // کف زون
   
   //--- فلگ برای تایید ورود قیمت به زون
   bool                    entered_reaction_zone; // آیا قیمت وارد زون شده است؟
};

//--- ساختار داده برای نگهداری اطلاعات نهایی یک الگوی تایید شده
struct ConfirmedPattern
{
   ENUM_PATTERN_TYPE type;                     // نوع الگو
   datetime          confirmation_time;        // زمان تایید الگو (زمان کندل تایید)
   
   //--- نقاط کلیدی الگو
   SwingPoint        p1;                       // قله/دره اول یا شانه چپ
   SwingPoint        p2;                       // قله/دره دوم یا سر
   SwingPoint        p3;                       // شانه راست فرضی (زمان و قیمت کندل تایید)
   
   //--- نقاط خط گردن
   SwingPoint        neckline_p1;
   SwingPoint        neckline_p2;
};


//==================================================================//
//              کلاس اصلی: شکارچی الگو (PatternManager)              //
//==================================================================//
class PatternManager
{
private:
   //--- نمونه داخلی کتابخانه ساختار بازار (غلاف ایزوله)
   MarketStructure* m_structure_instance;
   
   //--- متغیرهای تنظیمات و محیط اجرا
   string           m_symbol;
   ENUM_TIMEFRAMES  m_timeframe;
   long             m_chartId;
   bool             m_enableLogging;
   string           m_timeframeSuffix;      // پسوند تایم‌فریم برای نامگذاری اشیاء MTF

   //--- متغیرهای حالت
   PatternHypothesis m_hypotheses[];         // آرایه فرضیه‌های فعال (کمین‌ها)
   ConfirmedPattern m_last_dtb;             // آخرین الگوی دابل تاپ/باتم تایید شده
   ConfirmedPattern m_last_hns;             // آخرین الگوی سر و شانه تایید شده
   
   //--- متغیرهای ردیابی برای تشخیص رویداد جدید
   datetime         m_last_processed_high_time;
   datetime         m_last_processed_low_time;

public:
   //+------------------------------------------------------------------+
   //| سازنده کلاس (Constructor)                                       |
   //+------------------------------------------------------------------+
   PatternManager(const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId, const bool enableLogging_in,
                  const int fibUpdateLevel_in, const int fractalLength_in)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      m_enableLogging = enableLogging_in;
      
      //--- ایجاد پسوند تایم‌فریم برای تمایز اشیاء در حالت MTF
      m_timeframeSuffix = " (" + TimeFrameToStringShort(timeframe) + ")";
      
      //--- **نکته کلیدی معماری: ایجاد نمونه خصوصی از MarketStructure**
      //--- این نمونه فقط برای تحلیل داخلی استفاده شده و چیزی روی چارت رسم نمی‌کند
      m_structure_instance = new MarketStructure(m_symbol, m_timeframe, m_chartId, false, false, fibUpdateLevel_in, fractalLength_in);
      
      //--- آماده‌سازی متغیرهای حالت
      ArrayResize(m_hypotheses, 0);
      ZeroMemory(m_last_dtb);
      ZeroMemory(m_last_hns);
      m_last_processed_high_time = 0;
      m_last_processed_low_time = 0;
      
      //--- پاکسازی اشیاء گرافیکی قدیمی مربوط به این نمونه
      string prefix = "PAT_" + m_timeframeSuffix;
      ObjectsDeleteAll(m_chartId, prefix);

      LogEvent("کلاس PatternManager برای نماد " + m_symbol + " و تایم فریم " + EnumToString(m_timeframe) + " آغاز به کار کرد.", m_enableLogging, "[PAT]");
   }
   
   //+------------------------------------------------------------------+
   //| مخرب کلاس (Destructor)                                          |
   //+------------------------------------------------------------------+
   ~PatternManager()
   {
      //--- حذف نمونه داخلی MarketStructure برای جلوگیری از نشت حافظه
      if(CheckPointer(m_structure_instance) == POINTER_VALID)
      {
         delete m_structure_instance;
      }
      
      //--- پاکسازی تمام اشیاء گرافیکی ایجاد شده توسط این نمونه
      string prefix = "PAT_" + m_timeframeSuffix;
      ObjectsDeleteAll(m_chartId, prefix);
      
      LogEvent("کلاس PatternManager متوقف شد.", m_enableLogging, "[PAT]");
   }
   
   //+------------------------------------------------------------------+
   //| تابع اصلی پردازش (در هر کندل جدید فراخوانی شود)                  |
   //+------------------------------------------------------------------+
   void ProcessNewBar()
   {
      if(CheckPointer(m_structure_instance) != POINTER_VALID) return;

      //--- ۱. آپدیت ساختار بازار داخلی
      m_structure_instance.ProcessNewBar();
      
      //--- ۲. مانیتورینگ فرضیه‌های فعال (چک کردن شرایط ابطال و تایید)
      MonitorHypotheses();
      
      //--- ۳. بررسی وقوع رویداد ساختاری جدید و ایجاد کمین‌های جدید
      CheckForNewStructureEvent();
   }

private:
   //--- تابع: بررسی ثبت سقف/کف جدید و ایجاد فرضیه‌های متناسب
   void CheckForNewStructureEvent()
   {
      SwingPoint lastHigh = m_structure_instance.GetLastSwingHigh();
      SwingPoint lastLow = m_structure_instance.GetLastSwingLow();
      
      //--- بررسی رویداد سقف جدید
      if(lastHigh.time > 0 && lastHigh.time != m_last_processed_high_time)
      {
         m_last_processed_high_time = lastHigh.time;
         LogEvent("رویداد جدید: سقف ساختاری در " + TimeToString(lastHigh.time) + " ثبت شد. ایجاد فرضیه‌های نزولی...", m_enableLogging, "[PAT]");
         CreateNewBearishHypotheses();
      }
      
      //--- بررسی رویداد کف جدید
      if(lastLow.time > 0 && lastLow.time != m_last_processed_low_time)
      {
         m_last_processed_low_time = lastLow.time;
         LogEvent("رویداد جدید: کف ساختاری در " + TimeToString(lastLow.time) + " ثبت شد. ایجاد فرضیه‌های صعودی...", m_enableLogging, "[PAT]");
         CreateNewBullishHypotheses();
      }
   }
   
   //--- تابع: ایجاد فرضیه‌های نزولی (DT و H&S)
   void CreateNewBearishHypotheses()
   {
      //--- ۱. ایجاد فرضیه Double Top (همیشه با هر سقف جدید ایجاد می‌شود)
      SwingPoint peak1 = m_structure_instance.GetLastSwingHigh();
      if(peak1.time > 0)
      {
         PatternHypothesis dt_hypo;
         ZeroMemory(dt_hypo);
         dt_hypo.type = PATTERN_DOUBLE_TOP;
         dt_hypo.status = STATUS_MONITORING;
         dt_hypo.p1 = peak1;
         
         //--- تعریف دقیق زون واکنش بر اساس کندل قله اول
         int bar_index = iBarShift(m_symbol, m_timeframe, peak1.time);
         if(bar_index != -1)
         {
            double p1_open = iOpen(m_symbol, m_timeframe, bar_index);
            double p1_close = iClose(m_symbol, m_timeframe, bar_index);
            double p1_high = iHigh(m_symbol, m_timeframe, bar_index);
            
            dt_hypo.reaction_zone_high = p1_high;
            dt_hypo.reaction_zone_low = (p1_close >= p1_open) ? p1_open : p1_close; // اگر سبز بود Open، اگر قرمز بود Close
            AddHypothesis(dt_hypo);
         }
      }
      
      //--- ۲. ایجاد فرضیه Head and Shoulders (نیاز به دو سقف دارد)
      if(ArraySize(m_structure_instance.m_swingHighs_Array) >= 2)
      {
         SwingPoint head = m_structure_instance.m_swingHighs_Array[0];
         SwingPoint left_shoulder = m_structure_instance.m_swingHighs_Array[1];
         
         // شرط اصلی H&S: سر باید بالاتر از شانه چپ باشد
         if(head.price > left_shoulder.price)
         {
            PatternHypothesis hs_hypo;
            ZeroMemory(hs_hypo);
            hs_hypo.type = PATTERN_HEAD_AND_SHOULDERS;
            hs_hypo.status = STATUS_MONITORING;
            hs_hypo.p1 = left_shoulder;
            hs_hypo.p2 = head;
            
            //--- تعریف دقیق زون واکنش بر اساس بدنه کندل‌های شانه چپ و سر
            int ls_bar = iBarShift(m_symbol, m_timeframe, left_shoulder.time);
            int head_bar = iBarShift(m_symbol, m_timeframe, head.time);
            
            if(ls_bar != -1 && head_bar != -1)
            {
               double ls_body_high = MathMax(iOpen(m_symbol, m_timeframe, ls_bar), iClose(m_symbol, m_timeframe, ls_bar));
               double head_body_high = MathMax(iOpen(m_symbol, m_timeframe, head_bar), iClose(m_symbol, m_timeframe, head_bar));
               
               hs_hypo.reaction_zone_low = ls_body_high;
               hs_hypo.reaction_zone_high = head_body_high;
               AddHypothesis(hs_hypo);
            }
         }
      }
   }

   //--- تابع: ایجاد فرضیه‌های صعودی (DB و I-H&S)
   void CreateNewBullishHypotheses()
   {
      //--- ۱. ایجاد فرضیه Double Bottom (همیشه با هر کف جدید ایجاد می‌شود)
      SwingPoint valley1 = m_structure_instance.GetLastSwingLow();
      if(valley1.time > 0)
      {
         PatternHypothesis db_hypo;
         ZeroMemory(db_hypo);
         db_hypo.type = PATTERN_DOUBLE_BOTTOM;
         db_hypo.status = STATUS_MONITORING;
         db_hypo.p1 = valley1;
         
         //--- تعریف دقیق زون واکنش بر اساس کندل دره اول
         int bar_index = iBarShift(m_symbol, m_timeframe, valley1.time);
         if(bar_index != -1)
         {
            double v1_open = iOpen(m_symbol, m_timeframe, bar_index);
            double v1_close = iClose(m_symbol, m_timeframe, bar_index);
            double v1_low = iLow(m_symbol, m_timeframe, bar_index);
            
            db_hypo.reaction_zone_low = v1_low;
            db_hypo.reaction_zone_high = (v1_close >= v1_open) ? v1_close : v1_open; // اگر سبز بود Close، اگر قرمز بود Open
            AddHypothesis(db_hypo);
         }
      }
      
      //--- ۲. ایجاد فرضیه Inverse Head and Shoulders (نیاز به دو کف دارد)
      if(ArraySize(m_structure_instance.m_swingLows_Array) >= 2)
      {
         SwingPoint head = m_structure_instance.m_swingLows_Array[0];
         SwingPoint left_shoulder = m_structure_instance.m_swingLows_Array[1];
         
         // شرط اصلی I-H&S: سر باید پایین‌تر از شانه چپ باشد
         if(head.price < left_shoulder.price)
         {
            PatternHypothesis ihs_hypo;
            ZeroMemory(ihs_hypo);
            ihs_hypo.type = PATTERN_INVERSE_HEAD_AND_SHOULDERS;
            ihs_hypo.status = STATUS_MONITORING;
            ihs_hypo.p1 = left_shoulder;
            ihs_hypo.p2 = head;
            
            //--- تعریف دقیق زون واکنش بر اساس بدنه کندل‌ها
            int ls_bar = iBarShift(m_symbol, m_timeframe, left_shoulder.time);
            int head_bar = iBarShift(m_symbol, m_timeframe, head.time);
            
            if(ls_bar != -1 && head_bar != -1)
            {
               double ls_body_low = MathMin(iOpen(m_symbol, m_timeframe, ls_bar), iClose(m_symbol, m_timeframe, ls_bar));
               double head_body_low = MathMin(iOpen(m_symbol, m_timeframe, head_bar), iClose(m_symbol, m_timeframe, head_bar));
               
               ihs_hypo.reaction_zone_high = ls_body_low;
               ihs_hypo.reaction_zone_low = head_body_low;
               AddHypothesis(ihs_hypo);
            }
         }
      }
   }
   
   //--- تابع: اضافه کردن فرضیه جدید به آرایه مانیتورینگ
   void AddHypothesis(const PatternHypothesis &hypo)
   {
      //--- پاک کردن فرضیه‌های مشابه قبلی برای جلوگیری از انباشتگی
      for(int i = ArraySize(m_hypotheses) - 1; i >= 0; i--)
      {
         if(m_hypotheses[i].type == hypo.type)
         {
            ArrayRemove(m_hypotheses, i, 1);
         }
      }
      
      int size = ArraySize(m_hypotheses);
      ArrayResize(m_hypotheses, size + 1);
      m_hypotheses[size] = hypo;
      
      LogEvent("فرضیه جدید " + EnumToString(hypo.type) + " ایجاد و به لیست مانیتورینگ اضافه شد.", m_enableLogging, "[PAT]");
   }

   //--- تابع: حلقه اصلی مانیتورینگ فرضیه‌ها
   void MonitorHypotheses()
   {
      //--- حلقه از آخر به اول برای حذف امن عناصر
      for(int i = ArraySize(m_hypotheses) - 1; i >= 0; i--)
      {
         //--- چک کردن شرط ابطال
         if(CheckInvalidation(m_hypotheses[i]))
         {
            LogEvent("فرضیه " + EnumToString(m_hypotheses[i].type) + " باطل شد.", m_enableLogging, "[PAT]");
            ArrayRemove(m_hypotheses, i, 1);
            continue;
         }
         
         //--- چک کردن شرط تایید
         if(CheckConfirmation(m_hypotheses[i]))
         {
            LogEvent("فرضیه " + EnumToString(m_hypotheses[i].type) + " تایید شد!", m_enableLogging, "[PAT]");
            ConfirmPattern(m_hypotheses[i]);
            ArrayRemove(m_hypotheses, i, 1);
            continue;
         }
      }
   }
   
   //--- تابع: بررسی شرط ابطال برای یک فرضیه
   bool CheckInvalidation(PatternHypothesis &hypo)
   {
      double close1 = iClose(m_symbol, m_timeframe, 1);
      double high1 = iHigh(m_symbol, m_timeframe, 1);
      double low1 = iLow(m_symbol, m_timeframe, 1);

      switch(hypo.type)
      {
         case PATTERN_DOUBLE_TOP:
            // اگر کندل بالای سقف زون Close کند، باطل می‌شود
            return (close1 > hypo.reaction_zone_high);
            
         case PATTERN_DOUBLE_BOTTOM:
            // اگر کندل پایین کف زون Close کند، باطل می‌شود
            return (close1 < hypo.reaction_zone_low);

         case PATTERN_HEAD_AND_SHOULDERS:
            // اگر قیمت (حتی با شدو) از سقف زون بالاتر برود، باطل می‌شود
            return (high1 > hypo.reaction_zone_high);

         case PATTERN_INVERSE_HEAD_AND_SHOULDERS:
            // اگر قیمت (حتی با شدو) از کف زون پایین‌تر برود، باطل می‌شود
            return (low1 < hypo.reaction_zone_low);
      }
      return false;
   }
   
   //--- تابع: بررسی ماشه تایید برای یک فرضیه
   bool CheckConfirmation(PatternHypothesis &hypo)
   {
      double open1 = iOpen(m_symbol, m_timeframe, 1);
      double close1 = iClose(m_symbol, m_timeframe, 1);
      double high1 = iHigh(m_symbol, m_timeframe, 1);
      double low1 = iLow(m_symbol, m_timeframe, 1);
      
      switch(hypo.type)
      {
         case PATTERN_DOUBLE_TOP:
         case PATTERN_HEAD_AND_SHOULDERS:
            // ۱. آیا قیمت وارد زون شده است؟
            if(!hypo.entered_reaction_zone && high1 >= hypo.reaction_zone_low)
            {
               hypo.entered_reaction_zone = true;
               LogEvent("قیمت وارد زون واکنش فرضیه " + EnumToString(hypo.type) + " شد.", m_enableLogging, "[PAT]");
            }
            // ۲. اگر وارد شده، آیا کندل تایید ظاهر شده؟
            if(hypo.entered_reaction_zone)
            {
               // کندل نزولی غیر دوجی
               if(close1 < open1 && (open1 - close1) > (_Point * 5)) return true;
            }
            break;
            
         case PATTERN_DOUBLE_BOTTOM:
         case PATTERN_INVERSE_HEAD_AND_SHOULDERS:
             // ۱. آیا قیمت وارد زون شده است؟
            if(!hypo.entered_reaction_zone && low1 <= hypo.reaction_zone_high)
            {
               hypo.entered_reaction_zone = true;
               LogEvent("قیمت وارد زون واکنش فرضیه " + EnumToString(hypo.type) + " شد.", m_enableLogging, "[PAT]");
            }
            // ۲. اگر وارد شده، آیا کندل تایید ظاهر شده؟
            if(hypo.entered_reaction_zone)
            {
               // کندل صعودی غیر دوجی
               if(close1 > open1 && (close1 - open1) > (_Point * 5)) return true;
            }
            break;
      }
      return false;
   }
   
   //--- تابع: نهایی کردن الگو، ذخیره و فراخوانی ترسیم
   void ConfirmPattern(const PatternHypothesis &hypo)
   {
      ConfirmedPattern pattern;
      ZeroMemory(pattern);
      
      pattern.type = hypo.type;
      pattern.confirmation_time = iTime(m_symbol, m_timeframe, 1);
      pattern.p1 = hypo.p1;
      pattern.p2 = hypo.p2;
      
      //--- ثبت نقطه سوم الگو (شانه راست یا قله/دره دوم)
      pattern.p3.time = pattern.confirmation_time;
      pattern.p3.bar_index = 1;
      if(hypo.type == PATTERN_DOUBLE_TOP || hypo.type == PATTERN_HEAD_AND_SHOULDERS)
         pattern.p3.price = iHigh(m_symbol, m_timeframe, 1);
      else
         pattern.p3.price = iLow(m_symbol, m_timeframe, 1);

      //--- محاسبه نقاط خط گردن
      // (این بخش می‌تواند بر اساس نیاز پیچیده‌تر شود، در اینجا ساده‌سازی شده)
      if(hypo.type == PATTERN_DOUBLE_TOP || hypo.type == PATTERN_DOUBLE_BOTTOM)
      {
         pattern.neckline_p1 = m_structure_instance.FindOppositeSwing(hypo.p1.time, pattern.p3.time, hypo.type == PATTERN_DOUBLE_TOP);
      }
      else // H&S and I-H&S
      {
         pattern.neckline_p1 = m_structure_instance.FindOppositeSwing(hypo.p1.time, hypo.p2.time, hypo.type == PATTERN_HEAD_AND_SHOULDERS);
         pattern.neckline_p2 = m_structure_instance.FindOppositeSwing(hypo.p2.time, pattern.p3.time, hypo.type == PATTERN_HEAD_AND_SHOULDERS);
      }

      //--- ذخیره الگو و ترسیم
      if(hypo.type == PATTERN_DOUBLE_TOP || hypo.type == PATTERN_DOUBLE_BOTTOM)
      {
         // پاک کردن الگوی قبلی از همان نوع
         DeletePatternDrawings(m_last_dtb);
         m_last_dtb = pattern;
      }
      else
      {
         DeletePatternDrawings(m_last_hns);
         m_last_hns = pattern;
      }
      
      DrawConfirmedPattern(pattern);
   }

   //--- تابع: ترسیم الگوی تایید شده روی چارت
   void DrawConfirmedPattern(const ConfirmedPattern &pattern)
   {
      if(pattern.type == PATTERN_NONE) return;

      string base_name = "PAT_" + EnumToString(pattern.type) + "_" + TimeToString(pattern.confirmation_time) + m_timeframeSuffix;
      color pattern_color = (pattern.type == PATTERN_DOUBLE_TOP || pattern.type == PATTERN_HEAD_AND_SHOULDERS) ? clrCrimson : clrDodgerBlue;

      //--- ترسیم خطوط الگو
      // (این بخش می‌تواند گسترش یابد تا شکل کامل الگو رسم شود)
      
      //--- ترسیم خط گردن
      string neck_name = base_name + "_Neck";
      if(pattern.neckline_p1.time > 0 && pattern.neckline_p2.time > 0) // H&S
      {
         ObjectCreate(m_chartId, neck_name, OBJ_TREND, 0, pattern.neckline_p1.time, pattern.neckline_p1.price, pattern.neckline_p2.time, pattern.neckline_p2.price);
         ObjectSetInteger(m_chartId, neck_name, OBJPROP_RAY_RIGHT, true);
      }
      else if(pattern.neckline_p1.time > 0) // DT/DB
      {
         ObjectCreate(m_chartId, neck_name, OBJ_TREND, 0, pattern.neckline_p1.time, pattern.neckline_p1.price, pattern.confirmation_time, pattern.neckline_p1.price);
      }
      ObjectSetInteger(m_chartId, neck_name, OBJPROP_COLOR, pattern_color);
      ObjectSetInteger(m_chartId, neck_name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(m_chartId, neck_name, OBJPROP_STYLE, STYLE_DOT);

      //--- ترسیم برچسب الگو
      string label_name = base_name + "_Label";
      string label_text = StringSubstr(EnumToString(pattern.type), 8); // حذف "PATTERN_"
      
      // منطق پسوند تایم فریم برای لیبل
      if(m_timeframe != Period())
      {
         label_text += m_timeframeSuffix;
      }
      
      datetime label_time = pattern.confirmation_time + PeriodSeconds(m_timeframe) * 5;
      double y_offset = (pattern.type == PATTERN_DOUBLE_TOP || pattern.type == PATTERN_HEAD_AND_SHOULDERS) ? -30 * _Point : 30 * _Point;
      double label_price = pattern.neckline_p1.price + y_offset;

      ObjectCreate(m_chartId, label_name, OBJ_TEXT, 0, label_time, label_price);
      ObjectSetString(m_chartId, label_name, OBJPROP_TEXT, label_text);
      ObjectSetInteger(m_chartId, label_name, OBJPROP_COLOR, pattern_color);
      ObjectSetInteger(m_chartId, label_name, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(m_chartId, label_name, OBJPROP_ANCHOR, ANCHOR_LEFT);
   }

   //--- تابع: پاک کردن اشیاء گرافیکی یک الگوی قدیمی
   void DeletePatternDrawings(const ConfirmedPattern &pattern)
   {
      if(pattern.type == PATTERN_NONE) return;
      string base_name = "PAT_" + EnumToString(pattern.type) + "_" + TimeToString(pattern.confirmation_time) + m_timeframeSuffix;
      ObjectDelete(m_chartId, base_name + "_Neck");
      ObjectDelete(m_chartId, base_name + "_Label");
   }

public:
   //+------------------------------------------------------------------+
   //| توابع دسترسی عمومی (Accessors) - برای استفاده در اکسپرت           |
   //+------------------------------------------------------------------+
   
   //--- دریافت آخرین الگوی DT یا DB تایید شده
   ConfirmedPattern GetLastDoubleTopBottom() const { return m_last_dtb; }
   
   //--- دریافت آخرین الگوی H&S یا I-H&S تایید شده
   ConfirmedPattern GetLastHeadAndShoulders() const { return m_last_hns; }
};
//+------------------------------------------------------------------+

