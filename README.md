# 📚 کتابخانه MarketStructureLibrary - ابزار جامع تحلیل بازار برای MQL5

![Market Structure Library - EURUSD M15](https://github.com/Khajavi8056/Bise-Structure/blob/main/more/Strategy%20Tester%20Visualization%20_%20test%20structur%20on%20EURUSD,M15%20from%202025.01.01%20to%202025.10.23%2010_24_2025%207_48_28%20PM.png?raw=true)
![Market Structure Library - FVG & OB](https://github.com/Khajavi8056/Bise-Structure/blob/main/more/Strategy%20Tester%20Visualization%20_%20test%20structur%20on%20EURUSD,M15%20from%202025.01.01%20to%202025.10.23%2010_24_2025%207_52_41%20PM.png?raw=true)
![Market Structure Library - Liquidity & Pinbar](https://github.com/Khajavi8056/Bise-Structure/blob/main/more/Strategy%20Tester%20Visualization%20_%20test%20structur%20on%20EURUSD,M15%20from%202025.01.01%20to%202025.10.23%2010_24_2025%207_54_46%20PM.png?raw=true)

<div align="center">
  <img src="https://github.com/Khajavi8056/Bise-Structure/blob/main/more/Strategy%20Tester%20Visualization%20_%20test%20structur%20on%20EURUSD,M15%20from%202025.01.01%20to%202025.10.23%2010_24_2025%207_48_28%20PM.png?raw=true" width="32%" />
  <img src="https://github.com/Khajavi8056/Bise-Structure/blob/main/more/Strategy%20Tester%20Visualization%20_%20test%20structur%20on%20EURUSD,M15%20from%202025.01.01%20to%202025.10.23%2010_24_2025%207_52_41%20PM.png?raw=true" width="32%" />
  <img src="https://github.com/Khajavi8056/Bise-Structure/blob/main/more/Strategy%20Tester%20Visualization%20_%20test%20structur%20on%20EURUSD,M15%20from%202025.01.01%20to%202025.10.23%2010_24_2025%207_54_46%20PM.png?raw=true" width="32%" />
</div>

<script>
  const images = document.querySelectorAll('div[align="center"] img');
  let current = 0;
  images.forEach((img, i) => img.style.display = i === 0 ? 'inline-block' : 'none');
  setInterval(() => {
    images[current].style.display = 'none';
    current = (current + 1) % images.length;
    images[current].style.display = 'inline-block';
  }, 30000); // هر 30 ثانیه
</script>

---
**MarketStructureLibrary.mqh** یک کتابخانه قدرتمند و منعطف برای MetaTrader 5 است که برای تحلیل پیشرفته ساختار بازار، شناسایی شکاف ارزش منصفانه (FVG)، مدیریت نقاط محوری مینور، مدیریت نقدینگی بازار (شامل EQ، تله‌های ساختاری و سطوح دوره‌ای) و شناسایی پین‌بارها طراحی شده است. این کتابخانه با پشتیبانی از چند تایم‌فریم و چند نماد، ابزارهای قوی برای پیاده‌سازی مفاهیم Smart Money Concepts (SMC)، استراتژی‌های معاملاتی مبتنی بر FVG، ساختارهای مینور، نقدینگی و الگوهای پین‌بار در اختیار معامله‌گران و توسعه‌دهندگان قرار می‌دهد. 🚀

**نسخه فعلی: 3.00** (به‌روزرسانی با اضافه شدن قابلیت نقدینگی یکپارچه، EQ ماژور/مینور، تله‌های SMS/CF، سطوح دوره‌ای، شناسایی پین‌بار و بهینه‌سازی‌های MT5)

## ✨ ویژگی‌ها

- **پشتیبانی از چند تایم‌فریم (MTF)**: امکان تحلیل ساختار بازار، FVG، نقاط مینور، نقدینگی و پین‌بارها در تایم‌فریم‌های مختلف به صورت همزمان. 🕒
- **پشتیبانی از چند نماد**: قابلیت کار با هر نماد معاملاتی پشتیبانی‌شده توسط MetaTrader 5. 💹
- **مفاهیم Smart Money Concepts (SMC)**: شناسایی سقف‌های بالاتر (HH)، کف‌های بالاتر (HL)، سقف‌های پایین‌تر (LH)، کف‌های پایین‌تر (LL)، شکست ساختار (BoS) و تغییر کاراکتر (CHoCH). 📈
- **شناسایی شکاف ارزش منصفانه (FVG)**: تشخیص FVGهای صعودی و نزولی با فیلترهای قابل تنظیم، منطق ابطال در لحظه و مدیریت Order Block (OB) با شرط اختیاری FVG. 🔍
- **مدیریت نقاط محوری مینور**: شناسایی سقف‌ها و کف‌های مینور با استفاده از اندیکاتور Awesome Oscillator (AO) برای تحلیل دقیق‌تر بازار. 🔎
- **مدیریت نقدینگی بازار**: شناسایی Equal High/Low (EQ) ماژور/مینور، تله‌های Swing Market Structure (SMS) و Confirmation Flip (CF)، و سطوح دوره‌ای (PDH/PDL، PWH/PWL، PMH/PML، PYH/PYL). 💧
- **شناسایی پین‌بارها**: تشخیص پین‌بارهای تکی و ادغام‌شده (تا 3 کندل) با منطق ریاضی دقیق و رسم علامت π روی چارت. 📌
- **نمایش گرافیکی**: ترسیم نقاط محوری، نواحی FVG، سطوح فیبوناچی پویا، لیبل‌های روند، EQها، تله‌ها، سطوح دوره‌ای و پین‌بارها روی چارت با پسوندهای تایم‌فریم برای وضوح بیشتر. 🎨
- **مدیریت بهینه منابع**: محدود کردن ذخیره FVGها به 30 مورد، نقاط مینور به 10 مورد، OBها به ظرفیت رزرو شده و EQها به 4 مورد برای بهینه‌سازی عملکرد و مصرف حافظه. ⚙️
- **سیستم لاگ‌گیری طبقه‌بندی‌شده**: لاگ‌های عملکردی، خطاها و کامل با کدهای خاص برای دیباگ و مانیتورینگ، با سطوح LOG_FULL، LOG_PERFORMANCE و LOG_ERROR. 🖥️
- **سازگاری کامل**: طراحی شده برای کار بدون مشکل در تمام نسخه‌های MetaTrader 5 بدون هشدار تبدیل نوع ضمنی. ✅

## 🛠️ اجزا

این کتابخانه شامل چهار کلاس اصلی مستقل (با وابستگی‌های تزریقی) و یک کلاس اضافی برای پین‌بار است:

1. **کلاس MarketStructure** 📊
   - **هدف**: تحلیل ساختار بازار بر اساس نقاط محوری و تشخیص روند.
   - **ویژگی‌های کلیدی**:
     - شناسایی سقف‌ها و کف‌های محوری با استفاده از رویکرد فرکتالی. 🔝🔽
     - تشخیص جهت روند (صعودی، نزولی یا رنج) بر اساس الگوهای HH/HL و LL/LH.
     - ردیابی رویدادهای شکست ساختار (BoS) و تغییر کاراکتر (CHoCH).
     - شناسایی Order Block (OB) با شرط اختیاری FVG و مدیریت میتگیشن/ابطال لحظه‌ای.
     - شناسایی EQ ماژور و ترسیم سطوح فیبوناچی پویا برای تأیید نقاط محوری (به طور پیش‌فرض 35% اصلاح).
     - نمایش نقاط محوری و لیبل‌های روند با پسوندهای خاص تایم‌فریم (مانند H (4H) یا L (4H)).

2. **کلاس FVGManager** 🔲
   - **هدف**: مدیریت شناسایی و ابطال شکاف‌های ارزش منصفانه.
   - **ویژگی‌های کلیدی**:
     - شناسایی FVGهای صعودی و نزولی بر اساس الگوهای سه کندلی با فیلتر بدنه قوی. 🕯️
     - ابطال FVGها در لحظه با استفاده از بررسی قیمت‌های Bid/Ask در هر تیک.
     - ترسیم نواحی FVG به صورت مستطیل‌های پرشده با لیبل‌های متنی متمرکز در ناحیه.
     - محدود کردن تعداد FVGها به 30 ناحیه برای جلوگیری از بار اضافی حافظه.
     - پشتیبانی از نمایش چند تایم‌فریمی با پسوندهای واضح تایم‌فریم.
     - توابع جدید: GetNearestSupportFVG و GetNearestResistanceFVG برای شناسایی نزدیک‌ترین FVGهای حمایتی و مقاومتی.

3. **کلاس MinorStructure** 🔍
   - **هدف**: شناسایی و مدیریت سقف‌ها و کف‌های مینور با استفاده از اندیکاتور Awesome Oscillator (AO).
   - **ویژگی‌های کلیدی**:
     - شناسایی سقف‌ها و کف‌های مینور با استفاده از فرکتال‌های AO.
     - تنظیم طول فرکتال AO (به طور پیش‌فرض 3 کندل اطراف).
     - شناسایی OBهای مینور و میتگیشن/ابطال لحظه‌ای آن‌ها.
     - شناسایی EQ مینور و ترسیم آن‌ها.
     - ترسیم نقاط مینور با فلش‌های کوچک و آفست برای تمایز از نقاط محوری اصلی.
     - محدود کردن تعداد نقاط مینور به 10 مورد برای هر نوع (سقف/کف) برای بهینه‌سازی.
     - بهینه‌سازی منابع با کش کردن بافر AO و آزادسازی هندل اندیکاتور در دفع آبجکت.

4. **کلاس CLiquidityManager** 💧
   - **هدف**: مدیریت جامع نقدینگی بازار با وابستگی به MarketStructure و MinorStructure.
   - **ویژگی‌های کلیدی**:
     - شناسایی و ثبت EQ ماژور/مینور، تله‌های SMS/CF و سطوح دوره‌ای (روزانه، هفتگی، ماهانه، سالانه).
     - ماشین حالت برای تشخیص تله‌های ساختاری (SMS/CF) بر اساس دنباله CHoCH و BoS.
     - به‌روزرسانی خودکار سطوح دوره‌ای و ترسیم خطوط افقی با لیبل‌های چسبیده به لبه راست چارت.
     - تاریخچه رویدادهای نقدینگی با ظرفیت 50 مورد و دسترسی به آخرین رویدادها بر اساس نوع.
     - کنترل نمایش جداگانه برای EQ، تله‌ها و سطوح دوره‌ای (drawEQ, drawTraps, drawPDL و غیره).
     - جلوگیری از همپوشانی لیبل‌ها و رسم شرطی برای جلوگیری از تکرار.

5. **کلاس CPinbarDetector** 📌
   - **هدف**: شناسایی پین‌بارهای تکی و ادغام‌شده.
   - **ویژگی‌های کلیدی**:
     - تشخیص پین‌بارهای صعودی (Hammer) و نزولی (Shooting Star) بر اساس نسبت سایه و بدنه (پیش‌فرض: 66% سایه، 33% بدنه).
     - بررسی 6 حالت: تکی (C1، C2، C3) و ادغام‌شده (C1C2، C2C3، C1C2C3).
     - رسم علامت π با رنگ‌بندی (سبز/قرمز) و جلوگیری از رسم تکراری.
     - خروجی آرایه نتایج برای استفاده در منطق معاملاتی.

## 🚀 راهنمای استفاده

1. **راه‌اندازی اولیه** 🏁
   - نمونه‌هایی از کلاس‌های MarketStructure، FVGManager، MinorStructure، CLiquidityManager و CPinbarDetector را در تابع OnInit() اکسپرت خود ایجاد کنید.
   - CLiquidityManager وابسته به MarketStructure و MinorStructure است؛ پوینترها را به سازنده آن پاس دهید.
   - مثال:
     ```
     MarketStructure *H1_Struct = new MarketStructure(_Symbol, PERIOD_H1, ChartID(), true, true, 35, 10, true); // enableOB_FVG_Check=true
     FVGManager *H1_FVG = new FVGManager(_Symbol, PERIOD_H1, ChartID(), true, true);
     MinorStructure *H1_Minor = new MinorStructure(_Symbol, PERIOD_H1, ChartID(), true, true, 3);
     CLiquidityManager *H1_Liq = new CLiquidityManager(H1_Struct, H1_Minor, _Symbol, PERIOD_H1, ChartID(), true, true, true, true, true, true, true, true);
     CPinbarDetector *pinbarDetector = new CPinbarDetector();
     ```

2. **پردازش داده‌ها** 🔄
   - در OnTick() یا OnTimer():
     - متد ProcessNewTick() را برای FVGManager، MarketStructure و MinorStructure فراخوانی کنید تا ابطال FVG/OB و میتگیشن لحظه‌ای بررسی شود.
     - متد ProcessNewBar() را برای تمام کلاس‌ها در زمان بسته شدن کندل جدید فراخوانی کنید تا ساختار، FVGها، نقاط مینور، نقدینگی و EQها به‌روزرسانی شوند.
     - برای پین‌بار، DetectPinbars را در ProcessNewBar فراخوانی کنید.
   - مثال:
     ```
     if(IsNewBar(PERIOD_H1))
     {
         H1_Struct.ProcessNewBar();
         H1_FVG.ProcessNewBar();
         H1_Minor.ProcessNewBar();
         H1_Liq.ProcessNewBar();
         PinbarResult pins[];
         int count = pinbarDetector.DetectPinbars(_Symbol, PERIOD_H1, ChartID(), true, pins);
     }
     H1_FVG.ProcessNewTick();
     H1_Struct.ProcessNewTick();
     H1_Minor.ProcessNewTick();
     ```

3. **دسترسی به داده‌ها** 📊
   - از متدهای دسترسی برای استخراج داده‌های مورد نیاز برای منطق معاملاتی استفاده کنید:
     - **MarketStructure**:
       - GetLastSwingHigh(): آخرین سقف محوری.
       - GetLastSwingLow(): آخرین کف محوری.
       - GetCurrentTrend(): روند فعلی.
       - GetLastChoChTime(): زمان آخرین CHoCH.
       - GetLastBoSTime(): زمان آخرین BoS.
       - GetUnmitigatedOBCount(): تعداد OBهای مصرف نشده.
       - IsCurrentlyMitigatingOB(): وضعیت مصرف لحظه‌ای OB.
       - GetMajorEQPatternCount(): تعداد EQهای ماژور.
     - **FVGManager**:
       - GetFVG(index): FVG در اندیس.
       - GetFVGCount(): تعداد FVGها.
       - GetNearestSupportFVG(): نزدیک‌ترین FVG حمایتی.
       - GetNearestResistanceFVG(): نزدیک‌ترین FVG مقاومتی.
     - **MinorStructure**:
       - GetMinorSwingHigh(index): سقف مینور در اندیس.
       - GetMinorSwingLow(index): کف مینور در اندیس.
       - GetMinorHighsCount(): تعداد سقف‌های مینور.
       - GetEQPatternCount(): تعداد EQهای مینور.
       - GetMinorUnmitigatedOBCount(): تعداد OBهای مینور مصرف نشده.
       - IsCurrentlyMitigatingMinorOB(): وضعیت مصرف لحظه‌ای OB مینور.
     - **CLiquidityManager**:
       - GetHistoryCount(): تعداد رویدادهای نقدینگی.
       - GetLastEvent(): آخرین رویداد نقدینگی.
       - GetLastEventByType(type): آخرین رویداد بر اساس نوع (مثل LIQ_EQH).
     - **CPinbarDetector**:
       - DetectPinbars(): تعداد و نتایج پین‌بارها (در آرایه خروجی).

4. **کنترل نمایش** 🖼️
   - نمایش ترسیمات روی چارت را با پارامتر showDrawing در سازنده فعال یا غیرفعال کنید.
   - برای CLiquidityManager، ورودی‌های جداگانه برای هر نوع (drawEQ, drawTraps و غیره) وجود دارد.
   - عناصر بصری شامل: نقاط محوری، FVGها، فیبوناچی، EQها، تله‌ها، سطوح دوره‌ای و پین‌بارها.

## 📋 پیش‌نیازها

- **پلتفرم**: MetaTrader 5 (پشتیبانی از تمام نسخه‌ها).
- **زبان برنامه‌نویسی**: MQL5.
- **وابستگی‌ها**: هیچ (کتابخانه مستقل).
- **حداقل تعداد کندل‌ها**:
  - برای FVG: حداقل 4 کندل.
  - برای ساختار بازار: fractalLength * 2 + 1 کندل.
  - برای ساختار مینور: aoFractalLength * 2 + 1 کندل.
  - برای پین‌بار: حداقل 4 کندل.

## 🛠️ نصب

- **دانلود**: فایل MarketStructureLibrary.mqh را از این مخزن کلون یا دانلود کنید.
- **قرار دادن در MetaTrader 5**: فایل را در پوشه MQL5/Include در محل نصب MetaTrader 5 کپی کنید.
- **اضافه کردن به اکسپرت**: خط زیر را در ابتدای کد اکسپرت خود اضافه کنید:
  ```
  #include <MarketStructureLibrary.mqh>
  ```
- **کامپایل**: اکسپرت خود را در MetaEditor کامپایل کنید تا از اتصال صحیح کتابخانه اطمینان حاصل شود. 🔗

## 📖 مثال استفاده

در زیر یک اکسپرت ساده برای نشان دادن نحوه استفاده از کتابخانه ارائه شده است:

```
#include <MarketStructureLibrary.mqh>

MarketStructure *structH1;
FVGManager *fvgH1;
MinorStructure *minorH1;
CLiquidityManager *liqH1;
CPinbarDetector *pinbarDetector;

int OnInit()
{
   structH1 = new MarketStructure(_Symbol, PERIOD_H1, ChartID(), true, true, 35, 10, true);
   fvgH1 = new FVGManager(_Symbol, PERIOD_H1, ChartID(), true, true);
   minorH1 = new MinorStructure(_Symbol, PERIOD_H1, ChartID(), true, true, 3);
   liqH1 = new CLiquidityManager(structH1, minorH1, _Symbol, PERIOD_H1, ChartID(), true, true, true, true, true, true, true, true);
   pinbarDetector = new CPinbarDetector();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   delete structH1;
   delete fvgH1;
   delete minorH1;
   delete liqH1;
   delete pinbarDetector;
}

void OnTick()
{
   if(IsNewBar(PERIOD_H1))
   {
      structH1.ProcessNewBar();
      fvgH1.ProcessNewBar();
      minorH1.ProcessNewBar();
      liqH1.ProcessNewBar();
      PinbarResult pins[];
      int count = pinbarDetector.DetectPinbars(_Symbol, PERIOD_H1, ChartID(), true, pins);
   }
   fvgH1.ProcessNewTick();
   structH1.ProcessNewTick();
   minorH1.ProcessNewTick();

   // مثال: دسترسی به داده‌ها
   SwingPoint lastHigh = structH1.GetLastSwingHigh();
   TREND_TYPE trend = structH1.GetCurrentTrend();
   FVG supportFVG = fvgH1.GetNearestSupportFVG();
   SwingPoint minorHigh = minorH1.GetMinorSwingHigh(0);
   LiquidityEvent lastEvent = liqH1.GetLastEvent();
   Print("آخرین سقف محوری: ", DoubleToString(lastHigh.price, _Digits),
         " | روند: ", EnumToString(trend),
         " | نزدیک‌ترین FVG حمایتی: ", DoubleToString(supportFVG.lowPrice, _Digits),
         " | آخرین سقف مینور: ", DoubleToString(minorHigh.price, _Digits),
         " | آخرین رویداد نقدینگی: ", EnumToString(lastEvent.type));
}

bool IsNewBar(ENUM_TIMEFRAMES timeframe)
{
   static datetime lastBar = 0;
   datetime currentBar = iTime(_Symbol, timeframe, 0);
   if(lastBar != currentBar)
   {
      lastBar = currentBar;
      return true;
   }
   return false;
}
```

## 🔧 سفارشی‌سازی

- **سطح تأیید فیبوناچی**: مقدار fibUpdateLevel را در MarketStructure تغییر دهید (پیش‌فرض: 35%).
- **طول فرکتال**: مقدار fractalLength را در MarketStructure برای کنترل حساسیت شناسایی نقاط محوری تنظیم کنید (پیش‌فرض: 10 کندل).
- **طول فرکتال AO**: مقدار aoFractalLength را در MinorStructure برای تنظیم حساسیت شناسایی نقاط مینور تغییر دهید (پیش‌فرض: 3 کندل).
- **شرط FVG برای OB**: پارامتر enableOB_FVG_Check در MarketStructure (پیش‌فرض: true).
- **آستانه پین‌بار**: ثابت‌های PINBAR_SHADOW_RATIO_THRESHOLD (66%) و PINBAR_BODY_RATIO_THRESHOLD (33%) را در کد تغییر دهید.
- **لاگ‌گیری**: سطح لاگ را با DEFAULT_LOG_LEVEL تغییر دهید (پیش‌فرض: LOG_PERFORMANCE).
- **نمایش بصری**: پارامترهای showDrawing و draw... را در سازنده‌ها تنظیم کنید.

## ⚠️ نکات

- **عملکرد**: کتابخانه برای عملکرد بهینه طراحی شده و تعداد عناصر را محدود می‌کند تا از مشکلات حافظه جلوگیری شود.
- **مدیریت خطاها**: تمام توابع شامل بررسی‌هایی برای جلوگیری از کرش هستند، مانند اعتبارسنجی تعداد کندل‌ها و اندازه آرایه‌ها.
- **رفع هشدارها**: کتابخانه به‌روز شده تا تمام هشدارهای تبدیل نوع ضمنی را برطرف کند و با تنظیمات سخت‌گیرانه MQL5 سازگار باشد.
- **بهینه‌سازی منابع**: کلاس‌ها از کش کردن، رزرو آرایه و آزادسازی هندل‌ها برای مدیریت بهتر منابع استفاده می‌کنند.
- **وابستگی کلاس‌ها**: CLiquidityManager پس از ایجاد MarketStructure و MinorStructure ساخته شود.

## 📸 تصاویر

![تصویر 1](https://github.com/Khajavi8056/Bise-Structure/blob/main/more/Strategy%20Tester%20Visualization%20_%20test%20structur%20on%20EURUSD,M15%20from%202025.01.01%20to%202025.10.23%2010_24_2025%207_48_28%20PM.png?raw=true)

![تصویر 2](https://github.com/Khajavi8056/Bise-Structure/blob/main/more/Strategy%20Tester%20Visualization%20_%20test%20structur%20on%20EURUSD,M15%20from%202025.01.01%20to%202025.10.23%2010_24_2025%207_52_41%20PM.png?raw=true)

![تصویر 3](https://github.com/Khajavi8056/Bise-Structure/blob/main/more/Strategy%20Tester%20Visualization%20_%20test%20structur%20on%20EURUSD,M15%20from%202025.01.01%20to%202025.10.23%2010_24_2025%207_54_46%20PM.png?raw=true)

## 📬 تماس و پشتیبانی

برای سؤالات، گزارش باگ یا درخواست ویژگی‌های جدید، لطفاً یک مسئله (Issue) در این مخزن GitHub باز کنید. 📩

## 📄 مجوز

این پروژه تحت مجوز MIT منتشر شده است. برای جزئیات، فایل LICENSE را ببینید. 📜

معامله موفقی داشته باشید! 💰
