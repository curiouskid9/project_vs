
data one;
  input x;
  if int(x) ne 0 then do;
    _3sigdigit=round(x,10**(int(log10(abs(x)))-2));
    end;
  else do;
    _3sigdigit=round(x,10**(-1*(abs(int(log10(abs(x))))+3)));
    end;
datalines;
0.00001616
0.0051368
35.479
3149.0865
;

proc print;
  format x _3sigdigit  15.8;
run;
