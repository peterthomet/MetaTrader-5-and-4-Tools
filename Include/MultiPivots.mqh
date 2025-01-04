//
// MultiPivots.mqh
// Copyright 2020, getYourNet IT Services
// http://www.getyournet.ch
//

#property copyright "Copyright 2020, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "2.00"

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
   TypePivotsType PivotTypeMonth;
   TypePivotsType PivotTypeYear;
   bool PivotTypeHourMidPoints;
   bool PivotTypeFourHourMidPoints;
   bool PivotTypeDayMidPoints;
   bool PivotTypeWeekMidPoints;
   bool PivotTypeMonthMidPoints;
   bool PivotTypeYearMidPoints;
   ENUM_LINE_STYLE LineStyleHour;
   ENUM_LINE_STYLE LineStyleFourHour;
   ENUM_LINE_STYLE LineStyleDay;
   ENUM_LINE_STYLE LineStyleWeek;
   ENUM_LINE_STYLE LineStyleMonth;
   ENUM_LINE_STYLE LineStyleYear;
   datetime currenth1time;
   datetime lasth1time;
   datetime currenth4time;
   datetime lasth4time;
   datetime currentdaytime;
   datetime lastdaytime;
   datetime currentweektime;
   datetime lastweektime;
   datetime currentmonthtime;
   datetime lastmonthtime;
   datetime currentyeartime;
   datetime lastyeartime;
   bool weekstartuseservertime;
   int weekdaystart;
   int dayhourstart;
   datetime weekstarttime;
   bool draw;
   color pivotrangecolor;
   color pivottrendlinescolor;
   string symbol;
   TypePivotsSettings()
   {
      currenth1time=0; lasth1time=0; currenth4time=0; lasth4time=0; currentdaytime=0; lastdaytime=0; currentweektime=0; lastweektime=0; currentmonthtime=0; lastmonthtime=0; currentyeartime=0; lastyeartime=0; weekdaystart=-1; dayhourstart=-1; weekstarttime=0;
      draw=true;
      pivotrangecolor=C'250,250,250';
      pivottrendlinescolor=Gainsboro;
      symbol=_Symbol;
      objectnamespace="MultiPivots";
      colorPivot=C'250,250,250';
      colorS1=MistyRose;
      colorR1=MistyRose;
      colorS2=C'220,233,255';
      colorR2=C'220,233,255';
      colorS3=clrNONE;
      colorR3=clrNONE;
      colorS4=clrNONE;
      colorR4=clrNONE;
      colorS5=clrNONE;
      colorR5=clrNONE;
      colormidpoints=WhiteSmoke;
      PivotTypeHour=NONE;
      PivotTypeFourHour=NONE;
      PivotTypeDay=NONE;
      PivotTypeWeek=NONE;
      PivotTypeMonth=NONE;
      PivotTypeYear=NONE;
      PivotTypeHourMidPoints=false;
      PivotTypeFourHourMidPoints=false;
      PivotTypeDayMidPoints=false;
      PivotTypeWeekMidPoints=false;
      PivotTypeMonthMidPoints=false;
      PivotTypeYearMidPoints=false;
      LineStyleHour=STYLE_SOLID;
      LineStyleFourHour=STYLE_SOLID;
      LineStyleDay=STYLE_SOLID;
      LineStyleWeek=STYLE_SOLID;
      LineStyleMonth=STYLE_SOLID;
      LineStyleYear=STYLE_SOLID;
      weekstartuseservertime=false;
   }
   void Init() { lasth1time=0; lasth4time=0; lastdaytime=0; lastweektime=0; lastmonthtime=0; lastyeartime=0; } 
};

enum TypePivotsPeriod
{
   HOUR,
   FOURHOUR,
   DAY,
   WEEK,
   MONTH,
   YEAR
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
   double TC;
   double BC;
   TypePivotsTimeRange times;
};

struct TypePivotsData
{
   TypePivotsSettings Settings;
   TypePivots PivotsDay;
   TypePivots PivotsDayList[6];
   TypePivots PivotsFourHour;
   TypePivots PivotsFourHourList[6];
   TypePivots PivotsHour;
   TypePivots PivotsHourList[6];
   TypePivots PivotsWeek;
   TypePivots PivotsWeekList[6];
   TypePivots PivotsMonth;
   TypePivots PivotsMonthList[6];
   TypePivots PivotsYear;
   TypePivots PivotsYearList[6];
   bool Calculate(datetime timeref) { return PivotsGetPivots(this, timeref); };
};


