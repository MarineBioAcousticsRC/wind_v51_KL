%SOCAL_N_58_pltparams.txt
% eval(thisfile)

dname = 'GofAK_AB';
%B = [6399,6588];	% bad days per oneAtaTime.m
B = [];

ifile = 'GofAK_AB_01_01_HP_WindNoise.mat';		% input file name
ipath = 'D:\Wind_TF\Output';	% input file path

navepd = 5760;		% number of averages per day for df100 1Hz/5s

dctype = 1; 		% switch for decimation type
			% 0 = none, 1 = R2013b, 2 = R2016b
rm_fifo = 1;  		% needed for SOCAL_N_60

pflag = 1;		% print figures to files

sflag = 1;		% save *DailyAvesB.mat and *MonthlySpectra.mat output files

av = [100 100000 10 120];	% plot axis vector  