data cm;
   length var $100;
   atc_text="Curious(xxx)"||"0A"x||"Kid(yyy)"||"0A"x||"9(zzz)"||"0A"x;
   *in each component the text before parenthesis is atc text, 
      text within parenthesis is atc code;
   count=count(atc_text,"0A"x);
run;

proc sql;
      select max(count(atc_text,"0A"x)) into :maxvars separated by ""
      from cm;
quit;

data cm2;
   set cm;
   array atext[*] $200 atc_text1-atc_text&maxvars.;
   array acode[*] $200 atc_code1-atc_code&maxvars.;
   array finds[*] find1-find&maxvars.;
   do i=1 to &maxvars.;
      atext[i]=scan(atc_text,i,"0A"x);
      if index(atext(i),"(") then do;
         acode[i]=scan(atext(i),2,"()");
         atext[i]=scan(atext(i),1,"()");
      end;
      finds[i]=count(atext(i),"0A"x);
      
   end;
run;

      

