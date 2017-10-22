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

input color colorPivot=DarkKhaki;    // Color Pivot
input color colorS1=HotPink;    // Color S1
input color colorR1=HotPink;    // Color R1
input color colorS2=CornflowerBlue;    // Color S2
input color colorR2=CornflowerBlue;    // Color R2
input color colorS3=DarkGray;    // Color S3
input color colorR3=DarkGray;    // Color R3
input color colorS4=DarkGray;    // Color S4
input color colorR4=DarkGray;    // Color R4
enum PivotType
{
   NONE, // None
   PIVOT_CLASSIC, // Classic
   PIVOT_FIBONACCI, // Fibonacci
   PIVOT_DEMARK, // Demark
   PIVOT_CAMARILLA, // Camarilla
   PIVOT_WOODIES // Woodies
};
input PivotType PivotTypeHour=PIVOT_CLASSIC;    // Pivot Type Hour
input PivotType PivotTypeFourHour=PIVOT_CLASSIC;    // Pivot Type Four Hour
input PivotType PivotTypeDay=PIVOT_CLASSIC;    // Pivot Type Day

input ENUM_LINE_STYLE LineStyleHour=STYLE_SOLID;    // Line Style Hour
input ENUM_LINE_STYLE LineStyleFourHour=STYLE_SOLID;    // Line Style Four Hour
input ENUM_LINE_STYLE LineStyleDay=STYLE_SOLID;    // Line Style Day

string short_name="MultiPivots";
//double currentrange=0;
//double lastrange=0;
//double paintrange=0;
//double min, max;
datetime currenth1time=0;
datetime lasth1time=0;
datetime currenth4time=0;
datetime lasth4time=0;
datetime currentdaytime=0;
datetime lastdaytime=0;
bool newbar=false;
int weekdaystart=-1;
int dayhourstart=-1;
long firstbar=0;
long lastfirstbar=-1;

enum PivotPeriod
{
   HOUR,
   FOURHOUR,
   DAY,
   WEEK,
   MONTH
};

struct TimeRange
{
   datetime start;
   datetime end;
   datetime startdisplay;
   datetime enddisplay;
   PivotPeriod period;
};


void OnInit()
{
   EventSetTimer(1);
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
   if(rates_total>prev_calculated)
      newbar=true;
   return(rates_total);
}


void CreateLine(TimeRange& time, double price, color clr, string level, PivotType type, ENUM_LINE_STYLE style = STYLE_DOT, int width = 1)
{
   if(!PlotIndexGetInteger(0,PLOT_SHOW_DATA))
      return;
   if(time.period==HOUR) style=LineStyleHour;
   if(time.period==FOURHOUR) style=LineStyleFourHour;
   if(time.period==DAY) style=LineStyleDay;
   //string objname = short_name + " " + PivotPeriodToString(time.period) + " " + level + " " + TimeToString(time.startdisplay) + "-" + DoubleToString(price,_Digits);
   string objname = short_name + " " + PivotPeriodToString(time.period) + " " + level;
   ObjectCreate(0,objname,OBJ_TREND,0,time.startdisplay,price,time.enddisplay,price);
   ObjectSetInteger(0,objname,OBJPROP_RAY_RIGHT,true);
   ObjectSetInteger(0,objname,OBJPROP_STYLE,style);
   ObjectSetInteger(0,objname,OBJPROP_WIDTH,width);
   ObjectSetInteger(0,objname,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,objname,OBJPROP_BACK,true);
}


void DeleteObjects(string namespace="")
{
   ObjectsDeleteAll(0,short_name + (StringLen(namespace)==0 ? "" : " " + namespace));
   ChartRedraw();
}


void OnTimer()
{
   if(newbar || lastfirstbar!=firstbar)
   {
      datetime arr1[1];
      datetime dtarr[1];
      if(CopyTime(_Symbol,_Period,(int)firstbar,1,arr1)<1)
         return;
      if(CopyTime(_Symbol,PERIOD_H1,arr1[0],1,dtarr)==1)
      {
         currenth1time=dtarr[0];
         if(currenth1time!=lasth1time)
         {
            if(!FindWeekDayStart())
               return;

            TimeRange times;

            times=CalculatePivotRange(HOUR);
            DeleteObjects(PivotPeriodToString(times.period));
            if(PivotTypeHour>NONE)
               if(!CalculatePivots(times,PivotTypeHour))
                  return;
         
            times=CalculatePivotRange(FOURHOUR);
            currenth4time=times.start;
            if(currenth4time!=lasth4time)
            {
               DeleteObjects(PivotPeriodToString(times.period));
               if(PivotTypeFourHour>NONE)
                  if(!CalculatePivots(times,PivotTypeFourHour))
                     return;
               lasth4time=currenth4time;
            }

            times=CalculatePivotRange(DAY);
            currentdaytime=times.start;
            if(currentdaytime!=lastdaytime)
            {
               DeleteObjects(PivotPeriodToString(times.period));
               if(PivotTypeDay>NONE)
                  if(!CalculatePivots(times,PivotTypeDay))
                     return;
               lastdaytime=currentdaytime;
            }



            //Print("New Calculation:" + TimeToString(times.start) + " | " + TimeToString(times.end));
            lasth1time=currenth1time;
            lastfirstbar=firstbar;
         }
         newbar=false;
      }
      else
      {
         return;
      }
   }
   else
   {
      return;
   }

   //if(currentrange==lastrange)
   //   return;
   //paintrange=currentrange;
   //Paint();
   //lastrange=paintrange;
}


