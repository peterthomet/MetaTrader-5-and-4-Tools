// --------------------------------------------------------------------------
// CurrencyStrength.mq5
// Peter Thomet, getYournet.ch
// Price and RSI Calculations copied from Corr_RSI.mq4 - mladen
// --------------------------------------------------------------------------

#property copyright "2017, getYourNet.ch"
#property version   "2.0"
#property indicator_separate_window

#property indicator_buffers 52
#property indicator_plots   8

#include <MovingAverages.mqh>
#include <SmoothAlgorithms.mqh> 

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};

input enPrices PriceType = pr_close; // Price Type
input int rsi_period = 9; // RSI Period
input int ma_period = 3; // MA Period
input int ma_smoothing = 3; // MA Smoothing
input int BarsToCalculate = 100; // Number of Bars to calculate
input int ZeroPoint = 100; // Zero Point

input color Color_USD = SeaGreen;            // USD line color
input color Color_EUR = DarkSlateBlue;         // EUR line color
input color Color_GBP = DeepPink;              // GBP line color
input color Color_CHF = Black;        // CHF line color
input color Color_JPY = Maroon;           // JPY line color
input color Color_AUD = DarkOrange;       // AUD line color
input color Color_CAD = MediumVioletRed;           // CAD line color
input color Color_NZD = Gray;         // NZD line color

input int                wid_main =         2; //Lines width for current chart
input ENUM_LINE_STYLE style_slave = STYLE_DOT; //Style of alternative lines for current chart
input bool all_solid = false; //Draw all main style
input bool draw_current_pairs_only = false; //Draw indexes of current pairs only

double EURUSD[], // quotes
       GBPUSD[],
       USDCHF[],
       USDJPY[],
       AUDUSD[],
       USDCAD[],
       NZDUSD[],
       EURNZD[],
       EURCAD[],
       EURAUD[],
       EURJPY[],
       EURCHF[],
       EURGBP[],
       GBPNZD[],
       GBPAUD[],
       GBPCAD[],
       GBPJPY[],
       GBPCHF[],
       CADJPY[],
       CADCHF[],
       AUDCAD[],
       NZDCAD[],
       AUDCHF[],
       AUDJPY[],
       AUDNZD[],
       NZDJPY[],
       NZDCHF[],
       CHFJPY[],
       USDx[], // indexes
       EURx[],
       GBPx[],
       JPYx[],
       CHFx[],
       CADx[],
       AUDx[],
       NZDx[],
       USDplot[], // results of currency lines
       EURplot[],
       GBPplot[],
       JPYplot[],
       CHFplot[],
       CADplot[],
       AUDplot[],
       NZDplot[],
       USDrsi[], // buffers of intermediate data rsi
       EURrsi[],
       GBPrsi[],
       JPYrsi[],
       CHFrsi[],
       CADrsi[],
       AUDrsi[],
       NZDrsi[];

int y_pos = 3; // Y coordinate variable for the informatory objects  
datetime arrTime[28]; // Array with the last known time of a zero valued bar (needed for synchronization)  
int bars_tf[28]; // To check the number of available bars in different currency pairs  
int index = 0;
datetime tmp_time[1]; // Intermediate array for the time of the bar 
string namespace = "CurrencyStrength";
bool incalculation = false;
bool fullinit = true;
datetime lastticktime;
datetime currentticktime;
int sameticktimecount=0;
bool timerenabled=true;
bool istesting;
datetime lasttestevent;
int _BarsToCalculate;
CXMA xmaUSD,xmaEUR,xmaGBP,xmaCHF,xmaJPY,xmaCAD,xmaAUD,xmaNZD;
CJJMA jjmaUSD;

