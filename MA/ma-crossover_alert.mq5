//+------------------------------------------------------------------+
//|                                           MA-Crossover_Alert.mq5 |
//|         Copyright © 2005, Jason Robinson (jnrtrading)            |
//|                   http://www.jnrtading.co.uk                     |
//| Modified by Robert Hill to add LSMA and alert or send email      |
//| Added Global LastAlert to try to have alert only on new cross    |
//| but does not seem to work. So indicator does alert every bar     |
//+------------------------------------------------------------------+

/*
  +------------------------------------------------------------------+
  | Allows you to enter two ma periods and it will then show you at  |
  | Which point they crossed over. It is more usful on the shorter   |
  | periods that get obscured by the bars / candlesticks and when    |
  | the zoom level is out. Also allows you then to remove the  mas   |
  | from the chart. (emas are initially set at 5 and 20)             |
  +------------------------------------------------------------------+
*/
#property copyright "Copyright © 2005, Jason Robinson (jnrtrading)"
#property link      "http://www.jnrtrading.co.uk"

//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//----two buffers are used for calculation of drawing of the indicator
#property indicator_buffers 2
//---- only two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- red color is used for the indicator bearish line
#property indicator_color1  C'251,0,138'
//---- thickness of line of the indicator 1 is equal to 4
#property indicator_width1  1
//---- displaying the bearish label of the indicator line
#property indicator_label1  "MA-Crossover_Alert Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- lime color is used as the color of the bullish indicator line
#property indicator_color2  C'0,172,230'
//---- thickness of the indicator line 2 is equal to 4
#property indicator_width2  1
//---- displaying of the bullish label of the indicator
#property indicator_label2 "MA-Crossover_Alert Buy"
//+----------------------------------------------+
//|  Declaration of enumerations                 |
//+----------------------------------------------+
enum Smooth_Method
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_LSMA_  //LSMA
  };
//+----------------------------------------------+
//|  Declaration of constants                    |
//+----------------------------------------------+
#define RESET 0 // the constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input Smooth_Method FastMA_Mode=MODE_EMA_; //Smoothing method for fast moving
input uint FastMA_Period=5; //Period of averaging for fast moving
input ENUM_APPLIED_PRICE FastPriceMode=PRICE_CLOSE;//Price for fast moving
input Smooth_Method SlowMA_Mode=MODE_EMA_; //Smoothing method for slow moving
input uint SlowMA_Period=20; //Period of averaging for slow moving
input ENUM_APPLIED_PRICE SlowPriceMode=PRICE_CLOSE;//Price for slow moving
extern bool SoundON=true; //Alert
extern bool EmailON=false; //Email
input uint NumberofAlerts=2;
//+----------------------------------------------+

//---- declaration of dynamic arrays that
// will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//----
uint counter=0;
bool flagval1 = false;
bool flagval2 = false;
//----Declaration of variables for storing the indicators handles
int FaMA_Handle,SlMA_Handle;
//---- declaration of the integer variables for the start of data calculation
int StartBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   StartBars=int(MathMax(FastMA_Period,SlowMA_Period)+3+9);

//---- obtaining the indicators handles
   if(FastMA_Mode!=MODE_LSMA_)
     {
      FaMA_Handle=iMA(NULL,0,FastMA_Period,0,ENUM_MA_METHOD(FastMA_Mode),FastPriceMode);
      if(FaMA_Handle==INVALID_HANDLE)Print(" Failed to get handle of the FaMA indicator");
     }

   if(SlowMA_Mode!=MODE_LSMA_)
     {
      SlMA_Handle=iMA(NULL,0,SlowMA_Period,0,ENUM_MA_METHOD(SlowMA_Mode),SlowPriceMode);
      if(SlMA_Handle==INVALID_HANDLE)Print(" Failed to get handle of the SlMA indicator");
     }

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,159);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellBuffer,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyBuffer,true);

//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="MA-Crossover_Alert";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//----
//----   
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//---- checking the number of bars to be enough for the calculation
   if(rates_total<StartBars) return(RESET);
   if(FastMA_Mode!=MODE_LSMA_&&BarsCalculated(FaMA_Handle)<rates_total) return(RESET);
   if(SlowMA_Mode!=MODE_LSMA_&&BarsCalculated(SlMA_Handle)<rates_total) return(RESET);

//---- declaration of local variables 
   int limit,count;
   double fastMAnow,slowMAnow,fastMAprevious,slowMAprevious,Range,AvgRange,MA[],Ask,Bid;
   string text,sAsk,sBid,sPeriod;

//---- calculations of the necessary amount of data to be copied
//---- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-StartBars;       // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }

//---- indexing elements in arrays as time series 
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(MA,true);

