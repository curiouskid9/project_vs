%gen_init_001;


data adlb01;
   set adam.adlbh;
   where trta ne "";
run;

proc sort data=adlb01;
   by paramcd param trtan trta avisitn avisit;
run;


%macro csg_get_counts_all_by_levels(indsn=adlb01
                     ,byvar=%str(paramcd param trtan trta avisitn avisit)
                     ,keycountvar=lbnrind
                     );


%local _byvarlist _byvarcount
      ;


%*-------------------------------------------------;
%*Create a copy of the input dataset;
%*create some temporary variables as well to 
  enble smooth processing of the macro;
%*-------------------------------------------------;

data _csg_gc&indsn.01;
   set &indsn.;

   _csgbyvar=1;%*if no by variables are passed to the macro this will become the default;
run;


%*-------------------------------------------------;
%*processing of by variables list;
%*-------------------------------------------------;

%if &byvar= %then %let _byvarlist=_csgbyvar;
%else %let _byvarlist=&byvar.;

%*count the number of by variables;

%let _byvarcount=%sysfunc(countw(&_byvarlist));

%put Number of by group varialbes &_byvarcount.;


proc freq data= _csg_gc&indsn.01    noprint   ;
   *by &byvar.;
   tables    &keycountvar.             /list missing out=counts01;
run;

%mend;

options mprint sgen;
%csg_get_counts_all_by_levels(byvar=);
options nomprint nosgen;

%gen_term_001;

