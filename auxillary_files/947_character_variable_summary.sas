
dm log 'clear';
dm lst 'clear';
dm log 'preview';


*====================================================================;
*section of the code to check for number of distinct values;
*====================================================================;

%macro charsummary_in;

%do _char_i_=1 %to &ncharvars;

%let _var2_=;*macro variable to hold the variable which holds the variable which 
				satisfies the predefined limits;
%let _var2_label=;

*---------------------------------------------------------------------------;
*repeats for each character variable and checks if the variable has the
distinct values within th predefined range;
*----------------------------------------------------------------------------;

%let _var_=%scan(&charvars,&_char_i_.,"~");

proc sql noprint;
	create table ndistinct_temp as
		select "&_var_." as variable length=20, count(distinct &_var_.) as distinctvals
		from _temp_&_indsn.

		/*minumum and maximum number of allowed distinct values can be changed here*/

		having calculated distinctvals between &minlevels and &maxlevels;

	select distinctvals into :ndistinctvals from ndistinct_temp;

	select distinct variable into :_var2_ from ndistinct_temp
	where not missing(distinctvals);

quit;	


%put &=_var2_. &=_var2_label.;


*======================================================================;
*section of code which writes the distinct values and its occurences
to an external file;
*======================================================================;

%if &_var2_. ne  %then %do;*run only when a variable has the number of distinct
							values in the specified limits;

data label;
	set _temp_&_indsn.;
	array _xtemp &_var2_;
	_var2_label2=vlabel(_xtemp(1));
	call symputx("_var2_label",_var2_label2);
	stop;
run;

*----------------------------------------;
*code to get the distinct values and 
number of occurrences;
*----------------------------------------;
	%if &_byvar. ne %then %do;
proc sort data=_temp_&_indsn.;
	by &_byvar.;
run;
	%end;
proc freq data=_temp_&_indsn. noprint;
	%if &_byvar. ne %then %do;
	by &_byvar.;
	%end;
	tables &_var2_./out=counts(keep=&_var2_ &_byvar.  count);
run;

*-------------------------------------------;
*code to write the values to external file;
*-------------------------------------------;

data _null_;
	file print;*mod helps to append the values of variables;
	set counts end=last;
	%if &_byvar. ne %then %do;
	by &_byvar.;
	if first.%scan(&_byvar.,-1) then obs=1;
	else obs+1;
	%end;
	%else %do;
	obs=_N_;
	%end;
	if _n_=1 then do;
	put  133*"=";
	put @ 25 "The variable %cmpres(&_var2_.) (label=&_var2_label.) has %cmpres(&ndistinctvals.) distinct values";
	put @35 "and the distinct values and their frequencies are";
	put  133*"=";
	put ;
	end;

	%if &_byvar. ne %then %do;

	put @1 obs @10 &_byvar @70 &_var2_. @120 count;

	if last.%scan(&_byvar.,-1) then put @1 133*"-";

	%end;

	%else %do;
	put @1 obs  @5 &_var2_. @70 count;
	%end;
	if last then do;
	put;
	put  133*"=";
	put @1 ;
	put @1 ;
	end;
run;
%end;
%end;

	
%mend charsummary_in;



%macro charsummary(_libname=adam,_indsn=adsl, _byvar=,
	where=,
	filename=charsummary,
	minlevels=1,
	maxlevels=20);

*=========================================================;
*check for character variables in the dataset;
*=========================================================;

proc contents data=&_libname..&_indsn. out=cont noprint;
run;

data _temp_&_indsn.;
	set &_libname..&_indsn.;
	&where.; *apply any further filtering condition;
run;

data character;
	set cont;
	where type=2;
	keep name varnum label;
run;

*------------------------------------------------------------;
*assign the list of character variables to a macro variable;
*------------------------------------------------------------;

proc sql noprint;
	select name into :charvars separated by "~" from character order by varnum;

	select count(*) into :ncharvars from character;
quit;

%put &charvars;

*===========================================================;
*section of code to delete the file , if it already exists;
*===========================================================;

%let file=%sysget(homedrive)\users\%sysget(username)\desktop;

data _null_;
    fname="tempfile";
    rc=filename(fname,"%cmpres(&file.\&filename..txt)");*check for existence and assign a fileref;
    if rc = 0 and fexist(fname) then do;
       rc=fdelete(fname);*delete if the file exists;
	   putlog "NOTE: File &filename. deleted";
	   end;
    rc=filename(fname);*deassign the fileref;
run;

filename _file_ "&file.\&filename..txt";

%charsummary_in;

filename _file_ clear;

%mend;

/*%charsummary(_libname=adam,_indsn=adsl);*/

/*%charsummary(_libname=adam,_indsn=adlbc,_byvar=paramcd trta,where=%str(where avisitn=4;));*/
/*%charsummary(_libname=adam,_indsn=advsmax,_byvar=trta paramcd,where=%str(where avisitn=4;));*/

%charsummary(_libname=work,_indsn=asl2004,_byvar=sex);
