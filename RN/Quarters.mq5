//+------------------------------------------------------------------+
//|                                                     Quarters.mq5 |
//|                           Copyright 2016, getYourNet IT Services |
//|                                         http://www.getyournet.ch |
//+------------------------------------------------------------------+

#property copyright "Copyright 2016, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

input color colorMajor=clrGold;    // Color Major
input color colorMinor=clrGainsboro;    // Color Minor

string short_name="Quarters";
bool started = false;


void OnInit()
{
   started = false;
}


void OnDeinit(const int reason)
{
   if(reason==REASON_REMOVE)
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
   if(!started)
   {
      MqlTick tick;
      if(SymbolInfoTick(_Symbol,tick))
      {
         if(tick.last!=0)
         {
            Paint(tick.last);
            started=true;
         }
      }
   }

   return(rates_total);
}


void Paint(double lastprice)
{
   if(_Digits!=5 && _Digits!=4 && _Digits!=3)
      return;
   double base=0, step=0;
   if(_Digits==5)
   {
      base = NormalizeDouble(lastprice,2);
      step = 0.01;
   }
   if(_Digits==4)
   {
      base = NormalizeDouble(lastprice,1);
      step = 0.1;
   }
   if(_Digits==3)
   {
      base = NormalizeDouble(lastprice,0);
      step = 1;
   }
   double range = step*8;
   double lower = base - range;
   double upper = base + range;

   DeleteObjects();
   while(lower<=upper)
   {
      double f = step/4;
      CreateLine(lower,colorMajor);
      CreateLine(lower+(f*1),colorMajor);
      CreateLine(lower+(f*2),colorMajor);
      CreateLine(lower+(f*3),colorMajor);

      f = step/10;
      CreateLine(lower+(f*1),colorMinor,STYLE_DOT);
      CreateLine(lower+(f*2),colorMinor,STYLE_DOT);
      CreateLine(lower+(f*3),colorMinor,STYLE_DOT);
      CreateLine(lower+(f*4),colorMinor,STYLE_DOT);
      CreateLine(lower+(f*6),colorMinor,STYLE_DOT);
      CreateLine(lower+(f*7),colorMinor,STYLE_DOT);
      CreateLine(lower+(f*8),colorMinor,STYLE_DOT);
      CreateLine(lower+(f*9),colorMinor,STYLE_DOT);

      f = step/8;
      CreateLine(lower+(f*1),colorMinor);
      CreateLine(lower+(f*3),colorMinor);
      CreateLine(lower+(f*5),colorMinor);
      CreateLine(lower+(f*7),colorMinor);

      lower+=step;
   }
   ChartRedraw();
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