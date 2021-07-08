//
// CurrencyStrength.mq5/mq4
// Peter Thomet, getYournet.ch
//

#property copyright "2018, getYourNet.ch"
#property version "4.0"
#property indicator_separate_window

#property indicator_buffers 9
#property indicator_plots 8

//#include <MovingAverages.mqh>
#ifdef __MQL5__
//#include <SmoothAlgorithms.mqh>
#endif

#define CS_INDICATOR_MODE
#include <CurrencyStrength.mqh>

enum CalculationMode
{
   RAW,
   SMA,
   OSCILLATOR
};

enum ZeroPointTypeList
{
   ByBar, // Number of Bar
   Minutes3, // 3 Minutes
   Minutes5, // 5 Minutes
   Minutes15, // 15 Minutes
   Minutes30, // 30 Minutes
   Hour, // 1 Hour
   Hours4, // 4 Hours
   Day, // Start of Day
   Week // Start of Week
};

input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Timeframe
input CS_Prices PriceType = pr_close; // Price Type
input int SMALength = 6; // SMA Length for SMA Mode
input int SMALengthOscillatorLong = 19; // SMA Length Long for Oscillator Mode
input int SMALengthOscillatorShort = 5; // SMA Length Short for Oscillator Mode
input int BarsCalculate = 30; // Number of Bars to calculate
input int ZeroPoint = 30; // Zero Point Bar
input ZeroPointTypeList ZeroPointType = ByBar; // Zero Point Type
input bool ValueDisplayedWholeRange = false; // Value displayed is whole Range

input color Color_USD = MediumSeaGreen; // USD line color
input color Color_EUR = DodgerBlue; // EUR line color
input color Color_GBP = DeepPink; // GBP line color
input color Color_CHF = Black; // CHF line color
input color Color_JPY = Chocolate; // JPY line color
input color Color_AUD = DarkOrange; // AUD line color
input color Color_CAD = MediumVioletRed; // CAD line color
input color Color_NZD = Silver; // NZD line color

input color Color_StandardText = DimGray; // Color Standard Text
input color Color_BuyText = DodgerBlue; // Color Buy Text
input color Color_SellText = DimGray; // Color Sell Text
input color Color_BuyValue = MediumSeaGreen; // Color Buy Value
input color Color_SellValue = DeepPink; // Color Sell Value

input int wid_standard = 1; //Lines width
input int wid_main = 3; //Lines width for current chart
input ENUM_LINE_STYLE style_slave = STYLE_SOLID; //Style of alternative lines for current chart
input bool all_solid = false; //Draw all main style
input bool current_pairs_only = false; //Calculate current pairs only
input bool switch_symbol_on_signal = false; //Switch Symbol on Signal
input bool test_forward_trading = false; //Test Forward Trading
input bool alert_momentum = false; //Alert Momentum
input bool show_strongest = false; //Show Strongest Move
input bool show_values = true; //Show Values
input int test_trading_candle_expiration = 3; //Test Trading Candle Expiration
input bool switch_symbol_on_click_all_charts = false; //On Click Switch Symbol at all Charts
input double set_charts_shift = 0; //Set Chart Shift at Startup
input bool create_multiple_charts_time_line = false; //Create multiple Charts Time Line
input bool create_multiple_charts_price_line = false; //Create multiple Charts Price Line
input bool draw_percent_levels = false; //Draw Percent Levels
input color Color_percent_levels = Gainsboro; // Color Percent Levels

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
string appnamespace="CurrencyStrength";
bool incalculation=false;
datetime lastticktime;
datetime currentticktime;
int sameticktimecount=0;
bool timerenabled=false;
bool istesting;
datetime lasttestevent;
datetime lastalert;
bool CrossHair=false;
int offset=0;
datetime offsettimeref=0;
datetime offsettime=0;
int lastoffset=0;
CalculationMode modecurrent;
CalculationMode modelast;
bool NewBarBase=false;
ulong LastMicrosecondCount=0;
int basecurrency=-1;
bool showbasket=false;
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
         if(CS.currentpairsonly)
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


