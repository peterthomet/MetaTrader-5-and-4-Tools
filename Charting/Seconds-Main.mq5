//
// Seconds-Main.mq5
// getYourNet.ch
//

#property copyright "Copyright 2023, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "2.10"
#property description "Depending on your keyboard layout, press the key ""Z"" or ""Y"" to toggle the chart."
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   3
#property indicator_label1 "Candles"
#property indicator_label2 "Ticks Bid"
#property indicator_label3 "Ticks Ask"
#property indicator_color1  clrNONE, clrNONE
#property indicator_color2  clrNONE
#property indicator_color3  clrNONE

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
input int MaxBars=500; // Maximum Bars
input string Font="Impact";
input int FontSize=12; // Font Size
input color Color=clrGray;
input color ColorSelected=clrBlack; // Color Selected
input int MarginX=10; // Left Margin
input int MarginY=10; // Bottom Margin

enum HystoryStates
{
   Unloaded,
   SynchInitialized,
   Loaded
};
double canc[],cano[],canh[],canl[],colors[];
#define sopen 0
#define sclose 1
#define shigh 2
#define slow 3
bool init, historyloaded;
int historyloadcount;
bool visible;
bool CrossHair;
int c_CHART_COLOR_CANDLE_BULL,c_CHART_COLOR_CANDLE_BEAR,c_CHART_COLOR_CHART_UP,c_CHART_COLOR_CHART_DOWN,c_CHART_COLOR_CHART_LINE,scalefixsave;
double d_CHART_FIXED_MAX,d_CHART_FIXED_MIN,maxprice,minprice,maxsave,minsave;
datetime lasttime, time0, lasttime0, lasthistoryload;
int intervalseconds[9]={1,2,3,4,5,10,15,20,30};
Intervals Seconds;
int currentSeconds;
string appnamespace="SecondsChartIndicator";

struct TypeTimes
{
   MqlDateTime ts;
   datetime ti;
   TypeTimes(datetime time)
   {
      ti=time;
      TimeToStruct(ti,ts);
   }
};


void OnInit()
{
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
   Seconds=S15;
   currentSeconds=S15;
   SetIndexBuffer(0,cano,INDICATOR_DATA);
   SetIndexBuffer(1,canh,INDICATOR_DATA);
   SetIndexBuffer(2,canl,INDICATOR_DATA);
   SetIndexBuffer(3,canc,INDICATOR_DATA);
   SetIndexBuffer(4,colors,INDICATOR_COLOR_INDEX);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetInteger(1,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetInteger(2,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
   if(PlotIndexGetInteger(0,PLOT_LINE_COLOR,0)==-1)
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,(int)ChartGetInteger(0,CHART_COLOR_CANDLE_BULL));
   if(PlotIndexGetInteger(0,PLOT_LINE_COLOR,1)==-1)
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,(int)ChartGetInteger(0,CHART_COLOR_CANDLE_BEAR));
   if(PlotIndexGetInteger(1,PLOT_LINE_COLOR,0)==-1)
      PlotIndexSetInteger(1,PLOT_LINE_COLOR,0,(int)ChartGetInteger(0,CHART_COLOR_BID));
   if(PlotIndexGetInteger(2,PLOT_LINE_COLOR,0)==-1)
      PlotIndexSetInteger(2,PLOT_LINE_COLOR,0,(int)ChartGetInteger(0,CHART_COLOR_ASK));

   IndicatorSetString(INDICATOR_SHORTNAME,"Seconds Chart");

   if(GlobalVariableCheck(appnamespace+Symbol()+"d_CHART_FIXED_MAX"))
      d_CHART_FIXED_MAX=GlobalVariableGet(appnamespace+Symbol()+"d_CHART_FIXED_MAX");
   if(GlobalVariableCheck(appnamespace+Symbol()+"d_CHART_FIXED_MIN"))
      d_CHART_FIXED_MIN=GlobalVariableGet(appnamespace+Symbol()+"d_CHART_FIXED_MIN");

   if(GlobalVariableCheck(appnamespace+IntegerToString(ChartID())+"Seconds"))
      Seconds=(Intervals)GlobalVariableGet(appnamespace+IntegerToString(ChartID())+"Seconds");

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

   GlobalVariableSet(appnamespace+IntegerToString(ChartID())+"Seconds",Seconds);

   ObjectsDeleteAll(0,appnamespace,ChartWindowFind());
   EventKillTimer();
}


