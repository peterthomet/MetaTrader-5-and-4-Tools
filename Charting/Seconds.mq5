//
// Seconds.mq5
// getYourNet.ch
//

#property copyright "Copyright 2023, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_label1  "Up Candle, Down Candle"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  MediumSeaGreen,C'44,44,44'

enum Intervals
{
   S1, // 1 Second
   S2, // 2 Seconds
   S3, // 3 Seconds
   S4, // 4 Seconds
   S5, // 5 Seconds
   S10, // 10 Seconds
   S15, // 15 Seconds
   S20, // 20 Seconds
   S30 // 30 Seconds
};
input Intervals Seconds=S15;
input int MaxBars=200; // Maximum Bars

double canc[],cano[],canh[],canl[],colors[],seconds[][4];
#define sopen 0
#define sclose 1
#define shigh 2
#define slow 3
bool updating, init, historyloaded;
datetime lasttime, time0, lasttime0, lasthistoryload;
int intervalseconds[9]={1,2,3,4,5,10,15,20,30};
string appnamespace="SecondsChartIndicator";


void OnInit()
{
   updating=false;
   init=true;
   historyloaded=false;
   lasttime=0;
   time0=0;
   lasttime0=0;
   lasthistoryload=0;
   SetIndexBuffer(0,cano,INDICATOR_DATA);
   SetIndexBuffer(1,canh,INDICATOR_DATA);
   SetIndexBuffer(2,canl,INDICATOR_DATA);
   SetIndexBuffer(3,canc,INDICATOR_DATA);
   SetIndexBuffer(4,colors,INDICATOR_COLOR_INDEX);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   //PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
   IndicatorSetString(INDICATOR_SHORTNAME,(string)intervalseconds[Seconds]+" Seconds Chart");
   EventSetMillisecondTimer(1);
}


void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,appnamespace,ChartWindowFind());
   EventKillTimer();
}


void OnTimer()
{
   if(updating)
      return;
   updating=true;

   MqlDateTime dt;
   TimeCurrent(dt);
   datetime dti=TimeCurrent();
   double c=(double)dt.sec/(double)intervalseconds[Seconds];
   int maxbars=MaxBars;

   if(!historyloaded && (lasthistoryload+3)<TimeCurrent())
   {
      MqlTick ticks[];
      int received=CopyTicks(Symbol(),ticks,COPY_TICKS_INFO,((TimeCurrent()-3600)*1000),100000);
      Print(Symbol()+" Ticks loaded: "+received);
      
      if(received>0)
      {
         Print("First Tick Time: "+ticks[0].time);
         Print("Last Tick Time: "+ticks[received-1].time);
         
         MqlDateTime dttick;
         double ctick;
         datetime ticktimelast;
         int rt=ArraySize(canh);
         
         for(int i=received-1; i>=0; i--)
         {
            if(i==(received-1))
               ticktimelast=ticks[i].time;
            TimeToStruct(ticks[i].time,dttick);
            ctick=(double)dttick.sec/(double)intervalseconds[Seconds];

            if(MathFloor(ctick)==MathCeil(ctick))
            {
               //Print(dtt.sec);
               //break;
            }
            ticktimelast=ticks[i].time;
         }
         historyloaded=true;
      }
      lasthistoryload=TimeCurrent();
   }

   if(time0!=lasttime0)
   {
      int rt=ArraySize(canh);
      canh[rt-(maxbars+1)]=0;
      canl[rt-(maxbars+1)]=0;
      cano[rt-(maxbars+1)]=0;
      canc[rt-(maxbars+1)]=0;
      colors[rt-(maxbars+1)]=0;
      lasttime0=time0;
   }

   if(MathFloor(c)==MathCeil(c) && dti!=lasttime)
   {
      if(time0+PeriodSeconds()-dti!=0)
      {
         int rt=ArraySize(canh);
         for(int i=rt-maxbars; i<rt-1; i++)
         {
            canh[i]=canh[i+1];
            canl[i]=canl[i+1];
            cano[i]=cano[i+1];
            canc[i]=canc[i+1];
            colors[i]=colors[i+1];
         }
         canh[rt-1]=canc[rt-2];
         canl[rt-1]=canc[rt-2];
         cano[rt-1]=canc[rt-2];
         canc[rt-1]=canc[rt-2];
         colors[rt-1]=0;
      }
      lasttime=dti;
   }
   updating=false;
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
   int i=rates_total-1;
   if(canh[i]==0)
   {
      canh[i]=close[i];
      canl[i]=close[i];
      cano[i]=close[i];
      canc[i]=close[i];
      colors[i]=0;
   }
   canh[i]=MathMax(canh[i],close[i]);
   canl[i]=MathMin(canl[i],close[i]);
   canc[i]=close[i];
   colors[i]=cano[i]>canc[i] ? 1 : 0;
   time0=time[i];

   ObjectCreate(0,appnamespace+"-ASKLINE",OBJ_HLINE,ChartWindowFind(),0,SymbolInfoDouble(Symbol(),SYMBOL_ASK));
   ObjectSetInteger(0,appnamespace+"-ASKLINE",OBJPROP_COLOR,ChartGetInteger(0,CHART_COLOR_ASK));

   ObjectCreate(0,appnamespace+"-BIDLINE",OBJ_HLINE,ChartWindowFind(),0,SymbolInfoDouble(Symbol(),SYMBOL_BID));
   ObjectSetInteger(0,appnamespace+"-BIDLINE",OBJPROP_COLOR,ChartGetInteger(0,CHART_COLOR_BID));

   if(init)
   {
      lasttime0=time0;
      init=false;
   }
   return(rates_total);
}

