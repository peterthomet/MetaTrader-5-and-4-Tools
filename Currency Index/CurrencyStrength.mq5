//
// CurrencyStrength.mq5/mq4
// Peter Thomet, getYournet.ch
//

#property copyright "2018, getYourNet.ch"
#property version "3.0"
#property indicator_separate_window

#property indicator_buffers 45
#property indicator_plots 8

#include <MovingAverages.mqh>
#ifdef __MQL5__
#include <SmoothAlgorithms.mqh>
#endif

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
input int ma_period = 0; // MA Period
input int ma_smoothing = 3; // MA Smoothing
input int BarsToCalculate = 30; // Number of Bars to calculate
input int ZeroPoint = 30; // Zero Point

input color Color_USD = MediumSeaGreen;            // USD line color
input color Color_EUR = DodgerBlue;         // EUR line color
input color Color_GBP = DeepPink;              // GBP line color
input color Color_CHF = Black;        // CHF line color
input color Color_JPY = Chocolate;           // JPY line color
input color Color_AUD = DarkOrange;       // AUD line color
input color Color_CAD = MediumVioletRed;           // CAD line color
input color Color_NZD = Silver;         // NZD line color

input int wid_standard = 1; //Lines width
input int wid_main = 3; //Lines width for current chart
input ENUM_LINE_STYLE style_slave = STYLE_SOLID; //Style of alternative lines for current chart
input bool all_solid = false; //Draw all main style
input bool draw_current_pairs_only = false; //Draw indexes of current pairs only
input bool switch_symbol_on_signal = false; //Switch Symbol on Signal
input bool test_forward_trading = false; //Test Forward Trading
input bool alert_momentum = false; //Alert Momentum
input bool show_strongest = false; //Show Strongest Move
input bool show_values = true; //Show Values
input int test_trading_candle_expiration = 3; //Test Trading Candle Expiration
input bool switch_symbol_on_click_all_charts = false; //On Click Switch Symbol at all Charts

struct TypeCurrency
{
   string name;
};
TypeCurrency Currency[8];

struct TypePair
{
   string name;
   MqlRates rates[];
   bool timechanged;
};
TypePair Pair[28];

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
       UpDn[]; // buffers of intermediate data rsi

double LastValues[8][2];

int y_pos = 4; // Y coordinate variable for the informatory objects  
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
datetime lastalert;
int _BarsToCalculate;
bool MoveToCursor;
int CursorBarIndex=0;
string ExtraChars = "";
#ifdef __MQL5__
CXMA xmaUSD,xmaEUR,xmaGBP,xmaCHF,xmaJPY,xmaCAD,xmaAUD,xmaNZD;
CJJMA jjmaUSD;
#endif

struct TypeUpdown
{
   double maxup;
   double maxdn;
   string up;
   string dn;
   bool isupreversal;
   bool isdnreversal;
};

string currencyclicked=NULL;

struct TypeSignal
{
   bool open;
   datetime candleendtime;
   int candles;
   string pair;
   string direction;
};

TypeSignal tradesignal={false,NULL,0,"",""};


