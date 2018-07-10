#property strict
#property indicator_separate_window						// use a different window for indicator
#property indicator_buffers 3							// number of buffers (indicators) used:...
										// wt1, wt2, diffwt = wt1 - wt2
#property indicator_color1 Green						// colour for wt1
#property indicator_color2 Red							// colour for wt2
#property indicator_color3 Blue							// colour for diffwt = wt1 - wt2

#property indicator_level1 60.0							// mark +/- 60 in indicator window
#property indicator_level2 -60.0
#property indicator_levelcolor Black
#property indicator_levelwidth 2
#property indicator_level3 53.0							// mark +/- 53 in indicator window
#property indicator_level4 -53.0
#property indicator_levelcolor Black
#property indicator_levelwidth 2

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

double wt1[], wt2[], diffwt[];							// final buffers used for plotting indicator

int OnInit() {
//--- indicator buffers mapping
	SetIndexBuffer(0, wt1);							// set buffer for wt1
	SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, Green);			// line style for wt1
	SetIndexBuffer(1, wt2);							// set buffer for wt2
	SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, Red);			// line style for wt2
	SetIndexBuffer(2, diffwt);						// set buffer for wt1 - wt2
	SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2, Blue);			// line style for wt1 - wt2
//---
	return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

extern int n1 = 10;								// channel Length
extern int n2 = 21;								// average Length

int OnCalculate(const int rates_total,						// ignore all this
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
	
	string symb = Symbol();							// symbol of security in which the...
										// indicator is dropped
	
	double overbought = 70;							// overbought line on oscillator
	double oversold = -70;							// oversold line on oscillator
	
	int counted_bars = IndicatorCounted();					// total bars counted so far
	int i = Bars - counted_bars - 1;					// starting from left-most bar in window
	
	double ap[], esa[], diff[], d[], ci[], tci[];				// declare arrays
	double wt1expand[];							// expand on first wavetrend to...
										// calculate second wavetrend
	ArrayResize(ap, Bars, 1);						// allocate memory for the arrays
	ArrayResize(esa, Bars, 1);						// all these arrays are initialised to zero
	ArrayResize(diff, n1, 1);
	ArrayResize(d, Bars, 1);
	ArrayResize(ci, n2, 1);
	ArrayResize(tci, Bars, 1);
	ArrayResize(wt1expand, 4, 1);
	
	int j;									// looping indices
	
	while (i >= 0) {							// pick a bar on chart
		ap[i] = (High[i] + Low[i] + Close[i])/3.0;			// median price: ap = hlc3
		esa[i] = iMA(symb, 0, n1, 0, MODE_EMA, PRICE_TYPICAL, 0);	// EMA median price: esa = ema(ap, n1)
		
		if (i > Bars - MathMax(n1, n2) - 1) {				// check if sufficient left-most bars...
			i--;							// cannot perform any calculations...
			continue;						// until reaching Bar-Max(n1,n2)-1
		}
		
		for (j = i; j < i + n1; j++) {					// collect info on all earlier bars;...
										// increment in j means moving left of chart
			diff[j - i] = MathAbs(ap[j] - esa[j]);			// difference between median and
										// EMA median price
		}
		
		d[i] = iMAOnArray(diff, 0, n1, 0, MODE_EMA, 0);			// EMA of that difference:...
										// d = ema(abs(ap - esa), n1)
		for (j = Bars - 1; j >= Bars - MathMax(n1, n2); j--) {		// fill array elements between Bars - 1 and...
			d[j] = d[i];						// Bars - MathMax(n1,n2); they are zero otherwise
		}
		
		for (j = i; j < i + n2; j++) {					// collect info on all earlier bars;...
										// increment in j means moving left of chart
			ci[j - i] = (ap[j] - esa[j])/(0.015 * d[j]);		// prepare ci for current bar
		}
		
		tci[i] = iMAOnArray(ci, 0, n2, 0, MODE_EMA, 0);			// EMA of ci: tci = ema(ci, n2)
		
		wt1[i] = tci[i];						// set first wave trend buffer: wt1 = tci
		
		for (j = i; j <= i + 4 - 1; j++) {
			wt1expand[j - i] = tci[j];				// define array on wt1 for SMA calculation...
										// of wt2
		}
		wt2[i] = iMAOnArray(wt1expand, 0, 4, 0, MODE_SMA, 0);		// set second wavetrend buffer:
										// wt2 = sma(wt1, 4)
		diffwt[i] = wt1[i] - wt2[i];					// set difference buffer: wt1 - wt2
		
		i--;								// move to next bar on right
	}
	
//--- return value of prev_calculated for next call
	return(rates_total);
	
}
//+------------------------------------------------------------------+
