
*redacted;

options validvarname=upcase varlenchk=nowarn;
options mprint symbolgen;

%assignlibs;

*------------------------------------------------;
*formats for display purpose;
*-----------------------------------------------;

proc format;
   value trt01an
      1=1
      2=2
      3=3;

    value mhtermn
      1=1
      2=2
      3=3;

   value $mhtermn_disp
      1="CKD"
      2="T2DM"
      3="Both";
run;

*-----------------------------------------------;
*read input datasets;
*-----------------------------------------------;

data admh_pre;
   set s_adam_i.admh;
   trt01an=trtan;
   where parcat1n=1 and mhspid in ("1","2") and pprotfl="Y";
run;

data admh01;
   set admh_pre;
   output;
   trt01an=3;
   output;
run;

data adsl;
   set s_adam_i.adsl;
   where pprotfl="Y" and not missing(trt01an);
run;

data adsl2;
   set adsl;
   output;
   trt01an=3;
   output;
run;


*-------------------------------------------;
*creating a dummy dataset for trt counts;
*-------------------------------------------;

data dummytrt;
   trttotal=0;
   do trt01an=1 to 3;
      output;
   end;
run;

*-----------------------------------------;
*creating both category for events;
*-----------------------------------------;

data admh02 t2dm ckd;
   set admh01;
   mhtermn=input(mhspid,best.);

   if mhtermn=1 then output t2dm;
   else if mhtermn=2 then output ckd;

   output admh02;
run;

data both;
   merge t2dm(in=a keep=usubjid trt01an) ckd(in=b keep=usubjid trt01an );
   by usubjid trt01an;
   if a and b;
   mhtermn=3;
run;

proc sort data=admh02 out=admh03_pre nodupkey;
   by usubjid trt01an mhtermn ;
run;

data admh03;
   set admh03_pre both;
run;


data admh04;
   set admh02;
   where mhtermn=1;
run;

data admh05;
   set admh02;
   where mhtermn=2;
   adur1=adur;
run;

proc sql noprint;
   select count(*) into :nobs from admh_pre;
quit;

*=====================================================;
*obtaining actual counts for required variable;
*=====================================================;
*macro for counts and percentages;

%macro count_percent(var=,
                label=,
                group=
               );

*-------------------------------------------;
*obtain non-missing values as denominator;
*-------------------------------------------;

proc sql;
   create table &var._denoms as
   select trt01an,count(distinct usubjid) as trttotal
   from admh03 
   where &var not in (., 0)
   group by trt01an
   order by trt01an;
quit;

data &var.denoms;
   merge dummytrt &var._denoms;
   by trt01an;
run;

proc summary data=admh03 completetypes nway;
   class trt01an /preloadfmt;
   class &var./preloadfmt mlf;
   where not missing(&var.);
   format  &var. &var.. trt01an trt01an.;
   output out=&var._stats(drop=_type_ rename=(_freq_=count));
run;

*---------------------------------------;
*merge sex counts with trtcounts;
*---------------------------------------;

*numerator counts;

proc sort data=&var._stats;
   by trt01an ;
run;

*denominator counts;

proc sort data=&var._denoms;
   by trt01an ;
run;

data &var._stats2;
   merge &var._stats &var._denoms;
   by trt01an ;
run;

*-----------------------------------------------;
*calculate percentages;
*-----------------------------------------------;

data &var._stats3;
   set &var._stats2;
   length label statistic $50 cp $20;

   label="&label.";
   group=&group.;

   intord=input(&var.,best.);

   statistic=put(&var.,&var._disp.);

   if count ne 0 then cp=put(count,3.)|| ' ('||put(round(count*100/trttotal,0.1),5.1)||'%)';
   else cp=put(count,3.);

run;

proc sort data=&var._stats3;
   by  group intord label statistic;
run;

proc transpose data=&var._stats3 out=&var._stats4;
   by  group intord label statistic;
   var cp;
   id trt01an;
run;

data final_stats_&var.;
   length c1-c5 $200;
   set &var._stats4;
   if intord=0 and compress(_3)="0" then delete;
   c1=label;
   c2=statistic;
   c3=_1;
   c4=_2;
   c5=_3;
   
   keep group  intord c1-c5 ;
run;

proc sort data=final_stats_&var.;
   by  group intord;
run;
%mend count_percent;


*=======================================================;
*descriptive stats for numeric variables;
*=======================================================;
%macro descriptive(indsn=,
      var=,
      label=,
      group=,
      n=,
      mean=,
      sd=,
      min=,
      median=,
      max=
      );