void InitBuffer(int idx, double& buffer[], ENUM_INDEXBUFFER_TYPE data_type, string currency=NULL, color col=NULL)
{
#ifdef __MQL4__
   SetIndexStyle(idx, DRAW_NONE);
   if(data_type==INDICATOR_DATA)
   {
      SetIndexStyle(idx, DRAW_LINE, STYLE_SOLID, style_slave, col);
      SetIndexLabel(idx, currency);
   }
   else
   {
      SetIndexLabel(idx, "");
   }
   SetIndexLabel(idx, NULL);
#endif
   SetIndexBuffer(idx,buffer,data_type);
   ArraySetAsSeries(buffer,true);
   ArrayInitialize(buffer,EMPTY_VALUE);
   if(currency!=NULL)
   {
      PlotIndexSetString(idx,PLOT_LABEL,currency+"plot");
#ifdef __MQL5__
      PlotIndexSetInteger(idx,PLOT_SHOW_DATA,false);
#endif
      PlotIndexSetInteger(idx,PLOT_DRAW_BEGIN,_BarsToCalculate);
      PlotIndexSetInteger(idx,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(idx,PLOT_LINE_COLOR,col);
      PlotIndexSetDouble(idx,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      bool showlabel=true;
      if(StringFind(Symbol(),currency,0)!=-1 || all_solid)
      {
#ifdef __MQL4__
        SetIndexStyle(idx, DRAW_LINE, STYLE_SOLID, wid_main, col);
#endif
        PlotIndexSetInteger(idx,PLOT_LINE_WIDTH,wid_main);
        PlotIndexSetInteger(idx,PLOT_LINE_STYLE,STYLE_SOLID);
      }
      else
      {
         if(draw_current_pairs_only)
         {
            PlotIndexSetInteger(idx,PLOT_DRAW_TYPE,DRAW_NONE);
            showlabel=false;
         }
         else
         {
            PlotIndexSetInteger(idx,PLOT_DRAW_TYPE,DRAW_LINE);
#ifdef __MQL4__
            SetIndexStyle(idx, DRAW_LINE, STYLE_SOLID, wid_standard, col);
#endif
            PlotIndexSetInteger(idx,PLOT_LINE_WIDTH,wid_standard);
            PlotIndexSetInteger(idx,PLOT_LINE_STYLE,style_slave);
         }
      }
      if(showlabel)
         DrawObjects(currency,col);
   }
}


void OnInit()
{
   istesting=MQLInfoInteger(MQL_TESTER);
   
   _BarsToCalculate = BarsToCalculate;
   //_BarsToCalculate = BarsToCalculate+30;

   ExtraChars = StringSubstr(Symbol(), 6);
   
   IndicatorSetInteger(INDICATOR_DIGITS,5);

   string nameInd="CurrencyStrength";
   IndicatorSetString(INDICATOR_SHORTNAME,nameInd);

   InitBuffer(0,USDplot,INDICATOR_DATA,"USD",Color_USD);
   InitBuffer(15,USDx,INDICATOR_CALCULATIONS);

   InitBuffer(1,EURplot,INDICATOR_DATA,"EUR",Color_EUR);
   InitBuffer(8,EURUSD,INDICATOR_CALCULATIONS);
   InitBuffer(16,EURx,INDICATOR_CALCULATIONS);

   InitBuffer(2,GBPplot,INDICATOR_DATA,"GBP",Color_GBP);
   InitBuffer(9,GBPUSD,INDICATOR_CALCULATIONS);
   InitBuffer(17,GBPx,INDICATOR_CALCULATIONS);

   InitBuffer(3,JPYplot,INDICATOR_DATA,"JPY",Color_JPY);
   InitBuffer(10,USDJPY,INDICATOR_CALCULATIONS);
   InitBuffer(18,JPYx,INDICATOR_CALCULATIONS);

   InitBuffer(4,CHFplot,INDICATOR_DATA,"CHF",Color_CHF);
   InitBuffer(11,USDCHF,INDICATOR_CALCULATIONS);
   InitBuffer(19,CHFx,INDICATOR_CALCULATIONS);

   InitBuffer(5,CADplot,INDICATOR_DATA,"CAD",Color_CAD);
   InitBuffer(12,USDCAD,INDICATOR_CALCULATIONS);
   InitBuffer(20,CADx,INDICATOR_CALCULATIONS);

   InitBuffer(6,AUDplot,INDICATOR_DATA,"AUD",Color_AUD);
   InitBuffer(13,AUDUSD,INDICATOR_CALCULATIONS);
   InitBuffer(21,AUDx,INDICATOR_CALCULATIONS);

   InitBuffer(7,NZDplot,INDICATOR_DATA,"NZD",Color_NZD);
   InitBuffer(14,NZDUSD,INDICATOR_CALCULATIONS);
   InitBuffer(22,NZDx,INDICATOR_CALCULATIONS);

   InitBuffer(23,EURNZD,INDICATOR_CALCULATIONS);
   InitBuffer(24,EURCAD,INDICATOR_CALCULATIONS);
   InitBuffer(25,EURAUD,INDICATOR_CALCULATIONS);
   InitBuffer(26,EURJPY,INDICATOR_CALCULATIONS);
   InitBuffer(27,EURCHF,INDICATOR_CALCULATIONS);
   InitBuffer(28,EURGBP,INDICATOR_CALCULATIONS);

   InitBuffer(29,GBPNZD,INDICATOR_CALCULATIONS);
   InitBuffer(30,GBPAUD,INDICATOR_CALCULATIONS);
   InitBuffer(31,GBPCAD,INDICATOR_CALCULATIONS);
   InitBuffer(32,GBPJPY,INDICATOR_CALCULATIONS);
   InitBuffer(33,GBPCHF,INDICATOR_CALCULATIONS);

   InitBuffer(34,CADJPY,INDICATOR_CALCULATIONS);
   InitBuffer(35,CADCHF,INDICATOR_CALCULATIONS);
   InitBuffer(36,AUDCAD,INDICATOR_CALCULATIONS);
   InitBuffer(37,NZDCAD,INDICATOR_CALCULATIONS);

   InitBuffer(38,AUDCHF,INDICATOR_CALCULATIONS);
   InitBuffer(39,AUDJPY,INDICATOR_CALCULATIONS);
   InitBuffer(40,AUDNZD,INDICATOR_CALCULATIONS);

   InitBuffer(41,NZDJPY,INDICATOR_CALCULATIONS);
   InitBuffer(42,NZDCHF,INDICATOR_CALCULATIONS);
   InitBuffer(43,CHFJPY,INDICATOR_CALCULATIONS);

   SetIndexBuffer(44,UpDn,INDICATOR_CALCULATIONS);
#ifdef __MQL4__
   SetIndexStyle(44, DRAW_NONE);
   SetIndexLabel(44, NULL);
#endif
   ArraySetAsSeries(UpDn,true);
   ArrayInitialize(UpDn,EMPTY_VALUE);

   Pair[0].name="EURUSD";
   Pair[1].name="GBPUSD";
   Pair[2].name="USDCHF";
   Pair[3].name="USDJPY";
   Pair[4].name="USDCAD";
   Pair[5].name="AUDUSD";
   Pair[6].name="NZDUSD";
   Pair[7].name="EURNZD";
   Pair[8].name="EURCAD";
   Pair[9].name="EURAUD";
   Pair[10].name="EURJPY";
   Pair[11].name="EURCHF";
   Pair[12].name="EURGBP";
   Pair[13].name="GBPNZD";
   Pair[14].name="GBPAUD";
   Pair[15].name="GBPCAD";
   Pair[16].name="GBPJPY";
   Pair[17].name="GBPCHF";
   Pair[18].name="CADJPY";
   Pair[19].name="CADCHF";
   Pair[20].name="AUDCAD";
   Pair[21].name="NZDCAD";
   Pair[22].name="AUDCHF";
   Pair[23].name="AUDJPY";
   Pair[24].name="AUDNZD";
   Pair[25].name="NZDJPY";
   Pair[26].name="NZDCHF";
   Pair[27].name="CHFJPY";

   Currency[0].name="USD";
   Currency[1].name="EUR";
   Currency[2].name="GBP";
   Currency[3].name="JPY";
   Currency[4].name="CHF";
   Currency[5].name="CAD";
   Currency[6].name="AUD";
   Currency[7].name="NZD";

   if(!istesting)
   {
      EventSetTimer(1);
      ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
   }
}


void OnDeinit(const int reason)
{
   if(istesting)
      return;
   if(reason!=REASON_CHARTCHANGE)
      ObjectsDeleteAll(0,namespace,ChartWindowFind());
   EventKillTimer();
}


void CalculateAlert()
{
   if(!alert_momentum || Symbol()!="EURUSD")
      return;

   datetime dtarr[1];
   if(CopyTime(_Symbol,_Period,0,1,dtarr)!=1)
      return;

   int alertsecondsbefore=60;
   if(PeriodSeconds()==60)
      alertsecondsbefore=40;

   if(PeriodSeconds()-(TimeCurrent()-dtarr[0])<=alertsecondsbefore && lastalert!=dtarr[0])
   {
      bool usdup = USDplot[1]>USDplot[2] && USDplot[0]>=USDplot[1]+(USDplot[1]-USDplot[2]);
      bool usddown = USDplot[1]<USDplot[2] && USDplot[0]<=USDplot[1]-(USDplot[2]-USDplot[1]);
      bool eurup = EURplot[1]>EURplot[2] && EURplot[0]>=EURplot[1]+(EURplot[1]-EURplot[2]);
      bool eurdown = EURplot[1]<EURplot[2] && EURplot[0]<=EURplot[1]-(EURplot[2]-EURplot[1]);
      if(usdup && eurdown)
      {
         Alert(_Symbol + " Down Momentum");
         lastalert=dtarr[0];
      }
      if(usddown && eurup)
      {
         Alert(_Symbol + " Up Momentum");
         lastalert=dtarr[0];
      }
   }


}


void CheckUpDown(string currency, TypeUpdown& ud, double& arr[], int range)
{
   double diff=arr[0]-arr[range];
   if(diff>ud.maxup)
   {
      ud.maxup=diff;
      ud.up=currency;
      ud.isupreversal=arr[0]-arr[1]>0&&arr[0]-arr[1]>arr[1]-arr[2];
   }
   if(diff<ud.maxdn)
   {
      ud.maxdn=diff;
      ud.dn=currency;
      ud.isdnreversal=arr[0]-arr[1]<0&&arr[0]-arr[1]<arr[1]-arr[2];
   }
}


void StrongestMove(int range)
{
   //if(!show_strongest)
   //   return;

   TypeUpdown ud={-100,100,"","",false,false};

   CheckUpDown("USD",ud,USDplot,range);
   CheckUpDown("EUR",ud,EURplot,range);
   CheckUpDown("GBP",ud,GBPplot,range);
   CheckUpDown("JPY",ud,JPYplot,range);
   CheckUpDown("CHF",ud,CHFplot,range);
   CheckUpDown("CAD",ud,CADplot,range);
   CheckUpDown("AUD",ud,AUDplot,range);
   CheckUpDown("NZD",ud,NZDplot,range);
   
   bool signal=false;
   color c=DimGray;
   string pair=NormalizePairing(ud.up+ud.dn);
   bool up=false;
   if(StringFind(pair,ud.up)==0)
   {
      c=DodgerBlue;
      up=true;
   }
   if(StringFind(pair+ExtraChars,Symbol())==0)
   {
      if(up)
         UpDn[range-1]=1;
      else
         UpDn[range-1]=-1;
      //Print(UpDn[range-1]);
   }
   else
   {
      UpDn[range-1]=0;
   }
   if(ud.isupreversal && ud.isdnreversal)
   {
      //c=DodgerBlue;
      if(PeriodSeconds()-(TimeCurrent()-arrTime[0])<=20 && !tradesignal.open && test_forward_trading && range==1)
      {
         signal=true;
         tradesignal.open=true;
         tradesignal.candles=test_trading_candle_expiration;
         tradesignal.candleendtime=arrTime[0]+(PeriodSeconds()*tradesignal.candles);
         tradesignal.pair=pair;
         tradesignal.direction="up";
         if(StringFind(pair,ud.up)==0)
            tradesignal.direction="dn";
         Print(tradesignal.direction+" "+pair+" | "+TimeToString(tradesignal.candleendtime));
      }
   }
   if(show_strongest)
      AddSymbolButton(1, range, pair,c);
   if(signal && switch_symbol_on_signal)
      SwitchSymbol(pair);

}


int GetValueIndex(int row)
{
   int idx;
   for(idx=0; idx<8; idx++)
      if(LastValues[idx][1]==row)
         break;
   return idx;
}


void SetValues(int idx, double& values[])
{
   LastValues[idx][0]=values[0]-values[1];
   LastValues[idx][1]=idx+1;
}


void ShowTradeSets()
{
   string s1=Currency[((int)LastValues[7][1])-1].name;
   string s2=Currency[((int)LastValues[6][1])-1].name;
   string w1=Currency[((int)LastValues[0][1])-1].name;
   string w2=Currency[((int)LastValues[1][1])-1].name;
   
   string pair;
   pair=NormalizePairing(s1+w1);
   ShowTradeSet(1,1,pair,StringFind(pair,s1)==0);
   pair=NormalizePairing(s1+w2);
   ShowTradeSet(1,2,pair,StringFind(pair,s1)==0);
   pair=NormalizePairing(s2+w1);
   ShowTradeSet(1,3,pair,StringFind(pair,s2)==0);
   pair=NormalizePairing(s2+w2);
   ShowTradeSet(1,4,pair,StringFind(pair,s2)==0);
}


void ShowTradeSet(int col, int row, string text, bool buy)
{
   color _color=DimGray;
   if(buy)
      _color=DodgerBlue;
   int xdistance=((col-1)*62)+6;
   int ydistance=((row-1)*16)+20;
   string oname = namespace+"-SymbolButton-TradeSet-"+IntegerToString(col)+"-"+IntegerToString(row);
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,xdistance);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,ydistance);
   ObjectSetString(0,oname,OBJPROP_TEXT,text);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,_color);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,9);
}