void InitBuffer(int idx, double& buffer[], ENUM_INDEXBUFFER_TYPE data_type, string currency=NULL, color col=NULL)
{
   SetIndexBuffer(idx,buffer,data_type);
   ArraySetAsSeries(buffer,true);
   ArrayInitialize(buffer,EMPTY_VALUE);
   if(currency!=NULL)
   {
      PlotIndexSetString(idx,PLOT_LABEL,currency+"plot");
      PlotIndexSetInteger(idx,PLOT_DRAW_BEGIN,_BarsToCalculate);
      PlotIndexSetInteger(idx,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(idx,PLOT_LINE_COLOR,col);
      PlotIndexSetDouble(idx,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      //PlotIndexSetInteger(idx,PLOT_SHIFT,10);
      if(StringFind(Symbol(),currency,0)!=-1 || all_solid)
      {
        PlotIndexSetInteger(idx,PLOT_LINE_WIDTH,wid_main);
        PlotIndexSetInteger(idx,PLOT_LINE_STYLE,STYLE_SOLID);
      }
      else
      {
         if(draw_current_pairs_only)
         {
            PlotIndexSetInteger(idx,PLOT_DRAW_TYPE,DRAW_NONE);
         }
         else
         {
            PlotIndexSetInteger(idx,PLOT_DRAW_TYPE,DRAW_LINE);
            PlotIndexSetInteger(idx,PLOT_LINE_WIDTH,1);
            PlotIndexSetInteger(idx,PLOT_LINE_STYLE,style_slave);
         }
      }
      DrawObjects(currency,col);
   }
}


void OnInit()
{
   istesting=MQLInfoInteger(MQL_TESTER);
   
   _BarsToCalculate = BarsToCalculate;
   //_BarsToCalculate = BarsToCalculate+30;
   
   IndicatorSetInteger(INDICATOR_DIGITS,5);

   string nameInd="CurrencyStrength";
   IndicatorSetString(INDICATOR_SHORTNAME,nameInd);

   InitBuffer(0,USDplot,INDICATOR_DATA,"USD",Color_USD);
   InitBuffer(15,USDx,INDICATOR_CALCULATIONS);
   InitBuffer(23,USDrsi,INDICATOR_CALCULATIONS);

   InitBuffer(1,EURplot,INDICATOR_DATA,"EUR",Color_EUR);
   InitBuffer(8,EURUSD,INDICATOR_CALCULATIONS);
   InitBuffer(16,EURx,INDICATOR_CALCULATIONS);
   InitBuffer(24,EURrsi,INDICATOR_CALCULATIONS);

   InitBuffer(2,GBPplot,INDICATOR_DATA,"GBP",Color_GBP);
   InitBuffer(9,GBPUSD,INDICATOR_CALCULATIONS);
   InitBuffer(17,GBPx,INDICATOR_CALCULATIONS);
   InitBuffer(25,GBPrsi,INDICATOR_CALCULATIONS);

   InitBuffer(3,JPYplot,INDICATOR_DATA,"JPY",Color_JPY);
   InitBuffer(10,USDJPY,INDICATOR_CALCULATIONS);
   InitBuffer(18,JPYx,INDICATOR_CALCULATIONS);
   InitBuffer(26,JPYrsi,INDICATOR_CALCULATIONS);

   InitBuffer(4,CHFplot,INDICATOR_DATA,"CHF",Color_CHF);
   InitBuffer(11,USDCHF,INDICATOR_CALCULATIONS);
   InitBuffer(19,CHFx,INDICATOR_CALCULATIONS);
   InitBuffer(27,CHFrsi,INDICATOR_CALCULATIONS);

   InitBuffer(5,CADplot,INDICATOR_DATA,"CAD",Color_CAD);
   InitBuffer(12,USDCAD,INDICATOR_CALCULATIONS);
   InitBuffer(20,CADx,INDICATOR_CALCULATIONS);
   InitBuffer(28,CADrsi,INDICATOR_CALCULATIONS);

   InitBuffer(6,AUDplot,INDICATOR_DATA,"AUD",Color_AUD);
   InitBuffer(13,AUDUSD,INDICATOR_CALCULATIONS);
   InitBuffer(21,AUDx,INDICATOR_CALCULATIONS);
   InitBuffer(29,AUDrsi,INDICATOR_CALCULATIONS);

   InitBuffer(7,NZDplot,INDICATOR_DATA,"NZD",Color_NZD);
   InitBuffer(14,NZDUSD,INDICATOR_CALCULATIONS);
   InitBuffer(22,NZDx,INDICATOR_CALCULATIONS);
   InitBuffer(30,NZDrsi,INDICATOR_CALCULATIONS);

   InitBuffer(31,EURNZD,INDICATOR_CALCULATIONS);
   InitBuffer(32,EURCAD,INDICATOR_CALCULATIONS);
   InitBuffer(33,EURAUD,INDICATOR_CALCULATIONS);
   InitBuffer(34,EURJPY,INDICATOR_CALCULATIONS);
   InitBuffer(35,EURCHF,INDICATOR_CALCULATIONS);
   InitBuffer(36,EURGBP,INDICATOR_CALCULATIONS);

   InitBuffer(37,GBPNZD,INDICATOR_CALCULATIONS);
   InitBuffer(38,GBPAUD,INDICATOR_CALCULATIONS);
   InitBuffer(39,GBPCAD,INDICATOR_CALCULATIONS);
   InitBuffer(40,GBPJPY,INDICATOR_CALCULATIONS);
   InitBuffer(41,GBPCHF,INDICATOR_CALCULATIONS);

   InitBuffer(42,CADJPY,INDICATOR_CALCULATIONS);
   InitBuffer(43,CADCHF,INDICATOR_CALCULATIONS);
   InitBuffer(44,AUDCAD,INDICATOR_CALCULATIONS);
   InitBuffer(45,NZDCAD,INDICATOR_CALCULATIONS);

   InitBuffer(46,AUDCHF,INDICATOR_CALCULATIONS);
   InitBuffer(47,AUDJPY,INDICATOR_CALCULATIONS);
   InitBuffer(48,AUDNZD,INDICATOR_CALCULATIONS);

   InitBuffer(49,NZDJPY,INDICATOR_CALCULATIONS);
   InitBuffer(50,NZDCHF,INDICATOR_CALCULATIONS);
   InitBuffer(51,CHFJPY,INDICATOR_CALCULATIONS);
   EventSetTimer(1);
}


void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,"namespace",ChartWindowFind());
   EventKillTimer();
}


