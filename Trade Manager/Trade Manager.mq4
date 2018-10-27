//
// Trade Manager.mq4/mq5
// getYourNet.ch
//

#property copyright "Copyright 2018, getYourNet.ch"

#ifdef __MQL4__
   #include <..\Libraries\stdlib.mq4>
#endif
#ifdef __MQL5__
   #include <Trade\Trade.mqh>
   #include <errordescription.mqh>

   enum OrderType
   {
      OP_BUY,
      OP_SELL
   };
#endif

enum TypeInstance
{
   Instance1=1,
   Instance2=2,
   Instance3=3,
   Instance4=4,
   Instance5=5,
   Instance6=6,
   Instance7=7,
   Instance8=8,
   Instance9=9
};

enum TypeStopLossPercentBalanceAction
{
   CloseWorstTrade,
   CloseAllTrades
};

input TypeInstance Instance = 1;
input double BreakEvenAfterPips = 5;
input double AboveBEPips = 1;
input double StartTrailingPips = 7;
input double StopLossPips = 0;
input bool HedgeAtStopLoss = false;
input double HedgeVolumeFactor = 1;
input double HedgeFlatAtLevel = 5;
input double StopLossPercentBalance = 0;
input TypeStopLossPercentBalanceAction StopLossPercentBalanceAction = CloseWorstTrade;
input bool ActivateTrailing = true;
input double TrailingFactor = 0.6;
input double OpenLots = 0.01;
input bool ShowInfo = true;
input color TextColor = Gray;
input color TextColorBold = Black;
input int FontSize = 9;
input int TextGap = 16;
input bool ManageOwnTradesOnly = true;
input int ManageMagicNumberOnly = 0;
input int ManageOrderNumberOnly = 0;
input bool SwitchSymbolClickAllCharts = true;
input bool DrawLevelsAllCharts = true;
input bool DrawBackgroundPanel = true;
input int BackgroundPanelWidth = 200;
input color BackgroundPanelColor = clrNONE;
input bool MT5CommissionPerDeal = true;

string appname="Trade Manager";
string namespace="";
bool working=false;
double pipsfactor;
datetime lasttick;
datetime lasterrortime;
string lasterrorstring;
bool istesting;
bool initerror;
string ExtraChars = "";
string tickchar="";
int magicnumberfloor=0;
int basemagicnumber=0;
int hedgeoffsetmagicnumber=10000;
int closeallcommand=false;
double _BreakEvenAfterPips;
double _AboveBEPips;
double _StartTrailingPips;
double _StopLossPips;
double _OpenLots;

enum BEStopModes
{
   None=1,
   HardSingle=2,
   SoftBasket=3
};

struct TypeTradeInfo
{
   int orderindex;
   int type;
   double volume;
   double openprice;
   double points;
   double gain;
   long magicnumber;
   long orderticket;
   TypeTradeInfo()
   {
      orderindex=-1;
      type=NULL;
      volume=0;
      openprice=0;
      points=0;
      gain=0;
      magicnumber=0;
      orderticket=0;
   }
};

struct TypeTradeReference
{
   long magicnumber;
   double points;
   double gain;
   TypeTradeReference()
   {
      magicnumber=0;
      points=0;
      gain=0;
   }
};

struct TypeWorkingState
{
   BEStopModes StopMode;
   bool closebasketatBE;
   bool ManualBEStopLocked;
   bool SoftBEStopLocked;
   double peakgain;
   double peakpips;
   bool TrailingActivated;
   long currentbasemagicnumber;
   TypeTradeReference tradereference[];
   double globalgain;
   void Init()
   {
      closebasketatBE=false;
      ManualBEStopLocked=false;
      SoftBEStopLocked=false;
      StopMode=SoftBasket;
      peakgain=0;
      peakpips=0;
      TrailingActivated=false;
      currentbasemagicnumber=basemagicnumber;
      ArrayResize(tradereference,0);
      globalgain=0;
   };
   void Reset()
   {
      closebasketatBE=false;
      ManualBEStopLocked=false;
      SoftBEStopLocked=false;
      peakgain=0;
      peakpips=0;
      TrailingActivated=false;
      currentbasemagicnumber=basemagicnumber;
      ArrayResize(tradereference,0);
      globalgain=0;
   };
   void ResetLocks()
   {
      ManualBEStopLocked=false;
      SoftBEStopLocked=false;
   };
};
TypeWorkingState WS;

struct TypePairsTradesInfo
{
   string pair;
   double buyvolume;
   double sellvolume;
   double gain;
   double gainpips;
   TypeTradeInfo tradeinfo[];
   TypePairsTradesInfo()
   {
      pair="";
      buyvolume=0;
      sellvolume=0;
      gain=0;
      gainpips=0;
      ArrayResize(tradeinfo,0);
   }
};

struct TypeBasketInfo
{
   double gain;
   double gainpips;
   double gainpipsglobal;
   double gainpipsplus;
   double gainpipsminus;
   double volumeplus;
   double volumeminus;
   int buys;
   int sells;
   double buyvolume;
   double sellvolume;
   int managedorders;
   TypePairsTradesInfo pairsintrades[];
   int largestlossindex;
   double largestloss;
   void Init()
   {
      gain=0;
      gainpips=0;
      gainpipsglobal=0;
      gainpipsplus=0;
      gainpipsminus=0;
      volumeplus=0;
      volumeminus=0;
      buys=0;
      sells=0;
      buyvolume=0;
      sellvolume=0;
      managedorders=0;
      ArrayResize(pairsintrades,0);
      largestlossindex=-1;
      largestloss=0;
   };
};
TypeBasketInfo BI;


