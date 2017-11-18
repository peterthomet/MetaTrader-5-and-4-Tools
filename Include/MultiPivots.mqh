//
// MultiPivots.mqh
// Copyright 2016, getYourNet IT Services
// http://www.getyournet.ch
//

#property copyright "Copyright 2017, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"

enum TypePivotsType
{
   NONE, // None
   PIVOT_TRADITIONAL, // Traditional
   PIVOT_CLASSIC, // Classic
   PIVOT_FIBONACCI, // Fibonacci
   PIVOT_DEMARK, // Demark
   PIVOT_CAMARILLA, // Camarilla
   PIVOT_WOODIES // Woodies
};

struct TypePivotsSettings
{
   string objectnamespace;
   color colorPivot;
   color colorS1;
   color colorR1;
   color colorS2;
   color colorR2;
   color colorS3;
   color colorR3;
   color colorS4;
   color colorR4;
   color colorS5;
   color colorR5;
   color colormidpoints;
   TypePivotsType PivotTypeHour;
   TypePivotsType PivotTypeFourHour;
   TypePivotsType PivotTypeDay;
   TypePivotsType PivotTypeWeek;
   bool PivotTypeHourMidPoints;
   bool PivotTypeFourHourMidPoints;
   bool PivotTypeDayMidPoints;
   bool PivotTypeWeekMidPoints;
   ENUM_LINE_STYLE LineStyleHour;
   ENUM_LINE_STYLE LineStyleFourHour;
   ENUM_LINE_STYLE LineStyleDay;
   ENUM_LINE_STYLE LineStyleWeek;
   datetime currenth1time;
   datetime lasth1time;
   datetime currenth4time;
   datetime lasth4time;
   datetime currentdaytime;
   datetime lastdaytime;
   datetime currentweektime;
   datetime lastweektime;
   int weekdaystart;
   int dayhourstart;
   datetime weekstarttime;
   bool draw;
   TypePivotsSettings()
   {
      currenth1time=0; lasth1time=0; currenth4time=0; lasth4time=0; currentdaytime=0; lastdaytime=0; currentweektime=0; lastweektime=0; weekdaystart=-1; dayhourstart=-1; weekstarttime=0;
      draw=true;
      objectnamespace="MultiPivots";
      colorPivot=PaleGoldenrod;
      colorS1=LightPink;
      colorR1=LightPink;
      colorS2=LightBlue;
      colorR2=LightBlue;
      colorS3=LightGray;
      colorR3=LightGray;
      colorS4=LightGray;
      colorR4=LightGray;
      colorS5=LightGray;
      colorR5=LightGray;
      colormidpoints=WhiteSmoke;
      PivotTypeHour=PIVOT_TRADITIONAL;
      PivotTypeFourHour=PIVOT_TRADITIONAL;
      PivotTypeDay=PIVOT_TRADITIONAL;
      PivotTypeWeek=PIVOT_TRADITIONAL;
      PivotTypeHourMidPoints=true;
      PivotTypeFourHourMidPoints=true;
      PivotTypeDayMidPoints=true;
      PivotTypeWeekMidPoints=true;
      LineStyleHour=STYLE_SOLID;
      LineStyleFourHour=STYLE_SOLID;
      LineStyleDay=STYLE_SOLID;
      LineStyleWeek=STYLE_SOLID;
   }
   void Init() { lasth1time=0; lasth4time=0; lastdaytime=0; lastweektime=0; } 
};

enum TypePivotsPeriod
{
   HOUR,
   FOURHOUR,
   DAY,
   WEEK,
   MONTH
};

struct TypePivotsTimeRange
{
   datetime start;
   datetime end;
   datetime startdisplay;
   datetime enddisplay;
   TypePivotsPeriod period;
};

struct TypePivots
{
   double P;
   double S1;
   double S2;
   double S3;
   double S4;
   double S5;
   double R1;
   double R2;
   double R3;
   double R4;
   double R5;
   double MP;
   double MPP;
   double MM;
   double MMM;
};