void OnTimer()
{
   if(incalculation || !timerenabled)
      return;
   if(istesting)
   {
      datetime curtime=TimeCurrent();
      if(curtime-lasttestevent < 2)
         return;
      lasttestevent=curtime;
   }
   incalculation=true;
   if(CalculateIndex())
   {
      fullinit=false;
   }
   if(currentticktime != lastticktime)
   {
      lastticktime=currentticktime;
      sameticktimecount=0;
   }
   else
   {
      sameticktimecount++;
      if(sameticktimecount>=30)
      {
         timerenabled=false;
         fullinit=true;
         Print("Timer Stopped - No Data Feed Available");
      }
   }
   incalculation=false;
}


int OnCalculate(const int rates_total, 
                const int prev_calculated, 
                const datetime& time[], 
                const double& open[], 
                const double& high[], 
                const double& low[], 
                const double& close[], 
                const long& tick_volume[], 
                const long& volume[], 
                const int& spread[]) 
{
   currentticktime=TimeTradeServer();
   if(prev_calculated<rates_total)
   {
      fullinit=true;
      ArrayInitialize(USDplot,EMPTY_VALUE);
      ArrayInitialize(EURplot,EMPTY_VALUE);
      ArrayInitialize(GBPplot,EMPTY_VALUE);
      ArrayInitialize(CHFplot,EMPTY_VALUE);
      ArrayInitialize(JPYplot,EMPTY_VALUE);
      ArrayInitialize(CADplot,EMPTY_VALUE);
      ArrayInitialize(AUDplot,EMPTY_VALUE);
      ArrayInitialize(NZDplot,EMPTY_VALUE);
   }
   timerenabled=true;
   if(istesting)
      OnTimer();
   return(rates_total);
}


