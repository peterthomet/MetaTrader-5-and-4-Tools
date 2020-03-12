//
// Murrey Math.mqh
// getYourNet.ch
// Based on initial code by Vladislav Goshkov
//

#property strict


struct TypeMurreyMath
{
   string appnamespace;
   ENUM_TIMEFRAMES timeframe;
   double Values[13];
   double lowprice;
   double highprice;
   datetime starttime;
   datetime endtime;
   string Strings[13];
   string ToolTips[13];
   int Clolors[13];
   int Widths[13];
   int candles;
   int startcandle;
   int textshift;
   bool debug;


   TypeMurreyMath()
   {
      appnamespace="Murrey Math 1";
      timeframe=PERIOD_CURRENT;
      candles=64;
      startcandle=0;
      textshift=15;
      debug=false;

      Strings[0]="Extreme -2/8";
      Strings[1]="Overshoot -1/8";
      Strings[2]="Ultimate Support 0/8";
      Strings[3]="Stall Reverse 1/8";
      Strings[4]="Pivot Reverse 2/8";
      Strings[5]="Bottom Range 3/8";
      Strings[6]="Major SR 4/8";
      Strings[7]="Top Range 5/8";
      Strings[8]="Pivot Reverse 6/8";
      Strings[9]="Stall Reverse 7/8";
      Strings[10]="Ultimate Resistance 8/8";
      Strings[11]="Overshoot +1/8";
      Strings[12]="Extreme +2/8";
   
      ToolTips[0]="Extremely Overshoot";
      ToolTips[1]="Overshoot";
      ToolTips[2]="Ultimate Support";
      ToolTips[3]="Weak, Stall and Reverse";
      ToolTips[4]="Pivot Reverse";
      ToolTips[5]="Bottom Range";
      ToolTips[6]="Major Support/Resistance";
      ToolTips[7]="Top Range";
      ToolTips[8]="Pivot Reverse";
      ToolTips[9]="Weak, Stall and Reverse";
      ToolTips[10]="Ultimate Resistance";
      ToolTips[11]="Overshoot";
      ToolTips[12]="Extremely Overshoot";

      Clolors[0]=Black;
      Clolors[1]=Black;
      Clolors[2]=DeepSkyBlue;
      Clolors[3]=Orange;
      Clolors[4]=Red;
      Clolors[5]=Green;
      Clolors[6]=Blue;
      Clolors[7]=Green;
      Clolors[8]=Red;
      Clolors[9]=Orange;
      Clolors[10]=DeepSkyBlue;
      Clolors[11]=Black;
      Clolors[12]=Black;
   
      Widths[0]=2;
      Widths[1]=1;
      Widths[2]=1;
      Widths[3]=1;
      Widths[4]=1;
      Widths[5]=1;
      Widths[6]=1;
      Widths[7]=1;
      Widths[8]=1;
      Widths[9]=1;
      Widths[10]=1;
      Widths[11]=1;
      Widths[12]=2;
   }


   void Calculate()
   {
      int lowindex=0,highindex=0,lines=13;
   
      double dmml=0,dvtl=0,sum=0,mn=0,mx=0,
         x1=0,x2=0,x3=0,x4=0,x5=0,x6=0,y1=0,y2=0,y3=0,y4=0,y5=0,y6=0,
         octave=0,fractal=0,range=0,finalH=0,finalL=0;
  
      lowindex=iLowest(NULL,timeframe,MODE_LOW,candles,startcandle);
      highindex=iHighest(NULL,timeframe,MODE_HIGH,candles,startcandle);
      
      lowprice=iLow(NULL,timeframe,lowindex);
      highprice=iHigh(NULL,timeframe,highindex);

      starttime=iTime(NULL,timeframe,startcandle+candles);
      endtime=iTime(NULL,timeframe,startcandle)+(PeriodSeconds(timeframe)-1);
   
      if(highprice>0)
         fractal=0.1953125;
      if(highprice>0.390625)
         fractal=1.5625;
      if(highprice>1.5625)
         fractal=3.125;
      if(highprice>3.125)
         fractal=6.25;
      if(highprice>6.25)
         fractal=12.5;
      if(highprice>12.5)
         fractal=12.5;
      if(highprice>25)
         fractal=100;
      if(highprice>250)
         fractal=1000;
      if(highprice>2500)
         fractal=10000;
      if(highprice<=250000&&highprice>25000)
         fractal=100000;
         
      range=(highprice-lowprice);
      sum=MathFloor(MathLog(fractal/range)/MathLog(2));
      octave=fractal*(MathPow(0.5,sum));
      mn=MathFloor(lowprice/octave)*octave;
   
      if((mn+octave)>highprice)
         mx=mn+octave; 
      else
         mx=mn+(2*octave);
   
      if((lowprice>=(3*(mx-mn)/16+mn))&&(highprice<=(9*(mx-mn)/16+mn)))
         x2=mn+(mx-mn)/2; 
   
      if((lowprice>=(mn-(mx-mn)/8))&&(highprice<=(5*(mx-mn)/8+mn))&&(x2==0))
         x1=mn+(mx-mn)/2; 
   
      if((lowprice>=(mn+7*(mx-mn)/16))&&(highprice<=(13*(mx-mn)/16+mn)))
         x4=mn+3*(mx-mn)/4; 
   
      if((lowprice>=(mn+3*(mx-mn)/8))&&(highprice<=(9*(mx-mn)/8+mn))&&(x4==0))
         x5=mx; 
   
      if((lowprice>=(mn+(mx-mn)/8))&&(highprice<=(7*(mx-mn)/8+mn))&&(x1==0)&&(x2==0)&&(x4==0)&&(x5==0))
         x3=mn+3*(mx-mn)/4; 
   
      if((x1+x2+x3+x4+x5)==0)
         x6=mx; 
   
      finalH=x1+x2+x3+x4+x5+x6;
   
      if(x1>0)
         y1=mn; 
   
      if(x2>0)
         y2=mn+(mx-mn)/4; 
   
      if(x3>0)
         y3=mn+(mx-mn)/4; 
   
      if(x4>0)
         y4=mn+(mx-mn)/2; 
   
      if(x5>0)
         y5=mn+(mx-mn)/2; 
   
      if((finalH>0)&&((y1+y2+y3+y4+y5)==0))
         y6=mn; 
   
      finalL=y1+y2+y3+y4+y5+y6;
   
      for(int i=0;i<lines;i++)
         Values[i]=0;
            
      dmml=(finalH-finalL)/8;
   
      Values[0]=(finalL-dmml*2);
      for(int i=1;i<lines;i++)
         Values[i]=Values[i-1]+dmml;
   
   }


