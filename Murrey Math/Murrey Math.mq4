//
// Murrey Math.mq4/mq5
// getYourNet.ch
//

#property copyright "Copyright 2018, getYourNet.ch"
#property strict
#property indicator_chart_window
#property indicator_plots 0

#include <Murrey Math.mqh>

input string NameSpace="Murrey Math 1";
input ENUM_TIMEFRAMES TimeFrame=PERIOD_CURRENT;
input int ObserveCandles=64;
input int CandlesBack=1;
input color ColorMinus28=Black;
input color ColorMinus18=Black;
input color Color08=DeepSkyBlue;
input color Color18=Orange;
input color Color28=Red;
input color Color38=Green;
input color Color48=Blue;
input color Color58=Green;
input color Color68=Red;
input color Color78=Orange;
input color Color88=DeepSkyBlue;
input color ColorPlus18=Black;
input color ColorPlus28=Black;
input int WidthMinus28=2;
input int WidthMinus18=1;
input int Width08=1;
input int Width18=1;
input int Width28=1;
input int Width38=1;
input int Width48=1;
input int Width58=1;
input int Width68=1;
input int Width78=1;
input int Width88=1;
input int WidthPlus18=1;
input int WidthPlus28=2;
input int TextShift=20;
input bool DisableText=false;
input bool DebugMode=false;

bool newbar=false;
long firstbar=0;
long lastfirstbar=-1;
bool istesting;

TypeMurreyMath MM;


int OnInit()
{
   MM.appnamespace=NameSpace;
   MM.timeframe=TimeFrame;
   MM.candles=ObserveCandles;
   MM.startcandle=CandlesBack;
   MM.textshift=TextShift;
   MM.debug=DebugMode;
   
   MM.Clolors[0]=ColorMinus28;
   MM.Clolors[1]=ColorMinus18;
   MM.Clolors[2]=Color08;
   MM.Clolors[3]=Color18;
   MM.Clolors[4]=Color28;
   MM.Clolors[5]=Color38;
   MM.Clolors[6]=Color48;
   MM.Clolors[7]=Color58;
   MM.Clolors[8]=Color68;
   MM.Clolors[9]=Color78;
   MM.Clolors[10]=Color88;
   MM.Clolors[11]=ColorPlus18;
   MM.Clolors[12]=ColorPlus28;

   MM.Widths[0]=WidthMinus28;
   MM.Widths[1]=WidthMinus18;
   MM.Widths[2]=Width08;
   MM.Widths[3]=Width18;
   MM.Widths[4]=Width28;
   MM.Widths[5]=Width38;
   MM.Widths[6]=Width48;
   MM.Widths[7]=Width58;
   MM.Widths[8]=Width68;
   MM.Widths[9]=Width78;
   MM.Widths[10]=Width88;
   MM.Widths[11]=WidthPlus18;
   MM.Widths[12]=WidthPlus28;
   
   istesting=MQLInfoInteger(MQL_TESTER);
   EventSetTimer(1);

   return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason)
{
   EventKillTimer();
   MM.Cleanup();
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
   if(rates_total>prev_calculated)
   {
      newbar=true;
      if(istesting)
         OnTimer();
   }
   return(rates_total);
}


void OnTimer()
{
   if(newbar||lastfirstbar!=firstbar)
   {
      datetime arr1[1];
      if(CopyTime(_Symbol,_Period,(int)firstbar,1,arr1)<1)
         return;

      int candlestart=CandlesBack;
      if(firstbar>0)
      {
         datetime firstbartime=iTime(NULL,0,(int)firstbar);
         int indexbytime=iBarShift(NULL,MM.timeframe,firstbartime)+1;
         candlestart=MathMax(CandlesBack,indexbytime);
      }

      MM.startcandle=candlestart;
      MM.Calculate();
      MM.Draw(DisableText);
         
      lastfirstbar=firstbar;
      newbar=false;
   }
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      long firstvisible=ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR);
      long visiblebars=ChartGetInteger(0,CHART_VISIBLE_BARS);
      long widthinbars=ChartGetInteger(0,CHART_WIDTH_IN_BARS);
      if(firstvisible>(widthinbars-TextShift))
         firstbar=firstvisible-(widthinbars-TextShift);
      else
         firstbar=0;
   }
}