void InitCS()
{
   int smalong=0, smashort=0, zeropoint=GetZeroBar();

   if(modecurrent==SMA)
      smalong=SMALength;

   if(modecurrent==OSCILLATOR)
   {
      smalong=SMALengthOscillatorLong;
      smashort=SMALengthOscillatorShort;
   }
   
   CS.Init(
      BarsCalculate,
      zeropoint,
      StringSubstr(Symbol(),6),
      TimeFrame,
      current_pairs_only,
      PriceType,
      smalong,
      smashort,
      ValueDisplayedWholeRange
      );

   CS.recalculate=true;
     
   modelast=modecurrent;
}


void OnInit()
{
   int moderead=(int)GlobalVariableGet(appnamespace+IntegerToString(ChartID())+"_mode");
   if(moderead<0||moderead>OSCILLATOR)
      moderead=0;
   modecurrent=(CalculationMode)moderead;

   InitCS();

   istesting=MQLInfoInteger(MQL_TESTER);
   
   IndicatorSetInteger(INDICATOR_DIGITS,5);

   IndicatorSetString(INDICATOR_SHORTNAME,"CurrencyStrength");

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

   int offsetread=(int)GlobalVariableGet(appnamespace+IntegerToString(ChartID())+"_offset");
   if(offsetread>0)
   {
      offset=1;
      offsettime=offsetread;
   }

   int basecurrencyread=(int)GlobalVariableGet(appnamespace+IntegerToString(ChartID())+"_basecurrency");
   if(basecurrencyread>0)
      basecurrency=basecurrencyread-1;

   if(GlobalVariableCheck(appnamespace+IntegerToString(ChartID())+"_showbasket"))
      showbasket=true;
   
   AddFunctionButton(6,16,"RAW |");
   AddFunctionButton(39,16,"SMA |");
   AddFunctionButton(70,16,"OSCILLATOR");
   
   if(!istesting)
   {
      EventSetMillisecondTimer(1);
      ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
   }

   if(set_charts_shift>0)
      ChartSetDouble(0,CHART_SHIFT_SIZE,set_charts_shift);
      
   if(create_multiple_charts_time_line)
   {
      ObjectCreate(0,appnamespace+"MouseMove",OBJ_VLINE,0,D'2000.01.01 00:00',0);
      ObjectSetInteger(0,appnamespace+"MouseMove",OBJPROP_COLOR,ChartGetInteger(0,CHART_COLOR_FOREGROUND));
   }

   if(create_multiple_charts_price_line)
   {
      ObjectCreate(0,appnamespace+"MouseMovePrice",OBJ_HLINE,0,0,0);
      ObjectSetInteger(0,appnamespace+"MouseMovePrice",OBJPROP_COLOR,ChartGetInteger(0,CHART_COLOR_FOREGROUND));
   }
   
   if(draw_percent_levels)
   {
      for(int i=1; i<=15; i++)
      {
         double levelvalue=999.99+(0.00125*i);
         string percentstring=DoubleToString((levelvalue-1000)*100,3);
         string objname=appnamespace+"Percent"+percentstring;
         ObjectCreate(0,objname,OBJ_HLINE,ChartWindowFind(),0,levelvalue);
         ObjectSetInteger(0,objname,OBJPROP_COLOR,Color_percent_levels);
         ObjectSetInteger(0,objname,OBJPROP_BACK,true);
         ObjectSetString(0,objname,OBJPROP_TOOLTIP,percentstring+"%");
      }
   }

}


void OnDeinit(const int reason)
{
   if(istesting)
      return;
   if(reason!=REASON_CHARTCHANGE)
      ObjectsDeleteAll(0,appnamespace,ChartWindowFind());
   EventKillTimer();

   int offsetwrite=0;
   if(offset>0)
      offsetwrite=(int)offsettime;
   GlobalVariableSet(appnamespace+IntegerToString(ChartID())+"_offset",offsetwrite);

   GlobalVariableSet(appnamespace+IntegerToString(ChartID())+"_mode",modecurrent);

   GlobalVariableSet(appnamespace+IntegerToString(ChartID())+"_basecurrency",basecurrency+1);

   string varname=appnamespace+IntegerToString(ChartID())+"_showbasket";
   if(showbasket)
      GlobalVariableSet(varname,0);
   else
      GlobalVariableDel(varname);
}


