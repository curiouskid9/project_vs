
%macro countcheck(dsn1=, dsn2=, byvar=);

%local tablevar;
%let byvar=%sysfunc(compbl(&byvar.));
%let tablevar =%sysfunc(tranwrd(&byvar.,%str( ),%str(*)));

proc freq data=  &dsn1. noprint ;
	tables  &tablevar.  /list missing out=_uniquevalues01;
	where 1=1;
run;



proc freq data= &dsn2.  noprint;
	tables  &tablevar.  /list missing out=_uniquevalues02;
	where 1=1;
run;


data full both aonly bonly;
	merge _uniquevalues01(in=a drop=percent rename=(count=counta)) _uniquevalues02(in=b drop=percent rename=(count=countb));
	by &byvar.;
	if counta ne countb then cmiss=1;
	if a and b then both=1;
	if a and not b then aonly=1;
	if b and not a then bonly=1;
	if a or b then output full;
	if a and b then output both;
	if a and not b then output aonly;
	if b and not a then output bonly;
run;


proc sort data=&dsn1. out=&dsn1._sort;
	by &byvar.;
run;

data check_a;
	merge &dsn1._sort(in=a) full(in=b);
	by &byvar.;
	if a;
run;

proc sort data=&dsn2. out=&dsn2._sort;
	by &byvar.;
run;

data check_b;
	merge &dsn2._sort(in=a) full(in=b);
	by &byvar.;
	if a;
run;




%mend countcheck;

%countcheck(dsn1=  , dsn2= , byvar=  );

