//
// MultiPivots.mq5
// Copyright 2016, getYourNet IT Services
// http://www.getyournet.ch |
//

#property copyright "Copyright 2017, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
#property script_show_inputs

#include <MultiPivots.mqh>

input color colorPivot=PaleGoldenrod;    // Color Pivot
input color colorS1=LightPink;    // Color S1
input color colorR1=LightPink;    // Color R1
input color colorS2=LightBlue;    // Color S2
input color colorR2=LightBlue;    // Color R2
input color colorS3=LightGray;    // Color S3
input color colorR3=LightGray;    // Color R3
input color colorS4=LightGray;    // Color S4
input color colorR4=LightGray;    // Color R4
input color colorS5=LightGray;    // Color S5
input color colorR5=LightGray;    // Color R5
input color colormidpoints=WhiteSmoke;    // Color Mid-Points

input TypePivotsType PivotTypeHour=PIVOT_TRADITIONAL;    // Pivot Type Hour
input TypePivotsType PivotTypeFourHour=PIVOT_TRADITIONAL;    // Pivot Type Four Hour
input TypePivotsType PivotTypeDay=PIVOT_TRADITIONAL;    // Pivot Type Day
input TypePivotsType PivotTypeWeek=PIVOT_TRADITIONAL;    // Pivot Type Week
input bool PivotTypeHourMidPoints=true;    // Pivot Hour Show Mid-Points
input bool PivotTypeFourHourMidPoints=true;    // Pivot Four Hour Show Mid-Points
input bool PivotTypeDayMidPoints=true;    // Pivot Day Show Mid-Points
input bool PivotTypeWeekMidPoints=true;    // Pivot Week Show Mid-Points

input ENUM_LINE_STYLE LineStyleHour=STYLE_SOLID;    // Line Style Hour
input ENUM_LINE_STYLE LineStyleFourHour=STYLE_SOLID;    // Line Style Four Hour
input ENUM_LINE_STYLE LineStyleDay=STYLE_SOLID;    // Line Style Day
input ENUM_LINE_STYLE LineStyleWeek=STYLE_SOLID;    // Line Style Week

string short_name="MultiPivots";
bool newbar=false;
long firstbar=0;
long lastfirstbar=-1;
bool istesting;
TypePivotsData pivotsdata;


void OnInit()
{
   pivotsdata.Settings.draw=PlotIndexGetInteger(0,PLOT_SHOW_DATA);
   pivotsdata.Settings.objectnamespace=short_name;
   pivotsdata.Settings.colorPivot=colorPivot;
   pivotsdata.Settings.colorS1=colorS1;
   pivotsdata.Settings.colorR1=colorR1;
   pivotsdata.Settings.colorS2=colorS2;
   pivotsdata.Settings.colorR2=colorR2;
   pivotsdata.Settings.colorS3=colorS3;
   pivotsdata.Settings.colorR3=colorR3;
   pivotsdata.Settings.colorS4=colorS4;
   pivotsdata.Settings.colorR4=colorR4;
   pivotsdata.Settings.colorS5=colorS5;
   pivotsdata.Settings.colorR5=colorR5;
   pivotsdata.Settings.colormidpoints=colormidpoints;
   pivotsdata.Settings.PivotTypeHour=PivotTypeHour;
   pivotsdata.Settings.PivotTypeFourHour=PivotTypeFourHour;
   pivotsdata.Settings.PivotTypeDay=PivotTypeDay;
   pivotsdata.Settings.PivotTypeWeek=PivotTypeWeek;
   pivotsdata.Settings.PivotTypeHourMidPoints=PivotTypeHourMidPoints;
   pivotsdata.Settings.PivotTypeFourHourMidPoints=PivotTypeFourHourMidPoints;
   pivotsdata.Settings.PivotTypeDayMidPoints=PivotTypeDayMidPoints;
   pivotsdata.Settings.PivotTypeWeekMidPoints=PivotTypeWeekMidPoints;
   pivotsdata.Settings.LineStyleHour=LineStyleHour;
   pivotsdata.Settings.LineStyleFourHour=LineStyleFourHour;
   pivotsdata.Settings.LineStyleDay=LineStyleDay;
   pivotsdata.Settings.LineStyleDay=LineStyleWeek;
   
   istesting=MQLInfoInteger(MQL_TESTER);
   EventSetTimer(1);
}


void OnDeinit(const int reason)
{
   EventKillTimer();
   PivotsDeleteObjects(pivotsdata);
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
   if(rates_total>prev_calculated)
   {
      newbar=true;
      if(istesting)
         OnTimer();
   }
   return(rates_total);
}


void OnTimer()
{
   if(newbar || lastfirstbar!=firstbar)
   {
      datetime arr1[1];
      if(CopyTime(_Symbol,_Period,(int)firstbar,1,arr1)<1)
         return;
         
      if(!pivotsdata.Calculate(arr1[0]))
         return;
         
      lastfirstbar=firstbar;
      newbar=false;
   }
}


static bool ctrl_pressed = false;
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      long firstvisible=ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR);
      long visiblebars=ChartGetInteger(0,CHART_VISIBLE_BARS);
      if(firstvisible>visiblebars-1)
         firstbar=firstvisible-visiblebars+1;
      else
         firstbar=0;
   }
   if(id==CHARTEVENT_KEYDOWN)
   {
      if (ctrl_pressed == false && lparam == 17)
      {
         ctrl_pressed = true;
      }
      else if (ctrl_pressed == true)
      {
         if (lparam == 52)
         {
            if(!PlotIndexGetInteger(0,PLOT_SHOW_DATA))
            {
               PlotIndexSetInteger(0,PLOT_SHOW_DATA,true);
               pivotsdata.Settings.draw=true;
               pivotsdata.Settings.Init();
               newbar=true;
            }
            else
            {
               PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
               pivotsdata.Settings.draw=false;
               pivotsdata.Settings.Init();
               newbar=true;
            }
            ctrl_pressed = false;
         }
      }
   }
}

