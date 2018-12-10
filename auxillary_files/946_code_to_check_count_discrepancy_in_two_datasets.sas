
%macro countcheck(dsn1=, dsn2=, byvar=);

%*----------------------------------------------------;
%*create working copies of the input datasets;
%*----------------------------------------------------;

data _left;
	set &dsn1;
run;

data _right;
	set &dsn2;
run;

%*----------------------------------------------------;
%*process the macro parameters;
%*----------------------------------------------------;

%local tablevar;
%let byvar=%sysfunc(compbl(&byvar.));
%let tablevar =%sysfunc(tranwrd(&byvar.,%str( ),%str(*)));

%*----------------------------------------------------;
%*Obtain the counts in each input dataset;
%*----------------------------------------------------;

proc freq data=  _left noprint ;
	tables  &tablevar.  /list missing out=_uniquevalues01;
	where 1=1;
run;

proc freq data= _right  noprint;
	tables  &tablevar.  /list missing out=_uniquevalues02;
	where 1=1;
run;

%*----------------------------------------------------;
%*process the counts and create flags to identify issue patterns;
%*----------------------------------------------------;

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

%*----------------------------------------------------;
%*bring the flags into source data for easy filtering;
%*----------------------------------------------------;

proc sort data=_left out=_left_sort;
	by &byvar.;
run;

%*----------------------------------------------------;
%*dataset with unique values only in the left datset(dsn1);
%*----------------------------------------------------;

data check_a;
	merge _left_sort(in=a) full(in=b);
	by &byvar.;
	if a;
run;

proc sort data=_right out=_right_sort;
	by &byvar.;
run;

%*----------------------------------------------------;
%*dataset with unique values only in the right datset(dsn2);
%*----------------------------------------------------;

data check_b;
	merge _right_sort(in=a) full(in=b);
	by &byvar.;
	if a;
run;

%*----------------------------------------------------;
%*dataset with value differences seen as rows;
%*----------------------------------------------------;

data cmiss;
	set full;
	where cmiss=1;
run;

%mend countcheck;

%countcheck(dsn1=  , dsn2=  , byvar=  );