void OnInit()
{
   initerror=false;
   
   namespace=appname+" "+IntegerToString(Instance)+" ";

   magicnumberfloor=10000000*Instance;

   basemagicnumber=magicnumberfloor+1;

   istesting=MQLInfoInteger(MQL_TESTER);

   ExtraChars = StringSubstr(Symbol(), 6);

   pipsfactor=1;
   
   lasttick=TimeLocal();

   if(Digits()==5||Digits()==3)
      pipsfactor=10;

   _BreakEvenAfterPips=BreakEvenAfterPips*pipsfactor;
   _AboveBEPips=AboveBEPips*pipsfactor;
   _StopLossPips=StopLossPips*pipsfactor;
   _StartTrailingPips=StartTrailingPips*pipsfactor;
   _OpenLots=OpenLots;

   WS.Init();
   
   GetGlobalVariables();

   if(DrawBackgroundPanel)
   {
      string objname=namespace+"Panel";
      ObjectCreate(0,objname,OBJ_RECTANGLE_LABEL,0,0,0,0,0);
      ObjectSetInteger(0,objname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,objname,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,objname,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,objname,OBJPROP_XDISTANCE,BackgroundPanelWidth);
      ObjectSetInteger(0,objname,OBJPROP_YDISTANCE,TextGap);
      ObjectSetInteger(0,objname,OBJPROP_XSIZE,BackgroundPanelWidth);
      ObjectSetInteger(0,objname,OBJPROP_YSIZE,10000);
      color c=(color)ChartGetInteger(0,CHART_COLOR_BACKGROUND);
      if(BackgroundPanelColor!=clrNONE)
         c=BackgroundPanelColor;
      ObjectSetInteger(0,objname,OBJPROP_COLOR,c);
      ObjectSetInteger(0,objname,OBJPROP_BGCOLOR,c);
   }
   
   if(istesting)
   {
      OpenBuy();
      OpenBuy();
      OpenBuy();
   }

   if(!istesting)
      if(!EventSetMillisecondTimer(200))
         initerror=true;
}


void OnDeinit(const int reason)
{
   EventKillTimer();
   if(!istesting)
      DeleteAllObjects();
   SetGlobalVariables();
}


void OnTick()
{
   lasttick=TimeLocal();
   Manage();
}


void OnTimer()
{
   int lastctrlspan=(int)(TimeLocal()-lastctrl);
   if(lastctrlspan>1&&ctrlon)
   {
      DeleteLevels();
      DeleteLegend();
      ctrlon=false;
   }
   Manage();
}


void Manage()
{
   if(working||initerror)
      return;
   working=true;
   if(closeallcommand)
      CloseAllInternal();
   ManageOrders();
   ManageBasket();
   DisplayText();
   working=false;
}


void SetBEClose()
{
   if(WS.globalgain<0)
   {
      WS.closebasketatBE=!WS.closebasketatBE;
   }
   if(WS.globalgain>=0)
   {
      WS.ManualBEStopLocked=!WS.ManualBEStopLocked;
   }
}


void SetSoftStopMode()
{
   if(WS.StopMode==None)
      WS.StopMode=SoftBasket;
   else if(WS.StopMode==HardSingle)
      WS.StopMode=None;
   else
      WS.StopMode=None;

   WS.ResetLocks();
      
   SetGlobalVariables();
}


void SetHardStopMode()
{
   if(WS.StopMode==None)
      WS.StopMode=HardSingle;
   else if(WS.StopMode==SoftBasket)
      WS.StopMode=None;
   else
      WS.StopMode=None;

   WS.ResetLocks();
      
   SetGlobalVariables();
}


void SetGlobalVariables()
{
   string varname;
   GlobalVariableSet(namespace+"StopMode",WS.StopMode);
   GlobalVariableSet(namespace+"peakgain",WS.peakgain);
   GlobalVariableSet(namespace+"peakpips",WS.peakpips);
   GlobalVariableSet(namespace+"OpenLots",_OpenLots);
   GlobalVariableSet(namespace+"currentbasemagicnumber",WS.currentbasemagicnumber);
   varname=namespace+"ManualBEStopLocked";
   if(WS.ManualBEStopLocked)
      GlobalVariableSet(varname,0);
   else
      GlobalVariableDel(varname);
   varname=namespace+"closebasketatBE";
   if(WS.closebasketatBE)
      GlobalVariableSet(varname,0);
   else
      GlobalVariableDel(varname);

   int asize=ArraySize(WS.tradereference);
   for(int i=0; i<asize; i++)
      GlobalVariableSet(namespace+"TradeReference"+IntegerToString(WS.tradereference[i].magicnumber),WS.tradereference[i].gain);
}


void GetGlobalVariables()
{
   string varname=namespace+"StopMode";
   if(GlobalVariableCheck(varname))
      WS.StopMode=(BEStopModes)GlobalVariableGet(varname);
   varname=namespace+"peakgain";
   if(GlobalVariableCheck(varname))
      WS.peakgain=GlobalVariableGet(varname);
   varname=namespace+"peakpips";
   if(GlobalVariableCheck(varname))
      WS.peakpips=GlobalVariableGet(varname);
   varname=namespace+"OpenLots";
   if(GlobalVariableCheck(varname))
      _OpenLots=GlobalVariableGet(varname);
   varname=namespace+"currentbasemagicnumber";
   if(GlobalVariableCheck(varname))
      WS.currentbasemagicnumber=(int)GlobalVariableGet(varname);
   varname=namespace+"ManualBEStopLocked";
   if(GlobalVariableCheck(varname))
      WS.ManualBEStopLocked=true;
   varname=namespace+"closebasketatBE";
   if(GlobalVariableCheck(varname))
      WS.closebasketatBE=true;
      
   int varcount=GlobalVariablesTotal();
   for(int i=0; i<varcount; i++)
   {
      string n=GlobalVariableName(i);
      string s=namespace+"TradeReference";
      int p=StringFind(n,s);
      if(p==0)
      {
         int asize=ArraySize(WS.tradereference);
         ArrayResize(WS.tradereference,asize+1);
         WS.tradereference[asize].magicnumber=StringToInteger(StringSubstr(n,StringLen(s)));
         WS.tradereference[asize].gain=GlobalVariableGet(n);
      }
   }
}


