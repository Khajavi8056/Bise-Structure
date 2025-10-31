//+------------------------------------------------------------------+
//|                                                  CReactionZones   |
//|                              Copyright 2025, Khajavi - HipoAlgoritm|
//+------------------------------------------------------------------+

// شمارنده برای نوع خطوط واکنش
enum ENUM_REACTION_LINE_TYPE
  {
   LINE_TYPE_DRAW, // خط Draw
   LINE_TYPE_FLIP  // خط Flip
  };

// کلاس کمکی برای نگهداری داده‌های هر خط واکنش (ارث‌بری از CObject برای استفاده در CArrayObj)
class CReactionLine : public CObject
  {
public:
   ENUM_REACTION_LINE_TYPE lineType;       // نوع خط (Draw یا Flip)
   bool              isBullish;            // جهت خط (صعودی یا نزولی)
   double            price;                // قیمت خط
   datetime          time;                 // زمان کندل ایجاد خط
   int               bar_index;            // اندیس کندل ایجاد خط
   datetime          source_ob_time;       // زمان OB مادر (برای ابطال)
   string            flipType;             // نوع Flip ("F1"، "F2" یا "")
   string            obj_name_line;        // نام شیء گرافیکی خط
   string            obj_name_label;       // نام شیء گرافیکی لیبل

                     CReactionLine(void) { Reset(); }
                    ~CReactionLine(void) {}

   // تابع ریست مقادیر
   void              Reset(void)
     {
      lineType = LINE_TYPE_DRAW;
      isBullish = false;
      price = 0.0;
      time = 0;
      bar_index = -1;
      source_ob_time = 0;
      flipType = "";
      obj_name_line = "";
      obj_name_label = "";
     }
  };