void ShowValues()
{
   SetValues(0,USDplot);
   SetValues(1,EURplot);
   SetValues(2,GBPplot);
   SetValues(3,JPYplot);
   SetValues(4,CHFplot);
   SetValues(5,CADplot);
   SetValues(6,AUDplot);
   SetValues(7,NZDplot);

   ArraySort(LastValues);

   if(!show_values)
      return;

   ShowValue(1,1);
   ShowValue(1,2);
   ShowValue(1,3);
   ShowValue(1,4);
   ShowValue(1,5);
   ShowValue(1,6);
   ShowValue(1,7);
   ShowValue(1,8);
}


void ShowValue(int col, int row)
{
   int idx=GetValueIndex(row);
   double value=LastValues[idx][0];
   color _color=DimGray;
   if(idx>5)
      _color=MediumSeaGreen;
   if(idx<2)
      _color=DeepPink;
   //_color=DimGray;
   string text=DoubleToString(value*1000,0);
   //text="|||||||||";
   int xdistance=(col-1)*62+35;
   int ydistance=(row-1)*16+4;
   string oname = namespace+"-Value-"+IntegerToString(col)+"-"+IntegerToString(row);
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,xdistance);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,ydistance);
   ObjectSetString(0,oname,OBJPROP_TEXT,text);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,_color);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,9);
}


