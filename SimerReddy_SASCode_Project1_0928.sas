proc import datafile="C:\Users\simer\Documents\SMU\DS_6372\Unit6_ProjectDetails\ProjectDetails\archive\LifeExpectancyData2.csv"
          dbms=dlm out=LED replace;
     delimeter=',';
     getnames=yes;
     
run;

proc print data=LED;
run;
ods rtf file="C:\Users\simer\Documents\SMU\DS_6372\Unit6_ProjectDetails\ProjectDetails\archive\sasoutput.rtf";
proc means data=LED n mean max min range std;
output out=meansout mean=mean std=std;
title 'Summary of LifeExpectancyData';
run;
proc sgscatter data=LED;
  title "Scatterplot Matrix of LifeExpectancyData set 1";
  matrix Life_expectancy   Year   Adult_Mortality infant_deaths Alcohol percentage_expenditure Hepatitis_B  / diagonal=(histogram);
;
run;

proc sgscatter data=LED;
  title "Scatterplot Matrix of LifeExpectancyData  set 2";
  matrix Life_expectancy   Measles BMI under_five_deaths Polio Total_expenditure Diphtheria HIV_AIDS   / diagonal=(histogram);
;
run;
proc sgscatter data=LED;
  title "Scatterplot Matrix of LifeExpectancyData  set 3";
  matrix Life_expectancy   GDP Population thinness_1_19_years thinness_5_9_years Income_composition_of_resources Schooling  / diagonal=(histogram);
;
run;
proc reg data=LED corr plots(label) = (rstudentleverage cooksd);
model Life_expectancy= Year   Adult_Mortality infant_deaths Alcohol percentage_expenditure Hepatitis_B Measles BMI under_five_deaths Polio Total_expenditure Diphtheria HIV_AIDS GDP Population thinness_1_19_years thinness_5_9_years Income_composition_of_resources Schooling / VIF;
run; quit;
*Important observations;
*1) infant_deaths and under_five_deaths are highly correlated at 0.9969. Take infant_deaths out;
*2) GDP and percentage_expenditure are highly correlated at 0.9593. Take GDP out ;
*3) thinness_5_9_years and thinness_1_19_years 0.9279. Take thinness_5_9_years out;
*4) What do we do about under_five_deaths and Diphtheria? From VIFs, it looks like there's a correlation among these, but looking at the correlation factors above, we see it is -0.1784. So, we can keep them both in the model;

* Take infant_deaths,percentage_expenditure and GDP out and check VIFs;
proc reg data=LED corr plots(label) = (rstudentleverage cooksd);
model Life_expectancy= Year   Adult_Mortality Alcohol percentage_expenditure Hepatitis_B Measles BMI under_five_deaths Polio Total_expenditure Diphtheria HIV_AIDS Population thinness_1_19_years  Income_composition_of_resources Schooling / VIF;
run; quit;

* Looking at the residual plots, it feels necessary to do some transformations.;

data LED;
SET LED;
log_Life_expectancy = log(Life_expectancy);
log_percentage_expenditure = log(percentage_expenditure);
log_Adult_Mortality = log(Adult_Mortality);
log_Hepatitis_B = log(Hepatitis_B);
log_Measles = log(Measles);
log_BMI = log(BMI);
log_under_five_deaths = log(under_five_deaths);
log_Polio = log(Polio);
log_Total_expenditure = log(Total_expenditure);
log_Diphtheria = log(Diphtheria);
log_HIV_AIDS = log(HIV_AIDS);
log_Population = log(Population);

run;
*Try log transforms;
proc reg data=LED corr plots(label) = (rstudentleverage cooksd);
model Life_expectancy= Year   log_Adult_Mortality Alcohol log_percentage_expenditure log_Hepatitis_B log_Measles log_BMI log_under_five_deaths log_Polio Total_expenditure log_Diphtheria log_HIV_AIDS log_Population thinness_1_19_years  Income_composition_of_resources Schooling / VIF;
run; quit;

*Looking at the residula plots after log transforms, the following transform seem helpful: percentage_expenditure , Measles,under_five_deaths, HIV_AIDS and Population;