// کلاس اصلی مدیریت خطوط واکنش (Draw و Flip)
class CReactionZones
  {
private:
   // وابستگی‌ها (تزریق شده از طریق سازنده)
   MarketStructure  *m_major;              // پوینتر به ساختار بازار اصلی
   MinorStructure   *m_minor;              // پوینتر به ساختار بازار مینور

   // تنظیمات اصلی
   string            m_symbol;             // نماد معاملاتی
   ENUM_TIMEFRAMES   m_timeframe;          // تایم فریم اجرایی
   long              m_chartId;            // شناسه چارت
   bool              m_showDrawing;        // کنترل نمایش ترسیمات
   LOG_LEVEL         m_logLevel;           // سطح لاگ
   string            m_timeframeSuffix;    // پسوند تایم فریم برای نامگذاری اشیاء

   // تنظیمات گرافیکی
   color             m_color_draw;         // رنگ خطوط Draw
   color             m_color_flip;         // رنگ خطوط Flip

   // حافظه خطوط
   CArrayObj        *m_drawLines;          // لیست پوینترهای خطوط Draw
   CArrayObj        *m_flipLines;          // لیست پوینترهای خطوط Flip

   // حافظه ردیابی
   CArrayLong       *m_processedOB_Times;  // لیست زمان OBهای پردازش شده (برای جلوگیری از تکرار)
   datetime          m_lastProcessedBreakTime; // زمان آخرین شکست پردازش شده

   // --- توابع کمکی داخلی (Private) ---

   // تابع چک وابستگی‌ها
   bool              IsValidDependencies(void)
     {
      if(CheckPointer(m_major) == POINTER_INVALID)
        {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_103, "[RZ]", "پوینتر MarketStructure نامعتبر است.", true);
         return false;
        }
      if(CheckPointer(m_minor) == POINTER_INVALID)
        {
         CentralLog(LOG_ERROR, m_logLevel, ERROR_CODE_103, "[RZ]", "پوینتر MinorStructure نامعتبر است.", true);
         return false;
        }
      return true;
     }

   // تابع چک وجود ساختار مینور در بازه جنگ
   bool              CheckForMinorsInZone(int startIdx, int endIdx)
     {
      // دریافت آرایه‌های مینور
      int highCount = m_minor.GetMinorHighsCount();
      for(int i = 0; i < highCount; i++)
        {
         SwingPoint sp = m_minor.GetMinorSwingHigh(i);
         if(sp.bar_index >= startIdx && sp.bar_index <= endIdx) return true;
        }

      int lowCount = m_minor.GetMinorLowsCount();
      for(int i = 0; i < lowCount; i++)
        {
         SwingPoint sp = m_minor.GetMinorSwingLow(i);
         if(sp.bar_index >= startIdx && sp.bar_index <= endIdx) return true;
        }

      CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "هیچ ساختار مینوری در بازه جنگ پیدا نشد.");
      return false;
     }

   // تابع جستجوی OB مادر در بازه جنگ
   OrderBlock        FindMotherOBInZone(int startIdx, int endIdx, bool isBullish)
     {
      OrderBlock emptyOB; emptyOB.bar_index = -1; // OB خالی برای بازگشت در صورت عدم پیدا شدن

      int obCount = m_major.GetUnmitigatedOBCount();
      for(int i = 0; i < obCount; i++)
        {
         OrderBlock ob = m_major.GetUnmitigatedOB(i);
         if(ob.isBullish == isBullish && ob.bar_index >= startIdx && ob.bar_index <= endIdx)
           {
            return ob; // اولین (جدیدترین) OB مناسب را برگردان
           }
        }

      CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "هیچ OB مادری در بازه جنگ پیدا نشد.");
      return emptyOB;
     }

   // تابع اجرای منطق Draw و Flip
   void              ExecuteDrawFlipLogic(OrderBlock &ob, int breakIdx, bool isBullish)
     {
      CReactionLine *draw = CalculateDrawLine(ob, breakIdx, isBullish);
      if(CheckPointer(draw) != POINTER_INVALID)
        {
         AddToListWithCapacity(m_drawLines, draw);
         if(m_showDrawing) DrawReactionLine(draw);
         CReactionLine *flip = CalculateFlipLine(draw, breakIdx, isBullish);
         if(CheckPointer(flip) != POINTER_INVALID)
           {
            AddToListWithCapacity(m_flipLines, flip);
            if(m_showDrawing) DrawReactionLine(flip);
           }
        }
     }

   // تابع محاسبه خط Draw
   CReactionLine   *CalculateDrawLine(OrderBlock &ob, int breakIdx, bool isBullish)
     {
      CReactionLine *line = new CReactionLine;
      line->lineType = LINE_TYPE_DRAW;
      line->isBullish = isBullish;
      line->source_ob_time = ob.time;
      line->flipType = "";

      // جستجو از جدید به قدیم (از breakIdx + 1 تا ob.bar_index)
      for(int i = breakIdx + 1; i <= ob.bar_index; i++)
        {
         if(isBullish) // Demand OB
           {
            double low_i = iLow(m_symbol, m_timeframe, i);
            if(low_i <= ob.highPrice && low_i >= ob.lowPrice)
              {
               line->price = low_i;
               line->time = iTime(m_symbol, m_timeframe, i);
               line->bar_index = i;
               break;
              }
           }
         else // Supply OB
           {
            double high_i = iHigh(m_symbol, m_timeframe, i);
            if(high_i >= ob.lowPrice && high_i <= ob.highPrice)
              {
               line->price = high_i;
               line->time = iTime(m_symbol, m_timeframe, i);
               line->bar_index = i;
               break;
              }
           }
        }

      if(line->price == 0.0)
        {
         delete line;
         return NULL; // هیچ واکنشی پیدا نشد
        }

      return line;
     }

   // تابع محاسبه خط Flip
   CReactionLine   *CalculateFlipLine(CReactionLine *draw, int breakIdx, bool isBullish)
     {
      int start = breakIdx + 1;
      int end = draw.bar_index - 1;
      if(end < start) return NULL; // حالت سوم: بدون Flip

      CReactionLine *flip = new CReactionLine;
      flip->lineType = LINE_TYPE_FLIP;
      flip->isBullish = isBullish;
      flip->source_ob_time = draw->source_ob_time;
      flip->flipType = "";

      // F1: جستجوی جدیدترین Minor Swing در جهت مخالف
      bool f1_found = false;
      if(isBullish) // جستجوی Minor Low
        {
         int lowCount = m_minor.GetMinorLowsCount();
         for(int i = 0; i < lowCount; i++)
           {
            SwingPoint sp = m_minor.GetMinorSwingLow(i);
            if(sp.bar_index >= start && sp.bar_index <= end)
              {
               flip->price = sp.price;
               flip->time = sp.time;
               flip->bar_index = sp.bar_index;
               flip->flipType = "F1";
               f1_found = true;
               break;
              }
           }
        }
      else // جستجوی Minor High
        {
         int highCount = m_minor.GetMinorHighsCount();
         for(int i = 0; i < highCount; i++)
           {
            SwingPoint sp = m_minor.GetMinorSwingHigh(i);
            if(sp.bar_index >= start && sp.bar_index <= end)
              {
               flip->price = sp.price;
               flip->time = sp.time;
               flip->bar_index = sp.bar_index;
               flip->flipType = "F1";
               f1_found = true;
               break;
              }
           }
        }

      if(!f1_found)
        {
         // F2: جستجوی اکستریمم قیمتی
         int extIdx = isBullish ? iLowest(m_symbol, m_timeframe, MODE_LOW, end - start + 1, start) : iHighest(m_symbol, m_timeframe, MODE_HIGH, end - start + 1, start);
         if(extIdx != -1)
           {
            flip->price = isBullish ? iLow(m_symbol, m_timeframe, extIdx) : iHigh(m_symbol, m_timeframe, extIdx);
            flip->time = iTime(m_symbol, m_timeframe, extIdx);
            flip->bar_index = extIdx;
            flip->flipType = "F2";
           }
         else
           {
            delete flip;
            return NULL;
           }
        }

      return flip;
     }

   // تابع ابطال خطوط فعال
   void              ValidateActiveLines(void)
     {
      // ابطال خطوط Draw
      for(int i = m_drawLines.Total() - 1; i >= 0; i--)
        {
         CReactionLine *line = (CReactionLine*)m_drawLines.At(i);
         if(line != NULL && !IsOBStillValid(line.source_ob_time))
           {
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "خط Draw باطل شد چون OB مادر حذف شده.");
            DeleteReactionLine(line, i, m_drawLines);
           }
        }

      // ابطال خطوط Flip
      for(int i = m_flipLines.Total() - 1; i >= 0; i--)
        {
         CReactionLine *line = (CReactionLine*)m_flipLines.At(i);
         if(line != NULL && !IsOBStillValid(line.source_ob_time))
           {
            CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "خط Flip باطل شد چون OB مادر حذف شده.");
            DeleteReactionLine(line, i, m_flipLines);
           }
        }
     }

   // تابع چک اعتبار OB مادر
   bool              IsOBStillValid(datetime ob_time)
     {
      // جستجو در unmitigated
      int unmitCount = m_major.GetUnmitigatedOBCount();
      for(int i = 0; i < unmitCount; i++)
        {
         OrderBlock ob = m_major.GetUnmitigatedOB(i);
         if(ob.time == ob_time) return true;
        }

      // جستجو در mitigated
      int mitCount = m_major.GetMitigatedOBCount();
      for(int i = 0; i < mitCount; i++)
        {
         OrderBlock ob = m_major.GetMitigatedOB(i);
         if(ob.time == ob_time) return true;
        }

      return false;
     }

   // تابع علامت‌گذاری OB به عنوان پردازش شده
   void              MarkOBAsProcessed(OrderBlock &ob)
     {
      m_processedOB_Times.Add(ob.time);
     }

   // تابع چک پردازش شده بودن OB
   bool              IsOBProcessed(OrderBlock &ob)
     {
      return (m_processedOB_Times.Search(ob.time) != -1);
     }

   // تابع اضافه کردن به لیست با مدیریت ظرفیت
   void              AddToListWithCapacity(CArrayObj *list, CObject *obj)
     {
      list.Add(obj);
      ManageListCapacity(list);
     }

   // تابع مدیریت ظرفیت لیست (حداکثر ۲۰)
   void              ManageListCapacity(CArrayObj *list)
     {
      if(list.Total() > 20)
        {
         CReactionLine *oldLine = (CReactionLine*)list.At(0);
         if(oldLine != NULL)
           {
            DeleteReactionLine(oldLine, 0, list);
           }
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "ظرفیت لیست پر شد، قدیمی‌ترین خط حذف گردید.");
        }
     }

   // --- توابع گرافیکی ---

   // تابع رسم خط واکنش
   void              DrawReactionLine(CReactionLine *line)
     {
      string prefix = (line.lineType == LINE_TYPE_DRAW) ? "RZ_Draw_" : "RZ_Flip_";
      string direction = line.isBullish ? "Bull_" : "Bear_";
      line->obj_name_line = prefix + direction + TimeToString(line.time) + m_timeframeSuffix;
      line->obj_name_label = line->obj_name_line + "_Label";

      // ایجاد خط روند
      ObjectCreate(m_chartId, line->obj_name_line, OBJ_TREND, 0, line->time, line->price, TimeCurrent(), line->price);
      ObjectSetInteger(m_chartId, line->obj_name_line, OBJPROP_COLOR, (line.lineType == LINE_TYPE_DRAW) ? m_color_draw : m_color_flip);
      ObjectSetInteger(m_chartId, line->obj_name_line, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(m_chartId, line->obj_name_line, OBJPROP_RAY_RIGHT, true);

      // ایجاد لیبل
      string labelText = (line.lineType == LINE_TYPE_DRAW) ? "Draw" : "Flip " + line.flipType;
      labelText += m_timeframeSuffix;
      datetime midTime = line->time + (TimeCurrent() - line->time) / 2;
      ObjectCreate(m_chartId, line->obj_name_label, OBJ_TEXT, 0, midTime, line->price);
      ObjectSetString(m_chartId, line->obj_name_label, OBJPROP_TEXT, labelText);
      ObjectSetInteger(m_chartId, line->obj_name_label, OBJPROP_COLOR, COLOR_LABEL_TEXT);
      ObjectSetInteger(m_chartId, line->obj_name_label, OBJPROP_FONTSIZE, BASE_LABEL_FONT_SIZE);
      ObjectSetInteger(m_chartId, line->obj_name_label, OBJPROP_ANCHOR, ANCHOR_CENTER);
     }

   // تابع به‌روزرسانی موقعیت تمام لیبل‌ها
   void              UpdateAllLabelPositions(void)
     {
      // برای Draw Lines
      for(int i = 0; i < m_drawLines.Total(); i++)
        {
         CReactionLine *line = (CReactionLine*)m_drawLines.At(i);
         if(line != NULL)
           {
            datetime midTime = line->time + (TimeCurrent() - line->time) / 2;
            ObjectMove(m_chartId, line->obj_name_label, 0, midTime, line->price);
           }
        }

      // برای Flip Lines
      for(int i = 0; i < m_flipLines.Total(); i++)
        {
         CReactionLine *line = (CReactionLine*)m_flipLines.At(i);
         if(line != NULL)
           {
            datetime midTime = line->time + (TimeCurrent() - line->time) / 2;
            ObjectMove(m_chartId, line->obj_name_label, 0, midTime, line->price);
           }
        }
     }

   // تابع حذف خط واکنش
   void              DeleteReactionLine(CReactionLine *line, int index, CArrayObj *list)
     {
      if(m_showDrawing)
        {
         ObjectDelete(m_chartId, line->obj_name_line);
         ObjectDelete(m_chartId, line->obj_name_label);
        }
      list.Delete(index);
      delete line;
     }

public:
   //+------------------------------------------------------------------+
   //| سازنده کلاس (Constructor)                                       |
   //+------------------------------------------------------------------+
                     CReactionZones(MarketStructure *major_ptr, MinorStructure *minor_ptr,
                                    const string symbol, const ENUM_TIMEFRAMES timeframe, const long chartId,
                                    const bool showDrawing_in, const LOG_LEVEL logLevel_in = DEFAULT_LOG_LEVEL,
                                    color draw_color_in = clrBlue, color flip_color_in = clrBlue)
     {
      m_major = major_ptr;
      m_minor = minor_ptr;
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_chartId = chartId;
      m_showDrawing = showDrawing_in;
      m_logLevel = logLevel_in;
      m_color_draw = draw_color_in;
      m_color_flip = flip_color_in;
      m_timeframeSuffix = " (" + TimeFrameToStringShort(timeframe) + ")";

      // چک وابستگی‌ها
      if(!IsValidDependencies()) return;

      // مقداردهی اولیه متغیرها
      m_lastProcessedBreakTime = 0;

      // ایجاد لیست‌ها
      m_drawLines = new CArrayObj;
      m_flipLines = new CArrayObj;
      m_processedOB_Times = new CArrayLong;

      // پاکسازی اشیاء قدیمی RZ_... مربوط به این تایم فریم
      if(m_showDrawing)
        {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for(int i = total - 1; i >= 0; i--)
           {
            string name = ObjectName(m_chartId, i);
            if(StringFind(name, "RZ_") == 0 && StringFind(name, m_timeframeSuffix) != -1)
              {
               ObjectDelete(m_chartId, name);
              }
           }
        }

      CentralLog(LOG_FULL, m_logLevel, 0, "[RZ]", "کلاس CReactionZones آغاز به کار کرد.");
     }

   //+------------------------------------------------------------------+
   //| مخرب کلاس (Destructor)                                           |
   //+------------------------------------------------------------------+
                    ~CReactionZones(void)
     {
      // پاک کردن لیست‌ها و اشیاء
      for(int i = 0; i < m_drawLines.Total(); i++)
        {
         CReactionLine *line = (CReactionLine*)m_drawLines.At(i);
         delete line;
        }
      delete m_drawLines;

      for(int i = 0; i < m_flipLines.Total(); i++)
        {
         CReactionLine *line = (CReactionLine*)m_flipLines.At(i);
         delete line;
        }
      delete m_flipLines;

      delete m_processedOB_Times;

      // پاک کردن تمام اشیاء RZ_...
      if(m_showDrawing)
        {
         int total = ObjectsTotal(m_chartId, 0, -1);
         for(int i = total - 1; i >= 0; i--)
           {
            string name = ObjectName(m_chartId, i);
            if(StringFind(name, "RZ_") == 0 && StringFind(name, m_timeframeSuffix) != -1)
              {
               ObjectDelete(m_chartId, name);
              }
           }
        }

      CentralLog(LOG_FULL, m_logLevel, 0, "[RZ]", "کلاس CReactionZones متوقف شد.");
     }

   //+------------------------------------------------------------------+
   //| تابع اصلی: پردازش کندل جدید (ProcessNewBar)                     |
   //+------------------------------------------------------------------+
   void              ProcessNewBar(void)
     {
      // چک اولیه: وابستگی‌ها و بار تکراری
      if(!IsValidDependencies()) return;
      datetime currentBarTime = iTime(m_symbol, m_timeframe, 0);
      if(currentBarTime == 0) return;

      // همیشه ابطال را اجرا کن
      ValidateActiveLines();

      // چک شکست جدید
      datetime newBoS = m_major.GetLastBoSTime();
      datetime newCHoCH = m_major.GetLastChoChTime();
      datetime latestBreakTime = MathMax(newBoS, newCHoCH);

      if(latestBreakTime <= m_lastProcessedBreakTime) 
        {
         // هیچ شکست جدیدی نیست، فقط گرافیک را آپدیت کن
         if(m_showDrawing) UpdateAllLabelPositions();
         return;
        }

      // شکست جدید وجود دارد
      m_lastProcessedBreakTime = latestBreakTime;

      bool isBullish;
      SwingPoint brokenSwing;
      int breakIndex = iBarShift(m_symbol, m_timeframe, latestBreakTime, false);

      // تشخیص نوع شکست
      if(newBoS > newCHoCH) // BoS
        {
         isBullish = (m_major.GetCurrentTrend() == TREND_BULLISH);
         brokenSwing = isBullish ? m_major.GetSwingHigh(1) : m_major.GetSwingLow(1);
        }
      else // CHoCH
        {
         isBullish = (m_major.GetCurrentTrend() == TREND_BULLISH);
         brokenSwing = isBullish ? m_major.GetSwingHigh(1) : m_major.GetSwingLow(1);
        }

      if(brokenSwing.bar_index == -1) return; // سوئینگ نامعتبر

      int brokenSwingIndex = brokenSwing.bar_index;

      // تعریف بازه جنگ
      int warZoneStart = breakIndex + 1;
      int warZoneEnd = brokenSwingIndex - 1;
      if(warZoneEnd < warZoneStart)
        {
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "بازه جنگ نامعتبر است.");
         return;
        }

      // چک کیفیت: وجود مینور
      bool hasMinors = CheckForMinorsInZone(warZoneStart, warZoneEnd);
      if(!hasMinors)
        {
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "شکست فاقد ساختار مینور است.");
         return;
        }

      // جستجوی OB مادر
      OrderBlock motherOB = FindMotherOBInZone(warZoneStart, warZoneEnd, isBullish);
      if(motherOB.bar_index == -1)
        {
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "OB مادر پیدا نشد.");
         return;
        }

      // چک تکراری بودن
      if(IsOBProcessed(motherOB))
        {
         CentralLog(LOG_PERFORMANCE, m_logLevel, PERF_CODE_201, "[RZ]", "OB مادر قبلاً پردازش شده است.");
         return;
        }

      // اجرای منطق
      ExecuteDrawFlipLogic(motherOB, breakIndex, isBullish);
      MarkOBAsProcessed(motherOB);

      // همیشه گرافیک را آپدیت کن
      if(m_showDrawing) UpdateAllLabelPositions();
     }

   //+------------------------------------------------------------------+
   //| توابع عمومی (Public Accessors)                                   |
   //+------------------------------------------------------------------+

   // تابع به‌روزرسانی گرافیک (فقط جابجایی لیبل‌ها)
   void              UpdateGraphics(void)
     {
      if(m_showDrawing) UpdateAllLabelPositions();
     }

   // تعداد خطوط Draw
   int               GetDrawCount(void) const { return m_drawLines.Total(); }

   // تعداد خطوط Flip
   int               GetFlipCount(void) const { return m_flipLines.Total(); }

   // گرفتن خط Draw خاص
   CReactionLine    *GetDrawLine(int index) const
     {
      if(index >= 0 && index < m_drawLines.Total()) return (CReactionLine*)m_drawLines.At(index);
      return NULL;
     }

   // گرفتن خط Flip خاص
   CReactionLine    *GetFlipLine(int index) const
     {
      if(index >= 0 && index < m_flipLines.Total()) return (CReactionLine*)m_flipLines.At(index);
      return NULL;
     }
  };
//+------------------------------------------------------------------+