int GetZeroBar()
{
   int bar=ZeroPoint;
   if(ZeroPointType!=ByBar)
   {
      datetime Arr[];
      if(CopyTime(Symbol(),Period(),offset,BarsCalculate,Arr)==BarsCalculate)
      {
         for(int i=BarsCalculate-2; i>=0; i--)
         {
            MqlDateTime dt;
            MqlDateTime dtp;
            TimeToStruct(Arr[i],dt);
            TimeToStruct(Arr[i+1],dtp);
            bar=BarsCalculate-1-i;
            if(ZeroPointType==Minutes3 && Period()<=PERIOD_M3 && (MathFloor(dt.min/3)*3)!=(MathFloor(dtp.min/3)*3))
               break;
            if(ZeroPointType==Minutes5 && Period()<=PERIOD_M5 && (MathFloor(dt.min/5)*5)!=(MathFloor(dtp.min/5)*5))
               break;
            if(ZeroPointType==Minutes15 && Period()<=PERIOD_M15 && (MathFloor(dt.min/15)*15)!=(MathFloor(dtp.min/15)*15))
               break;
            if(ZeroPointType==Minutes30 && Period()<=PERIOD_M30 && (MathFloor(dt.min/30)*30)!=(MathFloor(dtp.min/30)*30))
               break;
            if(ZeroPointType==Hour && Period()<=PERIOD_H1 && dt.hour!=dtp.hour)
               break;
            if(ZeroPointType==Hours4 && Period()<=PERIOD_H4 && (MathFloor(dt.hour/4)*4)!=(MathFloor(dtp.hour/4)*4))
               break;
            if(ZeroPointType==Day && Period()<=PERIOD_D1 && dt.day!=dtp.day)
               break;
            if(ZeroPointType==Week && Period()<=PERIOD_W1 && (dt.day_of_week==6||dt.day_of_week==5))
               break;
         }
      }
   }
   return bar;
}


void CheckUpDown(string currency, TypeUpdown& ud, double& arr[], int range)
{
   double diff=arr[0+offset]-arr[range+offset];
   if(diff>ud.maxup)
   {
      ud.maxup=diff;
      ud.up=currency;
      ud.isupreversal=arr[0+offset]-arr[1+offset]>0&&arr[0+offset]-arr[1+offset]>arr[1+offset]-arr[2+offset];
   }
   if(diff<ud.maxdn)
   {
      ud.maxdn=diff;
      ud.dn=currency;
      ud.isdnreversal=arr[0+offset]-arr[1+offset]<0&&arr[0+offset]-arr[1+offset]<arr[1+offset]-arr[2+offset];
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
   color c=Color_SellText;
   string pair=CS.Pairs.NormalizePairing(ud.up+ud.dn);
   bool up=false;
   if(StringFind(pair,ud.up)==0)
   {
      c=Color_BuyText;
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
   color _color=Color_SellText;
   if(buy)
      _color=Color_BuyText;
   int xdistance=((col-1)*62)+6;
   int ydistance=((row-1)*16)+20;
   string oname = appnamespace+"-SymbolButton-TradeSet-"+IntegerToString(col)+"-"+IntegerToString(row);
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,xdistance);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,ydistance);
   ObjectSetString(0,oname,OBJPROP_TEXT,text);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,_color);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,oname,OBJPROP_ZORDER,1000);
}


void ShowValue(int col, int row)
{
   int idx=CS.Currencies.GetValueIndex(row);
   double value=CS.Currencies.LastValues[idx][0];
   color _color=Color_StandardText;
   if(idx>5)
      _color=Color_BuyValue;
   if(idx<2)
      _color=Color_SellValue;
   //_color=DimGray;
   string text=DoubleToString(value*100000,0);
   //text="|||||||||";
   int xdistance=(col-1)*62+35;
   int ydistance=(row-1)*16+4;
   string oname = appnamespace+"-Value-"+IntegerToString(col)+"-"+IntegerToString(row);
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
   string oname = appnamespace+"-SymbolButton-"+IntegerToString(col)+"-"+IntegerToString(row);
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,xdistance);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,ydistance);
   ObjectSetString(0,oname,OBJPROP_TEXT,text);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,_color);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,oname,OBJPROP_ZORDER,1000);
}


void AddFunctionButton(int x, int y, string text)
{
   string oname = appnamespace+"-FunctionButton-"+IntegerToString(x)+"-"+IntegerToString(y);
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,y);
   //ObjectSetString(0,oname,OBJPROP_FONT,"Segoe UI Symbol");
   ObjectSetString(0,oname,OBJPROP_TEXT,text);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,Color_StandardText);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,oname,OBJPROP_ZORDER,1000);
}