void AddSymbolButton(int col, int row, string text, color _color=DimGray)
{
   int xoffset=93;
   if(show_values)
      xoffset=117;
   int xdistance=((col-1)*62)+xoffset;
   int ydistance=((row-1)*16)+4;
   string oname = namespace+"-SymbolButton-"+IntegerToString(col)+"-"+IntegerToString(row);
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,xdistance);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,ydistance);
   ObjectSetString(0,oname,OBJPROP_TEXT,text);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,_color);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,9);
}


string NormalizePairing(string pair)
{
   string p=pair;
   for(int i=0; i<28; i++)
   {
      if(StringSubstr(p,3,3)+StringSubstr(p,0,3)==Pair[i].name)
      {
         p=Pair[i].name;
         break;
      }
   }
   return p;
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
      int strongcount=20;
      if(BarsToCalculate<strongcount-1)
         strongcount=BarsToCalculate-1;
      for(int i=1; i<=strongcount; i++)
         StrongestMove(i);
      //CalculateAlert();
      ShowValues();
      ShowTradeSets();
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
#ifdef __MQL5__
   currentticktime=TimeTradeServer();
#endif
#ifdef __MQL4__
   currentticktime=TimeCurrent();
#endif
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

      //USDplot[0]=USDplot[1];
      //EURplot[0]=EURplot[1];
      //GBPplot[0]=GBPplot[1];
      //CHFplot[0]=CHFplot[1];
      //JPYplot[0]=JPYplot[1];
      //CADplot[0]=CADplot[1];
      //AUDplot[0]=AUDplot[1];
      //NZDplot[0]=NZDplot[1];
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

   if(!GetRates("EURUSD",EURUSD,limit,Pair[0])) return(false);
   if(!GetRates("GBPUSD",GBPUSD,limit,Pair[1])) return(false);
   if(!GetRates("USDCHF",USDCHF,limit,Pair[2])) return(false);
   if(!GetRates("USDJPY",USDJPY,limit,Pair[3])) return(false);
   if(!GetRates("USDCAD",USDCAD,limit,Pair[4])) return(false);
   if(!GetRates("AUDUSD",AUDUSD,limit,Pair[5])) return(false);
   if(!GetRates("NZDUSD",NZDUSD,limit,Pair[6])) return(false);
   
   if(!GetRates("EURNZD",EURNZD,limit,Pair[7])) return(false);
   if(!GetRates("EURCAD",EURCAD,limit,Pair[8])) return(false);
   if(!GetRates("EURAUD",EURAUD,limit,Pair[9])) return(false);
   if(!GetRates("EURJPY",EURJPY,limit,Pair[10])) return(false);
   if(!GetRates("EURCHF",EURCHF,limit,Pair[11])) return(false);
   if(!GetRates("EURGBP",EURGBP,limit,Pair[12])) return(false);

   if(!GetRates("GBPNZD",GBPNZD,limit,Pair[13])) return(false);
   if(!GetRates("GBPAUD",GBPAUD,limit,Pair[14])) return(false);
   if(!GetRates("GBPCAD",GBPCAD,limit,Pair[15])) return(false);
   if(!GetRates("GBPJPY",GBPJPY,limit,Pair[16])) return(false);
   if(!GetRates("GBPCHF",GBPCHF,limit,Pair[17])) return(false);

   if(!GetRates("CADJPY",CADJPY,limit,Pair[18])) return(false);
   if(!GetRates("CADCHF",CADCHF,limit,Pair[19])) return(false);
   if(!GetRates("AUDCAD",AUDCAD,limit,Pair[20])) return(false);
   if(!GetRates("NZDCAD",NZDCAD,limit,Pair[21])) return(false);

   if(!GetRates("AUDCHF",AUDCHF,limit,Pair[22])) return(false);
   if(!GetRates("AUDJPY",AUDJPY,limit,Pair[23])) return(false);
   if(!GetRates("AUDNZD",AUDNZD,limit,Pair[24])) return(false);

   if(!GetRates("NZDJPY",NZDJPY,limit,Pair[25])) return(false);
   if(!GetRates("NZDCHF",NZDCHF,limit,Pair[26])) return(false);
   if(!GetRates("CHFJPY",CHFJPY,limit,Pair[27])) return(false);

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

            //EURx[i]=0;
            //EURx[i]-=(GBPUSD[i]-GBPUSD[start])/GBPUSD[start]*100;
            //EURx[i]+=(USDCHF[i]-USDCHF[start])/USDCHF[start]*100;
            //EURx[i]+=(USDJPY[i]-USDJPY[start])/USDJPY[start]*100;
            //EURx[i]+=(USDCAD[i]-USDCAD[start])/USDCAD[start]*100;
            //EURx[i]-=(AUDUSD[i]-AUDUSD[start])/AUDUSD[start]*100;
            //EURx[i]-=(NZDUSD[i]-NZDUSD[start])/NZDUSD[start]*100;
            //EURx[i]=EURx[i]/6;
            
            //EURx[i]=EURx[i]-USDx[i];

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
#ifdef __MQL5__
         if(i>sml && ma_period>1)
            USDplot[i]=xmaUSD.XMASeries(0, prev, total, MODE_T3, 0, ma_period, USDx[i], idx, false);
         else
#endif
            USDplot[i]=USDx[i];
         //USDplot[i]=jjmaUSD.JJMASeries(0, prev, total, 0, 100, ma_period, USDx[i], idx, false);
         USDplot[i]+=1000;
      if(IncludeCurrency("EUR"))
#ifdef __MQL5__
         if(i>sml && ma_period>1)
            EURplot[i]=xmaEUR.XMASeries(0, prev, total, MODE_T3, 0, ma_period, EURx[i], idx, false);
         else
#endif
            EURplot[i]=EURx[i];
         EURplot[i]+=1000;
      if(IncludeCurrency("GBP"))
#ifdef __MQL5__
         if(i>sml && ma_period>1)
            GBPplot[i]=xmaGBP.XMASeries(0, prev, total, MODE_T3, 0, ma_period, GBPx[i], idx, false);
         else
#endif
            GBPplot[i]=GBPx[i];
         GBPplot[i]+=1000;
      if(IncludeCurrency("CHF"))
#ifdef __MQL5__
         if(i>sml && ma_period>1)
            CHFplot[i]=xmaCHF.XMASeries(0, prev, total, MODE_T3, 0, ma_period, CHFx[i], idx, false);
         else
#endif
            CHFplot[i]=CHFx[i];
         CHFplot[i]+=1000;
      if(IncludeCurrency("JPY"))
#ifdef __MQL5__
         if(i>sml && ma_period>1)
            JPYplot[i]=xmaJPY.XMASeries(0, prev, total, MODE_T3, 0, ma_period, JPYx[i], idx, false);
         else
#endif
            JPYplot[i]=JPYx[i];
         JPYplot[i]+=1000;
      if(IncludeCurrency("CAD"))
#ifdef __MQL5__
         if(i>sml && ma_period>1)
            CADplot[i]=xmaCAD.XMASeries(0, prev, total, MODE_T3, 0, ma_period, CADx[i], idx, false);
         else
#endif
            CADplot[i]=CADx[i];
         CADplot[i]+=1000;
      if(IncludeCurrency("AUD"))
#ifdef __MQL5__
         if(i>sml && ma_period>1)
            AUDplot[i]=xmaAUD.XMASeries(0, prev, total, MODE_T3, 0, ma_period, AUDx[i], idx, false);
         else
#endif
            AUDplot[i]=AUDx[i];
         AUDplot[i]+=1000;
      if(IncludeCurrency("NZD"))
#ifdef __MQL5__
         if(i>sml && ma_period>1)
            NZDplot[i]=xmaNZD.XMASeries(0, prev, total, MODE_T3, 0, ma_period, NZDx[i], idx, false);
         else
#endif
            NZDplot[i]=NZDx[i];
         NZDplot[i]+=1000;
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


bool GetRates(string pair, double& buffer[], int bars, TypePair& p)
{
   if(!IncludePair(pair))
      return true;
   bool ret = true;
   int copied;
   //MqlRates rates[];
   
   int rcount=ArraySize(p.rates);
   datetime starttime=0;
   datetime endtime=0;
   p.timechanged=false;
   if(rcount<_BarsToCalculate)
   {
      p.timechanged=true;
   }
   else
   {
      endtime=p.rates[0].time;
      starttime=p.rates[_BarsToCalculate-1].time;
   }
   
   copied=CopyRates(pair+ExtraChars,PERIOD_CURRENT,0,_BarsToCalculate,p.rates);
   //if(copied==-1)
   if(copied<_BarsToCalculate)
   {
      WriteComment("Wait..."+pair);
      ret=false;
   }
   else
   {
      if(p.rates[0].time!=endtime || p.rates[_BarsToCalculate-1].time!=starttime)
      {
         p.timechanged=true;
         //Print("TIME CHANGED");
      }
   
      for(int i=0;i<copied;i++)
      {
         buffer[copied-i-1]=GetPrice(PriceType,p.rates,i);
      }
      CheckTrade(pair,p.rates,copied);
   }
   return ret;
}


void CheckTrade(string pair, MqlRates& rates[], int count)
{
   if(tradesignal.open && tradesignal.pair==pair)
   {
      if(rates[count-2].time>=tradesignal.candleendtime)
      {
         string candledirection="up";
         if(rates[count-2].close<rates[count-1-tradesignal.candles].open)
            candledirection="dn";
         SetTradeResults((candledirection==tradesignal.direction));
         if(!istesting)
         {
            MqlDateTime dt;
            TimeToStruct(tradesignal.candleendtime,dt);
            string filename=IntegerToString(dt.year)+"-"+IntegerToString(dt.mon,2,'0')+"-"+IntegerToString(dt.day,2,'0')+"-"+IntegerToString(dt.hour,2,'0')+"-"+IntegerToString(dt.min,2,'0');
            string on=namespace+"TempScreenShot";
            ENUM_OBJECT ot=OBJ_ARROW_CHECK;
            color c=MediumSeaGreen;
            if(candledirection!=tradesignal.direction)
            {
               ot=OBJ_ARROW_STOP;
               c=DeepPink;
            }
            ObjectCreate(0,on,ot,0,rates[count-2].time,rates[count-2].high+(_Point*0));
            ObjectSetInteger(0,on,OBJPROP_WIDTH,5);
            ObjectSetInteger(0,on,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
            ObjectSetInteger(0,on,OBJPROP_COLOR,c);
            ChartScreenShot(0,filename+".png",1280,720);
            ObjectDelete(0,on);
         }
         tradesignal.open=false;
      }
   }
}


void SetTradeResults(bool won)
{
   Print("Won "+IntegerToString(won));

   string oname1 = namespace+"-TradesWon";
   string oname2 = namespace+"-TradesTotal";
   if(ObjectFind(0,oname1)<0)
   {
      ObjectCreate(0,oname1,OBJ_LABEL,ChartWindowFind(),0,0);
      ObjectSetInteger(0,oname1,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,oname1,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0,oname1,OBJPROP_XDISTANCE,20);
      ObjectSetInteger(0,oname1,OBJPROP_YDISTANCE,25);
      ObjectSetString(0,oname1,OBJPROP_TEXT,"0");
      ObjectSetInteger(0,oname1,OBJPROP_COLOR,Black);
      ObjectSetInteger(0,oname1,OBJPROP_FONTSIZE,12);
   }
   if(won)
      ObjectSetString(0,oname1,OBJPROP_TEXT,IntegerToString(StringToInteger(ObjectGetString(0,oname1,OBJPROP_TEXT))+1));
   if(ObjectFind(0,oname2)<0)
   {
      ObjectCreate(0,oname2,OBJ_LABEL,ChartWindowFind(),0,0);
      ObjectSetInteger(0,oname2,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,oname2,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0,oname2,OBJPROP_XDISTANCE,60);
      ObjectSetInteger(0,oname2,OBJPROP_YDISTANCE,25);
      ObjectSetString(0,oname2,OBJPROP_TEXT,"1");
      ObjectSetInteger(0,oname2,OBJPROP_COLOR,Black);
      ObjectSetInteger(0,oname2,OBJPROP_FONTSIZE,12);
   }
   else
   {
      ObjectSetString(0,oname2,OBJPROP_TEXT,IntegerToString(StringToInteger(ObjectGetString(0,oname2,OBJPROP_TEXT))+1));
   }
}


int DrawObjects(string name,color _color)
{
   string oname = namespace+"-Currency-"+name;
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,6);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,y_pos);
   ObjectSetString(0,oname,OBJPROP_TEXT,name);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,_color);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,9);
   y_pos+=16;
   return(0);
}