bool CalculateIndex()
{
   int i,ii;
   int limit=_BarsToCalculate;
   int start=_BarsToCalculate-1;
   if(ZeroPoint<start && ZeroPoint>=0)
      start=ZeroPoint;

   if(fullinit)
      limit=_BarsToCalculate;
   else
      limit=1;

   //limit=_BarsToCalculate;

   if(!SynchronizeTimeframes())
      return(false);

   if(!GetRates("EURUSD",EURUSD,limit)) return(false);
   if(!GetRates("GBPUSD",GBPUSD,limit)) return(false);
   if(!GetRates("USDCHF",USDCHF,limit)) return(false);
   if(!GetRates("USDJPY",USDJPY,limit)) return(false);
   if(!GetRates("AUDUSD",AUDUSD,limit)) return(false);
   if(!GetRates("USDCAD",USDCAD,limit)) return(false);
   if(!GetRates("NZDUSD",NZDUSD,limit)) return(false);
   
   if(!GetRates("EURNZD",EURNZD,limit)) return(false);
   if(!GetRates("EURCAD",EURCAD,limit)) return(false);
   if(!GetRates("EURAUD",EURAUD,limit)) return(false);
   if(!GetRates("EURJPY",EURJPY,limit)) return(false);
   if(!GetRates("EURCHF",EURCHF,limit)) return(false);
   if(!GetRates("EURGBP",EURGBP,limit)) return(false);

   if(!GetRates("GBPNZD",GBPNZD,limit)) return(false);
   if(!GetRates("GBPAUD",GBPAUD,limit)) return(false);
   if(!GetRates("GBPCAD",GBPCAD,limit)) return(false);
   if(!GetRates("GBPJPY",GBPJPY,limit)) return(false);
   if(!GetRates("GBPCHF",GBPCHF,limit)) return(false);

   if(!GetRates("CADJPY",CADJPY,limit)) return(false);
   if(!GetRates("CADCHF",CADCHF,limit)) return(false);
   if(!GetRates("AUDCAD",AUDCAD,limit)) return(false);
   if(!GetRates("NZDCAD",NZDCAD,limit)) return(false);

   if(!GetRates("AUDCHF",AUDCHF,limit)) return(false);
   if(!GetRates("AUDJPY",AUDJPY,limit)) return(false);
   if(!GetRates("AUDNZD",AUDNZD,limit)) return(false);

   if(!GetRates("NZDJPY",NZDJPY,limit)) return(false);
   if(!GetRates("NZDCHF",NZDCHF,limit)) return(false);
   if(!GetRates("CHFJPY",CHFJPY,limit)) return(false);

   for(i=limit-1;i>=0;i--)
   {
      if(IncludeCurrency("USD"))
      {
         if(i==start){USDx[i]=0;}
         else
         {
            USDx[i]=0;
            USDx[i]-=(EURUSD[i]-EURUSD[start])/EURUSD[start]*100;
            USDx[i]-=(GBPUSD[i]-GBPUSD[start])/GBPUSD[start]*100;
            USDx[i]+=(USDCHF[i]-USDCHF[start])/USDCHF[start]*100;
            USDx[i]+=(USDJPY[i]-USDJPY[start])/USDJPY[start]*100;
            USDx[i]+=(USDCAD[i]-USDCAD[start])/USDCAD[start]*100;
            USDx[i]-=(AUDUSD[i]-AUDUSD[start])/AUDUSD[start]*100;
            USDx[i]-=(NZDUSD[i]-NZDUSD[start])/NZDUSD[start]*100;
            USDx[i]=USDx[i]/7;
         }
      }
      if(IncludeCurrency("EUR"))
      {
         if(i==start){EURx[i]=0;}
         else
         {
            EURx[i]=0;
            EURx[i]+=(EURUSD[i]-EURUSD[start])/EURUSD[start]*100;
            EURx[i]+=(EURNZD[i]-EURNZD[start])/EURNZD[start]*100;
            EURx[i]+=(EURCAD[i]-EURCAD[start])/EURCAD[start]*100;
            EURx[i]+=(EURAUD[i]-EURAUD[start])/EURAUD[start]*100;
            EURx[i]+=(EURJPY[i]-EURJPY[start])/EURJPY[start]*100;
            EURx[i]+=(EURCHF[i]-EURCHF[start])/EURCHF[start]*100;
            EURx[i]+=(EURGBP[i]-EURGBP[start])/EURGBP[start]*100;
            EURx[i]=EURx[i]/7;
         }
      }
      if(IncludeCurrency("GBP"))
      {
         if(i==start){GBPx[i]=0;}
         else
         {
            GBPx[i]=0;
            GBPx[i]+=(GBPUSD[i]-GBPUSD[start])/GBPUSD[start]*100;
            GBPx[i]+=(GBPNZD[i]-GBPNZD[start])/GBPNZD[start]*100;
            GBPx[i]+=(GBPAUD[i]-GBPAUD[start])/GBPAUD[start]*100;
            GBPx[i]+=(GBPCAD[i]-GBPCAD[start])/GBPCAD[start]*100;
            GBPx[i]+=(GBPJPY[i]-GBPJPY[start])/GBPJPY[start]*100;
            GBPx[i]+=(GBPCHF[i]-GBPCHF[start])/GBPCHF[start]*100;
            GBPx[i]-=(EURGBP[i]-EURGBP[start])/EURGBP[start]*100;
            GBPx[i]=GBPx[i]/7;
         }
      }
      if(IncludeCurrency("CHF"))
      {
         if(i==start){CHFx[i]=0;}
         else
         {
            CHFx[i]=0;
            CHFx[i]-=(USDCHF[i]-USDCHF[start])/USDCHF[start]*100;
            CHFx[i]-=(EURCHF[i]-EURCHF[start])/EURCHF[start]*100;
            CHFx[i]-=(GBPCHF[i]-GBPCHF[start])/GBPCHF[start]*100;
            CHFx[i]-=(CADCHF[i]-CADCHF[start])/CADCHF[start]*100;
            CHFx[i]-=(AUDCHF[i]-AUDCHF[start])/AUDCHF[start]*100;
            CHFx[i]-=(NZDCHF[i]-NZDCHF[start])/NZDCHF[start]*100;
            CHFx[i]+=(CHFJPY[i]-CHFJPY[start])/CHFJPY[start]*100;
            CHFx[i]=CHFx[i]/7;
         }
      }
      if(IncludeCurrency("JPY"))
      {
         if(i==start){JPYx[i]=0;}
         else
         {
            JPYx[i]=0;
            JPYx[i]-=(USDJPY[i]-USDJPY[start])/USDJPY[start]*100;
            JPYx[i]-=(EURJPY[i]-EURJPY[start])/EURJPY[start]*100;
            JPYx[i]-=(GBPJPY[i]-GBPJPY[start])/GBPJPY[start]*100;
            JPYx[i]-=(CADJPY[i]-CADJPY[start])/CADJPY[start]*100;
            JPYx[i]-=(AUDJPY[i]-AUDJPY[start])/AUDJPY[start]*100;
            JPYx[i]-=(NZDJPY[i]-NZDJPY[start])/NZDJPY[start]*100;
            JPYx[i]-=(CHFJPY[i]-CHFJPY[start])/CHFJPY[start]*100;
            JPYx[i]=JPYx[i]/7;
         }
      }
      if(IncludeCurrency("CAD"))
      {
         if(i==start){CADx[i]=0;}
         else
         {
            CADx[i]=0;
            CADx[i]-=(USDCAD[i]-USDCAD[start])/USDCAD[start]*100;
            CADx[i]-=(EURCAD[i]-EURCAD[start])/EURCAD[start]*100;
            CADx[i]-=(GBPCAD[i]-GBPCAD[start])/GBPCAD[start]*100;
            CADx[i]+=(CADJPY[i]-CADJPY[start])/CADJPY[start]*100;
            CADx[i]+=(CADCHF[i]-CADCHF[start])/CADCHF[start]*100;
            CADx[i]-=(AUDCAD[i]-AUDCAD[start])/AUDCAD[start]*100;
            CADx[i]-=(NZDCAD[i]-NZDCAD[start])/NZDCAD[start]*100;
            CADx[i]=CADx[i]/7;
         }
      }
      if(IncludeCurrency("AUD"))
      {
         if(i==start){AUDx[i]=0;}
         else
         {
            AUDx[i]=0;
            AUDx[i]+=(AUDUSD[i]-AUDUSD[start])/AUDUSD[start]*100;
            AUDx[i]-=(EURAUD[i]-EURAUD[start])/EURAUD[start]*100;
            AUDx[i]-=(GBPAUD[i]-GBPAUD[start])/GBPAUD[start]*100;
            AUDx[i]+=(AUDCAD[i]-AUDCAD[start])/AUDCAD[start]*100;
            AUDx[i]+=(AUDCHF[i]-AUDCHF[start])/AUDCHF[start]*100;
            AUDx[i]+=(AUDJPY[i]-AUDJPY[start])/AUDJPY[start]*100;
            AUDx[i]+=(AUDNZD[i]-AUDNZD[start])/AUDNZD[start]*100;
            AUDx[i]=AUDx[i]/7;
         }
      }
      if(IncludeCurrency("NZD"))
      {
         if(i==start){NZDx[i]=0;}
         else
         {
            NZDx[i]=0;
            NZDx[i]+=(NZDUSD[i]-NZDUSD[start])/NZDUSD[start]*100;
            NZDx[i]-=(EURNZD[i]-EURNZD[start])/EURNZD[start]*100;
            NZDx[i]-=(GBPNZD[i]-GBPNZD[start])/GBPNZD[start]*100;
            NZDx[i]+=(NZDCAD[i]-NZDCAD[start])/NZDCAD[start]*100;
            NZDx[i]-=(AUDNZD[i]-AUDNZD[start])/AUDNZD[start]*100;
            NZDx[i]+=(NZDJPY[i]-NZDJPY[start])/NZDJPY[start]*100;
            NZDx[i]+=(NZDCHF[i]-NZDCHF[start])/NZDCHF[start]*100;
            NZDx[i]=NZDx[i]/7;
         }
      }
   }

   ii=limit-1;


   int total = _BarsToCalculate;
   int prev, idx, sml=-1;
   for(i=ii;i>=0;i--)
   {
      prev = _BarsToCalculate-(i+1);
      idx = _BarsToCalculate-1-i;
      if(IncludeCurrency("USD"))
         if(i>sml)
            USDplot[i]=xmaUSD.XMASeries(0, prev, total, MODE_T3, 0, ma_period, USDx[i], idx, false);
         else
            USDplot[i]=USDx[i];
         //USDplot[i]=jjmaUSD.JJMASeries(0, prev, total, 0, 100, ma_period, USDx[i], idx, false);
      if(IncludeCurrency("EUR"))
         if(i>sml)
            EURplot[i]=xmaEUR.XMASeries(0, prev, total, MODE_T3, 0, ma_period, EURx[i], idx, false);
         else
            EURplot[i]=EURx[i];
      if(IncludeCurrency("GBP"))
         if(i>sml)
            GBPplot[i]=xmaGBP.XMASeries(0, prev, total, MODE_T3, 0, ma_period, GBPx[i], idx, false);
         else
            GBPplot[i]=GBPx[i];
      if(IncludeCurrency("CHF"))
         if(i>sml)
            CHFplot[i]=xmaCHF.XMASeries(0, prev, total, MODE_T3, 0, ma_period, CHFx[i], idx, false);
         else
            CHFplot[i]=CHFx[i];
      if(IncludeCurrency("JPY"))
         if(i>sml)
            JPYplot[i]=xmaJPY.XMASeries(0, prev, total, MODE_T3, 0, ma_period, JPYx[i], idx, false);
         else
            JPYplot[i]=JPYx[i];
      if(IncludeCurrency("CAD"))
         if(i>sml)
            CADplot[i]=xmaCAD.XMASeries(0, prev, total, MODE_T3, 0, ma_period, CADx[i], idx, false);
         else
            CADplot[i]=CADx[i];
      if(IncludeCurrency("AUD"))
         if(i>sml)
            AUDplot[i]=xmaAUD.XMASeries(0, prev, total, MODE_T3, 0, ma_period, AUDx[i], idx, false);
         else
            AUDplot[i]=AUDx[i];
      if(IncludeCurrency("NZD"))
         if(i>sml)
            NZDplot[i]=xmaNZD.XMASeries(0, prev, total, MODE_T3, 0, ma_period, NZDx[i], idx, false);
         else
            NZDplot[i]=NZDx[i];
   }
   return(true);
}


