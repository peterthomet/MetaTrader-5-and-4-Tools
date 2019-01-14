//
// CurrencyStrength.mqh
// getYourNet.ch
//

#property strict

enum CS_Prices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};

struct TypeCurrency
{
   string name;
   double index[];
};

struct TypeTrade
{
   string name;
   bool buy;
};

struct TypeCurrencies
{
   TypeCurrency Currency[8];
   double LastValues[8][2];
   TypeTrade Trade[4];
   TypeCurrencies()
   {
      Currency[0].name="USD";
      Currency[1].name="EUR";
      Currency[2].name="GBP";
      Currency[3].name="JPY";
      Currency[4].name="CHF";
      Currency[5].name="CAD";
      Currency[6].name="AUD";
      Currency[7].name="NZD";
   }
   int GetValueIndex(int row)
   {
      int idx;
      for(idx=0; idx<8; idx++)
         if(LastValues[idx][1]==row)
            break;
      return idx;
   }
};

struct TypePair
{
   string name;
   MqlRates rates[];
};

struct TypePairs
{
   TypePair Pair[28];
   bool anytimechanged;
   datetime maxtime;
   TypePairs()
   {
      Pair[0].name="EURUSD";
      Pair[1].name="GBPUSD";
      Pair[2].name="USDCHF";
      Pair[3].name="USDJPY";
      Pair[4].name="USDCAD";
      Pair[5].name="AUDUSD";
      Pair[6].name="NZDUSD";
      Pair[7].name="EURNZD";
      Pair[8].name="EURCAD";
      Pair[9].name="EURAUD";
      Pair[10].name="EURJPY";
      Pair[11].name="EURCHF";
      Pair[12].name="EURGBP";
      Pair[13].name="GBPNZD";
      Pair[14].name="GBPAUD";
      Pair[15].name="GBPCAD";
      Pair[16].name="GBPJPY";
      Pair[17].name="GBPCHF";
      Pair[18].name="CADJPY";
      Pair[19].name="CADCHF";
      Pair[20].name="AUDCAD";
      Pair[21].name="NZDCAD";
      Pair[22].name="AUDCHF";
      Pair[23].name="AUDJPY";
      Pair[24].name="AUDNZD";
      Pair[25].name="NZDJPY";
      Pair[26].name="NZDCHF";
      Pair[27].name="CHFJPY";
   }
   string NormalizePairing(string pair)
   {
      string p=pair;
      for(int i=0; i<28; i++)
      {
         if(StringSubstr(p,3,3)+StringSubstr(p,0,3)==Pair[i].name)
         {
            p=Pair[i].name;
            break;
         }
      }
      return p;
   }
};

struct TypeCurrencyStrength
{
   ENUM_TIMEFRAMES timeframe;
   int bars;
   int start;
   int offset;
   string extrachars;
   CS_Prices pricetype;
   bool recalculate;
   bool currentpairsonly;
   int syncmasterindex;
   TypeCurrencies Currencies;
   TypePairs Pairs;
   TypeCurrencyStrength()
   {
      timeframe=PERIOD_CURRENT;
      bars=10;
      start=0;
      offset=0;
      extrachars=StringSubstr(Symbol(),6);
      pricetype=pr_close;
      recalculate=false;
      currentpairsonly=false;
      syncmasterindex=0;
      string thissymbol=StringSubstr(Symbol(),0,6);
      for(int i=0; i<28; i++)
      {
         if(Pairs.Pair[i].name==thissymbol)
         {
            syncmasterindex=i;
            break;
         }
      }
   }
   void Init(int _Bars, int Zero, string ExtraChars, ENUM_TIMEFRAMES TimeFrameCustom, bool CurrentPairsOnly, CS_Prices _PriceType)
   {
      bars=_Bars;
      for(int i=0; i<8; i++)
         ArrayResize(Currencies.Currency[i].index,bars);

      if(Zero<bars&&Zero>=0)
         start=(bars-1)-Zero;

      extrachars=ExtraChars;
      
      timeframe=TimeFrameCustom;
      
      currentpairsonly=CurrentPairsOnly;
      
      pricetype=_PriceType;
   }
   bool IncludePair(string pair)
   {
      if(!currentpairsonly)
         return true;
      return IncludeCurrency(StringSubstr(pair,0,3)) || IncludeCurrency(StringSubstr(pair,3,3));
   }
   bool IncludeCurrency(string currency)
   {
      if(!currentpairsonly)
         return true;
      return StringFind(Symbol(),currency,0)!=-1;
   }
};


