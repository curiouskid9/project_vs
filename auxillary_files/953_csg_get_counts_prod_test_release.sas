%gen_init_001;

data adlb01;
   set adam.adlbh;
   where trta ne "" and paramcd=:"H";
   if mod(_n_,10)=1 then lbnrind="";
run;

data adsl01;
   set adam.adsl;
   where saffl="Y";
   if mod(_n_,10)=1 then agegr1n=.;
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
                     ,outdsn=
                     ,debug=N
                     );

%*--------------------------------------------------------------;
%*format for assigning a label for derived (total/missing) rows;
%*--------------------------------------------------------------;

proc format;
   value &macid.level_label(default=60)
   1001.901="(1001.901) Total: Non-missing result in data"
   1001.902="(1001.902) Missing: Record present, value missing"
   1001.903="(1001.903) Missing: Popultation count minus available non-missing data"
   1001.904="(1001.904) Total: All rows present in data"
   ;
run;

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
      
      %*--------------------------------------------------------------------------------;
      %*use an additional by variable to get the overall record counts in input dataset;
      %*--------------------------------------------------------------------------------;
      value=catx(" ","_CSGBYVAR",value);

      %*--------------------------------------------------------------------------------;
      %*create a some temporary local macro variables;
      %*--------------------------------------------------------------------------------;

      call symputx("_byvarlist",value,'L');
      call symputx("_byvarlistsql",translate(strip(value),',',' '),'L');
      call symputx("_byvarcount",countw(value),'L');
   end;

   if name="KEYCOUNTVAR" then do;
      value=compbl(value);
      %*--------------------------------------------------------------------------------;
      %*use a temporary count variable if no keycount var is passed;
      %*--------------------------------------------------------------------------------;

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

%*--------------------------------------------------------------------------------;
%*Create a copy of the input dataset, with applicable input filters;
%*--------------------------------------------------------------------------------;

data &macid.working_copy01;
   set &indsn.;
   &indsnwhere.;
run;

%*-----------------------------------------------;
%*get the variable type of count variable;
%*-----------------------------------------------;

data _null_;
   set &macid.working_copy01;
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

data &macid.working_copy02;

%*--------------------------------------------------------------------------------;
%*Assign a length of 200, if the variable is character to avoid truncation issues;
%*--------------------------------------------------------------------------------;
   %if &_csgcountvartype=C %then %do;
      length _csgcountvar $200;
   %end;


   set &macid.working_copy01;

   _csgcountvartype="&_csgcountvartype";

   %*--------------------------------------------------------------------------------;
   %*create some temporary variables for easy processing of the macro;
   %*--------------------------------------------------------------------------------;

   _csgbyvar=1;%*if no by variables are passed to the macro this will become the default;
   _csgdummynum=1;%*to use as a dummy numeric variable;
   _csgdummychar="CSG";%*to use as a dummy character variable;
  

   %*--------------------------------------------------------------------------------;
   %*duplicate the records to get the missing/non-missing/total row counts;
   %*--------------------------------------------------------------------------------;

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
      format _csgcountvar &macid.level_label.;
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

proc sort data=&macid.working_copy02;
   by &_byvarlist.;
run;

%*--------------------------------------------------------------------------------;
%*process the variables to determine the overall number of by levels;
%*--------------------------------------------------------------------------------;

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

%*--------------------------------------------------------------------------------;
%*macro to get the counts of all levels and merge into a single dataset;
%*--------------------------------------------------------------------------------;

%macro run_freq(_bylevel=,level=);

proc sort data=&macid.working_copy02;
   by &_bylevel.;
run;

proc freq data=&macid.working_copy02 noprint;
   by &_bylevel. ;
   %if %eval(&level) lt &_bycountvarcount. %then %do;
      where _csg_derived_row ne 1;
   %end;
   tables _csgdummynum/out=&macid.counts01_level_&level.(drop=percent _csgdummynum);
run;

%*--------------------------------------------------------------------------------;
%*merge individual top level by group counts to lowest level by group counts;
%*--------------------------------------------------------------------------------;
 
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

%*--------------------------------------------------------------------------------;
%*create the macro calls for all levels using call execute;
%*--------------------------------------------------------------------------------;

data _null_;
   set &macid.check02;
   var=cats('%run_freq(_bylevel=',level,',level=',i,');');
   call execute(var);
run;

%*--------------------------------------------------------------------------------;
%*intermediate processing of dataset;
%*--------------------------------------------------------------------------------;

data &macid.counts01_final;
   set &macid.counts01_final(rename=(_csgcountvar=&_csgcountvar.));
run;

%*--------------------------------------------------------------------------------;
%*if the population counts dataset exists(passed as a parameter), then the 
%* total number of missing counts will be obtained when compared to population total;
%*--------------------------------------------------------------------------------;

%if &popdenomsdataset ne %then %do;

proc sort data=popdenoms;
   by &popbyvar.;
run;

proc sort data=&macid.counts01_final;
   by &popbyvar.;
run;

%*--------------------------------------------------------------------------------;
%*merge with population counts and get the number of missing count when compared
%*to populatoin counts;
%*--------------------------------------------------------------------------------;

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

data &outdsn.;
   set &macid.counts01_final;
   drop _csgbyvar;
run;


%*-----------------------------------------------------------------------------;
%*Cleanup;
%*-----------------------------------------------------------------------------;

%if &debug ne Y %then %do;

proc datasets nowarn library=work memtype=data;
   delete &macid:;
   run;
quit;

%end;

%mend csg_get_counts;

options mprint sgen spool;

%csg_get_counts(indsn=adsl01
                ,indsnwhere=%str(where sex="F";)
                ,byvar= trt01an
                ,keycountvar=agegr1n
                ,popdenomsdataset=popdenoms
                ,popbyvar=trt01an
                ,outdsn=levelcounts
                ,debug=N
                 );

options nomprint nosgen nospool;

%gen_term_001;