double GetGlobalReferencesGain()
{
   double gain=0;
   int asize=ArraySize(WS.tradereference);
   for(int i=0; i<asize; i++)
      gain+=WS.tradereference[i].gain;
   return gain;
}


void ClearGlobalReferences()
{
   GlobalVariablesDeleteAll(namespace+"TradeReference");
   GlobalVariablesDeleteAll(namespace+"currentbasemagicnumber");
}


bool IsOrderToManage()
{
   bool manage=true,
   ismagicnumber=(OrderMagicNumberX()==ManageMagicNumberOnly),
   isinternalmagicnumber=(OrderMagicNumberX()>=basemagicnumber)&&(OrderMagicNumberX()<=basemagicnumber+(hedgeoffsetmagicnumber*100)),
   isordernumber=(OrderTicketX()==ManageOrderNumberOnly);
   
   if((ManageMagicNumberOnly>0&&!ismagicnumber)||(ManageOwnTradesOnly&&ManageMagicNumberOnly==0&&!isinternalmagicnumber))
      manage=false;
   
   if(ManageOrderNumberOnly>0&&!isordernumber)
      manage=false;
   return manage;
}


void ManageOrders()
{
   int cnt, ordertotal=OrdersTotalX();

   BI.Init();

   for(cnt=ordertotal-1;cnt>=0;cnt--)
   {
      if(OrderSelectX(cnt))
      {
         if(IsOrderToManage())
         {
            double tickvalue=TickValue();
            double gain=OrderProfitNet();
            double gainpips=(gain/OrderLotsX())/tickvalue;

            TypeTradeInfo ti;
            ti.orderindex=cnt;

            BI.managedorders++;
            int pidx=AddPairsInTrades(OrderSymbolX());

            BI.pairsintrades[pidx].gainpips+=gainpips/pipsfactor;

            double BESL=0;
            bool NeedSetSL=false;
            int hedgeordertype=0;
            if(OrderTypeSell())
            {
               ti.type=OP_SELL;
               hedgeordertype=OP_BUY;
               BESL=OrderOpenPriceX()-(_AboveBEPips*Point());
               BI.sells++;
               BI.sellvolume+=OrderLotsX();
               BI.pairsintrades[pidx].sellvolume+=OrderLotsX();
               if(OrderStopLossX()==0||OrderStopLossX()>BESL)
                  NeedSetSL=true;
            }
            if(OrderTypeBuy())
            {
               ti.type=OP_BUY;
               hedgeordertype=OP_SELL;
               BESL=OrderOpenPriceX()+(_AboveBEPips*Point());
               BI.buys++;
               BI.buyvolume+=OrderLotsX();
               BI.pairsintrades[pidx].buyvolume+=OrderLotsX();
               if(OrderStopLossX()==0||OrderStopLossX()<BESL)
                  NeedSetSL=true;
            }

            BI.pairsintrades[pidx].gain+=gain;
            if(gain<0&&gain<BI.largestloss)
            {
               BI.largestlossindex=cnt;
               BI.largestloss=gain;
            }
            BI.gain+=gain;

            if(gainpips<0)
            {
               BI.gainpipsminus+=gainpips*OrderLotsX()*tickvalue;
               BI.volumeminus+=OrderLotsX()*tickvalue;
            }
            else
            {
               BI.gainpipsplus+=gainpips*OrderLotsX()*tickvalue;
               BI.volumeplus+=OrderLotsX()*tickvalue;
            }
            
            if(WS.StopMode==HardSingle&&gainpips>=_BreakEvenAfterPips&&NeedSetSL)
               SetOrderSL(BESL);

            ti.volume=OrderLotsX();
            ti.openprice=OrderOpenPriceX();
            ti.points=gainpips;
            ti.gain=gain;
            ti.magicnumber=OrderMagicNumberX();
            ti.orderticket=OrderTicketX();
            AddTrade(BI.pairsintrades[pidx].tradeinfo,ti);
         }
      }
   }
}