void OnTimer()
{
   if((GetMicrosecondCount()-LastMicrosecondCount<1000000 && !NewBarBase && modecurrent==modelast) || incalculation || !timerenabled)
      return;
   LastMicrosecondCount=GetMicrosecondCount();

   if(istesting)
   {
      datetime curtime=TimeCurrent();
      if(curtime-lasttestevent < 2)
         return;
      lasttestevent=curtime;
   }
   
   if(offset>0)
   {
      datetime Arr[],currentbartime;
      if(CopyTime(Symbol(),Period(),0,1,Arr)==1)
      {
         currentbartime=Arr[0];
         if(currentbartime!=offsettimeref)
            offset=BarIndexByTime(offsettime);
      }
      else
         return;
   }
   
   incalculation=true;

   if(modecurrent!=modelast||(NewBarBase&&ZeroPointType!=ByBar))
      InitCS();
   
   if(CS_CalculateIndex(CS,offset,basecurrency,showbasket))
   {
      WriteComment(" ");
      
      if(offset>0)
         timerenabled=false;

      int strongcount=20;
      if(BarsCalculate<strongcount-1)
         strongcount=BarsCalculate-1;
      for(int i=1; i<=strongcount; i++)
         StrongestMove(i);

      if(show_values)
         for(int j=1; j<=8; j++)
            ShowValue(1,j);

      for(int t=0; t<4; t++)
         ShowTradeSet(1,t+1,CS.Currencies.Trade[t].name,CS.Currencies.Trade[t].buy);

      lastoffset=offset;

      NewBarBase=false;
      
      //double sum=0;
      //for(int z=0; z<8; z++)
      //   sum+=CS.Currencies.Currency[z].index[BarsCalculate-3].laging.high;
      //Print(sum);

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
      if(sameticktimecount>=30000)
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
   SetTickTime();

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
         USDplot[0]=USDplot[1];
         EURplot[0]=EURplot[1];
         GBPplot[0]=GBPplot[1];
         CHFplot[0]=CHFplot[1];
         JPYplot[0]=JPYplot[1];
         CADplot[0]=CADplot[1];
         AUDplot[0]=AUDplot[1];
         NZDplot[0]=NZDplot[1];
         if(offset==0)
            ClearUnusedBuffers();
      }
      NewBarBase=true;
   }
   if(offset==0||prev_calculated==0)
      timerenabled=true;
   if(istesting)
      OnTimer();
   return(rates_total);
}


void SetTickTime()
{
#ifdef __MQL5__
   currentticktime=TimeTradeServer();
#endif
#ifdef __MQL4__
   currentticktime=TimeCurrent();
#endif
}


void ClearUnusedBuffers()
{
   for(int i=0; i<=(BarsCalculate+lastoffset); i++)
   {
      if(i<offset||i>=BarsCalculate+offset)
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
            string on=appnamespace+"TempScreenShot";
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

   string oname1 = appnamespace+"-TradesWon";
   string oname2 = appnamespace+"-TradesTotal";
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
   string oname = appnamespace+"-Currency-"+name;
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,6);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,y_pos);
   ObjectSetString(0,oname,OBJPROP_TEXT,name);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,_color);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,oname,OBJPROP_ZORDER,1000);
   y_pos+=16;
   return(0);
}


