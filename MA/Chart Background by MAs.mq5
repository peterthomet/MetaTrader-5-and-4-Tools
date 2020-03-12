//  Chart Background by MAs

#property copyright "2020, getYourNet.ch"
#property link      "http://www.getyournet.ch"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "Fast MA Style"
#property indicator_label1 "Slow MA Style"
#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE
#property indicator_color1 DodgerBlue
#property indicator_color2 DodgerBlue

input int InpMAPeriod1=20; // Fast MA Period
input int InpMAPeriod2=200; // Slow MA Period
input ENUM_MA_METHOD InpMAMethod=MODE_SMA; // MA Method
input color ColorUptrend=C'248,255,253'; // Color Uptrend
input color ColorDowntrend=C'255,252,252'; // Color Downtrend
input color ColorNotrend=White; // Color No Trend

double ExtLineBuffer1[];
double ExtLineBuffer2[];
enum TypeState
{
   Uptrend,
   Downtrend,
   Notrend
};
int LastState;


void CalculateSimpleMA(int rates_total,int prev_calculated,int begin,const double &price[], int InpMAPeriod, double &ExtLineBuffer[])
{
   int i,limit;
   if(prev_calculated==0)
   {
      limit=InpMAPeriod+begin;
      for(i=0; i<limit-1; i++) ExtLineBuffer[i]=0.0;
      double firstValue=0;
      for(i=begin; i<limit; i++)
         firstValue+=price[i];
      firstValue/=InpMAPeriod;
      ExtLineBuffer[limit-1]=firstValue;
   }
   else limit=prev_calculated-1;
   for(i=limit; i<rates_total && !IsStopped(); i++)
      ExtLineBuffer[i]=ExtLineBuffer[i-1]+(price[i]-price[i-InpMAPeriod])/InpMAPeriod;
}


void CalculateEMA(int rates_total,int prev_calculated,int begin,const double &price[], int InpMAPeriod, double &ExtLineBuffer[])
{
   int    i,limit;
   double SmoothFactor=2.0/(1.0+InpMAPeriod);
   if(prev_calculated==0)
   {
      limit=InpMAPeriod+begin;
      ExtLineBuffer[begin]=price[begin];
      for(i=begin+1; i<limit; i++)
         ExtLineBuffer[i]=price[i]*SmoothFactor+ExtLineBuffer[i-1]*(1.0-SmoothFactor);
   }
   else limit=prev_calculated-1;
   for(i=limit; i<rates_total && !IsStopped(); i++)
      ExtLineBuffer[i]=price[i]*SmoothFactor+ExtLineBuffer[i-1]*(1.0-SmoothFactor);
}


void CalculateLWMA(int rates_total,int prev_calculated,int begin,const double &price[], int InpMAPeriod, double &ExtLineBuffer[])
{
   int        i,limit;
   static int weightsum;
   double     sum;
   if(prev_calculated==0)
   {
      weightsum=0;
      limit=InpMAPeriod+begin;
      for(i=0; i<limit; i++) ExtLineBuffer[i]=0.0;
      double firstValue=0;
      for(i=begin; i<limit; i++)
      {
         int k=i-begin+1;
         weightsum+=k;
         firstValue+=k*price[i];
      }
      firstValue/=(double)weightsum;
      ExtLineBuffer[limit-1]=firstValue;
   }
   else limit=prev_calculated-1;
   for(i=limit; i<rates_total && !IsStopped(); i++)
   {
      sum=0;
      for(int j=0; j<InpMAPeriod; j++) sum+=(InpMAPeriod-j)*price[i-j];
      ExtLineBuffer[i]=sum/weightsum;
   }
}


void CalculateSmoothedMA(int rates_total,int prev_calculated,int begin,const double &price[], int InpMAPeriod, double &ExtLineBuffer[])
{
   int i,limit;
   if(prev_calculated==0)
   {
      limit=InpMAPeriod+begin;
      //--- set empty value for first limit bars
      for(i=0; i<limit-1; i++) ExtLineBuffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin; i<limit; i++)
         firstValue+=price[i];
      firstValue/=InpMAPeriod;
      ExtLineBuffer[limit-1]=firstValue;
   }
   else limit=prev_calculated-1;
   for(i=limit; i<rates_total && !IsStopped(); i++)
      ExtLineBuffer[i]=(ExtLineBuffer[i-1]*(InpMAPeriod-1)+price[i])/InpMAPeriod;
}


void OnInit()
{
   SetIndexBuffer(0,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLineBuffer2,INDICATOR_DATA);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod1);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpMAPeriod2);
   PlotIndexSetInteger(0,PLOT_SHIFT,0);
   PlotIndexSetInteger(1,PLOT_SHIFT,0);
   string short_name="unknown ma";
   switch(InpMAMethod)
   {
   case MODE_EMA :
      short_name="EMA";
      break;
   case MODE_LWMA :
      short_name="LWMA";
      break;
   case MODE_SMA :
      short_name="SMA";
      break;
   case MODE_SMMA :
      short_name="SMMA";
      break;
   }
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

   LastState=Notrend;
}


void OnDeinit(const int reason)
{
   ResetBackground();
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   if(rates_total<MathMax(InpMAPeriod1,InpMAPeriod2)-1+begin)
      return(0);
   if(prev_calculated==0)
   {
      ArrayInitialize(ExtLineBuffer1,0);
      ArrayInitialize(ExtLineBuffer2,0);
   }
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod1-1+begin);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpMAPeriod2-1+begin);

   switch(InpMAMethod)
   {
   case MODE_EMA:
      CalculateEMA(rates_total,prev_calculated,begin,price,InpMAPeriod1,ExtLineBuffer1);
      CalculateEMA(rates_total,prev_calculated,begin,price,InpMAPeriod2,ExtLineBuffer2);
      break;
   case MODE_LWMA:
      CalculateLWMA(rates_total,prev_calculated,begin,price,InpMAPeriod1,ExtLineBuffer1);
      CalculateLWMA(rates_total,prev_calculated,begin,price,InpMAPeriod2,ExtLineBuffer2);
      break;
   case MODE_SMMA:
      CalculateSmoothedMA(rates_total,prev_calculated,begin,price,InpMAPeriod1,ExtLineBuffer1);
      CalculateSmoothedMA(rates_total,prev_calculated,begin,price,InpMAPeriod2,ExtLineBuffer2);
      break;
   case MODE_SMA:
      CalculateSimpleMA(rates_total,prev_calculated,begin,price,InpMAPeriod1,ExtLineBuffer1);
      CalculateSimpleMA(rates_total,prev_calculated,begin,price,InpMAPeriod2,ExtLineBuffer2);
      break;
   }

   if(prev_calculated>0)
   {
      int c=prev_calculated-1;

      TypeState state=Notrend;

      if(ExtLineBuffer1[c]>ExtLineBuffer2[c])
         state=Uptrend;

      if(ExtLineBuffer1[c]<ExtLineBuffer2[c])
         state=Downtrend;

      bool isuptrend=ExtLineBuffer1[c]>ExtLineBuffer2[c];
      bool isdowntrend=ExtLineBuffer1[c]<ExtLineBuffer2[c];
   
      if(state!=Notrend)
      {
         if(state==Uptrend)
           ChartSetInteger(0,CHART_COLOR_BACKGROUND,ColorUptrend);
         if(state==Downtrend)
           ChartSetInteger(0,CHART_COLOR_BACKGROUND,ColorDowntrend);
      }
      else
         ResetBackground();
         
      LastState=state;
   }
   
   return(rates_total);
}


void ResetBackground()
{
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,ColorNotrend);
}