void ManageBasket()
{
   if(BI.managedorders==0)
   {
      WS.Reset();
      ClearGlobalReferences();
      
      if(istesting)
      {
         MathSrand((int)TimeLocal());
         bool buy=(MathRand()%2);
         buy=false;
         if(buy)
         {
            OpenBuy();
            OpenBuy();
            OpenBuy();
         }
         else
         {
            OpenSell();
            OpenSell();
            OpenSell();
         }
      }
      return;
   }

   bool closeall=false;
   
   WS.globalgain=GetGlobalReferencesGain();

   BI.gainpips=(BI.gainpipsplus+BI.gainpipsminus)/(BI.volumeplus+BI.volumeminus);
   
   BI.gainpipsglobal=0;
   if(BI.gain!=0)
      BI.gainpipsglobal=(BI.gainpips/BI.gain)*WS.globalgain;

   WS.peakpips=MathMax(BI.gainpipsglobal,WS.peakpips);
   
   WS.peakgain=MathMax(WS.globalgain,WS.peakgain);

   int size1=ArraySize(BI.pairsintrades);
   for(int i=0; i<size1; i++)
   {
      int size2=ArraySize(BI.pairsintrades[i].tradeinfo);
      for(int j=0; j<size2; j++)
      {
         TypeTradeInfo ti=BI.pairsintrades[i].tradeinfo[j];
         if(_StopLossPips>0&&(ti.points+_StopLossPips)<=0)
         {
            if(OrderSelectX(ti.orderindex)&&IsAutoTradingEnabled())
            {
               if(HedgeAtStopLoss)
               {
                  long hedgemagicnumber=GetHedgeMagicNumber(BI.pairsintrades[i].tradeinfo,ti);
                  double hedgevolume=GetHedgeVolume(BI.pairsintrades[i].tradeinfo,ti);
                  if(hedgemagicnumber>-1&&hedgevolume>0)
                  {
                     if(OpenOrder(HedgeType(ti.type),hedgevolume,hedgemagicnumber,BI.pairsintrades[i].pair+ExtraChars))
                     {
                     }
                  }
               }
               else
               {
                  if(CloseSelectedOrder())
                  {
                  }
               }
            }
         }
      }
   }

   if(StopLossPercentBalance>0)
   {
      if((BI.gain)+((AccountBalanceX()/100)*StopLossPercentBalance)<=0)
      {
         if(StopLossPercentBalanceAction==CloseWorstTrade)
         {
            if(OrderSelectX(BI.largestlossindex)&&IsAutoTradingEnabled())
            {
               if(CloseSelectedOrder())
               {
               }
            }
         }
         else if(StopLossPercentBalanceAction==CloseAllTrades)
         {
            closeall=true;
         }
      }
   }

   if(ActivateTrailing&&BI.gainpipsglobal>=_StartTrailingPips)
      WS.TrailingActivated=true;

   if(WS.TrailingActivated&&WS.globalgain<GetTrailingLimit())
      closeall=true;
   
   if(WS.closebasketatBE&&WS.globalgain>=0)
      closeall=true;

   if(WS.ManualBEStopLocked&&WS.globalgain<=0)
      closeall=true;
   
   if(WS.StopMode==SoftBasket&&_BreakEvenAfterPips>0&&WS.peakpips>=_BreakEvenAfterPips)
      WS.SoftBEStopLocked=true;   
   
   if(WS.SoftBEStopLocked&&BI.gainpipsglobal<_AboveBEPips)
      closeall=true;

   if(closeall)
      CloseAllInternal();
}


double GetTrailingLimit()
{
   return WS.peakgain*TrailingFactor;
}


void DisplayText()
{
   if(!ShowInfo)
      return;

   DeleteText();

   if(tickchar=="")
      tickchar="-";
   else
      tickchar="";

   int rowindex=0;

   if(!IsAutoTradingEnabled())
   {
      CreateLabel(rowindex,FontSize,DeepPink,tickchar+" Autotrading Disabled");
      rowindex++;
   }
   else
   {
      if(TimeLocal()-lasttick>60)
         CreateLabel(rowindex,FontSize,DeepPink,tickchar+" No Market Activity");
      else
         CreateLabel(rowindex,FontSize,MediumSeaGreen,tickchar+" Running");
      rowindex++;
   }

   string stopmodetext="";
   if(WS.StopMode==None)
      stopmodetext="No Break Even Mode";
   if(WS.StopMode==HardSingle)
      stopmodetext="Hard Single Break Even Mode";
   if(WS.StopMode==SoftBasket)
      stopmodetext="Soft Basket Break Even Mode";
   CreateLabel(rowindex,FontSize,TextColor,stopmodetext);
   rowindex++;

   CreateLabel(rowindex,FontSize,TextColor,"Balance: "+DoubleToString(AccountBalanceX(),0));
   rowindex++;
   
   CreateLabel(rowindex,FontSize,TextColor,"Free Margin: "+DoubleToString(AccountFreeMarginX(),1));
   rowindex++;

   CreateLabel(rowindex,FontSize,TextColor,"Leverage: "+IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)));
   rowindex++;

   CreateLabel(rowindex,FontSize,TextColor,"Open Volume: "+DoubleToString(_OpenLots,2));
   rowindex++;

   if(BI.managedorders!=0)
   {
      if(BI.buyvolume>0)
      {      
         CreateLabel(rowindex,FontSize,TextColor,IntegerToString(BI.buys)+" Buy: "+DoubleToString(BI.buyvolume,2));
         rowindex++;
      }
   
      if(BI.sellvolume>0)
      {
         CreateLabel(rowindex,FontSize,TextColor,IntegerToString(BI.sells)+" Sell: "+DoubleToString(BI.sellvolume,2));
         rowindex++;
      }
   
      CreateLabel(rowindex,FontSize,TextColor,"Pips: "+DoubleToString(BI.gainpipsglobal/pipsfactor,1));
      rowindex++;
   
      CreateLabel(rowindex,FontSize,TextColor,"Percent: "+DoubleToString(WS.globalgain/(AccountBalanceX()/100),1));
      rowindex++;
   
      color gaincolor=MediumSeaGreen;
      if(BI.gain<0)
         gaincolor=DeepPink;
      CreateLabel(rowindex,(int)MathFloor(FontSize*2.3),gaincolor,DoubleToString(BI.gain,2));
      rowindex++;
      rowindex++;
      
      double globalgain=NormalizeDouble(WS.globalgain,2);
      if(globalgain!=NormalizeDouble(BI.gain,2))
      {
         color closedlossescolor=MediumSeaGreen;
         double gaintotal=globalgain;
         if(gaintotal<0)
            closedlossescolor=DeepPink;
         CreateLabel(rowindex,FontSize,closedlossescolor,DoubleToString(gaintotal,2));
         rowindex++;
      }
   
      if(WS.closebasketatBE)
      {
         CreateLabel(rowindex,FontSize,DeepPink,"Close Basket at Break Even");
         rowindex++;
      }
   
      if(WS.TrailingActivated)
      {
         CreateLabel(rowindex,FontSize,MediumSeaGreen,"Trailing Activ, Current Limit: "+DoubleToString(GetTrailingLimit(),2));
         rowindex++;
      }
      else
      {
         if(WS.ManualBEStopLocked)
         {
            CreateLabel(rowindex,FontSize,MediumSeaGreen,"Manual Break Even Stop Locked");
            rowindex++;
         }
      
         if(WS.SoftBEStopLocked)
         {
            CreateLabel(rowindex,FontSize,MediumSeaGreen,"Basket Break Even Stop Locked");
            rowindex++;
         }
      }
   
      int asize=ArraySize(BI.pairsintrades);
      if(asize>0)
         rowindex++;
      for(int i=0; i<asize; i++)
      {
         color paircolor=TextColor;
         if(BI.pairsintrades[i].pair+ExtraChars==Symbol())
            paircolor=TextColorBold;
         CreateLabel(rowindex,FontSize,paircolor,BI.pairsintrades[i].pair,"-TMSymbolButton");

         string pairtext="";

         if(BI.pairsintrades[i].buyvolume>0)
            pairtext+=DoubleToString(BI.pairsintrades[i].buyvolume,2)+" Buy";
         if(BI.pairsintrades[i].sellvolume>0)
            pairtext+=" "+DoubleToString(BI.pairsintrades[i].sellvolume,2)+" Sell";

         pairtext+=" "+DoubleToString(BI.pairsintrades[i].gain,2);

         color pairstextcolor=MediumSeaGreen;
         if(BI.pairsintrades[i].gain<0)
            pairstextcolor=DeepPink;

         CreateLabel(rowindex,FontSize,pairstextcolor,pairtext,"",60);
         rowindex++;
      }
   }

   if(TimeLocal()-lasterrortime<3)
   {
      CreateLabel(rowindex,FontSize,DeepPink,lasterrorstring);
      rowindex++;
   }
   ChartRedraw();
}