void SetIndicatorView()
{
   if(Seconds==currentSeconds)
      return;

   if(visible)
   {
      if(Seconds==-1)
      {
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
         PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
         PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
      }
      else
      {
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES);
         PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
         PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
      }
   }
   currentSeconds=Seconds;
}


void LoadHistoryToSeconds(datetime starttime=0)
{
   datetime dt[];
   int count=(int)MathCeil(MaxBars/(60/intervalseconds[Seconds]));
   if(CopyTime(Symbol(),PERIOD_M1,0,count,dt)<count)
      return;
   _Print("Starttime: "+IntegerToString(dt[0]));
   
   MqlTick ticks[];
   int received=CopyTicksRange(Symbol(),ticks,COPY_TICKS_INFO,dt[0]*1000,0);
   historyloadcount++;
   _Print(Symbol()+" Ticks loaded: "+(string)received);
   
   if(received>0&&historyloadcount>1)
   {
      _Print("First Tick Time: "+(string)ticks[0].time);
      _Print("Last Tick Time: "+(string)ticks[received-1].time);
      
      int rt=ArraySize(canh);
      int x=received-1;
      TypeTimes t1(ticks[x].time);
      double c=(double)t1.ts.sec/(double)intervalseconds[Seconds];
      datetime barstarttime=t1.ti-(int)(MathRound((c-MathFloor(c))*intervalseconds[Seconds]));

      //Print(MathRound((c-MathFloor(c))*intervalseconds[Seconds]));
      //Print(barstarttime);
      
      ArrayInitialize(cano,0);
      ArrayInitialize(canh,0);
      ArrayInitialize(canl,0);
      ArrayInitialize(canc,0);
      ArrayInitialize(colors,0);

      maxprice=DBL_MIN;
      minprice=DBL_MAX;

      for(int i=rt-1; i>=rt-MaxBars; i--)
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
}


void LoadHistoryTicks(datetime starttime=0)
{
   MqlTick ticks[];
   int received=CopyTicks(Symbol(),ticks,COPY_TICKS_INFO,0,MaxBars);
   historyloadcount++;
   _Print(Symbol()+" Ticks loaded: "+(string)received);
   
   if(received>0&&historyloadcount>1)
   {
      _Print("First Tick Time: "+(string)ticks[0].time);
      _Print("Last Tick Time: "+(string)ticks[received-1].time);
      
      int rt=ArraySize(canh);
      int x=received-1;
      
      ArrayInitialize(cano,0);
      ArrayInitialize(canh,0);
      ArrayInitialize(canl,0);
      ArrayInitialize(canc,0);
      ArrayInitialize(colors,0);

      maxprice=DBL_MIN;
      minprice=DBL_MAX;

      for(int i=rt-1; i>=rt-MaxBars; i--)
      {
         canh[i]=ticks[x].bid;
         canl[i]=ticks[x].ask;
         x--;

         maxprice=MathMax(maxprice,canh[i]);
         minprice=MathMin(minprice,canh[i]);
      }
      historyloaded=true;
   }
}


void OnTimer()
{
   if(init || TimeTradeServer()<time0)
      return;

   if(!historyloaded && lasthistoryload<TimeTradeServer())
   {
      SetIndicatorView();
      if(Seconds>-1)
         LoadHistoryToSeconds();
      else
         LoadHistoryTicks();
      lasthistoryload=TimeTradeServer();
   }

   if(Seconds==-1)
      return;

   TypeTimes t1(TimeTradeServer());
   double c=(double)t1.ts.sec/(double)intervalseconds[Seconds];
   int maxbars=MaxBars;

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
   
      if(MathFloor(c)==MathCeil(c) && t1.ti!=lasttime)
      {
         int diff=(int)(time0+PeriodSeconds()-t1.ti);
         if(diff!=0 && diff!=PeriodSeconds())
         {
            //_Print("SHIFT INTERNAL Current: "+(string)TimeCurrent()+" Trade Server: "+(string)TimeTradeServer()+" Value: "+(string)diff);
            ShiftBuffers();
            ChartRedraw();
         }
         lasttime=t1.ti;
      }
   }
}


