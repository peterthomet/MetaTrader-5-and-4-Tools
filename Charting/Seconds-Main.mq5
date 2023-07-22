//
// Seconds-Main.mq5
// getYourNet.ch
//

#property copyright "Copyright 2023, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrNONE, clrNONE

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

double canc[],cano[],canh[],canl[],colors[];
#define sopen 0
#define sclose 1
#define shigh 2
#define slow 3
bool updating, init, historyloaded;
int historyloadcount;
bool visible;
bool CrossHair;
int c_CHART_COLOR_CANDLE_BULL,c_CHART_COLOR_CANDLE_BEAR,c_CHART_COLOR_CHART_UP,c_CHART_COLOR_CHART_DOWN,c_CHART_COLOR_CHART_LINE,scalefixsave;
double d_CHART_FIXED_MAX,d_CHART_FIXED_MIN,maxprice,minprice,maxsave,minsave;
datetime lasttime, time0, lasttime0, lasthistoryload;
int intervalseconds[9]={1,2,3,4,5,10,15,20,30};
string appnamespace="SecondsChartIndicator";


void OnInit()
{
   updating=false;
   init=true;
   historyloaded=false;
   historyloadcount=0;
   visible=false;
   CrossHair=false;
   d_CHART_FIXED_MAX=0;
   d_CHART_FIXED_MIN=0;
   maxprice=DBL_MIN;
   minprice=DBL_MAX;
   maxsave=0;
   minsave=0;
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
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
   if(PlotIndexGetInteger(0,PLOT_LINE_COLOR,0)==clrNONE)
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,(int)ChartGetInteger(0,CHART_COLOR_CANDLE_BULL));
   if(PlotIndexGetInteger(0,PLOT_LINE_COLOR,1)==clrNONE)
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,(int)ChartGetInteger(0,CHART_COLOR_CANDLE_BEAR));
   IndicatorSetString(INDICATOR_SHORTNAME,(string)intervalseconds[Seconds]+" Seconds Chart");

   if(GlobalVariableCheck(appnamespace+Symbol()+"d_CHART_FIXED_MAX"))
      d_CHART_FIXED_MAX=GlobalVariableGet(appnamespace+Symbol()+"d_CHART_FIXED_MAX");
   if(GlobalVariableCheck(appnamespace+Symbol()+"d_CHART_FIXED_MIN"))
      d_CHART_FIXED_MIN=GlobalVariableGet(appnamespace+Symbol()+"d_CHART_FIXED_MIN");

   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);

   EventSetMillisecondTimer(1);
}


void OnDeinit(const int reason)
{
   if(visible)
      Disable();

   GlobalVariableTemp(appnamespace+Symbol()+"d_CHART_FIXED_MAX");
   GlobalVariableSet(appnamespace+Symbol()+"d_CHART_FIXED_MAX",d_CHART_FIXED_MAX);
   GlobalVariableTemp(appnamespace+Symbol()+"d_CHART_FIXED_MIN");
   GlobalVariableSet(appnamespace+Symbol()+"d_CHART_FIXED_MIN",d_CHART_FIXED_MIN);

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
      int received=CopyTicksRange(Symbol(),ticks,COPY_TICKS_INFO,((TimeTradeServer()-3600)*1000),0);
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
            maxprice=MathMax(maxprice,canh[i]);
            minprice=MathMin(minprice,canl[i]);
         }
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
   }

   if(init)
   {
      lasttime0=time0;
      init=false;
      _Print("INIT COMPLETED "+(string)TimeTradeServer());
   }

   return(rates_total);
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_MOUSE_MOVE)
   {
      if(sparam=="16")
         CrossHair=true;
      if(CrossHair&&sparam=="1")
      {
         // Reset
         CrossHair=false;
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
            PrintFormat("Window=%d X=%d  Y=%d  =>  Time=%s  Price=%G SParam=%s",window,x,y,TimeToString(dt),price,sparam);
         }
      }
   }
   
   if(id==CHARTEVENT_CHART_CHANGE)
   {

   }

   if(id==CHARTEVENT_KEYDOWN)
   {
      if(lparam == 90) // Key Z
      {
         if(!visible)
            Enable();
         else
            Disable();
         visible=!visible;
      }
   }
}


void Enable()
{
   c_CHART_COLOR_CANDLE_BULL=(int)ChartGetInteger(0,CHART_COLOR_CANDLE_BULL);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrNONE);
   c_CHART_COLOR_CANDLE_BEAR=(int)ChartGetInteger(0,CHART_COLOR_CANDLE_BEAR);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrNONE);
   c_CHART_COLOR_CHART_UP=(int)ChartGetInteger(0,CHART_COLOR_CHART_UP);
   ChartSetInteger(0,CHART_COLOR_CHART_UP,clrNONE);
   c_CHART_COLOR_CHART_DOWN=(int)ChartGetInteger(0,CHART_COLOR_CHART_DOWN);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,clrNONE);
   c_CHART_COLOR_CHART_LINE=(int)ChartGetInteger(0,CHART_COLOR_CHART_LINE);
   ChartSetInteger(0,CHART_COLOR_CHART_LINE,clrNONE);

   maxsave=ChartGetDouble(0,CHART_FIXED_MAX);
   minsave=ChartGetDouble(0,CHART_FIXED_MIN);
   scalefixsave=(int)ChartGetInteger(0,CHART_SCALEFIX);

   ChartSetInteger(0,CHART_SCALEFIX,true);
   if(d_CHART_FIXED_MAX==0)
   {
      d_CHART_FIXED_MAX=maxprice+((maxprice-minprice)/3);
      d_CHART_FIXED_MIN=minprice-((maxprice-minprice)/3);
   }
   double price=canc[ArraySize(canc)-1];
   double centeroffset=price-(d_CHART_FIXED_MAX-((d_CHART_FIXED_MAX-d_CHART_FIXED_MIN)/2));
   if(MathAbs(centeroffset)<(d_CHART_FIXED_MAX-d_CHART_FIXED_MIN)/2)
      centeroffset=0;
   d_CHART_FIXED_MAX+=centeroffset;
   d_CHART_FIXED_MIN+=centeroffset;
   ChartSetDouble(0,CHART_FIXED_MAX,d_CHART_FIXED_MAX);
   ChartSetDouble(0,CHART_FIXED_MIN,d_CHART_FIXED_MIN);

   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES);
}


void Disable()
{
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);

   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,c_CHART_COLOR_CANDLE_BULL);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,c_CHART_COLOR_CANDLE_BEAR);
   ChartSetInteger(0,CHART_COLOR_CHART_UP,c_CHART_COLOR_CHART_UP);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,c_CHART_COLOR_CHART_DOWN);
   ChartSetInteger(0,CHART_COLOR_CHART_LINE,c_CHART_COLOR_CHART_LINE);
   
   d_CHART_FIXED_MAX=ChartGetDouble(0,CHART_FIXED_MAX);
   d_CHART_FIXED_MIN=ChartGetDouble(0,CHART_FIXED_MIN);

   ChartSetInteger(0,CHART_SCALEFIX,scalefixsave);
   ChartSetDouble(0,CHART_FIXED_MAX,maxsave);
   ChartSetDouble(0,CHART_FIXED_MIN,minsave);
}


void _Print(string text)
{
   return;
   Print(text);
}