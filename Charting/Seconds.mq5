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
input bool ShowBid=true; // Show Bid Line
input bool ShowAsk=true; // Show Ask Line

double canc[],cano[],canh[],canl[],colors[];
#define sopen 0
#define sclose 1
#define shigh 2
#define slow 3
bool updating, init, historyloaded;
int historyloadcount;
datetime lasttime, time0, lasttime0, lasthistoryload;
int intervalseconds[9]={1,2,3,4,5,10,15,20,30};
string appnamespace="SecondsChartIndicator";


void OnInit()
{
   updating=false;
   init=true;
   historyloaded=false;
   historyloadcount=0;
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
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
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
   if(updating||init)
      return;
   updating=true;

   MqlDateTime dt;
   TimeTradeServer(dt);
   datetime dti=TimeTradeServer();
   double c=(double)dt.sec/(double)intervalseconds[Seconds];
   int maxbars=MaxBars;

   if(!historyloaded && (lasthistoryload+1)<TimeTradeServer())
   {
      MqlTick ticks[];
      int received=CopyTicks(Symbol(),ticks,COPY_TICKS_INFO,((TimeTradeServer()-3600)*1000),100000);
      historyloadcount++;
      _Print(Symbol()+" Ticks loaded: "+(string)received);
      
      if(received>0&&historyloadcount>1)
      {
         _Print("First Tick Time: "+(string)ticks[0].time);
         _Print("Last Tick Time: "+(string)ticks[received-1].time);
         
         int rt=ArraySize(canh);
         int x=received-1;
         datetime barstarttime=dti-(int)((c-MathFloor(c))*intervalseconds[Seconds]);
         
         for(int i=rt-1; i>=rt-maxbars; i--)
         {
            canh[i]=ticks[x].bid;
            canl[i]=ticks[x].bid;
            cano[i]=ticks[x].bid;
            canc[i]=ticks[x].bid;
            colors[i]=0;
            
            while(barstarttime<=ticks[x].time && x>0)
            {
               x--;
               canh[i]=MathMax(canh[i],ticks[x].bid);
               canl[i]=MathMin(canl[i],ticks[x].bid);
               cano[i]=ticks[x].bid;
               colors[i]=cano[i]>canc[i] ? 1 : 0;
            }
            barstarttime-=intervalseconds[Seconds];
         }
         DrawPriceLines();
         historyloaded=true;
      }
      lasthistoryload=TimeTradeServer();
   }

   if(historyloaded)
   {
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
         int diff=(int)(time0+PeriodSeconds()-dti);
         if(diff!=0 && diff!=PeriodSeconds())
         {
            _Print("SHIFT INTERNAL Current: "+(string)TimeCurrent()+" Trade Server: "+(string)TimeTradeServer()+" Value: "+(string)diff);
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
   }
   
   ChartRedraw();
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
   time0=time[i];

   if(!init && historyloaded)
   {
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

      if(prev_calculated==(rates_total-1))
         _Print("SHIFT CHART AUTO Current: "+(string)TimeCurrent()+" Trade Server: "+(string)TimeTradeServer()+" Candle: "+(string)time[i]);
      
      DrawPriceLines();
   }

   if(init)
   {
      lasttime0=time0;
      init=false;
      _Print("INIT COMPLETED "+(string)TimeTradeServer());
   }

   return(rates_total);
}


void DrawPriceLines()
{
   if(ShowAsk)
   {
      ObjectCreate(0,appnamespace+"-ASKLINE",OBJ_HLINE,ChartWindowFind(),0,SymbolInfoDouble(Symbol(),SYMBOL_ASK));
      ObjectSetInteger(0,appnamespace+"-ASKLINE",OBJPROP_COLOR,ChartGetInteger(0,CHART_COLOR_ASK));
   }

   if(ShowBid)
   {
      ObjectCreate(0,appnamespace+"-BIDLINE",OBJ_HLINE,ChartWindowFind(),0,SymbolInfoDouble(Symbol(),SYMBOL_BID));
      ObjectSetInteger(0,appnamespace+"-BIDLINE",OBJPROP_COLOR,ChartGetInteger(0,CHART_COLOR_BID));
   }
}


void _Print(string text)
{
   return;
   Print(text);
}