int WriteComment(string text)
{
   string name=appnamespace+"-f_comment";
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


static bool ctrl_pressed = false;
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_KEYDOWN)
   {
      if(lparam == 17)
         ctrl_pressed = !ctrl_pressed;
   }
   if(id==CHARTEVENT_MOUSE_MOVE)
   {
      int currentoffset=offset;

      if(sparam=="24")
         CrossHair=true;
      if(CrossHair&&sparam=="9")
         CrossHair=false;
      if(CrossHair&&sparam=="1")
      {
         CrossHair=false;
         offset=0;

         long chartid=ChartFirst();
         while(chartid>-1)
         {
            if(chartid!=ChartID())
            {
               ObjectSetInteger(chartid,"CurrencyStrengthMouseMove",OBJPROP_TIME,TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*240));
               ObjectSetDouble(chartid,"CurrencyStrengthMouseMovePrice",OBJPROP_PRICE,0);
               ChartRedraw(chartid);
            }
            chartid=ChartNext(chartid);
         }
      }

      if(CrossHair)
      {
         int x=(int)lparam;
         int y=(int)dparam;
         datetime dt=0;
         double price=0;
         int window=0;
         if(ChartXYToTimePrice(0,x,y,window,dt,price))
         {
            //PrintFormat("Window=%d X=%d  Y=%d  =>  Time=%s  Price=%G SParam=%s",window,x,y,TimeToString(dt),price,sparam);
            offset=BarIndexByTime(dt-(PeriodSeconds()/2));
            
            long chartid=ChartFirst();
            while(chartid>-1)
            {
               if(chartid!=ChartID())
               {
                  ObjectSetInteger(chartid,"CurrencyStrengthMouseMove",OBJPROP_TIME,dt);
                  ObjectSetDouble(chartid,"CurrencyStrengthMouseMovePrice",OBJPROP_PRICE,price);
                  ChartRedraw(chartid);
               }
               chartid=ChartNext(chartid);
            }
         }
      }
      
      if(offset!=currentoffset)
      {
         SetTickTime();
         NewBarBase=true;
         ClearUnusedBuffers();
         timerenabled=true;
      }
   }
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(sparam,"-FunctionButton")>-1)
      {
         string objtext=ObjectGetString(0,sparam,OBJPROP_TEXT);

         if(StringFind(objtext,"RAW")>-1)
            modecurrent=RAW;
         if(StringFind(objtext,"SMA")>-1)
            modecurrent=SMA;
         if(StringFind(objtext,"OSCILLATOR")>-1)
            modecurrent=OSCILLATOR;

         SetTickTime();
         timerenabled=true;
      }
      if(StringFind(sparam,"-SymbolButton")>-1)
      {
         SwitchSymbol(ObjectGetString(0,sparam,OBJPROP_TEXT));
      }
      if(StringFind(sparam,"-Currency")>-1 && !CS.currentpairsonly)
      {
         string z=ObjectGetString(0,sparam,OBJPROP_TEXT);
         z=StringSubstr(z,StringLen(z)-3);

         if(currencyclicked==NULL)
         {
            currencyclicked=z;
         }
         else
         {
            if(currencyclicked==z)
            {
               if(z=="USD")
                  SwitchBaseCurrency(0);
               if(z=="EUR")
                  SwitchBaseCurrency(1);
               if(z=="GBP")
                  SwitchBaseCurrency(2);
               if(z=="JPY")
                  SwitchBaseCurrency(3);
               if(z=="CHF")
                  SwitchBaseCurrency(4);
               if(z=="CAD")
                  SwitchBaseCurrency(5);
               if(z=="AUD")
                  SwitchBaseCurrency(6);
               if(z=="NZD")
                  SwitchBaseCurrency(7);

               CS.recalculate=true;
               SetTickTime();
               timerenabled=true;
            }
            else
            {
               SwitchSymbol(CS.Pairs.NormalizePairing(z+currencyclicked));
            }
            currencyclicked=NULL;
         }
      }
   }
}


void SwitchBaseCurrency(int base)
{
   if(basecurrency==-1)
      basecurrency=base;
   else
      basecurrency=-1;
   
   showbasket=ctrl_pressed;
}


int BarIndexByTime(datetime start)
{
   int ret=0;
   datetime Arr[],end;
   if(CopyTime(Symbol(),Period(),0,1,Arr)==1)
   {
      end=Arr[0];
      offsettime=start;
      offsettimeref=end;
      return Bars(Symbol(),Period(),start,end)-1;
      
      //if(CopyTime(Symbol(),Period(),start,end,Arr)>0)
      //{
         //ret=ArraySize(Arr)-1;
         //int CursorBarIndex2=Bars(Symbol(),Period(),dt,time1)-1;
         //Print(CursorBarIndex2);
         //PrintFormat("BarTime=%s",TimeToString(Arr[0]));
         //PrintFormat("Window=%d X=%d  Y=%d  =>  Time=%s  Price=%G Barindex=%i SParam=%s",window,x,y,TimeToString(dt),price,CursorBarIndex,sparam);
      //}
   }
   return ret;
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
      AddSymbolButton(2, 1, currentsymbol,Color_StandardText);
   }
}