   void Draw(bool notext=false)
   {
      int lines=13;
      string objname="";
      string baseobjname=appnamespace+" "+IntegerToString(timeframe);

      datetime drawendwindow;
      datetime drawend=iTime(NULL,0,0)+PeriodSeconds()*textshift;
      int barsgap=(int)ChartGetInteger(0,CHART_WIDTH_IN_BARS)-(int)ChartGetInteger(0,CHART_VISIBLE_BARS);
      if(barsgap>0)
         drawendwindow=iTime(NULL,0,0)+(PeriodSeconds()*(barsgap+1));
      else
         drawendwindow=iTime(NULL,0,(int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR)-(int)ChartGetInteger(0,CHART_WIDTH_IN_BARS));
      drawend=MathMin(drawend,drawendwindow);

      for(int i=0;i<lines;i++)
      {
         objname=baseobjname+" Line "+IntegerToString(i);
         if(ObjectFind(0,objname)==-1)
         {
            ObjectCreate(0,objname,OBJ_TREND,0,0,0);
            ObjectSetInteger(0,objname,OBJPROP_STYLE,STYLE_SOLID);
            ObjectSetInteger(0,objname,OBJPROP_COLOR,Clolors[i]);
            ObjectSetInteger(0,objname,OBJPROP_WIDTH,Widths[i]);
            ObjectSetString(0,objname,OBJPROP_TOOLTIP,ToolTips[i]);
            ObjectSetInteger(0,objname,OBJPROP_BACK,true);
            ObjectSetInteger(0,objname,OBJPROP_RAY_RIGHT,false);
         }
         ObjectSetInteger(0,objname,OBJPROP_TIME,0,endtime+1);
         ObjectSetDouble(0,objname,OBJPROP_PRICE,0,Values[i]);
         ObjectSetInteger(0,objname,OBJPROP_TIME,1,drawend);
         ObjectSetDouble(0,objname,OBJPROP_PRICE,1,Values[i]);
   
         objname=baseobjname+" Text "+IntegerToString(i);
         if(ObjectFind(0,objname)==-1)
         {
            ObjectCreate(0,objname,OBJ_TEXT,0,0,0);
            ObjectSetInteger(0,objname,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
            ObjectSetInteger(0,objname,OBJPROP_COLOR,Clolors[i]);
            ObjectSetInteger(0,objname,OBJPROP_FONTSIZE,7);
            ObjectSetString(0,objname,OBJPROP_FONT,"Arial");
            string text=Strings[i];
            if(notext)
               text=" ";
            ObjectSetString(0,objname,OBJPROP_TEXT,text);
            ObjectSetString(0,objname,OBJPROP_TOOLTIP,ToolTips[i]);
         }
         ObjectSetInteger(0,objname,OBJPROP_TIME,0,drawend);
         ObjectSetDouble(0,objname,OBJPROP_PRICE,0,Values[i]);
      }

      if(debug)
      {
         ObjectsDeleteAll(0,baseobjname+" Debug");
         objname=baseobjname+" Debug Rectangle";
         ObjectCreate(0,objname,OBJ_RECTANGLE,0,starttime,lowprice,endtime,highprice);
         ObjectSetInteger(0,objname,OBJPROP_BACK,true);
         ObjectSetInteger(0,objname,OBJPROP_FILL,true);
         ObjectSetInteger(0,objname,OBJPROP_COLOR,C'248,248,248');
      }
      ChartRedraw();
   }


   void Cleanup()
   {
      ObjectsDeleteAll(0,appnamespace);
   }
};

