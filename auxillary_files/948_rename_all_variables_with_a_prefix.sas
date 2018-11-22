-----------------------------------------------------------------------------;

proc contents data=asly01 out=cont01 noprint;
run;

proc sort data=cont01;
	by varnum;
run;

data _null_;
	set cont01 end=last;
	length rename $32767 temprename $200;
	retain rename;
	temprename=strip(name)||" = _2004_"||strip(name);

	rename=catx(" ",rename,temprename);

	keep name rename temprename;
	
	if last then do;
		call symputx("_renamevars","rename =("||strip(rename)||")");
	end;	
run;

%put &=_renamevars.;


data asly02;
	set asly01(&_renamevars);
run;