void ShiftBuffers()
{
   int rt=ArraySize(cano);
   for(int i=rt-MaxBars; i<rt-1; i++)
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


void ShiftBuffersTicks()
{
   int rt=ArraySize(canh);
   for(int i=rt-MaxBars; i<rt-1; i++)
   {
      canh[i]=canh[i+1];
      canl[i]=canl[i+1];
   }
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
      if(Seconds>-1)
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
      }
      else
      {
         ShiftBuffersTicks();
         canh[i]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         canl[i]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      }
      
      if(close[i]==0)
         Print("Invalid Data, Close is 0");

      double delta=MathAbs((close[i]-close[i-1])/(close[i-1]/100));
      if(delta>=2)
         Print("Invalid Data, Delta:"+DoubleToString(delta)+" Current/Last Close:"+DoubleToString(close[i])+"/"+DoubleToString(close[i-1]));

      //if(prev_calculated==(rates_total-1))
      //   _Print("SHIFT CHART AUTO Current: "+(string)TimeCurrent()+" Trade Server: "+(string)TimeTradeServer()+" Candle: "+(string)time[i]);
   }

   if(init)
   {
      lasttime0=time0;
      init=false;
      _Print("INIT COMPLETED / Trade-Server:"+(string)TimeTradeServer()+" Time0:"+(string)time0+" RATES-TOTAL:"+IntegerToString(rates_total)+" PREV-CALCULATED:"+IntegerToString(prev_calculated));
   }

   return(rates_total);
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_MOUSE_MOVE)
   {
      return;
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

   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      //Print("CHARTEVENT_OBJECT_CLICK "+sparam);

      int f1=StringFind(sparam,"SCButton");
      if(f1>-1)
      {
         Seconds=(Intervals)StringToInteger(StringSubstr(sparam,f1+8));
         historyloaded=false;
         DeleteButtons();
         CreateButtons();
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
   if(Seconds==-1)
      price=canh[ArraySize(canh)-1];
   double centeroffset=price-(d_CHART_FIXED_MAX-((d_CHART_FIXED_MAX-d_CHART_FIXED_MIN)/2));
   if(MathAbs(centeroffset)<(d_CHART_FIXED_MAX-d_CHART_FIXED_MIN)/2)
      centeroffset=0;
   d_CHART_FIXED_MAX+=centeroffset;
   d_CHART_FIXED_MIN+=centeroffset;
   ChartSetDouble(0,CHART_FIXED_MAX,d_CHART_FIXED_MAX);
   ChartSetDouble(0,CHART_FIXED_MIN,d_CHART_FIXED_MIN);

   if(Seconds==-1)
   {
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
   }
   else
   {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES);
   }
   
   CreateButtons();
}


void Disable()
{
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);

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
   
   DeleteButtons();
}


void CreateButtons()
{
   CreateButton(-1,"TI",(Seconds==-1));
   for(int i=0; i<9; i++)
      CreateButton(i,"S"+IntegerToString(intervalseconds[i]),(Seconds==i));
}


void CreateButton(int index, string text, bool selected=false)
{
   string objname=appnamespace+"SCButton"+IntegerToString(index);
   ObjectCreate(0,objname,OBJ_LABEL,0,0,0,0,0);
   ObjectSetInteger(0,objname,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,objname,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
   index++;
   int space=index*25;
   if(index>=6)
      space+=(8*(index-6));
   ObjectSetInteger(0,objname,OBJPROP_XDISTANCE,MarginX+space);
   ObjectSetInteger(0,objname,OBJPROP_YDISTANCE,MarginY);
   color c=Color;
   if(selected)
      c=ColorSelected;
   ObjectSetInteger(0,objname,OBJPROP_COLOR,c);
   ObjectSetInteger(0,objname,OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,objname,OBJPROP_FONT,Font);
   ObjectSetString(0,objname,OBJPROP_TEXT,text);
}


void DeleteButtons()
{
   ObjectsDeleteAll(0,appnamespace+"SCButton");
}


void _Print(string text)
{
   return;
   Print(text);
}