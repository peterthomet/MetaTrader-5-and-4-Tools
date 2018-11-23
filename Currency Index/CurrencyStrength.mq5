//
// CurrencyStrength.mq5/mq4
// Peter Thomet, getYournet.ch
//

#property copyright "2018, getYourNet.ch"
#property version "3.0"
#property indicator_separate_window

#property indicator_buffers 9
#property indicator_plots 8

//#include <MovingAverages.mqh>
#ifdef __MQL5__
//#include <SmoothAlgorithms.mqh>
#endif

#define CS_INDICATOR_MODE

enum CS_Prices
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

input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Timeframe
input CS_Prices PriceType = pr_close; // Price Type
input int BarsCalculate = 30; // Number of Bars to calculate
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
   double index[];
};

struct TypeTrade
{
   string name;
   bool buy;
};

struct TypeCurrencies
{
   TypeCurrency Currency[8];
   double LastValues[8][2];
   TypeTrade Trade[4];
   TypeCurrencies()
   {
      Currency[0].name="USD";
      Currency[1].name="EUR";
      Currency[2].name="GBP";
      Currency[3].name="JPY";
      Currency[4].name="CHF";
      Currency[5].name="CAD";
      Currency[6].name="AUD";
      Currency[7].name="NZD";
   }
   int GetValueIndex(int row)
   {
      int idx;
      for(idx=0; idx<8; idx++)
         if(LastValues[idx][1]==row)
            break;
      return idx;
   }
};

struct TypePair
{
   string name;
   MqlRates rates[];
};

struct TypePairs
{
   TypePair Pair[28];
   bool anytimechanged;
   datetime maxtime;
   TypePairs()
   {
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
};

struct TypeCurrencyStrength
{
   ENUM_TIMEFRAMES timeframe;
   int bars;
   int start;
   string extrachars;
   CS_Prices pricetype;
   bool recalculate;
   TypeCurrencies Currencies;
   TypePairs Pairs;
   TypeCurrencyStrength()
   {
      timeframe=PERIOD_CURRENT;
      bars=10;
      start=0;
      extrachars=StringSubstr(Symbol(),6);
      pricetype=pr_close;
      recalculate=false;
   }
   void Init(int _Bars, int Zero, string ExtraChars, ENUM_TIMEFRAMES TimeFrameCustom)
   {
      bars=_Bars;
      for(int i=0; i<8; i++)
         ArrayResize(Currencies.Currency[i].index,bars);

      if(Zero<bars&&Zero>=0)
         start=(bars-1)-Zero;

      extrachars=ExtraChars;
      
      timeframe=TimeFrameCustom;
   }
};
TypeCurrencyStrength CS;

double USDplot[],
       EURplot[],
       GBPplot[],
       JPYplot[],
       CHFplot[],
       CADplot[],
       AUDplot[],
       NZDplot[],
       UpDn[];

int y_pos = 4;
string namespace="CurrencyStrength";
bool incalculation=false;
datetime lastticktime;
datetime currentticktime;
int sameticktimecount=0;
bool timerenabled=true;
bool istesting;
datetime lasttestevent;
datetime lastalert;
bool MoveToCursor;
int CursorBarIndex=0;
#ifdef __MQL5__
//CXMA xmaUSD,xmaEUR,xmaGBP,xmaCHF,xmaJPY,xmaCAD,xmaAUD,xmaNZD;
//CJJMA jjmaUSD;
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
      PlotIndexSetInteger(idx,PLOT_DRAW_BEGIN,BarsCalculate);
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
   
   IndicatorSetInteger(INDICATOR_DIGITS,5);

   string nameInd="CurrencyStrength";
   IndicatorSetString(INDICATOR_SHORTNAME,nameInd);

   InitBuffer(0,USDplot,INDICATOR_DATA,"USD",Color_USD);
   InitBuffer(1,EURplot,INDICATOR_DATA,"EUR",Color_EUR);
   InitBuffer(2,GBPplot,INDICATOR_DATA,"GBP",Color_GBP);
   InitBuffer(3,JPYplot,INDICATOR_DATA,"JPY",Color_JPY);
   InitBuffer(4,CHFplot,INDICATOR_DATA,"CHF",Color_CHF);
   InitBuffer(5,CADplot,INDICATOR_DATA,"CAD",Color_CAD);
   InitBuffer(6,AUDplot,INDICATOR_DATA,"AUD",Color_AUD);
   InitBuffer(7,NZDplot,INDICATOR_DATA,"NZD",Color_NZD);

   SetIndexBuffer(8,UpDn,INDICATOR_CALCULATIONS);
#ifdef __MQL4__
   SetIndexStyle(8, DRAW_NONE);
   SetIndexLabel(8, NULL);
#endif
   ArraySetAsSeries(UpDn,true);
   ArrayInitialize(UpDn,EMPTY_VALUE);