//---- main loop of the indicator calculation
   for(int bar=limit; bar>=0; bar--)
     {
      count=bar;
      Range=0;
      AvgRange=0;
      for(count=bar;count<=bar+9;count++) AvgRange=AvgRange+MathAbs(high[count]-low[count]);
      Range=AvgRange/10;

      if(FastMA_Mode==MODE_LSMA_)
        {
         fastMAnow=LSMA(open,high,low,close,FastMA_Period,FastPriceMode,bar);
         fastMAprevious=LSMA(open,high,low,close,FastMA_Period,FastPriceMode,bar+1);

        }
      else
        {
         //--- copy newly appeared data in the array
         if(CopyBuffer(FaMA_Handle,0,bar,2,MA)<=0) return(RESET);
         fastMAnow=MA[0];
         fastMAprevious=MA[1];
        }

      if(SlowMA_Mode==MODE_LSMA_)
        {
         slowMAnow=LSMA(open,high,low,close,SlowMA_Period,SlowPriceMode,bar);
         slowMAprevious=LSMA(open,high,low,close,SlowMA_Period,SlowPriceMode,bar+1);
        }
      else
        {
         //--- copy newly appeared data in the array
         if(CopyBuffer(SlMA_Handle,0,bar,2,MA)<=0) return(RESET);
         slowMAnow=MA[0];
         slowMAprevious=MA[1];
        }

      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;

      if(fastMAnow>slowMAnow && fastMAprevious<slowMAprevious)
        {
         if(bar==1 && !flagval1)
           {
            flagval1=true;
            flagval2=false;
           }
         BuyBuffer[bar]=low[bar]-Range*0.75;
        }

      if(fastMAnow<slowMAnow && fastMAprevious>slowMAprevious)
        {
         if(bar==1&!flagval2)
           {
            flagval2=true;
            flagval1=false;
           }
         SellBuffer[bar]=high[bar]+Range*0.75;
        }
     }

   if(rates_total!=prev_calculated) counter=0;

   if(BuyBuffer[1]&&counter<=NumberofAlerts)
     {
      counter++;
      MqlDateTime tm;
      TimeToStruct(TimeCurrent(),tm);
      text=TimeToString(TimeCurrent(),TIME_DATE)+" "+string(tm.hour)+":"+string(tm.min);
      Ask=close[0];
      Bid=close[0]+spread[0];
      sAsk=DoubleToString(Ask,_Digits);
      sBid=DoubleToString(Bid,_Digits);
      sPeriod=EnumToString(ChartPeriod());
      if(SoundON) Print("BUY signal at Ask=",Ask,"\n Bid=",Bid,"\n currtime=",text,"\n Symbol=",Symbol()," Period=",sPeriod);
      if(EmailON) SendMail("BUY signal alert","BUY signal at Ask="+sAsk+", Bid="+sBid+", Date="+text+" Symbol="+Symbol()+" Period="+sPeriod);
     }

   if(SellBuffer[1]&&counter<=NumberofAlerts)
     {
      counter++;
      MqlDateTime tm;
      TimeToStruct(TimeCurrent(),tm);
      text=TimeToString(TimeCurrent(),TIME_DATE)+" "+string(tm.hour)+":"+string(tm.min);
      Ask=close[0];
      Bid=close[0]+spread[0];
      sAsk=DoubleToString(Ask,_Digits);
      sBid=DoubleToString(Bid,_Digits);
      sPeriod=EnumToString(ChartPeriod());
      if(SoundON) Print("SELL signal at Ask=",sAsk,"\n Bid=",sBid,"\n Date=",text,"\n Symbol=",Symbol()," Period=",sPeriod);
      if(EmailON) SendMail("SELL signal alert","SELL signal at Ask="+sAsk+", Bid="+sBid+", Date="+text+" Symbol="+Symbol()+" Period="+sPeriod);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| LSMA with PriceMode                                              |
//+------------------------------------------------------------------+
double LSMA
(
 const double &Open[],
 const double &High[],
 const double &Low[],
 const double &Close[],
 int Rperiod,
 ENUM_APPLIED_PRICE prMode,
 int shift
 )
  {
//----
   int i;
   double sum,pr;
   int length;
   double lengthvar;
   double tmp;
   double wt;

   length=Rperiod;

   sum=0;
   for(i=length; i>=1; i--)
     {
      lengthvar = length+1;
      lengthvar/= 3;
      tmp=0;
      switch(prMode)
        {
         case PRICE_CLOSE: pr= Close[length-i+shift];break;
         case PRICE_OPEN: pr = Open[length-i+shift];break;
         case PRICE_HIGH: pr = High[length-i+shift];break;
         case PRICE_LOW: pr=Low[length-i+shift];break;
         case PRICE_MEDIAN: pr=(High[length-i+shift]+Low[length-i+shift])/2;break;
         case PRICE_TYPICAL: pr=(High[length-i+shift]+Low[length-i+shift]+Close[length-i+shift])/3;break;
         case PRICE_WEIGHTED: pr=(High[length-i+shift]+Low[length-i+shift]+Close[length-i+shift]+Close[length-i+shift])/4;break;
        }
      tmp = ( i - lengthvar)*pr;
      sum+=tmp;
     }
   wt=sum*6/(length*(length+1));
//----
   return(wt);
  }
//+------------------------------------------------------------------+