bool IncludePair(string pair)
{
   if(!draw_current_pairs_only)
      return true;
   return IncludeCurrency(StringSubstr(pair,0,3)) || IncludeCurrency(StringSubstr(pair,3,3));
}


bool IncludeCurrency(string currency)
{
   if(!draw_current_pairs_only)
      return true;
   return StringFind(Symbol(),currency,0)!=-1;
}


bool GetRates(string pair, double& buffer[], int bars)
{
   if(!IncludePair(pair))
      return true;
   bool ret = true;
   int copied;
   MqlRates rates[];
   copied=CopyRates(pair,PERIOD_CURRENT,0,_BarsToCalculate,rates);
   if(copied==-1)
   {
      WriteComment("Wait..."+pair);
      ret=false;
   }
   else
   {
      for(int i=0;i<copied;i++)
      {
         buffer[copied-i-1]=GetPrice(PriceType,rates,i);
      }
   }
   return ret;
}


int DrawObjects(string name,color _color)
{
   string oname = namespace+"-"+name;
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,5);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,y_pos);
   ObjectSetString(0,oname,OBJPROP_TEXT,name);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,_color);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,8);
   y_pos+=15;
   return(0);
}


int WriteComment(string text)
{
   string name=namespace+"-f_comment";
   color _color=Gray;
   ObjectCreate(0,name,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,5);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,3);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,_color);
   return(0);
}