struct TypePivotsData
{
   TypePivotsSettings Settings;
   TypePivots PivotsDay;
   TypePivots PivotsFourHour;
   TypePivots PivotsHour;
   TypePivots PivotsWeek;
   bool Calculate(datetime timeref) { return PivotsGetPivots(timeref); };
};

TypePivotsData PD;


bool PivotsGetPivots(datetime timeref)
{
   datetime dtarr[1];
   if(CopyTime(_Symbol,PERIOD_H1,timeref,1,dtarr)==1)
   {
      PD.Settings.currenth1time=dtarr[0];
      if(PD.Settings.currenth1time!=PD.Settings.lasth1time)
      {
         if(!PivotsFindWeekDayStart(timeref))
            return false;

         TypePivotsTimeRange times;

         if(PD.Settings.PivotTypeWeek>NONE)
         {
            times=PivotsCalculatePivotRange(WEEK);
            PD.Settings.currentweektime=times.start;
            if(PD.Settings.currentweektime!=PD.Settings.lastweektime)
            {
               PivotsDeleteObjects(PivotsPivotPeriodToString(times.period));
               if(!PivotsCalculatePivots(times,PD.Settings.PivotTypeWeek,PD.PivotsWeek))
                  return false;
               PD.Settings.lastweektime=PD.Settings.currentweektime;
            }
         }

         if(PD.Settings.PivotTypeDay>NONE)
         {
            times=PivotsCalculatePivotRange(DAY);
            PD.Settings.currentdaytime=times.start;
            if(PD.Settings.currentdaytime!=PD.Settings.lastdaytime)
            {
               PivotsDeleteObjects(PivotsPivotPeriodToString(times.period));
               if(!PivotsCalculatePivots(times,PD.Settings.PivotTypeDay,PD.PivotsDay))
                  return false;
               PD.Settings.lastdaytime=PD.Settings.currentdaytime;
            }
         }

         if(PD.Settings.PivotTypeFourHour>NONE)
         {
            times=PivotsCalculatePivotRange(FOURHOUR);
            PD.Settings.currenth4time=times.start;
            if(PD.Settings.currenth4time!=PD.Settings.lasth4time)
            {
               PivotsDeleteObjects(PivotsPivotPeriodToString(times.period));
               if(!PivotsCalculatePivots(times,PD.Settings.PivotTypeFourHour,PD.PivotsFourHour))
                  return false;
               PD.Settings.lasth4time=PD.Settings.currenth4time;
            }
         }

         if(PD.Settings.PivotTypeHour>NONE)
         {
            times=PivotsCalculatePivotRange(HOUR);
            PivotsDeleteObjects(PivotsPivotPeriodToString(times.period));
            if(!PivotsCalculatePivots(times,PD.Settings.PivotTypeHour,PD.PivotsHour))
               return false;
         }

         PD.Settings.lasth1time=PD.Settings.currenth1time;
      }
      return true;
   }
   else
   {
      return false;
   }
}