   CS.Init(
      BarsCalculate,
      ZeroPoint,
      StringSubstr(Symbol(),6),
      TimeFrame
      );

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
   if(CopyTime(Symbol(),Period(),0,1,dtarr)!=1)
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
         Alert(Symbol() + " Down Momentum");
         lastalert=dtarr[0];
      }
      if(usddown && eurup)
      {
         Alert(Symbol() + " Up Momentum");
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
   string pair=CS.Pairs.NormalizePairing(ud.up+ud.dn);
   bool up=false;
   if(StringFind(pair,ud.up)==0)
   {
      c=DodgerBlue;
      up=true;
   }
   if(StringFind(pair+CS.extrachars,Symbol())==0)
   {
      if(up)
         UpDn[range-1]=1;
      else
         UpDn[range-1]=-1;
   }
   else
   {
      UpDn[range-1]=0;
   }
   if(ud.isupreversal && ud.isdnreversal)
   {
      if(PeriodSeconds()-(TimeCurrent()-CS.Pairs.maxtime)<=20 && !tradesignal.open && test_forward_trading && range==1)
      {
         signal=true;
         tradesignal.open=true;
         tradesignal.candles=test_trading_candle_expiration;
         tradesignal.candleendtime=CS.Pairs.maxtime+(PeriodSeconds()*tradesignal.candles);
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


void ShowValue(int col, int row)
{
   int idx=CS.Currencies.GetValueIndex(row);
   double value=CS.Currencies.LastValues[idx][0];
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
   if(CS_CalculateIndex(CS))
   {
      WriteComment(" ");

      int strongcount=20;
      if(BarsCalculate<strongcount-1)
         strongcount=BarsCalculate-1;
      for(int i=1; i<=strongcount; i++)
         StrongestMove(i);
      //CalculateAlert();

      if(show_values)
         for(int j=1; j<=8; j++)
            ShowValue(1,j);

      for(int t=0; t<4; t++)
         ShowTradeSet(1,t+1,CS.Currencies.Trade[t].name,CS.Currencies.Trade[t].buy);

      ChartRedraw();
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
      CS.recalculate=true;

      if(prev_calculated==0)
      {
         ArrayInitialize(USDplot,EMPTY_VALUE);
         ArrayInitialize(EURplot,EMPTY_VALUE);
         ArrayInitialize(GBPplot,EMPTY_VALUE);
         ArrayInitialize(CHFplot,EMPTY_VALUE);
         ArrayInitialize(JPYplot,EMPTY_VALUE);
         ArrayInitialize(CADplot,EMPTY_VALUE);
         ArrayInitialize(AUDplot,EMPTY_VALUE);
         ArrayInitialize(NZDplot,EMPTY_VALUE);
      }
      else
      {
         for(int i=0; i<=BarsCalculate; i++)
         {
            USDplot[i]=EMPTY_VALUE;
            EURplot[i]=EMPTY_VALUE;
            GBPplot[i]=EMPTY_VALUE;
            CHFplot[i]=EMPTY_VALUE;
            JPYplot[i]=EMPTY_VALUE;
            CADplot[i]=EMPTY_VALUE;
            AUDplot[i]=EMPTY_VALUE;
            NZDplot[i]=EMPTY_VALUE;
         }
      }
   }
   timerenabled=true;
   if(istesting)
      OnTimer();
   return(rates_total);
}


bool CS_CalculateIndex(TypeCurrencyStrength& cs)
{
   int limit=cs.bars;

   cs.Pairs.anytimechanged=false;
   cs.Pairs.maxtime=0;

   bool failed=false;
   for(int i=0; i<28; i++)
   {
      if(!CS_GetRates(cs.Pairs.Pair[i],cs))
         failed=true;
   }
   if(failed)
      return(false);

   if(cs.Pairs.anytimechanged||cs.recalculate)
      limit=cs.bars;
   else
      limit=1;

   for(int y=cs.bars-limit;y<cs.bars;y++)
   {
      for(int z=0; z<8; z++)
      {
         string cn=cs.Currencies.Currency[z].name;
         if(IncludeCurrency(cn))
         {
            cs.Currencies.Currency[z].index[y]=0;
            if(y!=cs.start)
            {
               for(int x=0; x<28; x++)
               {
                  bool isbase=(StringSubstr(cs.Pairs.Pair[x].name,0,3)==cn);
                  bool isquote=(StringSubstr(cs.Pairs.Pair[x].name,3,3)==cn);
                  if(isbase||isquote)
                  {
                     int firstgap=(int)(cs.Pairs.maxtime-cs.Pairs.Pair[x].rates[cs.bars-1].time);
                     int shift=(firstgap/PeriodSeconds(cs.timeframe));

                     if((y+shift)>(cs.bars-1))
                        shift=(cs.bars-1)-y;

                     double pi=CS_GetPrice(PriceType,cs.Pairs.Pair[x].rates,y+shift);
                     double ps=CS_GetPrice(PriceType,cs.Pairs.Pair[x].rates,cs.start+shift);
                     if(isbase)
                        cs.Currencies.Currency[z].index[y]+=(pi-ps)/ps*100;
                     if(isquote)
                        cs.Currencies.Currency[z].index[y]-=(pi-ps)/ps*100;
                  }
               }
               cs.Currencies.Currency[z].index[y]=cs.Currencies.Currency[z].index[y]/7;
            }
            if(y==(cs.bars-1))
            {
               cs.Currencies.LastValues[z][0]=cs.Currencies.Currency[z].index[y]-cs.Currencies.Currency[z].index[y-1];
               cs.Currencies.LastValues[z][1]=z+1;
            }
#ifdef CS_INDICATOR_MODE
            int ti=(cs.bars-1)-y;
            double va=cs.Currencies.Currency[z].index[y]+1000;
            if(cn=="USD") USDplot[ti]=va;
            if(cn=="EUR") EURplot[ti]=va;
            if(cn=="GBP") GBPplot[ti]=va;
            if(cn=="CHF") CHFplot[ti]=va;
            if(cn=="JPY") JPYplot[ti]=va;
            if(cn=="CAD") CADplot[ti]=va;
            if(cn=="AUD") AUDplot[ti]=va;
            if(cn=="NZD") NZDplot[ti]=va;
#endif
         }
      }
   }
   
   ArraySort(cs.Currencies.LastValues);

   string s1=cs.Currencies.Currency[((int)cs.Currencies.LastValues[7][1])-1].name;
   string s2=cs.Currencies.Currency[((int)cs.Currencies.LastValues[6][1])-1].name;
   string w1=cs.Currencies.Currency[((int)cs.Currencies.LastValues[0][1])-1].name;
   string w2=cs.Currencies.Currency[((int)cs.Currencies.LastValues[1][1])-1].name;

   string pair;

   pair=cs.Pairs.NormalizePairing(s1+w1);
   cs.Currencies.Trade[0].name=pair;
   cs.Currencies.Trade[0].buy=StringFind(pair,s1)==0;

   pair=cs.Pairs.NormalizePairing(s1+w2);
   cs.Currencies.Trade[1].name=pair;
   cs.Currencies.Trade[1].buy=StringFind(pair,s1)==0;

   pair=cs.Pairs.NormalizePairing(s2+w1);
   cs.Currencies.Trade[2].name=pair;
   cs.Currencies.Trade[2].buy=StringFind(pair,s2)==0;

   pair=cs.Pairs.NormalizePairing(s2+w2);
   cs.Currencies.Trade[3].name=pair;
   cs.Currencies.Trade[3].buy=StringFind(pair,s2)==0;

   cs.recalculate=false;

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


bool CS_GetRates(TypePair& p, TypeCurrencyStrength& cs)
{
   if(!IncludePair(p.name))
      return true;
   bool ret = true;
   int copied;
   int rcount=ArraySize(p.rates);
   datetime newesttime=0;
   datetime oldesttime=0;
   if(rcount<cs.bars)
   {
      cs.Pairs.anytimechanged=true;
   }
   else
   {
      oldesttime=p.rates[0].time;
      newesttime=p.rates[cs.bars-1].time;
   }
   
   copied=CopyRates(p.name+cs.extrachars,cs.timeframe,0,cs.bars,p.rates);
   if(copied<cs.bars)
   {
      WriteComment("Loading... "+p.name);
      ret=false;
   }
   else
   {
      if(p.rates[0].time!=oldesttime || p.rates[cs.bars-1].time!=newesttime)
         cs.Pairs.anytimechanged=true;

      cs.Pairs.maxtime=MathMax(cs.Pairs.maxtime,p.rates[cs.bars-1].time);
   
      CheckTrade(p.name,p.rates,copied);
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


double CS_GetPrice(int tprice, MqlRates& rates[], int i)
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
            SwitchSymbol(CS.Pairs.NormalizePairing(z+currencyclicked));
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
               ChartSetSymbolPeriod(chartid,tosymbol+CS.extrachars,ChartPeriod(chartid));
            chartid=ChartNext(chartid);
         }
      }
      ChartSetSymbolPeriod(0,tosymbol+CS.extrachars,0);
      AddSymbolButton(2, 1, currentsymbol);
   }
}
