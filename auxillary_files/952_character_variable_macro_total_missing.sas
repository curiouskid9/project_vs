
%gen_init_001;

proc format;
   value $lbnrind(default=8)
   "NORMAL"="NORMAL"
   "ABNORMAL"="ABNORMAL"
   "LOW"="LOW"
   "HIGH"="HIGH"
   ;
run;

data adlb01;
   set adam.adlbh;
   where trta ne "" and paramcd=:"H";
   if mod(_n_,10)=1 then lbnrind="";
run;

data adsl01;
   set adam.adsl;
   where saffl="Y";
run;

proc sort data=adlb01;
   by paramcd param trtan trta avisitn avisit;
run;


%macro csg_get_counts(indsn=
                     ,indsnwhere=%str()
                     ,byvar=%str( )
                     ,keycountvar=
                     ,macid=_csg_gc_
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
   fulllist=cats("&_byvarlistsql.",",","&_csgcountvarsql.");
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
         _csgcountvar=1001.908; *total rows present in data excluding missing values;
         output;
      end;
      if missing(&_csgcountvar.) then do;
          _csgcountvar=1001.901;*record present - missing value in data;
         output;
      end;
      _csgcountvar=1001.909; *total rows present in data including missing values;
      output;
   %end;
   %else %do;
       if not missing(&_csgcountvar.) then do;
         _csgcountvar=&_csgcountvar.; *actual non-missing values;
         output;
         _csgcountvar="ZZZ01-Total: Non-missing result in data"; *total rows present in data excluding missing values;
         output;
      end;
      if missing(&_csgcountvar.) then do;
          _csgcountvar="ZZZ02-Missing: Record present, value missing";*record present - missing value in data;
         output;
      end;
      _csgcountvar="ZZZ03-Total: All rows present in data"; *total rows present in data including missing values;
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

%mend csg_get_counts;

options mprint sgen spool;

%csg_get_counts(indsn=adsl01
                ,indsnwhere=%str()
                ,byvar=trt01an trt01a
                ,keycountvar=race
                 );

options nomprint nosgen nospool;

%gen_term_001;