proc reg data=LED corr plots(label) = (rstudentleverage cooksd);
model log_Life_expectancy= Year   Adult_Mortality Alcohol log_percentage_expenditure Hepatitis_B log_Measles BMI log_under_five_deaths Polio Total_expenditure Diphtheria log_HIV_AIDS log_Population thinness_1_19_years  Income_composition_of_resources Schooling / VIF;
run; quit;

* Model assesment using ASE;
*Run different models using partition fraction(test = .7) and ASEPlots ;
PROC GLMSELECT DATA= LED plots(stepaxis = number) = (criterionpanel ASEPlot) seed = 1; 
title "Forward selection using CV Press as stop criteria with ASE";
partition fraction(test = .5); 
class Status Country;
model log_Life_expectancy= Year   Adult_Mortality Alcohol log_percentage_expenditure Hepatitis_B log_Measles BMI log_under_five_deaths Polio Total_expenditure Diphtheria log_HIV_AIDS log_Population thinness_1_19_years  Income_composition_of_resources Schooling  / selection = Forward(stop=CV);
output out = Forwardsel ;
run;
PROC GLMSELECT DATA= LED plots(stepaxis = number) = (criterionpanel ASEPlot) seed = 1;
title "Backward selection using CV Press as stop criteria with ASE"; 
partition fraction(test = .5); 
class Status Country;
model log_Life_expectancy= Year   Adult_Mortality Alcohol log_percentage_expenditure Hepatitis_B log_Measles BMI log_under_five_deaths Polio Total_expenditure Diphtheria log_HIV_AIDS log_Population thinness_1_19_years  Income_composition_of_resources Schooling  / selection = backward(stop=CV);
output out = Backwardsel ;
run;
PROC GLMSELECT DATA= LED plots(stepaxis = number) = (criterionpanel ASEPlot) seed = 1;
title "Stepwise selection using CV Press as stop criteria with ASE"; 
partition fraction(test = .5); 
class Status Country;
model log_Life_expectancy= Year   Adult_Mortality Alcohol log_percentage_expenditure Hepatitis_B log_Measles BMI log_under_five_deaths Polio Total_expenditure Diphtheria log_HIV_AIDS log_Population thinness_1_19_years  Income_composition_of_resources Schooling  / selection = Stepwise(stop=CV);
output out = Stepwisesel ;
run;
PROC GLMSELECT DATA= LED plots(stepaxis = number) = (criterionpanel ASEPlot) seed = 1;
title "LASSO selection using CV Press as stop criteria with ASE"; 
partition fraction(test = .5); 
class Status Country;
model log_Life_expectancy= Year   Adult_Mortality Alcohol log_percentage_expenditure Hepatitis_B log_Measles BMI log_under_five_deaths Polio Total_expenditure Diphtheria log_HIV_AIDS log_Population thinness_1_19_years  Income_composition_of_resources Schooling  / selection = lasso( choose = cv) CVDETAILS;
output out = LASSOsel ;
run;
PROC GLMSELECT DATA= LED plots(stepaxis = number) = (criterionpanel ASEPlot) seed = 1;
title "LARS selection using CV Press as stop criteria with ASE"; 
partition fraction(test = .5); 
class Status Country;
model log_Life_expectancy= Year   Adult_Mortality Alcohol log_percentage_expenditure Hepatitis_B log_Measles BMI log_under_five_deaths Polio Total_expenditure Diphtheria log_HIV_AIDS log_Population thinness_1_19_years  Income_composition_of_resources Schooling  / selection = lars( choose = cv) CVDETAILS;
output out = LARSsel ;
run;

PROC GLM DATA= LED plots = all; 
title "Custom Model WITH VARIABLES SELECTED FROM stepwise SELECTION "; 
class Status Country;
model log_Life_expectancy = Adult_Mortality  Alcohol log_percentage_expenditure    log_under_five_deaths  Diphtheria log_HIV_AIDS  Income_composition_of_resources Schooling / solution ;
output out = Customsel ;
run;
ods rtf close;