bool PivotsGetPivots(TypePivotsData& PD, datetime timeref)
{
   datetime dtarr[1];
   int i;
   
   if(CopyTime(PD.Settings.symbol,PERIOD_H1,timeref,1,dtarr)==1)
   {
      PD.Settings.currenth1time=dtarr[0];
      if(PD.Settings.currenth1time!=PD.Settings.lasth1time)
      {
         if(!PivotsFindWeekDayStart(PD,timeref))
            return false;

         TypePivotsTimeRange timescurrent;
         TypePivotsTimeRange times;

         if(PD.Settings.PivotTypeYear>NONE)
         {
            timescurrent=PivotsCalculatePivotRange(PD,YEAR,0);
            PD.Settings.currentyeartime=timescurrent.start;
            if(PD.Settings.currentyeartime!=PD.Settings.lastyeartime)
            {
               PivotsDeleteObjects(PD,PivotsPivotPeriodToString(timescurrent.period));
               for(i=-1; i<=4; i++)
               {
                  times=timescurrent;
                  if(i!=0)
                     times=PivotsCalculatePivotRange(PD,YEAR,i);
                  if(!PivotsCalculatePivots(PD,times,PD.Settings.PivotTypeYear,PD.PivotsYearList[i+1]))
                     return false;
                  PivotsDrawPivots(PD,PD.Settings.PivotTypeYear,PD.PivotsYearList,i+1);
               }
               PD.PivotsYear=PD.PivotsYearList[1];
               PD.Settings.lastyeartime=PD.Settings.currentyeartime;
            }
         }

         if(PD.Settings.PivotTypeMonth>NONE)
         {
            timescurrent=PivotsCalculatePivotRange(PD,MONTH,0);
            PD.Settings.currentmonthtime=timescurrent.start;
            if(PD.Settings.currentmonthtime!=PD.Settings.lastmonthtime)
            {
               PivotsDeleteObjects(PD,PivotsPivotPeriodToString(timescurrent.period));
               for(i=-1; i<=4; i++)
               {
                  times=timescurrent;
                  if(i!=0)
                     times=PivotsCalculatePivotRange(PD,MONTH,i);
                  if(!PivotsCalculatePivots(PD,times,PD.Settings.PivotTypeMonth,PD.PivotsMonthList[i+1]))
                     return false;
                  PivotsDrawPivots(PD,PD.Settings.PivotTypeMonth,PD.PivotsMonthList,i+1);
               }
               PD.PivotsMonth=PD.PivotsMonthList[1];
               PD.Settings.lastmonthtime=PD.Settings.currentmonthtime;
            }
         }
         
         if(PD.Settings.PivotTypeWeek>NONE)
         {
            timescurrent=PivotsCalculatePivotRange(PD,WEEK,0);
            PD.Settings.currentweektime=timescurrent.start;
            if(PD.Settings.currentweektime!=PD.Settings.lastweektime)
            {
               PivotsDeleteObjects(PD,PivotsPivotPeriodToString(timescurrent.period));
               for(i=-1; i<=4; i++)
               {
                  times=timescurrent;
                  if(i!=0)
                     times=PivotsCalculatePivotRange(PD,WEEK,i);
                  if(!PivotsCalculatePivots(PD,times,PD.Settings.PivotTypeWeek,PD.PivotsWeekList[i+1]))
                     return false;
                  PivotsDrawPivots(PD,PD.Settings.PivotTypeWeek,PD.PivotsWeekList,i+1);
               }
               PD.PivotsWeek=PD.PivotsWeekList[1];
               PD.Settings.lastweektime=PD.Settings.currentweektime;
            }
         }

         if(PD.Settings.PivotTypeDay>NONE)
         {
            timescurrent=PivotsCalculatePivotRange(PD,DAY,0);
            PD.Settings.currentdaytime=timescurrent.start;
            if(PD.Settings.currentdaytime!=PD.Settings.lastdaytime)
            {
               PivotsDeleteObjects(PD,PivotsPivotPeriodToString(timescurrent.period));
               for(i=-1; i<=4; i++)
               {
                  times=timescurrent;
                  if(i!=0)
                     times=PivotsCalculatePivotRange(PD,DAY,i);
                  if(!PivotsCalculatePivots(PD,times,PD.Settings.PivotTypeDay,PD.PivotsDayList[i+1]))
                     return false;
                  PivotsDrawPivots(PD,PD.Settings.PivotTypeDay,PD.PivotsDayList,i+1);
               }
               PD.PivotsDay=PD.PivotsDayList[1];
               PD.Settings.lastdaytime=PD.Settings.currentdaytime;
            }
         }

         if(PD.Settings.PivotTypeFourHour>NONE)
         {
            timescurrent=PivotsCalculatePivotRange(PD,FOURHOUR,0);
            PD.Settings.currenth4time=timescurrent.start;
            if(PD.Settings.currenth4time!=PD.Settings.lasth4time)
            {
               PivotsDeleteObjects(PD,PivotsPivotPeriodToString(timescurrent.period));
               for(i=-1; i<=4; i++)
               {
                  times=timescurrent;
                  if(i!=0)
                     times=PivotsCalculatePivotRange(PD,FOURHOUR,i);
                  if(!PivotsCalculatePivots(PD,times,PD.Settings.PivotTypeFourHour,PD.PivotsFourHourList[i+1]))
                     return false;
                  PivotsDrawPivots(PD,PD.Settings.PivotTypeFourHour,PD.PivotsFourHourList,i+1);
               }
               PD.PivotsFourHour=PD.PivotsFourHourList[1];
               PD.Settings.lasth4time=PD.Settings.currenth4time;
            }
         }

         if(PD.Settings.PivotTypeHour>NONE)
         {
            timescurrent=PivotsCalculatePivotRange(PD,HOUR,0);
            PivotsDeleteObjects(PD,PivotsPivotPeriodToString(timescurrent.period));
            for(i=-1; i<=4; i++)
            {
               times=timescurrent;
               if(i!=0)
                  times=PivotsCalculatePivotRange(PD,HOUR,i);
               if(!PivotsCalculatePivots(PD,times,PD.Settings.PivotTypeHour,PD.PivotsHourList[i+1]))
                  return false;
               PivotsDrawPivots(PD,PD.Settings.PivotTypeHour,PD.PivotsHourList,i+1);
            }
            PD.PivotsHour=PD.PivotsHourList[1];
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


void PivotsDrawPivots(TypePivotsData& PD, TypePivotsType type, TypePivots& p[], int i)
{
   if(!PD.Settings.draw)
      return;

   if(PD.Settings.colorPivot!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].P,PD.Settings.colorPivot,"PP",type);
   if(PD.Settings.pivotrangecolor!=clrNONE)
   {
      //PivotsCreateLine(PD,p[i].times,p[i].TC,PD.Settings.colorPivot,"TC",type);
      //PivotsCreateLine(PD,p[i].times,p[i].BC,PD.Settings.colorPivot,"BC",type);
      PivotsCreateRectangle(PD,p[i].times,p[i].TC,p[i].BC,PD.Settings.pivotrangecolor,"TC-BC",type);
   }
   if(PD.Settings.colorS1!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].S1,PD.Settings.colorS1,"S1",type);
   if(PD.Settings.colorR1!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].R1,PD.Settings.colorR1,"R1",type);
   if(PD.Settings.colorS2!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].S2,PD.Settings.colorS2,"S2",type);
   if(PD.Settings.colorR2!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].R2,PD.Settings.colorR2,"R2",type);
   if(PD.Settings.colorS3!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].S3,PD.Settings.colorS3,"S3",type);
   if(PD.Settings.colorR3!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].R3,PD.Settings.colorR3,"R3",type);
   if(PD.Settings.colorS4!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].S4,PD.Settings.colorS4,"S4",type);
   if(PD.Settings.colorR4!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].R4,PD.Settings.colorR4,"R4",type);
   if(PD.Settings.colorS5!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].S5,PD.Settings.colorS5,"S5",type);
   if(PD.Settings.colorR5!=clrNONE)
      PivotsCreateLine(PD,p[i].times,p[i].R5,PD.Settings.colorR5,"R5",type);
   if((p[i].times.period==YEAR && PD.Settings.PivotTypeYearMidPoints) || (p[i].times.period==MONTH && PD.Settings.PivotTypeMonthMidPoints) || (p[i].times.period==WEEK && PD.Settings.PivotTypeWeekMidPoints) || (p[i].times.period==DAY && PD.Settings.PivotTypeDayMidPoints) || (p[i].times.period==FOURHOUR && PD.Settings.PivotTypeFourHourMidPoints) || (p[i].times.period==HOUR && PD.Settings.PivotTypeHourMidPoints))
   {
      PivotsCreateLine(PD,p[i].times,p[i].MM,PD.Settings.colormidpoints,"M-",type);
      PivotsCreateLine(PD,p[i].times,p[i].MMM,PD.Settings.colormidpoints,"M--",type);
      PivotsCreateLine(PD,p[i].times,p[i].MP,PD.Settings.colormidpoints,"M+",type);
      PivotsCreateLine(PD,p[i].times,p[i].MPP,PD.Settings.colormidpoints,"M++",type);
   }
   if(PD.Settings.pivottrendlinescolor!=clrNONE&&(i==2||i==3||i==4))
   {
      TypePivotsTimeRange t=p[i].times;
      t.enddisplay=p[i-1].times.startdisplay;
      //PivotsCreateLine(PD,t,p[i].BC,p[i-1].BC,Gray,"T-BC",type,2,1,true);

      double gap=p[i-1].P-p[i].P;
      PivotsCreateLine(PD,p[i-1].times,p[i-1].P+gap,p[i-1].P+(gap*2),PD.Settings.pivottrendlinescolor,"TU1-P",type,2,1,true);
      PivotsCreateLine(PD,p[i-1].times,p[i-1].P,p[i-1].P+gap,PD.Settings.pivottrendlinescolor,"T-P",type,2,1,true);
      PivotsCreateLine(PD,p[i-1].times,p[i].P,p[i].P+gap,PD.Settings.pivottrendlinescolor,"TL1-P",type,2,1,true);

      //PivotsCreateLine(PD,t,p[i].TC,p[i-1].TC,Gray,"T-TC",type,2,1,true);
   }
}


