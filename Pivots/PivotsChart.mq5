//
// PivotsChart.mq5
//

#property copyright "Copyright 2021, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  C'0,172,230', LightSlateGray, DeepPink, Wheat
#property indicator_label1  "Buy Momentum | Default | Sell Momentum | Developing"

double OpenBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];
double ColorBuffer[];


void OnInit()
{
   SetIndexBuffer(0,OpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,CloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ColorBuffer,INDICATOR_COLOR_INDEX);

   PlotIndexSetInteger(0,PLOT_SHIFT,1);
   PlotIndexSetInteger(1,PLOT_SHIFT,1);
   PlotIndexSetInteger(2,PLOT_SHIFT,1);
   PlotIndexSetInteger(3,PLOT_SHIFT,1);
   PlotIndexSetInteger(4,PLOT_SHIFT,1);

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   IndicatorSetString(INDICATOR_SHORTNAME,"PivotsChart");
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
}


int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
{
   int i, limit;

   if(prev_calculated==0)
   {
      OpenBuffer[0]=Open[0];
      HighBuffer[0]=High[0];
      LowBuffer[0]=Low[0];
      CloseBuffer[0]=Close[0];
      limit=1;
   }
   else
      limit=prev_calculated-2;

   for(i=limit; i<rates_total && !IsStopped(); i++)
   {
      double pivot=(High[i]+Low[i]+Close[i])/3;
      double range1=(High[i]+Low[i])/2;
      double range2=(pivot-range1)+pivot;

      OpenBuffer[i]=range1;
      HighBuffer[i-1]=High[i];
      HighBuffer[i]=range2;
      LowBuffer[i-1]=Low[i];
      LowBuffer[i]=range1;
      CloseBuffer[i]=range2;

      ColorBuffer[i]=1;
      if(i==rates_total-1)
         ColorBuffer[i]=3;

      if(Low[i]>(OpenBuffer[i-1]+CloseBuffer[i-1])/2 && High[i]>(OpenBuffer[i-1]+CloseBuffer[i-1])/2)
         ColorBuffer[i-1]=0;
      if(Low[i]<(OpenBuffer[i-1]+CloseBuffer[i-1])/2 && High[i]<(OpenBuffer[i-1]+CloseBuffer[i-1])/2)
         ColorBuffer[i-1]=2;
      
   }
   return(rates_total);
}
