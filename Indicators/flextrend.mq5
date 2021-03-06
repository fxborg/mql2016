//+------------------------------------------------------------------+
//|                                                    flextrend.mq5 |
//| flextrend v1.00                           Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <MovingAverages.mqh>
#property indicator_buffers 16
#property indicator_plots 1

#property indicator_minimum -21
#property indicator_maximum 21
#property indicator_level1 10
#property indicator_level2 -10

#property indicator_separate_window

#property indicator_type1 DRAW_COLOR_HISTOGRAM
#property indicator_color1 clrDodgerBlue,clrRed
#property indicator_width1 2




input double InpStep1Factor =1.2; //Step Size
input int    InpStep1Period =10;  //Smoothing
input int    InpEmaPeriod =128;   //EMA Period
int SDPeriod=36;
double FastAlpha=2.0/(InpStep1Period+1.0);
double SlowAlpha=2.0/(InpEmaPeriod+1.0);
double SDAlpha=2.0/(SDPeriod+1.0);

int AtrPeriod=100;      // ATR Period
double AtrAlpha=2.0/(AtrPeriod+1.0);
double Size1=1.0;
double Size2=1.25;
double Size3=1.5;
double Size4=1.75;
double Size5=2.0;
double Size6=2.25;

//--- input parameters
double ATR[];
double TREND[];
double CLR[];
double RET[];
double RETMA[];
double VAR[];
double SD[];

double SLOWMA[];
double SLOW[];
double SLOW1[];
double SLOW2[];
double SLOW3[];
double SLOW4[];
double SLOW5[];
double SLOW6[];

double FASTMA[];
double FASTMA2[];
double FAST[];
double FAST1[];
double FAST2[];
double FAST3[];
double FAST4[];
double FAST5[];
double FAST6[];


int min_rates_total=2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//---- Initialization of variables of data calculation starting point

//--- indicator buffers
   int i=0;
   SetIndexBuffer(i++,TREND,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,FASTMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SLOWMA,INDICATOR_CALCULATIONS);
 

   SetIndexBuffer(i++,FAST,INDICATOR_CALCULATIONS);

   SetIndexBuffer(i++,FAST1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST5,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST6,INDICATOR_CALCULATIONS);

   SetIndexBuffer(i++,ATR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,RET,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,RETMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,VAR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SD,INDICATOR_CALCULATIONS);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int first;
   if(rates_total<=min_rates_total)
      return(0);
//---
//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first<prev_calculated) first=prev_calculated-1;

   for(int i=first;i<rates_total && !IsStopped();i++)
     {

      TREND[i]=EMPTY_VALUE;
      CLR[i]=EMPTY_VALUE;
      RET[i]=EMPTY_VALUE;
      RETMA[i]=EMPTY_VALUE;
      VAR[i]=EMPTY_VALUE;
      SD[i]=EMPTY_VALUE;
      ATR[i]=EMPTY_VALUE;
      FAST[i]=EMPTY_VALUE;

      FASTMA[i]=EMPTY_VALUE;
      SLOWMA[i]=EMPTY_VALUE;

      FAST1[i]=EMPTY_VALUE;
      FAST2[i]=EMPTY_VALUE;
      FAST3[i]=EMPTY_VALUE;
      FAST4[i]=EMPTY_VALUE;
      FAST5[i]=EMPTY_VALUE;
      FAST6[i]=EMPTY_VALUE;

      double atr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      ATR[i]=atr;
      RET[i]=close[i]-close[i-1];
      if(i==begin_pos)continue;
      RETMA[i]=SDAlpha*RET[i]+(1-SDAlpha)*RETMA[i-1];
      atr=fmax(ATR[i-1]*0.667,fmin(atr,ATR[i-1]*1.333));
      ATR[i]=AtrAlpha*atr+(1-AtrAlpha)*ATR[i-1];
      double price=(close[i]+high[i]+low[i])/3;

      //--- 
      iStepMa(FAST1,price,ATR[i]*Size1*InpStep1Factor,i);
      iStepMa(FAST2,price,ATR[i]*Size2*InpStep1Factor,i);
      iStepMa(FAST3,price,ATR[i]*Size3*InpStep1Factor,i);
      iStepMa(FAST4,price,ATR[i]*Size4*InpStep1Factor,i);
      iStepMa(FAST5,price,ATR[i]*Size5*InpStep1Factor,i);
      iStepMa(FAST6,price,ATR[i]*Size6*InpStep1Factor,i);
      FAST[i]=(FAST1[i]+FAST2[i]+FAST3[i]+FAST4[i]+FAST5[i]+FAST6[i])/6.0;

      //--- 
      
      if(i<=begin_pos+1)
      {
         FASTMA[i]=FAST[i];
         SLOWMA[i]=close[i];
         TREND[i]=0;
         continue;
      }
   
      FASTMA[i]=FastAlpha*FAST[i]+(1-FastAlpha)*FASTMA[i-1];
      SLOWMA[i]=SlowAlpha*close[i]+(1-SlowAlpha)*SLOWMA[i-1];
      TREND[i]=fmin(20,fmax(-20,2.8*(FASTMA[i]-SLOWMA[i])/ATR[i]));
      CLR[i]=TREND[i]>=0 ? 0:1;
    }
//----

   return(rates_total);
  }
//+------------------------------------------------------------------+
void iStepMa(double &step[],const double price,const double size,const int i)
  {
   if((price-size)>step[i-1]) step[i]=price-size;
   else if((price+size)<step[i-1]) step[i]=price+size;
   else step[i]=step[i-1];

  }
//+------------------------------------------------------------------+