bool PivotsCalculatePivots(TypePivotsTimeRange& times, TypePivotsType type, TypePivots& p)
{
   int count;
   double High[],Low[],Close[],Open[],HighDay,LowDay,CloseDay,OpenDay;
   double range=0,pivot=0,support1=0,support2=0,support3=0,support4=0,support5=0,resistance1=0,resistance2=0,resistance3=0,resistance4=0,resistance5=0,mplus=0,mplusplus=0,mminus=0,mminusminus=0;

   p.P=0;
   p.S1=0;
   p.S2=0;
   p.S3=0;
   p.S4=0;
   p.S5=0;
   p.R1=0;
   p.R2=0;
   p.R3=0;
   p.R4=0;
   p.R5=0;
   p.MP=0;
   p.MPP=0;
   p.MM=0;
   p.MMM=0;

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
      case PIVOT_TRADITIONAL:
         pivot=(CloseDay+HighDay+LowDay)/3;
         support1=(2*pivot)-HighDay;
         mminus=pivot-((pivot-support1)/2);
         support2=pivot-(HighDay - LowDay);
         mminusminus=support1-((support1-support2)/2);
         support3=(2*pivot)-((2* HighDay)-LowDay);
         support4=(3*pivot)-((3* HighDay)-LowDay);
         support5=(4*pivot)-((4* HighDay)-LowDay);
         resistance1=(2*pivot)-LowDay;
         mplus=pivot+((resistance1-pivot)/2);
         resistance2=pivot+(HighDay - LowDay);
         mplusplus=resistance1+((resistance2-resistance1)/2);
         resistance3=(2*pivot)+(HighDay-(2*LowDay));
         resistance4=(3*pivot)+(HighDay-(3*LowDay));
         resistance5=(4*pivot)+(HighDay-(4*LowDay));
         break;
       case PIVOT_CLASSIC:
         pivot=(CloseDay+HighDay+LowDay)/3;
         support1=(2*pivot)-HighDay;
         support2=pivot-(HighDay - LowDay);
         support3=(2*pivot)-((2* HighDay)-LowDay);
         resistance1=(2*pivot)-LowDay;
         resistance2=pivot+(HighDay - LowDay);
         resistance3=(2*pivot)+(HighDay-(2*LowDay));
         break;
      case PIVOT_FIBONACCI:
         range=HighDay-LowDay;
         pivot=(CloseDay+HighDay+LowDay)/3;
         support1=pivot-0.382*range;
         support2=pivot-0.618*range;
         support3=pivot-range;
         resistance1=pivot+0.382*range;
         resistance2=pivot+0.618*range;
         resistance3=pivot+range;
         break;
      case PIVOT_DEMARK:
         if(CloseDay<OpenDay) pivot=HighDay+2*LowDay+CloseDay;
         if(CloseDay>OpenDay) pivot=2*HighDay+LowDay+CloseDay;
         if(CloseDay==OpenDay) pivot=HighDay+LowDay+2*CloseDay;
         support1=pivot/2-HighDay;
         resistance1=pivot/2-LowDay;
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
         resistance1=2*pivot-LowDay;
         resistance2=pivot+HighDay-LowDay;
         break;
   }

   p.P=pivot;
   p.S1=support1;
   p.S2=support2;
   p.S3=support3;
   p.S4=support4;
   p.S5=support5;
   p.R1=resistance1;
   p.R2=resistance2;
   p.R3=resistance3;
   p.R4=resistance4;
   p.R5=resistance5;
   p.MP=mplus;
   p.MPP=mplusplus;
   p.MM=mminus;
   p.MMM=mminusminus;

   if(PD.Settings.draw)
   {
      PivotsCreateLine(times,pivot,PD.Settings.colorPivot,"PP",type);
      PivotsCreateLine(times,support1,PD.Settings.colorS1,"S1",type);
      PivotsCreateLine(times,resistance1,PD.Settings.colorR1,"R1",type);
      PivotsCreateLine(times,support2,PD.Settings.colorS2,"S2",type);
      PivotsCreateLine(times,resistance2,PD.Settings.colorR2,"R2",type);
      PivotsCreateLine(times,support3,PD.Settings.colorS3,"S3",type);
      PivotsCreateLine(times,resistance3,PD.Settings.colorR3,"R3",type);
      PivotsCreateLine(times,support4,PD.Settings.colorS4,"S4",type);
      PivotsCreateLine(times,resistance4,PD.Settings.colorR4,"R4",type);
      PivotsCreateLine(times,support5,PD.Settings.colorS5,"S5",type);
      PivotsCreateLine(times,resistance5,PD.Settings.colorR5,"R5",type);
      if((times.period==WEEK && PD.Settings.PivotTypeWeekMidPoints) || (times.period==DAY && PD.Settings.PivotTypeDayMidPoints) || (times.period==FOURHOUR && PD.Settings.PivotTypeFourHourMidPoints) || (times.period==HOUR && PD.Settings.PivotTypeHourMidPoints))
      {
         PivotsCreateLine(times,mminus,PD.Settings.colormidpoints,"M-",type);
         PivotsCreateLine(times,mminusminus,PD.Settings.colormidpoints,"M--",type);
         PivotsCreateLine(times,mplus,PD.Settings.colormidpoints,"M+",type);
         PivotsCreateLine(times,mplusplus,PD.Settings.colormidpoints,"M++",type);
      }
   }

   return true;
}