void CreateLabel(int RI, int fontsize, color c, string text, string group="", int xshift=0)
{
   string objname=namespace+"Text"+IntegerToString(RI+1)+group;
   ObjectCreate(0,objname,OBJ_LABEL,0,0,0,0,0);
   ObjectSetInteger(0,objname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,objname,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,objname,OBJPROP_XDISTANCE,5+xshift);
   ObjectSetInteger(0,objname,OBJPROP_YDISTANCE,20+(TextGap*RI));
   ObjectSetInteger(0,objname,OBJPROP_COLOR,c);
   ObjectSetInteger(0,objname,OBJPROP_FONTSIZE,fontsize);
   ObjectSetString(0,objname,OBJPROP_FONT,"Arial");
   ObjectSetString(0,objname,OBJPROP_TEXT,text);
}


void DrawLevels()
{
   if(DrawLevelsAllCharts)
   {
      long chartid=ChartFirst();
      while(chartid>-1)
      {
         if(ChartSymbol(chartid)==Symbol())
            DrawLevels(chartid);
         chartid=ChartNext(chartid);
      }
   }
   else
      DrawLevels(0);
}


void DrawLevels(long chartid)
{
   //CreateLevel(chartid,namespace+"Level1",MediumSeaGreen,Bid-(AboveBEPips*Point));
   //CreateLevel(chartid,namespace+"Level2",DeepPink,Bid-(BreakEvenAfterPips*Point));
   //CreateLevel(chartid,namespace+"Level3",MediumSeaGreen,Ask+(AboveBEPips*Point));
   //CreateLevel(chartid,namespace+"Level4",DeepPink,Ask+(BreakEvenAfterPips*Point));

   if(_StopLossPips>0)
   {
      //CreateRectangle(chartid,namespace+"Rectangle1",WhiteSmoke,Ask+(StopLossPips*Point),Bid-(StopLossPips*Point));
      CreateLevel(chartid,namespace+"Level1",DeepPink,AskX()+(_StopLossPips*Point()));
      CreateLevel(chartid,namespace+"Level2",DeepPink,BidX()-(_StopLossPips*Point()));
   }

   CreateRectangle(chartid,namespace+"Rectangle10",WhiteSmoke,AskX()+(_BreakEvenAfterPips*Point()),BidX()-(_BreakEvenAfterPips*Point()));
   CreateRectangle(chartid,namespace+"Rectangle11",WhiteSmoke,AskX()+(_AboveBEPips*Point()),BidX()-(_AboveBEPips*Point()));

   ChartRedraw(chartid);
}


void CreateLevel(long chartid, string objname, color c, double price)
{
   if(ObjectFind(chartid,objname)<0)
   {
      ObjectCreate(chartid,objname,OBJ_HLINE,0,0,0);
      ObjectSetInteger(chartid,objname,OBJPROP_COLOR,c);
      ObjectSetInteger(chartid,objname,OBJPROP_WIDTH,2);
      ObjectSetInteger(chartid,objname,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(chartid,objname,OBJPROP_BACK,true);
   }
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,price);
}


void CreateRectangle(long chartid, string objname, color c, double price1, double price2)
{
   if(ObjectFind(chartid,objname)<0)
   {
      ObjectCreate(chartid,objname,OBJ_RECTANGLE,0,0,0);
      ObjectSetInteger(chartid,objname,OBJPROP_FILL,true);
      ObjectSetInteger(chartid,objname,OBJPROP_COLOR,c);
      ObjectSetInteger(chartid,objname,OBJPROP_BGCOLOR,c);
      ObjectSetInteger(chartid,objname,OBJPROP_BACK,true);
   }
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,0,price1);
   ObjectSetInteger(chartid,objname,OBJPROP_TIME,0,TimeCurrent()-4000000);
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,1,price2);
   ObjectSetInteger(chartid,objname,OBJPROP_TIME,1,TimeCurrent());
}


