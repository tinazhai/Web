*Jun Zhai Final jz3181;
*1.0 import data and union;
proc import out=US1
     datafile="C:\Users\tina_\Desktop\SAS\FINAL\HD.xlsx"
	 dbms=xlsx replace;
	 sheet="US1";
	 getnames=yes;
run;
proc import out=US2
     datafile="C:\Users\tina_\Desktop\SAS\FINAL\HD.xlsx"
	 dbms=xlsx replace;
	 sheet="US2";
	 getnames=yes;
run;
proc import out=EU1
     datafile="C:\Users\tina_\Desktop\SAS\FINAL\HD.xlsx"
	 dbms=xlsx replace;
	 sheet="EU1";
	 getnames=yes;
run;
proc import out=EU2
     datafile="C:\Users\tina_\Desktop\SAS\FINAL\HD.xlsx"
	 dbms=xlsx replace;
	 sheet="EU2";
	 getnames=yes;
run;

data HD;
     set US1 US2 EU1 EU2;
run;

*2.0 format and label;
proc format;
     value sex 1="Male" 0="Female";
     value cp 1="Typical angina"
              2="Atypical angina"
              3="Non-anginal pain"
              4="Asymptomatic";
     value fbs 1="True" 0="False";
     value exang 0="No" 1="Yes";
     value slope 1="upsloping" 2="flat" 3="downsloping";
     value thal 3="normal" 6="fixed defect" 7="reversable defect";
     value restecg 0="Normal"
                   1="ST-T abnormal" 2="left ventricular hypertrophy";
run;
 
data HD;
     set HD;
	 format sex sex. cp cp. fbs fbs. exang exang. slope slope.
	 thal thal. restecg restecg.;
*deal with missing data;	 
     array con {3} trestbps chol thalach;
     do i=1 to 3;
        if con{i}="0" then con{i}="";
     end;
     drop i;
run;
proc print data=HD(obs=10);run;

*3.0 correlation;
proc corr data=HD;
     var diag;
	 with age sex cp trestbps chol fbs restecg thal thalach exang oldpeak slope ca;
run;

ods listing gpath="C:\Users\tina_\Desktop\SAS\FINAL" style=htmlblue;

ods graphics on/ reset outputfmt=png imagename='p1';
title'Scatter Plot of Continuous Variable';
proc sgscatter data=HD;
  matrix chol trestbps thalach oldpeak / diagonal=(histogram normal);
  run;
ods graphics off;

*4.1 ordinal;

proc logistic data = HD plots=all;
class diag (ref = "0") sex (ref ="Female") cp (ref="Typical angina") fbs (ref="False") 
restecg (ref="Normal") exang (ref="No") slope (ref="flat") ca (ref="0") thal (ref="normal") / param = ref;
model diag = age -- thal /  selection=stepwise;
store odfit;
run;

ods graphics on/ reset outputfmt=png imagename='p2';
proc plm source=odfit;
     effectplot slicefit(x=trestbps plotby=diag sliceby=ca) ;
	 effectplot slicefit(x=oldpeak plotby=diag sliceby=cp);
	 ffectplot slicefit(x=chol plotby=diag sliceby=thal);
run;
ods graphics off;

*4.2 binary;
data HD2;
set HD;
length bidiag $4.;
if diag="0" then bidiag="No";
else bidiag="Yes" ;
drop diag;
run;
proc print data=HD2(obs=10);run;

ods graphics on/ reset outputfmt=png imagename='p4';
proc logistic data=HD2 plots=all ;
class bidiag (ref="No") sex (ref ="Female") cp (ref="Typical angina") fbs (ref="False") 
restecg (ref="Normal") exang (ref="No") slope (ref="flat") ca (ref="0") thal (ref="normal") / param = ref;
model bidiag = age -- thal / link=logit selection=stepwise outroc=roc;
store binfit;
run;
ods graphics off;

ods graphics on/ reset outputfmt=png imagename='p5';
proc plm source=binfit;
     effectplot slicefit(x=age plotby=sex sliceby=exang);
	 effectplot slicefit(x=age plotby=sex sliceby=slope);
run;
ods graphics off;

*5.0 plot continuous variable;
proc sgplot data=HD2;
styleattrs datalinepatterns=(solid);
reg y=oldpeak x= age / group=bidiag  degree=3;
run;

proc sgplot data=HD2;
styleattrs datalinepatterns=(solid);
reg y=trestbps x= age / group=bidiag degree=3;
run;

proc sgplot data=HD2;
styleattrs datalinepatterns=(solid);
reg y=thalach x= age / group=bidiag  degree=3;
run;

* 6.0 ANOVA for continuous variable;
proc univariate data=HD normal;
     var oldpeak;
	 class diag;
run; *not normal;
proc anova data=HD;
     class diag;
	 model oldpeak=diag;
	 means diag / hovtest=bf dunnett("0");
run;quit;*all;

proc univariate data=HD normal;
     var chol;
	 class diag;
run;*most normal;
proc anova data=HD;
     class diag;
	 model chol=diag;
	 means diag / hovtest=bf dunnett("0");
run;quit;*4-0,2-0;

proc univariate data=HD normal;
     var trestbps;
	 class diag;
run;*not normal;
proc anova data=HD;
     class diag;
	 model trestbps=diag;
	 means diag / hovtest=bf dunnett("0");
run;quit;*4-0,3-0,2-0;

proc univariate data=HD normal;
     var thalach;
	 class diag;
run;*normal;
proc anova data=HD;
     class diag;
	 model thalach=diag;
	 means diag / hovtest=bf dunnett("0");
run;quit;*all;

ods listing close;




