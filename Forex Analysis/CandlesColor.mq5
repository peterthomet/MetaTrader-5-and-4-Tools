//
// CandlesColor.mq5
// getYourNet.ch
//

#property copyright "Copyright 2024, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 5
#property indicator_label1 "Open;High;Low;Close"
#property indicator_plots 1
#property indicator_type1 DRAW_COLOR_CANDLES

input color ColorBarUp=clrNONE;
input color ColorBarDown=clrNONE;

double _open[],_high[],_low[],_close[];
double _color[];


int OnInit()
{
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES);

   SetIndexBuffer(0,_open,INDICATOR_DATA);
   SetIndexBuffer(1,_high,INDICATOR_DATA);
   SetIndexBuffer(2,_low,INDICATOR_DATA);
   SetIndexBuffer(3,_close,INDICATOR_DATA);

   SetIndexBuffer(4,_color,INDICATOR_COLOR_INDEX);

   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,2);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,NULL);

   PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,ColorBarUp);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,ColorBarDown);

   if(PlotIndexGetInteger(0,PLOT_LINE_COLOR,0)==-1)
   {
      int cb=(int)ChartGetInteger(0,CHART_COLOR_CANDLE_BULL);
      int red=cb%256;
      int green=((cb-(cb%256))/256)%256;
      int blue=cb>>16;
      red=MathMin(red+50,255);
      green=MathMin(green+50,255);
      blue=MathMin(blue+50,255);
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,(blue<<16)+(green<<8)+(red));
   }
   if(PlotIndexGetInteger(0,PLOT_LINE_COLOR,1)==-1)
   {
      int cb=(int)ChartGetInteger(0,CHART_COLOR_CANDLE_BEAR);
      int red=cb%256;
      int green=((cb-(cb%256))/256)%256;
      int blue=cb>>16;
      red=MathMin(red+50,255);
      green=MathMin(green+50,255);
      blue=MathMin(blue+50,255);
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,(blue<<16)+(green<<8)+(red));
   }

   return(0);
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{

   MqlDateTime t;

   for(int i=prev_calculated;i<=rates_total-1;i++)
   {
      _open[i]=NULL;
      _high[i]=NULL;
      _low[i]=NULL;
      _close[i]=NULL;

      datetime candle_time=time[i];

      TimeToStruct(time[i],t);

      if((t.min>=45 && t.min<50) || (t.min>=15 && t.min<20))
      {
         _open[i]=open[i];
         _high[i]=high[i];
         _low[i]=low[i];
         _close[i]=close[i];
      
         _color[i]=0;
         if(open[i]>=close[i])
            _color[i]=1;
      }
   }
     
   return(rates_total-1);
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id-CHARTEVENT_CUSTOM==3333)
   {
      if(lparam==0)
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);

      if(lparam==1)
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_COLOR_CANDLES);
   }
}