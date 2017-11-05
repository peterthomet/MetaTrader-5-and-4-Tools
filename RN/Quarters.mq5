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
#property indicator_plots 1

input color colorMajor=PaleGoldenrod;    // Color Major
input color colorMinor=WhiteSmoke;    // Color Minor
input bool MajorQuarters=false; // Show Major Quarters
input bool MajorHalfRN=false; // Show Major Half RN
input bool MinorQuarters=false; // Show Minor Quarters
input bool MinorRN=false; // Show Minor RN

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
   if(_Digits!=5 && _Digits!=4 && _Digits!=3)
      return true;
      
   double step=0;
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

   double lower=NormalizeDouble(min,digits)-step;
   double upper=max;
   double rangesteps=(max-min)/step;
   
   bool showMinorQuarters=false;
   bool showMinorRN=false;
   bool showMajorQuarters=false;
   bool showMajorHalfRN=false;
   bool showMajorRN=false;
   color colorMajorSub=colorMinor;
   int widthMajorMain=1;

   if(rangesteps<40)
   {
      showMajorRN=true;
      if(rangesteps<14)
      {
         showMajorHalfRN=true;
         if(rangesteps<5.5)
         {
            showMajorQuarters=true;
            if(rangesteps<3.5)
            {
               showMinorRN=true;
               widthMajorMain=2;
               colorMajorSub=colorMajor;
               if(rangesteps<1.5)
               {
                  showMinorQuarters=true;
               }
            }
         }
      }
   }

   DeleteObjects();
   while(lower<=upper)
   {
      double f = step/4;
      if(showMajorRN)
         CreateLine(lower,colorMajor,STYLE_SOLID,widthMajorMain);
      if(showMajorQuarters && MajorQuarters)
         CreateLine(lower+(f*1),colorMajorSub,STYLE_SOLID,1);
      if(showMajorHalfRN && MajorHalfRN)
         CreateLine(lower+(f*2),colorMajorSub,STYLE_SOLID,1);
      if(showMajorQuarters && MajorQuarters)
         CreateLine(lower+(f*3),colorMajorSub,STYLE_SOLID,1);

      f = step/10;
      if(showMinorRN && MinorRN)
      {
         CreateLine(lower+(f*1),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*2),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*3),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*4),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*6),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*7),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*8),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*9),colorMinor,STYLE_SOLID,1);
      }

      f = step/8;
      if(showMinorQuarters && MinorQuarters)
      {
         CreateLine(lower+(f*1),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*3),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*5),colorMinor,STYLE_SOLID,1);
         CreateLine(lower+(f*7),colorMinor,STYLE_SOLID,1);
      }

      lower+=step;
   }
   ChartRedraw();
   return true;
}


void CreateLine(double price, color clr, ENUM_LINE_STYLE style = STYLE_SOLID, int width = 1)
{
   if(!PlotIndexGetInteger(0,PLOT_SHOW_DATA))
      return;
   string objname = short_name + " " + DoubleToString(price,_Digits);
   ObjectCreate(0,objname,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,objname,OBJPROP_STYLE,style);
   ObjectSetInteger(0,objname,OBJPROP_WIDTH,width);
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


static bool ctrl_pressed = false;
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      min = ChartGetDouble(0,CHART_PRICE_MIN,0);
      max = ChartGetDouble(0,CHART_PRICE_MAX,0);
      currentrange = NormalizeDouble(max-min,_Digits);
   }
   if(id==CHARTEVENT_KEYDOWN)
   {
      if (ctrl_pressed == false && lparam == 17)
      {
         ctrl_pressed = true;
      }
      else if (ctrl_pressed == true)
      {
         if (lparam == 51)
         {
            if(!PlotIndexGetInteger(0,PLOT_SHOW_DATA))
            {
               PlotIndexSetInteger(0,PLOT_SHOW_DATA,true);
               lastrange=0;
            }
            else
            {
               PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
               lastrange=0;
            }
            ctrl_pressed = false;
         }
      }
   }
}