bool CS_CalculateIndex(TypeCurrencyStrength& cs, int Offset=0)
{
   int limit=cs.bars;

   cs.Pairs.anytimechanged=false;
   cs.Pairs.maxtime=0;

   if(cs.offset!=Offset)
   {
      cs.offset=Offset;
      cs.recalculate=true;
   }

   bool failed=false;
   for(int i=0; i<28; i++)
   {
      if(!CS_GetRates(cs.Pairs.Pair[i],cs))
         failed=true;
   }
   if(failed)
      return(false);

   if(cs.Pairs.anytimechanged||cs.recalculate)
      limit=cs.bars;
   else
      limit=1;

   for(int y=cs.bars-limit;y<cs.bars;y++)
   {
      for(int z=0; z<8; z++)
      {
         string cn=cs.Currencies.Currency[z].name;
         if(cs.IncludeCurrency(cn))
         {
            cs.Currencies.Currency[z].index[y]=0;
            if(y!=cs.start)
            {
               for(int x=0; x<28; x++)
               {
                  bool isbase=(StringSubstr(cs.Pairs.Pair[x].name,0,3)==cn);
                  bool isquote=(StringSubstr(cs.Pairs.Pair[x].name,3,3)==cn);
                  if(isbase||isquote)
                  {
                     int firstgap=(int)(cs.Pairs.maxtime-cs.Pairs.Pair[x].rates[cs.bars-1].time);
                     int shift=(firstgap/PeriodSeconds(cs.timeframe));

                     if((y+shift)>(cs.bars-1))
                        shift=(cs.bars-1)-y;
// ??????????
if(cs.offset>0)
   shift=0;
                     double pi=CS_GetPrice(cs.pricetype,cs.Pairs.Pair[x].rates,y+shift);
                     double ps=CS_GetPrice(cs.pricetype,cs.Pairs.Pair[x].rates,cs.start+shift);
                     if(isbase)
                        cs.Currencies.Currency[z].index[y]+=(pi-ps)/ps*100;
                     if(isquote)
                        cs.Currencies.Currency[z].index[y]-=(pi-ps)/ps*100;
                  }
               }
               cs.Currencies.Currency[z].index[y]=cs.Currencies.Currency[z].index[y]/7;
            }
            if(y==(cs.bars-1))
            {
               cs.Currencies.LastValues[z][0]=cs.Currencies.Currency[z].index[y]-cs.Currencies.Currency[z].index[y-1];
               cs.Currencies.LastValues[z][1]=z+1;
            }
#ifdef CS_INDICATOR_MODE
            int ti=((cs.bars-1)-y)+cs.offset;
            double va=cs.Currencies.Currency[z].index[y]+1000;
            if(cn=="USD") USDplot[ti]=va;
            if(cn=="EUR") EURplot[ti]=va;
            if(cn=="GBP") GBPplot[ti]=va;
            if(cn=="CHF") CHFplot[ti]=va;
            if(cn=="JPY") JPYplot[ti]=va;
            if(cn=="CAD") CADplot[ti]=va;
            if(cn=="AUD") AUDplot[ti]=va;
            if(cn=="NZD") NZDplot[ti]=va;
#endif
         }
      }
   }
   
   ArraySort(cs.Currencies.LastValues);

   string s1=cs.Currencies.Currency[((int)cs.Currencies.LastValues[7][1])-1].name;
   string s2=cs.Currencies.Currency[((int)cs.Currencies.LastValues[6][1])-1].name;
   string w1=cs.Currencies.Currency[((int)cs.Currencies.LastValues[0][1])-1].name;
   string w2=cs.Currencies.Currency[((int)cs.Currencies.LastValues[1][1])-1].name;

   string pair;

   pair=cs.Pairs.NormalizePairing(s1+w1);
   cs.Currencies.Trade[0].name=pair;
   cs.Currencies.Trade[0].buy=StringFind(pair,s1)==0;

   pair=cs.Pairs.NormalizePairing(s1+w2);
   cs.Currencies.Trade[1].name=pair;
   cs.Currencies.Trade[1].buy=StringFind(pair,s1)==0;

   pair=cs.Pairs.NormalizePairing(s2+w1);
   cs.Currencies.Trade[2].name=pair;
   cs.Currencies.Trade[2].buy=StringFind(pair,s2)==0;

   pair=cs.Pairs.NormalizePairing(s2+w2);
   cs.Currencies.Trade[3].name=pair;
   cs.Currencies.Trade[3].buy=StringFind(pair,s2)==0;

   cs.recalculate=false;

   return(true);
}