void DisplayLegend()
{
   CreateLegend(namespace+"Legend1",5+(int)MathFloor(TextGap*2.4),"Hotkeys: Press Ctrl plus");
   CreateLegend(namespace+"Legend2",5+(int)MathFloor(TextGap*1.6),"1 Open Buy | 3 Open Sell | 0 Close All");
   CreateLegend(namespace+"Legend3",5+(int)MathFloor(TextGap*0.8),"5 Hard SL | 6 Soft SL | 8 Close at BE");
   CreateLegend(namespace+"Legend4",5+(int)MathFloor(TextGap*0),"; Decrease Volume | : Increase Volume");
}


void CreateLegend(string objname, int y, string text)
{
   ObjectCreate(0,objname,OBJ_LABEL,0,0,0,0,0);
   ObjectSetInteger(0,objname,OBJPROP_CORNER,CORNER_RIGHT_LOWER);
   ObjectSetInteger(0,objname,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);
   ObjectSetInteger(0,objname,OBJPROP_XDISTANCE,5);
   ObjectSetInteger(0,objname,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,objname,OBJPROP_COLOR,TextColor);
   ObjectSetInteger(0,objname,OBJPROP_FONTSIZE,(int)MathFloor(FontSize*0.8));
   ObjectSetString(0,objname,OBJPROP_FONT,"Arial");
   ObjectSetString(0,objname,OBJPROP_TEXT,text);
}


void DeleteLegend()
{
   ObjectsDeleteAll(0,namespace+"Legend");
}


void DeleteLevels()
{
   if(DrawLevelsAllCharts)
   {
      long chartid=ChartFirst();
      while(chartid>-1)
      {
         if(ChartSymbol(chartid)==Symbol())
         {
            ObjectsDeleteAll(chartid,namespace+"Level");
            ObjectsDeleteAll(chartid,namespace+"Rectangle");
         }
         chartid=ChartNext(chartid);
      }
   }
   else
      ObjectsDeleteAll(0,namespace+"Level");
}


void DeleteText()
{
   ObjectsDeleteAll(0,namespace+"Text");
}


void DeleteAllObjects()
{
   ObjectsDeleteAll(0,namespace);
}


long GetHedgeLevel(long mn)
{
   long t1=mn-magicnumberfloor;
   return (long)MathFloor(t1/hedgeoffsetmagicnumber);
}


long GetMagicNumberFraction(long mn)
{
   long t1=mn-magicnumberfloor;
   long t2=(long)MathFloor(t1/hedgeoffsetmagicnumber);
   long t3=t1-(hedgeoffsetmagicnumber*t2);
   if(t3<0)
      t3=0;
   return t3;
}


double GetHedgeVolume(TypeTradeInfo& tradeinfo[], TypeTradeInfo& tiin)
{
   double ret=0;
   long mn=GetMagicNumberFraction(tiin.magicnumber);
   double sells=0, buys=0, factor=HedgeVolumeFactor;
   long hedgelevel=GetHedgeLevel(tiin.magicnumber);
   if(hedgelevel>=(HedgeFlatAtLevel-1))
      factor=1;
   int size=ArraySize(tradeinfo);
   for(int i=0; i<size; i++)
   {
      if(GetMagicNumberFraction(tradeinfo[i].magicnumber)==mn)
      {
         if(tradeinfo[i].type==OP_BUY)
            buys+=tradeinfo[i].volume;
         if(tradeinfo[i].type==OP_SELL)
            sells+=tradeinfo[i].volume;
      }
   }
   if(tiin.type==OP_BUY)
      ret=(buys*factor)-sells;
   if(tiin.type==OP_SELL)
      ret=(sells*factor)-buys;
   return ret;
}


long GetHedgeMagicNumber(TypeTradeInfo& tradeinfo[], TypeTradeInfo& tiin)
{
   long r=tiin.magicnumber+hedgeoffsetmagicnumber;
   if(TradeReferenceExists(r))
      r=-1;
   return r;
}


int HedgeType(int type)
{
   if(type==OP_BUY)
      return OP_SELL;
   if(type==OP_SELL)
      return OP_BUY;
   return -1;
}


bool OpenOrder(int type, double volume=NULL, long magicnumber=NULL, string symbol=NULL)
{
   if(type==OP_BUY)
      return OpenBuy(volume,magicnumber,symbol);
   if(type==OP_SELL)
      return OpenSell(volume,magicnumber,symbol);
   return false;
}


bool OpenBuy(double volume=NULL, long magicnumber=NULL, string symbol=NULL)
{
   double v=_OpenLots;
   if(volume!=NULL)
      v=volume;
   long m=WS.currentbasemagicnumber;
   if(magicnumber!=NULL)
      m=magicnumber;
   string s=Symbol();
   if(symbol!=NULL)
      s=symbol;
   string c=namespace+IntegerToString(m);
#ifdef __MQL4__
   int ret=OrderSend(s,OP_BUY,v,AskX(s),5,0,0,c,m);
   if(ret>-1&&magicnumber==NULL)
      WS.currentbasemagicnumber++;
   SetLastError(ret);
   return (ret>-1);
#endif
#ifdef __MQL5__
   CTrade trade;
   trade.SetExpertMagicNumber(m);
   bool ret=trade.PositionOpen(s,ORDER_TYPE_BUY,v,AskX(s),NULL,NULL,c);
   if(ret&&magicnumber==NULL)
      WS.currentbasemagicnumber++;
   SetLastErrorBool(ret);
   return ret;
#endif
}


