%let max_len=100;

data string01;
	infile datalines truncover;
	input string $32767.;
	length temp $32767 ;

	bp=&max_len.;
	length temp1 $&max_len.;

	temp_s=string;

	j=0;

	do while(lengthn(compress(temp_s))>0);
		if lengthn(temp_s) le bp then do;
			temp1=temp_s;
			leave;
		end;
		else do;
			if substrn(temp_s,bp,1)=" " then do;
				temp1=substrn(temp_s,1,bp);
				temp_s=substrn(temp_s,bp+1);
			end;
			else do;
				pos=bp-index(reverse(substrn(temp_s,1,bp)),' ');
				temp1=substrn(temp_s,1,pos);
				temp_s=substrn(temp_s,pos+1);
			end;
		end;

		if j=0 then temp=temp1;
		else temp=catx('~',trim(temp),trim(temp1));
		j+1;

	end;

	if j=0 then temp=temp1;
	else temp=catx('~',trim(temp),trim(temp1));

	retain max;
	max=max(max,countc(temp,'~')+1);
	term=scan(temp,1,'~');
	call symputx('maxvars',max-1);
	
datalines;
Hi
SAS was developed at North Carolina State University from 1966 until 1976, when SAS Institute was incorporated. SAS was further developed in the 1980s and 1990s with the addition of new statistical procedures, additional components and the introduction of JMP. A point-and-click interface was added in version 9 in 2004. A social media analytics product was added in 2010
SAS was developed at North Carolina State University from 1966 until 1976, when SAS Institute was incorporated. SAS was further developed in the 1980s and 1990s with the addition of new statistical procedures, additional components and the introduction of JMP. A point-and-click interface was added in version 9 in 2004. A social media analytics product was added in 2010SAS was developed at North Carolina State University from 1966 until 1976, when SAS Institute was incorporated. SAS was further developed in the 1980s and 1990s with the addition of new statistical procedures, additional components and the introduction of JMP. A point-and-click interface was added in version 9 in 2004. A social media analytics product was added in 2010
SAS was developed at North Carolina State University from 1966 until 1976, when SAS Institute was incorporated. SAS was further developed in the 1980s and 1990s with the addition of new statistical procedures, additional components and the introduction of JMP. A point-and-click interface was added in version 9 in 2004. A social media analytics product was added in 2010
Hello
;
run;

%macro split_vars;
	%if &maxvars gt 0 %then %do;
		data string01;
			set string01;
			array newvars[&maxvars] $ &max_len. term1-term&maxvars.;
			do i=1 to &maxvars.;
				newvars[i]=scan(temp,i+1,'~');
			end;
			drop i;
		run;
	%end;
%mend split_vars;

%split_vars;