bool CS_GetRates(TypePair& p, TypeCurrencyStrength& cs)
{
   if(!cs.IncludePair(p.name))
      return true;
   bool ret = true;
   int copied;
   int rcount=ArraySize(p.rates);
   datetime newesttime=0;
   datetime oldesttime=0;
   if(rcount<cs.bars)
   {
      cs.Pairs.anytimechanged=true;
   }
   else
   {
      oldesttime=p.rates[0].time;
      newesttime=p.rates[cs.bars-1].time;
      //Print(p.name+" "+TimeToString(oldesttime));
   }
   
   copied=CopyRates(p.name+cs.extrachars,cs.timeframe,cs.offset,cs.bars,p.rates);
   if(copied<cs.bars)
   {
#ifdef CS_INDICATOR_MODE
      WriteComment("Loading... "+p.name);
#endif
      ret=false;
   }
   else
   {
      if(p.rates[0].time!=oldesttime || p.rates[cs.bars-1].time!=newesttime)
         cs.Pairs.anytimechanged=true;

      cs.Pairs.maxtime=MathMax(cs.Pairs.maxtime,p.rates[cs.bars-1].time);
   
#ifdef CS_INDICATOR_MODE
      CheckTrade(p.name,p.rates,copied);
#endif
   }
   return ret;
}


double CS_GetPrice(int tprice, MqlRates& rates[], int i)
{
  if (tprice>=pr_haclose)
   {
      int ratessize = ArraySize(rates);
         
         double haOpen;
         if (i>0)
                haOpen  = (rates[i-1].open + rates[i-1].close)/2.0;
         else   haOpen  = (rates[i].open+rates[i].close)/2;
         double haClose = (rates[i].open + rates[i].high + rates[i].low + rates[i].close) / 4.0;
         double haHigh  = MathMax(rates[i].high, MathMax(haOpen,haClose));
         double haLow   = MathMin(rates[i].low , MathMin(haOpen,haClose));

         rates[i].open=haOpen;
         rates[i].close=haClose;

         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   switch (tprice)
   {
      case pr_close:     return(rates[i].close);
      case pr_open:      return(rates[i].open);
      case pr_high:      return(rates[i].high);
      case pr_low:       return(rates[i].low);
      case pr_median:    return((rates[i].high+rates[i].low)/2.0);
      case pr_medianb:   return((rates[i].open+rates[i].close)/2.0);
      case pr_typical:   return((rates[i].high+rates[i].low+rates[i].close)/3.0);
      case pr_weighted:  return((rates[i].high+rates[i].low+rates[i].close+rates[i].close)/4.0);
      case pr_average:   return((rates[i].high+rates[i].low+rates[i].close+rates[i].open)/4.0);
      case pr_tbiased:   
               if (rates[i].close>rates[i].open)
                     return((rates[i].high+rates[i].close)/2.0);
               else  return((rates[i].low+rates[i].close)/2.0);        
      case pr_tbiased2:   
               if (rates[i].close>rates[i].open) return(rates[i].high);
               if (rates[i].close<rates[i].open) return(rates[i].low);
                                     return(rates[i].close);        
   }
   return(0);
}