int WriteComment(string text)
{
   string name=namespace+"-f_comment";
   color _color=DimGray;
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

      for(int i=0; i<28; i++)
         GetPairData(Pair[i].name);

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
   bars_tf[index]=Bars(pair+ExtraChars,PERIOD_CURRENT);
   copy=CopyTime(pair+ExtraChars,PERIOD_CURRENT,0,1,tmp_time);
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


static bool ctrl_pressed = false;
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_KEYDOWN)
   {
      if (ctrl_pressed == false && lparam == 17)
      {
         ctrl_pressed = true;
      }
      else if (ctrl_pressed == true)
      {
         if (lparam == 57)
         {
            MoveToCursor=!MoveToCursor;
            ctrl_pressed = false;
         }
      }
   }
   if(id==CHARTEVENT_MOUSE_MOVE)
   {
      int x=(int)lparam;
      int y=(int)dparam;
      datetime dt=0;
      double price=0;
      int window=0;
      if(ChartXYToTimePrice(0,x,y,window,dt,price))
      {
         dt=dt-(PeriodSeconds()/2);
         datetime Arr[],time1;
         if(CopyTime(Symbol(),Period(),0,1,Arr)==1)
         {
            time1=Arr[0];
            if(CopyTime(Symbol(),Period(),dt,time1,Arr)>0)
            {
               CursorBarIndex=ArraySize(Arr)-1;
               //PrintFormat("Window=%d X=%d  Y=%d  =>  Time=%s  Price=%G Barindex=%i",window,x,y,TimeToString(dt),price,CursorBarIndex);
            }
         }
      }
   }
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(sparam,"-SymbolButton")>-1)
      {
         SwitchSymbol(ObjectGetString(0,sparam,OBJPROP_TEXT));
      }
      if(StringFind(sparam,"-Currency")>-1 && !draw_current_pairs_only)
      {
         string z=ObjectGetString(0,sparam,OBJPROP_TEXT);
         z=StringSubstr(z,StringLen(z)-3);
         if(currencyclicked==NULL)
         {
            currencyclicked=z;
         }
         else
         {
            SwitchSymbol(NormalizePairing(z+currencyclicked));
            currencyclicked=NULL;
         }
      }
   }
}


void SwitchSymbol(string tosymbol)
{
   if(istesting)
      return;
   string currentsymbol=StringSubstr(ChartSymbol(),0,6);
   if(currentsymbol!=tosymbol)
   {
      if(switch_symbol_on_click_all_charts)
      {
         long chartid=ChartFirst();
         while(chartid>-1)
         {
            if(chartid!=ChartID())
               ChartSetSymbolPeriod(chartid,tosymbol+ExtraChars,ChartPeriod(chartid));
            chartid=ChartNext(chartid);
         }
      }
      ChartSetSymbolPeriod(0,tosymbol+ExtraChars,0);
      AddSymbolButton(2, 1, currentsymbol);
   }
}
