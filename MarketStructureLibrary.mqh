//+------------------------------------------------------------------+
//| تابع اصلی: پردازش کندل بسته شده (نسخه نهایی و بهینه)             |
//+------------------------------------------------------------------+
bool ProcessNewBar()
{
   //--- ۱. تعیین بازه اسکن بر اساس آخرین نقطه یافت شده
   int barsCount = iBars(m_symbol, m_timeframe);
   if (barsCount < (m_aoFractalLength * 2) + 1) return false;

   int barsToCopy;
   // اگر اولین اجراست، ۲۰۰ کندل آخر را اسکن کن
   if (m_lastScanTime == 0)
   {
      barsToCopy = MathMin(200, barsCount - 1);
   }
   // در غیر این صورت، فقط از کندل فعلی تا آخرین نقطه پیدا شده را اسکن کن
   else
   {
      int lastFoundIndex = iBarShift(m_symbol, m_timeframe, m_lastScanTime, false);
      // اگر iBarShift شکست خورد یا نقطه خیلی دور بود، برای امنیت ۲۰۰ کندل را اسکن کن
      if (lastFoundIndex <= 0 || lastFoundIndex > 200)
         barsToCopy = MathMin(200, barsCount - 1);
      else
         barsToCopy = lastFoundIndex;
   }
   
   if(barsToCopy <= (m_aoFractalLength * 2)) return false;

   //--- ۲. کپی بافرها
   double ao_buffer[]; ArraySetAsSeries(ao_buffer, true);
   double high_buffer[]; ArraySetAsSeries(high_buffer, true);
   double low_buffer[]; ArraySetAsSeries(low_buffer, true);
   datetime time_buffer[]; ArraySetAsSeries(time_buffer, true);

   if (CopyBuffer(m_ao_handle, 0, 1, barsToCopy, ao_buffer) <= 0) return false;
   if (CopyHigh(m_symbol, m_timeframe, 1, barsToCopy, high_buffer) <= 0) return false;
   if (CopyLow(m_symbol, m_timeframe, 1, barsToCopy, low_buffer) <= 0) return false;
   if (CopyTime(m_symbol, m_timeframe, 1, barsToCopy, time_buffer) <= 0) return false;

   //--- ۳. حلقه اسکن از جدید به قدیمی
   for (int i = 0; i <= ArraySize(ao_buffer) - (m_aoFractalLength * 2) - 1; i++)
   {
      int centerIndex = i + m_aoFractalLength;

      //--- شناسایی فرکتال AO برای سقف مینور
      bool isMinorHigh = true;
      for (int j = 1; j <= m_aoFractalLength; j++)
      {
         if (ao_buffer[centerIndex] <= ao_buffer[centerIndex - j] || ao_buffer[centerIndex] <= ao_buffer[centerIndex + j])
         {
            isMinorHigh = false;
            break;
         }
      }

      if (isMinorHigh)
      {
         double maxHigh = 0; datetime maxTime = 0;
         for (int k = i; k < i + (m_aoFractalLength * 2) + 1; k++)
         {
            if (high_buffer[k] > maxHigh)
            {
               maxHigh = high_buffer[k];
               maxTime = time_buffer[k];
            }
         }
         
         if(AddMinorHigh(maxHigh, maxTime))
         {
            // <<< نکته کلیدی: m_lastScanTime فقط بعد از یافتن موفقیت‌آمیز آپدیت می‌شود
            m_lastScanTime = maxTime;
            return true; 
         }
      }
      else
      {
         //--- شناسایی فرکتال AO برای کف مینور
         bool isMinorLow = true;
         for (int j = 1; j <= m_aoFractalLength; j++)
         {
            if (ao_buffer[centerIndex] >= ao_buffer[centerIndex - j] || ao_buffer[centerIndex] >= ao_buffer[centerIndex + j])
            {
               isMinorLow = false;
               break;
            }
         }
         if (isMinorLow)
         {
            double minLow = DBL_MAX; datetime minTime = 0;
            for (int k = i; k < i + (m_aoFractalLength * 2) + 1; k++)
            {
               if (low_buffer[k] < minLow)
               {
                  minLow = low_buffer[k];
                  minTime = time_buffer[k];
               }
            }
            
            if(AddMinorLow(minLow, minTime))
            {
               // <<< نکته کلیدی: m_lastScanTime فقط بعد از یافتن موفقیت‌آمیز آپدیت می‌شود
               m_lastScanTime = minTime;
               return true;
            }
         }
      }
   }
   return false;
}