bool OpenSell(double volume=NULL, long magicnumber=NULL, string symbol=NULL)
{
   double v=_OpenLots;
   if(volume!=NULL)
      v=volume;
   long m=WS.currentbasemagicnumber;
   if(magicnumber!=NULL)
      m=magicnumber;
   string s=Symbol();
   if(symbol!=NULL)
      s=symbol;
   string c=namespace+IntegerToString(m);
#ifdef __MQL4__
   int ret=OrderSend(s,OP_SELL,v,BidX(s),5,0,0,c,m);
   if(ret>-1&&magicnumber==NULL)
      WS.currentbasemagicnumber++;
   SetLastError(ret);
   return (ret>-1);
#endif
#ifdef __MQL5__
   CTrade trade;
   trade.SetExpertMagicNumber(m);
   bool ret=trade.PositionOpen(s,ORDER_TYPE_SELL,v,BidX(s),NULL,NULL,c);
   if(ret&&magicnumber==NULL)
      WS.currentbasemagicnumber++;
   SetLastErrorBool(ret);
   return ret;
#endif
}


void AddTradeReference(TypeTradeInfo& tiin)
{
   int asize=ArraySize(WS.tradereference);
   bool found=false;
   for(int i=0; i<asize; i++)
   {
      if(WS.tradereference[i].magicnumber==tiin.magicnumber)
      {
         found=true;
         WS.tradereference[i].gain=tiin.gain;
         WS.tradereference[i].points=tiin.points;
         break;
      }
   }
   if(!found)
   {
      ArrayResize(WS.tradereference,asize+1);
      WS.tradereference[asize].magicnumber=tiin.magicnumber;
      WS.tradereference[asize].gain=tiin.gain;
      WS.tradereference[asize].points=tiin.points;
   }
}


bool TradeReferenceExists(long magicnumber)
{
   int asize=ArraySize(WS.tradereference);
   bool found=false;
   for(int i=0; i<asize; i++)
   {
      if(WS.tradereference[i].magicnumber==magicnumber)
      {
         found=true;
         break;
      }
   }
   return found;
}


void AddTrade(TypeTradeInfo& ti[], TypeTradeInfo& tiin)
{
   AddTradeReference(tiin);

   int asize=ArraySize(ti);
   ArrayResize(ti,asize+1);
   ti[asize].orderindex=tiin.orderindex;
   ti[asize].type=tiin.type;
   ti[asize].volume=tiin.volume;
   ti[asize].openprice=tiin.openprice;
   ti[asize].points=tiin.points;
   ti[asize].gain=tiin.gain;
   ti[asize].magicnumber=tiin.magicnumber;
   ti[asize].orderticket=tiin.orderticket;
}


int AddPairsInTrades(string tradedsymbol)
{
   int asize=ArraySize(BI.pairsintrades), idx=-1;
   string symbol=StringSubstr(tradedsymbol,0,6);
   bool found=false;
   for(int i=0; i<asize; i++)
   {
      if(BI.pairsintrades[i].pair==symbol)
      {
         found=true;
         idx=i;
         break;
      }
   }
   if(!found)
   {
      ArrayResize(BI.pairsintrades,asize+1);
      BI.pairsintrades[asize].pair=symbol;
      idx=asize;
   }
   return idx;
}


void CloseAllInternal()
{
   int total=OrdersTotalX();
   int cnt=0, delcnt=0;
#ifdef __MQL4__
   RefreshRates();
#endif
   for(cnt=total-1;cnt>=0;cnt--)
   {
      if(OrderSelectX(cnt))
         if(IsOrderToManage())
            if(CloseSelectedOrder())
               delcnt++;
   }
   if(delcnt>0)
      DeleteText();
   closeallcommand=false;
}


bool CloseSelectedOrder()
{
   bool ret;
#ifdef __MQL4__
   if(OrderType()==OP_BUY)
      ret=OrderClose(OrderTicketX(),OrderLotsX(),MarketInfo(OrderSymbolX(),MODE_BID),5);
   if(OrderType()==OP_SELL) 
      ret=OrderClose(OrderTicketX(),OrderLotsX(),MarketInfo(OrderSymbolX(),MODE_ASK),5);
   if(OrderType()>OP_SELL)
      ret=OrderDelete(OrderTicketX());
   SetLastErrorBool(ret);
#endif
#ifdef __MQL5__
   CTrade trade;
   ret=trade.PositionClose(OrderTicketX());
   SetLastErrorBool(ret);
#endif
   return ret;
}


bool IsAutoTradingEnabled()
{
   return AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)
         &&AccountInfoInteger(ACCOUNT_TRADE_EXPERT)
         &&TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)
         &&MQLInfoInteger(MQL_TRADE_ALLOWED);
}


static datetime lastctrl=0;
static bool ctrlon=false;
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(sparam,"-TMSymbolButton")>-1)
         SwitchSymbol(ObjectGetString(0,sparam,OBJPROP_TEXT));
   }
   
   if(id==CHARTEVENT_KEYDOWN)
   {
      if(lparam==17)
      {
         lastctrl=TimeLocal();
         DrawLevels();
         DisplayLegend();
         ctrlon=true;
      }
      if(TimeLocal()-lastctrl<2)
      {
         lastctrl=TimeLocal();
         if (lparam == 49)
            OpenBuy();
         if (lparam == 51)
            OpenSell();
         if (lparam == 48)
            closeallcommand=true;
         if (lparam == 56)
            SetBEClose();
         if (lparam == 54)
            SetSoftStopMode();
         if (lparam == 53)
            SetHardStopMode();
         if (lparam == 188)
            _OpenLots=MathMax(_OpenLots-0.01,0.01);
         if (lparam == 190)
            _OpenLots+=0.01;
      }
   }
}