bool PivotsCalculatePivots(TypePivotsData& PD, TypePivotsTimeRange& times, TypePivotsType type, TypePivots& p)
{
   int count;
   double Highx[],Lowx[],Closex[],Openx[],HighDay,LowDay,CloseDay,OpenDay;
   double range=0,pivot=0,support1=0,support2=0,support3=0,support4=0,support5=0,resistance1=0,resistance2=0,resistance3=0,resistance4=0,resistance5=0,mplus=0,mplusplus=0,mminus=0,mminusminus=0,range1=0,range2=0;
   datetime currenttime[1];

   ENUM_TIMEFRAMES tf=PERIOD_H1;
   
   if(times.end-times.start>(PeriodSeconds(PERIOD_W1)*2))
      tf=PERIOD_MN1;

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
   p.TC=0;
   p.BC=0;

   count=CopyTime(PD.Settings.symbol,tf,0,1,currenttime);
   if(count<=0)
      return false;

   count=CopyHigh(PD.Settings.symbol,tf,times.start,times.end,Highx);
   if(count<=0)
      return false;
#ifdef __MQL5__
   HighDay=Highx[ArrayMaximum(Highx,0,count)];
#endif
#ifdef __MQL4__
   HighDay=Highx[ArrayMaximum(Highx,count,0)];
#endif
   count=CopyLow(PD.Settings.symbol,tf,times.start,times.end,Lowx);
   if(count<=0)
      return false;
#ifdef __MQL5__
   LowDay=Lowx[ArrayMinimum(Lowx,0,count)];
#endif
#ifdef __MQL4__
   LowDay=Lowx[ArrayMinimum(Lowx,count,0)];
#endif
   count=CopyClose(PD.Settings.symbol,tf,MathMin(times.end,currenttime[0]),1,Closex);
   if(count<=0)
      return false;
   CloseDay=Closex[0];
   count=CopyOpen(PD.Settings.symbol,tf,MathMin(times.end+1,currenttime[0]),1,Openx);
   if(count<=0)
      return false;
   OpenDay=Openx[0];

   switch(type)
   {
      case PIVOT_TRADITIONAL:
         pivot=(CloseDay+HighDay+LowDay)/3;
         range1=(HighDay+LowDay)/2;
         range2=(pivot-range1)+pivot;
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
         range1=(HighDay+LowDay)/2;
         range2=(pivot-range1)+pivot;
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
         range1=(HighDay+LowDay)/2;
         range2=(pivot-range1)+pivot;
         support1=pivot-0.382*range;
         support2=pivot-0.618*range;
         support3=pivot-0.786*range;
         support4=pivot-range;
         support5=pivot-1.382*range;
         resistance1=pivot+0.382*range;
         resistance2=pivot+0.618*range;
         resistance3=pivot+0.786*range;
         resistance4=pivot+range;
         resistance5=pivot+1.382*range;
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
   p.TC=MathMax(range1,range2);
   p.BC=MathMin(range1,range2);
   
   p.times=times;

   return true;
}


bool PivotsFindWeekDayStart(TypePivotsData& PD, datetime timeref)
{
   if(PD.Settings.weekstarttime>0 && PD.Settings.weekstarttime<=timeref && PD.Settings.weekstarttime>timeref-518400)
      return true;
   int bars=200;
   datetime dtarr[];
   ArraySetAsSeries(dtarr,true);
   if(CopyTime(PD.Settings.symbol,PERIOD_H1,timeref,bars,dtarr)==bars)
   {
      datetime ref=dtarr[0];
      for(int i=1;i<bars;i++)
      {
         MqlDateTime wdstart;
         TimeToStruct(ref,wdstart);

         if((ref-dtarr[i]>86400 && wdstart.day_of_week<=1) || (PD.Settings.weekstartuseservertime && wdstart.day_of_week==1 && wdstart.hour==0))
         {
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


datetime PivotsCleanupWeeekendAndDaysGaps(TypePivotsData& PD, datetime time)
{
   datetime timeadjusted=time;
   datetime dtarr[1];

   if(time>PD.Settings.currenth1time)
      return timeadjusted;

   MqlDateTime timestruct;
   TimeToStruct(time,timestruct);

   int weekdayempty1=PD.Settings.weekdaystart-1;
   if(weekdayempty1<0)
      weekdayempty1=7+weekdayempty1;

   int weekdayempty2=PD.Settings.weekdaystart-2;
   if(weekdayempty2<0)
      weekdayempty2=7+weekdayempty2;

   if(timestruct.day_of_week==weekdayempty1||timestruct.day_of_week==weekdayempty2)
      timeadjusted=timeadjusted-172800;

   if(CopyTime(PD.Settings.symbol,PERIOD_H1,timeadjusted,1,dtarr)==1)
   {
      if(dtarr[0]<timeadjusted)
      {
         timeadjusted=timeadjusted-PeriodSeconds(PERIOD_D1);
         if(CopyTime(PD.Settings.symbol,PERIOD_H1,timeadjusted,1,dtarr)==1)
         {
            if(dtarr[0]<timeadjusted)
               timeadjusted=timeadjusted-PeriodSeconds(PERIOD_D1);
         }
      }
   }

   return timeadjusted;
}


TypePivotsTimeRange PivotsCalculatePivotRange(TypePivotsData& PD, TypePivotsPeriod period, int offsetindex)
{
   TypePivotsTimeRange times;
   times.start=0;
   times.end=0;
   times.period=period;
   
   int houroffset, h1hour, offsettime;
   
   if(period==HOUR)
   {
      offsettime=PeriodSeconds(PERIOD_H1)*offsetindex;
      times.startdisplay=PD.Settings.currenth1time-offsettime;
      times.startdisplay=PivotsCleanupWeeekendAndDaysGaps(PD,times.startdisplay);
      times.enddisplay=times.startdisplay+PeriodSeconds(PERIOD_H1)-1;
      times.start=times.startdisplay-PeriodSeconds(PERIOD_H1);
      times.start=PivotsCleanupWeeekendAndDaysGaps(PD,times.start);
      times.end=times.start+PeriodSeconds(PERIOD_H1)-1;
   }
   if(period==FOURHOUR)
   {
      offsettime=PeriodSeconds(PERIOD_H4)*offsetindex;
      houroffset=PD.Settings.dayhourstart;
      if(houroffset>12)
         houroffset=PD.Settings.dayhourstart-24;
      MqlDateTime h1time;
      TimeToStruct(PD.Settings.currenth1time,h1time);
      h1hour=h1time.hour;
      int h4start=(int)(MathFloor((h1time.hour-houroffset)/4)*4)+houroffset;
      times.startdisplay=PD.Settings.currenth1time-(PeriodSeconds(PERIOD_H1)*(h1hour-h4start))-offsettime;
      times.startdisplay=PivotsCleanupWeeekendAndDaysGaps(PD,times.startdisplay);
      times.enddisplay=times.startdisplay+(PeriodSeconds(PERIOD_H1)*4)-1;
      times.start=times.startdisplay-(PeriodSeconds(PERIOD_H1)*4);
      times.start=PivotsCleanupWeeekendAndDaysGaps(PD,times.start);
      times.end=times.start+(PeriodSeconds(PERIOD_H1)*4)-1;
   }
   if(period==DAY)
   {
      houroffset=PD.Settings.dayhourstart;
      if(houroffset>12)
         houroffset=PD.Settings.dayhourstart-24;
      MqlDateTime h1time;
      TimeToStruct(PD.Settings.currenth1time,h1time);
      h1hour=h1time.hour;
      int daystart=(int)(MathFloor((h1time.hour-houroffset)/24)*24)+houroffset;
      times.startdisplay=PD.Settings.currenth1time-(PeriodSeconds(PERIOD_H1)*(h1hour-daystart));
      if(offsetindex<=2)
      {
         offsettime=PeriodSeconds(PERIOD_D1)*offsetindex;
         times.startdisplay=PivotsCleanupWeeekendAndDaysGaps(PD,times.startdisplay-offsettime);
      }
      else
      {
         offsettime=PeriodSeconds(PERIOD_D1);
         for(int index=offsetindex; index>0; index--)
            times.startdisplay=PivotsCleanupWeeekendAndDaysGaps(PD,times.startdisplay-offsettime);
      }
      times.enddisplay=times.startdisplay+(PeriodSeconds(PERIOD_H1)*24)-1;
      times.start=times.startdisplay-(PeriodSeconds(PERIOD_H1)*24);
      times.start=PivotsCleanupWeeekendAndDaysGaps(PD,times.start);
      times.end=times.start+(PeriodSeconds(PERIOD_H1)*24)-1;
   }
   if(period==WEEK)
   {
      offsettime=PeriodSeconds(PERIOD_W1)*offsetindex;
      times.startdisplay=PD.Settings.weekstarttime-offsettime;
      times.enddisplay=times.startdisplay+(PeriodSeconds(PERIOD_H1)*(24*5))-1;
      times.start=times.startdisplay-(PeriodSeconds(PERIOD_H1)*(24*7));
      times.end=times.start+(PeriodSeconds(PERIOD_H1)*(24*5))-1;
   }
   if(period==MONTH)
   {
      MqlDateTime h1time, startdisplay, enddisplay, start, temp1;
      TimeToStruct(PD.Settings.currenth1time,h1time);

      startdisplay.hour=0;
      startdisplay.min=0;
      startdisplay.sec=0;
      startdisplay.day=1;
      startdisplay.year=h1time.year;
      startdisplay.mon=h1time.mon-offsetindex;
      if(startdisplay.mon>12)
      {
         startdisplay.mon=startdisplay.mon-12;
         startdisplay.year++;
      }
      if(startdisplay.mon<1)
      {
         startdisplay.mon=12+startdisplay.mon;
         startdisplay.year--;
      }
      times.startdisplay=StructToTime(startdisplay);
      TimeToStruct(times.startdisplay,temp1);

      int weekdayempty1=PD.Settings.weekdaystart-1;
      if(weekdayempty1<0)
         weekdayempty1=7+weekdayempty1;
   
      int weekdayempty2=PD.Settings.weekdaystart-2;
      if(weekdayempty2<0)
         weekdayempty2=7+weekdayempty2;
   
      if(temp1.day_of_week==weekdayempty1)
         times.startdisplay=times.startdisplay+86400;
      if(temp1.day_of_week==weekdayempty2)
         times.startdisplay=times.startdisplay+172800;
      
      enddisplay=startdisplay;
      enddisplay.mon++;
      if(enddisplay.mon>12)
      {
         enddisplay.mon=1;
         enddisplay.year++;
      }
      times.enddisplay=StructToTime(enddisplay)-1;
      start=startdisplay;
      start.mon--;
      if(start.mon<1)
      {
         start.mon=12;
         start.year--;
      }
      times.start=StructToTime(start);
      times.end=StructToTime(startdisplay)-1;
   }
   if(period==YEAR)
   {
      MqlDateTime h1time, startdisplay, enddisplay, start;
      TimeToStruct(PD.Settings.currenth1time,h1time);

      startdisplay.hour=0;
      startdisplay.min=0;
      startdisplay.sec=0;
      startdisplay.day=1;
      startdisplay.year=h1time.year-offsetindex;
      startdisplay.mon=1;
      times.startdisplay=StructToTime(startdisplay);
      enddisplay=startdisplay;
      enddisplay.year++;
      times.enddisplay=StructToTime(enddisplay)-1;
      start=startdisplay;
      start.year--;
      times.start=StructToTime(start);
      times.end=StructToTime(startdisplay)-1;
   }

   return times;
}


string PivotsPivotPeriodToString(TypePivotsPeriod period)
{
   if(period==HOUR) return "Hour";
   if(period==FOURHOUR) return "4Hour";
   if(period==DAY) return "Day";
   if(period==WEEK) return "Week";
   if(period==MONTH) return "Month";
   if(period==YEAR) return "Year";
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


void PivotsCreateLine(TypePivotsData& PD, TypePivotsTimeRange& time, double price, color clr, string level, TypePivotsType type, ENUM_LINE_STYLE style = STYLE_DOT, int width = 1, bool rayright=false)
{
   PivotsCreateLine(PD,time,price,price,clr,level,type,style,width,rayright);
}


void PivotsCreateLine(TypePivotsData& PD, TypePivotsTimeRange& time, double price1, double price2, color clr, string level, TypePivotsType type, ENUM_LINE_STYLE style = STYLE_DOT, int width = 1, bool rayright=false)
{
   if(time.period==HOUR) style=PD.Settings.LineStyleHour;
   if(time.period==FOURHOUR) style=PD.Settings.LineStyleFourHour;
   if(time.period==DAY) style=PD.Settings.LineStyleDay;
   if(time.period==WEEK) style=PD.Settings.LineStyleWeek;
   if(time.period==MONTH) style=PD.Settings.LineStyleMonth;
   if(time.period==YEAR) style=PD.Settings.LineStyleYear;
   string objname = PD.Settings.objectnamespace + " " + PivotsPivotPeriodToString(time.period) + " " + level + " " + PivotsPivotTypeToString(type) + " " + IntegerToString(time.startdisplay);
   ObjectCreate(0,objname,OBJ_TREND,0,time.startdisplay,price1,time.enddisplay,price2);
   ObjectSetInteger(0,objname,OBJPROP_RAY_RIGHT,rayright);
   ObjectSetInteger(0,objname,OBJPROP_STYLE,style);
   ObjectSetInteger(0,objname,OBJPROP_WIDTH,width);
   ObjectSetInteger(0,objname,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,objname,OBJPROP_BACK,true);
}


void PivotsCreateRectangle(TypePivotsData& PD, TypePivotsTimeRange& time, double price1, double price2, color clr, string level, TypePivotsType type)
{
   string objname = PD.Settings.objectnamespace + " " + PivotsPivotPeriodToString(time.period) + " " + level + " " + PivotsPivotTypeToString(type) + " " + IntegerToString(time.startdisplay);
   ObjectCreate(0,objname,OBJ_RECTANGLE,0,time.startdisplay,price1,time.enddisplay,price2);
   ObjectSetInteger(0,objname,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,objname,OBJPROP_FILL,true);
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
   if(level=="TC") lv=pivots.TC;
   if(level=="BC") lv=pivots.BC;
   return lv;
}


void PivotsDeleteObjects(TypePivotsData& PD, string pivotsnamespace="")
{
   ObjectsDeleteAll(0,PD.Settings.objectnamespace + (StringLen(pivotsnamespace)==0 ? "" : " " + pivotsnamespace));
   ChartRedraw();
}
