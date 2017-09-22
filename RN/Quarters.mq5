//+------------------------------------------------------------------+
//|                                                     Quarters.mq5 |
//|                           Copyright 2016, getYourNet IT Services |
//|                                         http://www.getyournet.ch |
//+------------------------------------------------------------------+

#property copyright "Copyright 2017, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

input color colorMajor=Khaki;    // Color Major
input color colorMinor=WhiteSmoke;    // Color Minor

string short_name="Quarters";
double currentrange=0;
double lastrange=0;
double paintrange=0;
double min, max;


void OnInit()
{
   EventSetTimer(2);
}


void OnDeinit(const int reason)
{
   EventKillTimer();
   //if(reason==REASON_REMOVE)
      DeleteObjects();
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
                const int &spread[]
                )
{
   return(rates_total);
}


bool Paint()
{
   //Print("Paint");

   double lastprice;
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return false;

   if(tick.bid==0)
      return false;

   lastprice=tick.bid;
      
   if(_Digits!=5 && _Digits!=4 && _Digits!=3)
      return true;
      
   double base=0, step=0;
   int digits=0;
   if(_Digits==5)
   {
      digits=2;
      step = 0.01;
   }
   if(_Digits==4)
   {
      digits=1;
      step = 0.1;
   }
   if(_Digits==3)
   {
      digits=0;
      step = 1;
   }
   base = NormalizeDouble(lastprice,digits);

   double range = step*8;
   double lower = base - range;
   double upper = base + range;
   double rangesteps;
   
   lower=NormalizeDouble(min,digits)-step;
   upper=max;
   
   rangesteps=(max-min)/step;
   
   DeleteObjects();
   while(lower<=upper)
   {
      double f = step/4;
      if(rangesteps<40)
         CreateLine(lower,colorMajor);
      if(rangesteps<5.5)
         CreateLine(lower+(f*1),colorMajor);
      if(rangesteps<14)
         CreateLine(lower+(f*2),colorMajor);
      if(rangesteps<5.5)
         CreateLine(lower+(f*3),colorMajor);

      f = step/10;
      if(rangesteps<3.5)
      {
         CreateLine(lower+(f*1),colorMinor,STYLE_DOT);
         CreateLine(lower+(f*2),colorMinor,STYLE_DOT);
         CreateLine(lower+(f*3),colorMinor,STYLE_DOT);
         CreateLine(lower+(f*4),colorMinor,STYLE_DOT);
         CreateLine(lower+(f*6),colorMinor,STYLE_DOT);
         CreateLine(lower+(f*7),colorMinor,STYLE_DOT);
         CreateLine(lower+(f*8),colorMinor,STYLE_DOT);
         CreateLine(lower+(f*9),colorMinor,STYLE_DOT);
      }

      f = step/8;
      if(rangesteps<1.5)
      {
         CreateLine(lower+(f*1),colorMinor);
         CreateLine(lower+(f*3),colorMinor);
         CreateLine(lower+(f*5),colorMinor);
         CreateLine(lower+(f*7),colorMinor);
      }

      lower+=step;
   }
   ChartRedraw();
   return true;
}


void CreateLine(double price, color clr, ENUM_LINE_STYLE style = STYLE_SOLID)
{
   style = STYLE_SOLID;
   string objname = short_name + " " + DoubleToString(price,_Digits);
   ObjectCreate(0,objname,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,objname,OBJPROP_STYLE,style);
   ObjectSetInteger(0,objname,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,objname,OBJPROP_BACK,true);
}


void DeleteObjects()
{
   ObjectsDeleteAll(0,short_name);
   ChartRedraw();
}


void OnTimer()
{
   if(currentrange==lastrange)
      return;

   paintrange=currentrange;

   Paint();
      
   lastrange=paintrange;
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      min = ChartGetDouble(0,CHART_PRICE_MIN,0);
      max = ChartGetDouble(0,CHART_PRICE_MAX,0);
      currentrange = NormalizeDouble(max-min,_Digits);
   }
}