void SwitchSymbol(string tosymbol)
{
   if(istesting)
      return;
   string currentsymbol=StringSubstr(ChartSymbol(),0,6);
   if(currentsymbol!=tosymbol)
   {
      if(SwitchSymbolClickAllCharts)
      {
         long chartid=ChartFirst();
         while(chartid>-1)
         {
            if(chartid!=ChartID())
               ChartSetSymbolPeriod(chartid,tosymbol+ExtraChars,ChartPeriod(chartid));
            chartid=ChartNext(chartid);
         }
      }
      ChartSetSymbolPeriod(0,tosymbol+ExtraChars,0);
   }
}


void SetLastErrorBool(bool result)
{
   if(!result)
      SetLastError(-1);
}


void SetLastError(int result)
{
   if(result>-1)
      return;
   lasterrortime=TimeLocal();
   lasterrorstring="Went wrong, "+ErrorDescription(GetLastError());
}


long OrderMagicNumberX()
{
#ifdef __MQL4__
   return OrderMagicNumber();
#endif
#ifdef __MQL5__
   return PositionGetInteger(POSITION_MAGIC);
#endif
}


long OrderTicketX()
{
#ifdef __MQL4__
   return OrderTicket();
#endif
#ifdef __MQL5__
   return PositionGetInteger(POSITION_TICKET);
#endif
}


int OrdersTotalX()
{
#ifdef __MQL4__
   return OrdersTotal();
#endif
#ifdef __MQL5__
   return PositionsTotal();
#endif
}


bool OrderSelectX(int index)
{
#ifdef __MQL4__
   return OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
#endif
#ifdef __MQL5__
   return (StringLen(PositionGetSymbol(index))>0);
#endif
}


string OrderSymbolX()
{
#ifdef __MQL4__
   return OrderSymbol();
#endif
#ifdef __MQL5__
   return PositionGetString(POSITION_SYMBOL);
#endif
}


double TickValue()
{
#ifdef __MQL4__
   return MarketInfo(OrderSymbolX(),MODE_TICKVALUE);
#endif
#ifdef __MQL5__
   return SymbolInfoDouble(OrderSymbolX(),SYMBOL_TRADE_TICK_VALUE);
#endif
}


double OrderProfitNet()
{
#ifdef __MQL4__
   return OrderProfit()+OrderCommission()+OrderSwap();
#endif
#ifdef __MQL5__
   double commission=0;
   if(HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER)))
   {
      ulong Ticket=0;
      int dealscount=HistoryDealsTotal();
      for(int i=0;i<dealscount;i++)
      {
         ulong TicketDeal=HistoryDealGetTicket(i);
         if(TicketDeal>0)
         {
            if(HistoryDealGetInteger(TicketDeal,DEAL_ENTRY)==DEAL_ENTRY_IN)
            {
               Ticket=TicketDeal;
               break;
            }
         }
      }
      if(Ticket>0)
      {
         double LotsIn=HistoryDealGetDouble(Ticket,DEAL_VOLUME);
         if(LotsIn>0)
            commission=HistoryDealGetDouble(Ticket,DEAL_COMMISSION)*PositionGetDouble(POSITION_VOLUME)/LotsIn;
         if(MT5CommissionPerDeal)
            commission=commission*2;
      }
   }
   return PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+commission;
#endif
}


double OrderLotsX()
{
#ifdef __MQL4__
   return OrderLots();
#endif
#ifdef __MQL5__
   return PositionGetDouble(POSITION_VOLUME);
#endif
}


bool OrderTypeBuy()
{
#ifdef __MQL4__
   return (OrderType()==OP_BUY);
#endif
#ifdef __MQL5__
   return (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
#endif
}


bool OrderTypeSell()
{
#ifdef __MQL4__
   return (OrderType()==OP_SELL);
#endif
#ifdef __MQL5__
   return (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL);
#endif
}


double OrderOpenPriceX()
{
#ifdef __MQL4__
   return OrderOpenPrice();
#endif
#ifdef __MQL5__
   return PositionGetDouble(POSITION_PRICE_OPEN);
#endif
}


double OrderStopLossX()
{
#ifdef __MQL4__
   return OrderStopLoss();
#endif
#ifdef __MQL5__
   return PositionGetDouble(POSITION_SL);
#endif
}


double OrderTakeProfitX()
{
#ifdef __MQL4__
   return OrderTakeProfit();
#endif
#ifdef __MQL5__
   return PositionGetDouble(POSITION_TP);
#endif
}

double AccountBalanceX()
{
#ifdef __MQL4__
   return AccountBalance();
#endif
#ifdef __MQL5__
   return AccountInfoDouble(ACCOUNT_BALANCE);
#endif
}


double AccountFreeMarginX()
{
#ifdef __MQL4__
   return AccountFreeMargin();
#endif
#ifdef __MQL5__
   return AccountInfoDouble(ACCOUNT_MARGIN_FREE);
#endif
}


double AskX(string symbol=NULL)
{
   string s=Symbol();
   if(symbol!=NULL)
      s=symbol;
#ifdef __MQL4__
   return Ask;
#endif
#ifdef __MQL5__
   MqlTick last_tick;
   SymbolInfoTick(s,last_tick);
   return last_tick.ask;
#endif
}


double BidX(string symbol=NULL)
{
   string s=Symbol();
   if(symbol!=NULL)
      s=symbol;
#ifdef __MQL4__
   return Bid;
#endif
#ifdef __MQL5__
   MqlTick last_tick;
   SymbolInfoTick(s,last_tick);
   return last_tick.bid;
#endif
}


void SetOrderSL(double sl)
{
#ifdef __MQL4__
   SetLastErrorBool(OrderModify(OrderTicketX(),OrderOpenPriceX(),sl,OrderTakeProfitX(),0));
#endif
#ifdef __MQL5__
   CTrade trade;
   SetLastErrorBool(trade.PositionModify(OrderTicketX(),sl,OrderTakeProfitX()));
#endif
}
