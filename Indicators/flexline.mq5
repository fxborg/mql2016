//+------------------------------------------------------------------+
//|                                                     flexline.mq5 |
//| flexline v1.00                            Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 9
#property indicator_plots 1


#property indicator_chart_window

#property indicator_type1 DRAW_LINE
#property indicator_color1 clrRed
#property indicator_width1 2





input double InpStepSize = 1.2; //Step Size
input int    InpSmoothing =10;  //Smoothing
double Alpha=2.0/(InpSmoothing+1.0);


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

double FLEX[];
double STEP[];
double STEP1[];
double STEP2[];
double STEP3[];
double STEP4[];
double STEP5[];
double STEP6[];


int min_rates_total=2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//---- Initialization of variables of data calculation starting point

//--- indicator buffers
   int i=0;
   SetIndexBuffer(i++,FLEX,INDICATOR_DATA);
   SetIndexBuffer(i++,STEP,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP5,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP6,INDICATOR_CALCULATIONS);


   SetIndexBuffer(i++,ATR,INDICATOR_CALCULATIONS);

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

      ATR[i]=EMPTY_VALUE;
      STEP[i]=EMPTY_VALUE;

      FLEX[i]=EMPTY_VALUE;

      STEP1[i]=EMPTY_VALUE;
      STEP2[i]=EMPTY_VALUE;
      STEP3[i]=EMPTY_VALUE;
      STEP4[i]=EMPTY_VALUE;
      STEP5[i]=EMPTY_VALUE;
      STEP6[i]=EMPTY_VALUE;

      double atr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      ATR[i]=atr;
      if(i==begin_pos)continue;
      atr=fmax(ATR[i-1]*0.667,fmin(atr,ATR[i-1]*1.333));
      ATR[i]=AtrAlpha*atr+(1-AtrAlpha)*ATR[i-1];

      double price=(close[i]+high[i]+low[i])/3;

      //--- 
      iStepMa(STEP1,price,ATR[i]*Size1*InpStepSize,i);
      iStepMa(STEP2,price,ATR[i]*Size2*InpStepSize,i);
      iStepMa(STEP3,price,ATR[i]*Size3*InpStepSize,i);
      iStepMa(STEP4,price,ATR[i]*Size4*InpStepSize,i);
      iStepMa(STEP5,price,ATR[i]*Size5*InpStepSize,i);
      iStepMa(STEP6,price,ATR[i]*Size6*InpStepSize,i);
      STEP[i]=(STEP1[i]+STEP2[i]+STEP3[i]+STEP4[i]+STEP5[i]+STEP6[i])/6.0;

      //--- 
      

      
      if(i<=begin_pos+1)
      {
         FLEX[i]=STEP[i];
         continue;
      }
      FLEX[i]=Alpha*STEP[i]+(1.0-Alpha)*FLEX[i-1];

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
