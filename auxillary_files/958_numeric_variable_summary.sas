
dm log 'clear';
dm lst 'clear';
dm log 'preview';


*====================================================================;
*section of the code to check for number of distinct values;
*====================================================================;

%macro numsummary_in;

%do _num_i_=1 %to &nnumvars;

%let _var2_=;*macro variable to hold the variable which holds the variable which 
				satisfies the predefined limits;
%let _var2_label=;

*---------------------------------------------------------------------------;
*repeats for each numeric variable and checks if the variable has the
distinct values within th predefined range;
*----------------------------------------------------------------------------;

%let _var_=%scan(&numvars,&_num_i_.,"~");

proc sql noprint;
	create table ndistinct_temp as
		select "&_var_." as variable length=20, count(distinct &_var_.) as distinctvals
		from _temp_&_indsn.

		;

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
	title "Descriptive stats for %trim(&_var2_.) (&_var2_label.)";

proc summary data=_temp_&_indsn. print n nmiss mean stddev min q1 median q3 max range;
	%if &_byvar. ne %then %do;
	by &_byvar.;
	%end;
	var &_var2_.;
run;
%end;
%end;
	
%mend numsummary_in;



%macro numsummary(_libname=adam,_indsn=adsl, _byvar=,
	where=,
	filename=numsummary);

*=========================================================;
*check for numeric variables in the dataset;
*=========================================================;

proc contents data=&_libname..&_indsn. out=cont noprint;
run;

data _temp_&_indsn.;
	set &_libname..&_indsn.;
	&where.; *apply any further filtering condition;
run;

data numeric;
	set cont;
	where type=1;
	keep name varnum label;
run;

*------------------------------------------------------------;
*assign the list of numeric variables to a macro variable;
*------------------------------------------------------------;

proc sql noprint;
	select name into :numvars separated by "~" from numeric order by varnum;

	select count(*) into :nnumvars from numeric;
quit;

%put &numvars;



%numsummary_in;


%mend;

/*%numsummary(_libname=adam,_indsn=adsl);*/

/*%numsummary(_libname=adam,_indsn=adlbc,_byvar=paramcd trta,where=%str(where avisitn=4;));*/
/*%numsummary(_libname=adam,_indsn=advsmax,_byvar=trta paramcd,where=%str(where avisitn=4;));*/

%numsummary(_libname=work,_indsn=adsl,_byvar=);