bool CalculatePivots(TimeRange& times, PivotType type)
{
   int count;
   double High[],Low[],Close[],Open[],HighDay,LowDay,CloseDay,OpenDay;
   double range=0,pivot=0,support1=0,support2=0,support3=0,support4=0,resistance1=0,resistance2=0,resistance3=0,resistance4=0;

   count=CopyHigh(NULL,PERIOD_H1,times.start,times.end,High);
   if(count<=0)
      return false;
   HighDay=High[ArrayMaximum(High,0,count)];
   count=CopyLow(NULL,PERIOD_H1,times.start,times.end,Low);
   if(count<=0)
      return false;
   LowDay=Low[ArrayMinimum(Low,0,count)];
   count=CopyClose(NULL,PERIOD_H1,times.end,1,Close);
   if(count<=0)
      return false;
   CloseDay=Close[0];
   count=CopyOpen(NULL,_Period,times.end+1,1,Open);
   if(count<=0)
      return false;
   OpenDay=Open[0];

   switch(type)
   {
      case PIVOT_CLASSIC:
         pivot=(CloseDay+HighDay+LowDay)/3;
         support1=(2*pivot)-HighDay;
         support2=pivot-(HighDay - LowDay);
         support3=(2*pivot)-((2* HighDay)-LowDay);
         support4=EMPTY_VALUE;
         resistance1=(2*pivot)-LowDay;
         resistance2=pivot+(HighDay - LowDay);
         resistance3=(2*pivot)+(HighDay-(2*LowDay));
         resistance4=EMPTY_VALUE;
         break;
      case PIVOT_FIBONACCI:
         range=HighDay-LowDay;
         pivot=(CloseDay+HighDay+LowDay)/3;
         support1=pivot-0.382*range;
         support2=pivot-0.618*range;
         support3=pivot-range;
         support4=EMPTY_VALUE;
         resistance1=pivot+0.382*range;
         resistance2=pivot+0.618*range;
         resistance3=pivot+range;
         resistance4=EMPTY_VALUE;
         break;
      case PIVOT_DEMARK:
         if(CloseDay<OpenDay) pivot=HighDay+2*LowDay+CloseDay;
         if(CloseDay>OpenDay) pivot=2*HighDay+LowDay+CloseDay;
         if(CloseDay==OpenDay) pivot=HighDay+LowDay+2*CloseDay;
         support1=pivot/2-HighDay;
         resistance1=pivot/2-LowDay;
         pivot=EMPTY_VALUE;
         support2=EMPTY_VALUE;
         support3=EMPTY_VALUE;
         support4=EMPTY_VALUE;
         resistance2=EMPTY_VALUE;
         resistance3=EMPTY_VALUE;
         resistance4=EMPTY_VALUE;
         break;
      case PIVOT_CAMARILLA:
         range=HighDay-LowDay;
         pivot=EMPTY_VALUE;
         support1=CloseDay-range*1.1/12;
         support2=CloseDay-range*1.1/6;
         support3=CloseDay-range*1.1/4;
         support4=CloseDay-range*1.1/2;
         resistance1=range*1.1/12+CloseDay;
         resistance2=range*1.1/6+CloseDay;
         resistance3=range*1.1/4+CloseDay;
         resistance4=range*1.1/2+CloseDay;
         break;
      case PIVOT_WOODIES:
         range=HighDay-LowDay;
         pivot=(HighDay+LowDay+2*CloseDay)/4;
         support1=2*pivot-HighDay;
         support2=pivot-HighDay+LowDay;
         support3=EMPTY_VALUE;
         support4=EMPTY_VALUE;
         resistance1=2*pivot-LowDay;
         resistance2=pivot+HighDay-LowDay;
         resistance3=EMPTY_VALUE;
         resistance4=EMPTY_VALUE;
         break;
   }

   CreateLine(times,pivot,colorPivot,"PP",type);
   CreateLine(times,support1,colorS1,"S1",type);
   CreateLine(times,resistance1,colorR1,"R1",type);
   CreateLine(times,support2,colorS2,"S2",type);
   CreateLine(times,resistance2,colorR2,"R2",type);
   CreateLine(times,support3,colorS3,"S3",type);
   CreateLine(times,resistance3,colorR3,"R3",type);

   return true;
}