bool PivotsFindWeekDayStart(datetime timeref)
{
   if(PD.Settings.weekstarttime>0 && PD.Settings.weekstarttime<=timeref && PD.Settings.weekstarttime>timeref-518400)
      return true;
   int bars=200;
   datetime dtarr[];
   ArraySetAsSeries(dtarr,true);
   if(CopyTime(_Symbol,PERIOD_H1,timeref,bars,dtarr)==bars)
   {
      datetime ref=dtarr[0];
      for(int i=1;i<bars;i++)
      {
         if(ref-dtarr[i]>86400)
         {
            MqlDateTime wdstart;
            TimeToStruct(ref,wdstart);
            PD.Settings.weekdaystart=wdstart.day_of_week;
            PD.Settings.dayhourstart=wdstart.hour;
            PD.Settings.weekstarttime=ref;
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


TypePivotsTimeRange PivotsCalculatePivotRange(TypePivotsPeriod period)
{
   TypePivotsTimeRange times;
   times.start=0;
   times.end=0;
   times.period=period;
   
   if(period==HOUR)
   {
      times.startdisplay=PD.Settings.currenth1time;
      times.enddisplay=PD.Settings.currenth1time+PeriodSeconds(PERIOD_H1)-1;
      times.start=PD.Settings.currenth1time-PeriodSeconds(PERIOD_H1);
      MqlDateTime starttime;
      TimeToStruct(times.start,starttime);
      if(starttime.day_of_week==PD.Settings.weekdaystart && starttime.hour==PD.Settings.dayhourstart-1)
         times.start=times.start-172800;
      times.end=times.start+PeriodSeconds(PERIOD_H1)-1;
   }
   if(period==FOURHOUR)
   {
      int houroffset=PD.Settings.dayhourstart;
      if(houroffset>12)
         houroffset=PD.Settings.dayhourstart-24;
      MqlDateTime h1time;
      TimeToStruct(PD.Settings.currenth1time,h1time);
      int h1hour=h1time.hour;
      int h4start=(int)(MathFloor((h1time.hour-houroffset)/4)*4)+houroffset;
      times.startdisplay=PD.Settings.currenth1time-(PeriodSeconds(PERIOD_H1)*(h1hour-h4start));
      times.enddisplay=times.startdisplay+(PeriodSeconds(PERIOD_H1)*4)-1;
      times.start=times.startdisplay-(PeriodSeconds(PERIOD_H1)*4);
      MqlDateTime starttime;
      TimeToStruct(times.start,starttime);
      if(starttime.day_of_week==PD.Settings.weekdaystart && starttime.hour<PD.Settings.dayhourstart)
         times.start=times.start-172800;
      times.end=times.start+(PeriodSeconds(PERIOD_H1)*4)-1;
   }
   if(period==DAY)
   {
      int houroffset=PD.Settings.dayhourstart;
      if(houroffset>12)
         houroffset=PD.Settings.dayhourstart-24;
      MqlDateTime h1time;
      TimeToStruct(PD.Settings.currenth1time,h1time);
      int h1hour=h1time.hour;
      int daystart=(int)(MathFloor((h1time.hour-houroffset)/24)*24)+houroffset;
      times.startdisplay=PD.Settings.currenth1time-(PeriodSeconds(PERIOD_H1)*(h1hour-daystart));
      times.enddisplay=times.startdisplay+(PeriodSeconds(PERIOD_H1)*24)-1;
      times.start=times.startdisplay-(PeriodSeconds(PERIOD_H1)*24);
      MqlDateTime starttime;
      TimeToStruct(times.start,starttime);
      int weekdayempty=PD.Settings.weekdaystart-1;
      if(weekdayempty<0)
         weekdayempty=7+weekdayempty;
      if(starttime.day_of_week==weekdayempty)
         times.start=times.start-172800;
      times.end=times.start+(PeriodSeconds(PERIOD_H1)*24)-1;
   }
   if(period==WEEK)
   {
      times.startdisplay=PD.Settings.weekstarttime;
      times.enddisplay=times.startdisplay+(PeriodSeconds(PERIOD_H1)*(24*5))-1;
      times.start=times.startdisplay-(PeriodSeconds(PERIOD_H1)*(24*5));
      times.end=times.start+(PeriodSeconds(PERIOD_H1)*(24*5))-1;
   }

   return times;
}


string PivotsPivotPeriodToString(TypePivotsPeriod period)
{
   if(period==HOUR) return "Hour";
   if(period==FOURHOUR) return "4Hour";
   if(period==DAY) return "Day";
   if(period==WEEK) return "Week";
   return "-";
}


string PivotsPivotTypeToString(TypePivotsType type)
{
   if(type==NONE) return "None";
   if(type==PIVOT_TRADITIONAL) return "Traditional";
   if(type==PIVOT_CLASSIC) return "Classic";
   if(type==PIVOT_FIBONACCI) return "Fibonacci";
   if(type==PIVOT_DEMARK) return "Demark";
   if(type==PIVOT_CAMARILLA) return "Camarilla";
   if(type==PIVOT_WOODIES) return "Woodies";
   return "-";
}


void PivotsCreateLine(TypePivotsTimeRange& time, double price, color clr, string level, TypePivotsType type, ENUM_LINE_STYLE style = STYLE_DOT, int width = 1)
{
   if(time.period==HOUR) style=PD.Settings.LineStyleHour;
   if(time.period==FOURHOUR) style=PD.Settings.LineStyleFourHour;
   if(time.period==DAY) style=PD.Settings.LineStyleDay;
   if(time.period==WEEK) style=PD.Settings.LineStyleWeek;
   string objname = PD.Settings.objectnamespace + " " + PivotsPivotPeriodToString(time.period) + " " + level + " " + PivotsPivotTypeToString(type);
   ObjectCreate(0,objname,OBJ_TREND,0,time.startdisplay,price,time.enddisplay,price);
   //ObjectSetInteger(0,objname,OBJPROP_RAY_RIGHT,true);
   ObjectSetInteger(0,objname,OBJPROP_STYLE,style);
   ObjectSetInteger(0,objname,OBJPROP_WIDTH,width);
   ObjectSetInteger(0,objname,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,objname,OBJPROP_BACK,true);
}


bool PivotsIsPivotRange(double price1, double price2, TypePivots& pivots, string level)
{
   double upper=MathMax(price1,price2), lower=MathMin(price1,price2), lv=PivotsGetLevelByString(pivots, level);
   return (lv<=upper && lv>=lower);
}


bool PivotsIsAbovePivot(double price1, TypePivots& pivots, string level)
{
   double lv=PivotsGetLevelByString(pivots, level);
   return (price1>=lv);
}


double PivotsGetLevelByString(TypePivots& pivots, string level)
{
   double lv=0;
   if(level=="P") lv=pivots.P;
   if(level=="S1") lv=pivots.S1;
   if(level=="S2") lv=pivots.S2;
   if(level=="S3") lv=pivots.S3;
   if(level=="S4") lv=pivots.S4;
   if(level=="S5") lv=pivots.S5;
   if(level=="R1") lv=pivots.R1;
   if(level=="R2") lv=pivots.R2;
   if(level=="R3") lv=pivots.R3;
   if(level=="R4") lv=pivots.R4;
   if(level=="R5") lv=pivots.R5;
   if(level=="MP") lv=pivots.MP;
   if(level=="MPP") lv=pivots.MPP;
   if(level=="MM") lv=pivots.MM;
   if(level=="MMM") lv=pivots.MMM;
   return lv;
}


void PivotsDeleteObjects(string namespace="")
{
   ObjectsDeleteAll(0,PD.Settings.objectnamespace + (StringLen(namespace)==0 ? "" : " " + namespace));
   ChartRedraw();
}