bool SynchronizeTimeframes()
{
   ArrayInitialize(arrTime,0);
   ArrayInitialize(bars_tf,0);
   bool writeComment=true;
   for(int n=0;n<1;n++)
   {
      int exit=-1;
      if(writeComment){WriteComment("Synchronizing Timeframes");writeComment=false;}
      index=-1;

      GetPairData("EURUSD");
      GetPairData("GBPUSD");
      GetPairData("USDCHF");
      GetPairData("USDJPY");
      GetPairData("USDCAD");
      GetPairData("AUDUSD");
      GetPairData("NZDUSD");
      GetPairData("EURNZD");
      GetPairData("EURCAD");
      GetPairData("EURAUD");
      GetPairData("EURJPY");
      GetPairData("EURCHF");
      GetPairData("EURGBP");
      GetPairData("GBPNZD");
      GetPairData("GBPAUD");
      GetPairData("GBPCAD");
      GetPairData("GBPJPY");
      GetPairData("GBPCHF");
      GetPairData("CADJPY");
      GetPairData("CADCHF");
      GetPairData("AUDCAD");
      GetPairData("NZDCAD");
      GetPairData("AUDCHF");
      GetPairData("AUDJPY");
      GetPairData("AUDNZD");
      GetPairData("NZDJPY");
      GetPairData("NZDCHF");
      GetPairData("CHFJPY");

      for(int h=1;h<=index;h++)
      {
         if(arrTime[0]==arrTime[h] && arrTime[0]!=0 && exit==-1){exit=1;}
         if(arrTime[0]!=arrTime[h] && arrTime[0]!=0 && exit==1){exit=0;}
         if(bars_tf[h]<_BarsToCalculate){exit=0;}
      }
      if(exit==1){WriteComment("Timeframes synchronized");return(true);}
   }
   WriteComment("Trying to synchronize Timeframes");
   return(false);
}


