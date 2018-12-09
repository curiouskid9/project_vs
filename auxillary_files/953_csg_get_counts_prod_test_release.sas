%gen_init_001;

data adlb01;
   set adam.adlbh;
   where trta ne "" and paramcd=:"H";
   if mod(_n_,10)=1 then lbnrind="";
run;

data adsl01;
   set adam.adsl;
   where saffl="Y";
   if mod(_n_,10)=1 then race="";
run;

proc sql;
   create table popdenoms as
      select trt01an,trt01a,count(distinct usubjid) as popdenom
      from adsl01
      group by trt01an,trt01a;
quit;

proc sort data=adlb01;
   by paramcd param trtan trta avisitn avisit;
run;


%macro csg_get_counts(indsn=
                     ,indsnwhere=%str()
                     ,byvar=%str( )
                     ,keycountvar=
                     ,macid=_csg_gc_
                     ,popdenomsdataset=popdenoms
                     ,popbyvar=
                     );

%*--------------------------------------------------------------;
%*get the list of parameters of the this macro;
%*process the macro variables as needed;
%*--------------------------------------------------------------;

data _csg_gc_localmacvars;
   set sashelp.vmacro;
   where scope = "&sysmacroname";
   name=upcase(name);
   if name="BYVAR" then do;
      value=compbl(value);
      value=catx(" ","_CSGBYVAR",value);
      call symputx("_byvarlist",value,'L');
      call symputx("_byvarlistsql",translate(strip(value),',',' '),'L');
      call symputx("_byvarcount",countw(value),'L');
   end;
   if name="KEYCOUNTVAR" then do;
      value=compbl(value);
      if missing(value) then value="_CSGCOUNTVAR";
      call symputx("_csgcountvar",value);
      call symputx("_csgcountvarsql",translate(strip(value),',',' '));
   end;
run;

%*-----------------------------------------------------------;
%*check the overall count of by and count variables;
%*-----------------------------------------------------------;

data &macid.check01;
   fulllist=cats("&_byvarlistsql.",",","_csgcountvar");
   listcount=countw(fulllist,",");
   call symputx( "_bycountvarsql", fulllist,'L');
   call symputx( "_bycountvarcount", listcount,'L');
run;

data _csg_woking_copy;
   set &indsn.;
   &indsnwhere.;
run;

%*-----------------------------------------------;
%*get the variable type of count variable;
%*-----------------------------------------------;

data _null_;
   set _csg_woking_copy;
   array _csgtemp &_csgcountvar;
   vtype=vtype(_csgtemp[1]);
   call symputx("_csgcountvartype",vtype,'L');
   stop;
run;


%*-------------------------------------------------;
%*Create a copy of the input dataset;
%*create some temporary variables as well to 
  enble smooth processing of the macro;
%*-------------------------------------------------;

data _csg_woking_copy;
   %if &_csgcountvartype=C %then %do;
      length _csgcountvar $200;
   %end;

   set _csg_woking_copy;

   _csgcountvartype="&_csgcountvartype";

   _csgbyvar=1;%*if no by variables are passed to the macro this will become the default;
   _csgdummynum=1;%*to use as a dummy numeric variable;
   _csgdummychar="CSG";%*to use as a dummy character variable;
  
   %if &_csgcountvartype.=N %then %do;
      if not missing(&_csgcountvar.) then do;
         _csgcountvar=&_csgcountvar.; *actual non-missing values;
         output;
         _csg_derived_row=1;
         _csgcountvar=1001.901; *total rows present in data excluding missing values;
         output;
      end;
      if missing(&_csgcountvar.) then do;
         _csg_derived_row=.;
          _csgcountvar=1001.902;*record present - missing value in data;
         output;
      end;
      _csg_derived_row=1;
      _csgcountvar=1001.904; *total rows present in data including missing values;
      output;
   %end;
   %else %do;
       if not missing(&_csgcountvar.) then do;
         _csgcountvar=&_csgcountvar.; *actual non-missing values;
         output;
         _csg_derived_row=1;
         _csgcountvar="ZZZ01-Total: Non-missing result in data"; *total rows present in data excluding missing values;
         output;
      end;
      if missing(&_csgcountvar.) then do;
         _csg_derived_row=.;
          _csgcountvar="ZZZ02-Missing: Record present, value missing";*record present - missing value in data;
         output;
      end;
      _csg_derived_row=1;
      _csgcountvar="ZZZ04-Total: All rows present in data"; *total rows present in data including missing values;
      output;     
   %end;
run;

proc sort data=_csg_woking_copy;
   by &_byvarlist.;
run;

proc freq data=_csg_woking_copy noprint;
   by &_byvarlist.;
   tables _csgcountvar/out=counts01(rename=(_csgcountvar=&_csgcountvar) drop=percent);
run;



data &macid.check02;
   length var level $1000;
   var="&_bycountvarsql.";
   do i= 1 to &_bycountvarcount.;
      level=catx(" ",level,scan(var,i,','));
      output;
   end;
run;

proc sort data=&macid.check02;
   by descending i;
run;


%macro run_freq(_bylevel=,level=);

proc sort data=_csg_woking_copy;
   by &_bylevel.;
run;

proc freq data=_csg_woking_copy noprint;
   by &_bylevel. ;
   %if %eval(&level) lt &_bycountvarcount. %then %do;
      where _csg_derived_row ne 1;
   %end;
   tables _csgdummynum/out=&macid.counts01_level_&level.(drop=percent _csgdummynum);
run;


%if %eval(&level) lt &_bycountvarcount. %then %do;
   
   data &macid.counts01_final;
      merge &macid.counts01_final 
            &macid.counts01_level_&level.(rename=(count=level&level._count));
      by &_bylevel.;

      length level&level._groups $200;
      level&level._groups=tranwrd(upcase("&_bylevel."),"_CSGBYVAR","ALLROWS");
   run; 
%end;
%else %do;
data &macid.counts01_final;
   set &macid.counts01_level_&level.;
run;
%end;

%mend run_freq;

data _null_;
   set &macid.check02;
   var=cats('%run_freq(_bylevel=',level,',level=',i,');');
   call execute(var);
run;

data &macid.counts01_final;
   set &macid.counts01_final(rename=(_csgcountvar=&_csgcountvar.));
run;

%if &popdenomsdataset ne %then %do;

proc sort data=popdenoms;
   by &popbyvar.;
run;

proc sort data=&macid.counts01_final;
   by &popbyvar.;
run;

data &macid.counts01_final;
   merge &macid.counts01_final(in=a) popdenoms(in=b);
   by &popbyvar.;
   if a;
run;

data &macid.counts01_final;
   set &macid.counts01_final;
   if count=. then count=0;
   if popdenom=. then popdenom=0;
   output;
%if &_csgcountvartype.=C %then %do;
   if &_csgcountvar="ZZZ01-Total: Non-missing result in data" then do;
      count=popdenom-count;
      &_csgcountvar="ZZZ03-Missing: Popultation count minus available non-missing data";
      output;
   end;
%end;
%else %do;
   if &_csgcountvar=1001.901 then do;
      count=popdenom-count;
      &_csgcountvar=1001.903;
      output;
   end;
%end;

run;
%end;

%mend csg_get_counts;

options mprint sgen spool;

%csg_get_counts(indsn=adsl01
                ,indsnwhere=%str()
                ,byvar=trt01an agegr1n agegr1
                ,keycountvar=
                ,popdenomsdataset=popdenoms
                ,popbyvar=trt01an
                 );

options nomprint nosgen nospool;

%gen_term_001;