proc summary data=&indsn.  nway;
   class trt01an;
   where not missing(&var.);
   var &var.;
   output out=&var._stats(drop=_type_ _freq_)
   n= mean= std= min= median= max= /autoname;
run;

data &var._stats2;
   set &var._stats;
   n=put(&var._n,&n.);
   mean=put(&var._mean,&mean.);
   sd=put(&var._stddev,&sd.);
   min=put(&var._min,&min.);
   median=put(&var._median,&median.);
   max=put(&var._median,&max.);

   drop &var._:;
run;

proc transpose data=&var._stats2 out=&var._stats3(drop=_name_) label=statistic;
   by   trt01an;
   var n mean sd min median max;
   label n="n"
         mean="Mean"
         sd="SD"
         min="Min"
         median="Median"
         max="Max";
run;

data &var._stats4;
   set &var._stats3;
   length label $50;

   label="&label.";
   group=&group.;

   select(statistic);
      when("n") intord=1;
      when ("Mean") intord=2;
      when ("SD") intord=3;
      when ("Min") intord=4;
      when ("Median") intord=5;
      when ("Max") intord=6;
   otherwise;
   end;
run;

proc sort data=&var._stats4;
   by  group intord label statistic;
run;

proc transpose data=&var._stats4 out=_final_stats_&var.;
   by  group intord label statistic;
   var col1;
   id trt01an;
run;

data final_stats_&var.;
   set _final_stats_&var.;
   length c1-c5 $200;
   c1=label;
   c2=statistic;
   c3=_1;
   c4=_2;
   c5=_3;
   keep group  intord c1-c5 ;
run;

%mend descriptive;

%macro dm013t;

%if &nobs gt 0 %then %do;

%count_percent(var=mhtermn,
            label=%str(Medical Condition),
             group=1
            );

%descriptive(
      indsn=admh04,
      var=adur,
      label=%str(Duration of CKD (Years)[1]),
      group=2,
      n=3.,
      mean=6.2,
      sd=6.2,
      min=5.1,
      median=6.2,
      max=5.1
      );

%descriptive(
      indsn=admh05,
      var=adur1,
      label=%str(Duration of T2DM (Years)[1]),
      group=3,
      n=3.,
      mean=6.2,
      sd=6.2,
      min=5.1,
      median=6.2,
      max=5.1
      );


data final;
   set final_stats_:;
run;

proc sort data=final;
   by group intord;
run;


*====================================================================;
*macro variables of treatment totals for column headers;
*====================================================================;

proc sql noprint;
   select count(distinct usubjid) into :n1 from adsl2 where trt01an=1;
   select count(distinct usubjid) into :n2 from adsl2 where trt01an=2;
   select count(distinct usubjid) into :n3 from adsl2 where trt01an=3;
quit;

%put number of subjects in trt1 : &n1;
%put number of subjects in trt2 : &n2;
%put number of subjects in trt3 : &n3;
%aligdec (indsn=final,invar=%str(c3 c4 c5));

proc datasets library=work;
   modify final;
   rename c3c=c3 c4c=c4 c5c=c5;
run;

* Printing the final output;
%*redacted;

proc report data = final center headline headskip nowd split='~' missing spacing=0;
    column group c1  intord c2  c3 c4 c5  ;
    define group/order noprint order=data;
    define intord /order noprint order=data;
    define c1/width=30 "Parameter" order  width = 40 flow spacing = 0;
    define c2/width=30 "Category/~Statistic"  width = 15 flow spacing = 0;
    define c3/"*redacted;" "(N=%cmpres(&n1))" width=18  ;
    define c4/ "Placebo"  "(N=%cmpres(&n2))" width=18  ;
    define c5/"Total" "(N=%cmpres(&n3))" width=18  ;
break after group / skip;
run;
%end;

%else %do;

   data final;
      length c1-c4 $100;
      call missing(of c1-c4);
   run;

%*redacted;

   data final;
      length c1-c5 $100;
      call missing(of c1-c5);
   run;

   data nores;
      length comment $200;
      comment="---------------- No Results to Show at This Time ------------";
   run;

   proc report data=nores headline headskip nowd;
      column comment;
      define comment/ display ' ' width=100 center;
   run;

%end;

data compt.dm013t;
   set final;
   keep c1-c5;
run;

%mend dm013t;

%dm013t;

*redacted;
*redacted;

*redacted;(prog=&prog_loc./dm013t.log);
*redacted;(prog=&prog_loc./dm013t.sas, standalone=Y);


*redacted;