bool GetPairData(string pair)
{
   if(!IncludePair(pair))
      return false;
   int copy;
   index++;
   bars_tf[index]=Bars(pair,PERIOD_CURRENT);
   copy=CopyTime(pair,PERIOD_CURRENT,0,1,tmp_time);
   arrTime[index]=tmp_time[0];
   return true;
}


double GetPrice(int tprice, MqlRates& rates[], int i)
{
  if (tprice>=pr_haclose)
   {
      int ratessize = ArraySize(rates);
         
         double haOpen;
         if (i>0)
                haOpen  = (rates[i-1].open + rates[i-1].close)/2.0;
         else   haOpen  = (rates[i].open+rates[i].close)/2;
         double haClose = (rates[i].open + rates[i].high + rates[i].low + rates[i].close) / 4.0;
         double haHigh  = MathMax(rates[i].high, MathMax(haOpen,haClose));
         double haLow   = MathMin(rates[i].low , MathMin(haOpen,haClose));

         rates[i].open=haOpen;
         rates[i].close=haClose;

         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   switch (tprice)
   {
      case pr_close:     return(rates[i].close);
      case pr_open:      return(rates[i].open);
      case pr_high:      return(rates[i].high);
      case pr_low:       return(rates[i].low);
      case pr_median:    return((rates[i].high+rates[i].low)/2.0);
      case pr_medianb:   return((rates[i].open+rates[i].close)/2.0);
      case pr_typical:   return((rates[i].high+rates[i].low+rates[i].close)/3.0);
      case pr_weighted:  return((rates[i].high+rates[i].low+rates[i].close+rates[i].close)/4.0);
      case pr_average:   return((rates[i].high+rates[i].low+rates[i].close+rates[i].open)/4.0);
      case pr_tbiased:   
               if (rates[i].close>rates[i].open)
                     return((rates[i].high+rates[i].close)/2.0);
               else  return((rates[i].low+rates[i].close)/2.0);        
      case pr_tbiased2:   
               if (rates[i].close>rates[i].open) return(rates[i].high);
               if (rates[i].close<rates[i].open) return(rates[i].low);
                                     return(rates[i].close);        
   }
   return(0);
}