bool FindWeekDayStart()
{
   if(weekdaystart>-1)
      return true;
   int bars=200;
   datetime dtarr[];
   ArraySetAsSeries(dtarr,true);
   if(CopyTime(_Symbol,PERIOD_H1,0,bars,dtarr)==bars)
   {
      datetime ref=dtarr[0];
      for(int i=1;i<bars;i++)
      {
         if(ref-dtarr[i]>86400)
         {
            MqlDateTime wdstart;
            TimeToStruct(ref,wdstart);
            weekdaystart=wdstart.day_of_week;
            dayhourstart=wdstart.hour;
            break;
         }
         ref=dtarr[i];
      }
      return true;
   }
   else
   {
      return false;
   }
}


TimeRange CalculatePivotRange(PivotPeriod period)
{
   TimeRange times;
   times.start=0;
   times.end=0;
   times.period=period;
   
   if(period==HOUR)
   {
      times.startdisplay=currenth1time;
      times.enddisplay=currenth1time+PeriodSeconds(PERIOD_H1)-1;
      times.start=currenth1time-PeriodSeconds(PERIOD_H1);
      MqlDateTime starttime;
      TimeToStruct(times.start,starttime);
      if(starttime.day_of_week==weekdaystart && starttime.hour==dayhourstart-1)
         times.start=times.start-172800;
      times.end=times.start+PeriodSeconds(PERIOD_H1)-1;
   }
   if(period==FOURHOUR)
   {
      int houroffset=dayhourstart;
      if(houroffset>12)
         houroffset=dayhourstart-24;
      MqlDateTime h1time;
      TimeToStruct(currenth1time,h1time);
      int h1hour=h1time.hour;
      int h4start=(int)(MathFloor((h1time.hour-houroffset)/4)*4)+houroffset;
      times.startdisplay=currenth1time-(PeriodSeconds(PERIOD_H1)*(h1hour-h4start));
      times.enddisplay=times.startdisplay+(PeriodSeconds(PERIOD_H1)*4)-1;
      times.start=times.startdisplay-(PeriodSeconds(PERIOD_H1)*4);
      MqlDateTime starttime;
      TimeToStruct(times.start,starttime);
      if(starttime.day_of_week==weekdaystart && starttime.hour<dayhourstart)
         times.start=times.start-172800;
      times.end=times.start+(PeriodSeconds(PERIOD_H1)*4)-1;
   }
   if(period==DAY)
   {
      int houroffset=dayhourstart;
      if(houroffset>12)
         houroffset=dayhourstart-24;
      MqlDateTime h1time;
      TimeToStruct(currenth1time,h1time);
      int h1hour=h1time.hour;
      //int daystart=(int)(MathFloor((h1time.hour-houroffset)/24)*24)+houroffset;
      //times.startdisplay=currenth1time-(PeriodSeconds(PERIOD_H1)*(h1hour-daystart));
      times.startdisplay=currenth1time-(PeriodSeconds(PERIOD_H1)*(h1hour-houroffset));
      times.enddisplay=times.startdisplay+(PeriodSeconds(PERIOD_H1)*24)-1;
      times.start=times.startdisplay-(PeriodSeconds(PERIOD_H1)*24);
      MqlDateTime starttime;
      TimeToStruct(times.start,starttime);
      int weekdayempty=weekdaystart-1;
      if(weekdayempty<0)
         weekdayempty=7+weekdayempty;
      if(starttime.day_of_week==weekdayempty)
         times.start=times.start-172800;
      times.end=times.start+(PeriodSeconds(PERIOD_H1)*24)-1;
   }

   return times;
}


string PivotPeriodToString(PivotPeriod period)
{
   if(period==HOUR) return "Hour";
   if(period==FOURHOUR) return "4Hour";
   if(period==DAY) return "Day";
   if(period==WEEK) return "Week";
   return "-";
}


static bool ctrl_pressed = false;
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      //min = ChartGetDouble(0,CHART_PRICE_MIN,0);
      //max = ChartGetDouble(0,CHART_PRICE_MAX,0);
      //currentrange = NormalizeDouble(max-min,_Digits);
      long firstvisible=ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR);
      long visiblebars=ChartGetInteger(0,CHART_VISIBLE_BARS);
      if(firstvisible>visiblebars-1)
         firstbar=firstvisible-visiblebars+1;
      else
         firstbar=0;
      //Print("First: " + firstbar);
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
               lasth1time=0;
               lasth4time=0;
               lastdaytime=0;
               newbar=true;
            }
            else
            {
               PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
               lasth1time=0;
               lasth4time=0;
               lastdaytime=0;
               newbar=true;
            }
            ctrl_pressed = false;
         }
      }
   }
}

