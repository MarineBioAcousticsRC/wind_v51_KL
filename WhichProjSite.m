function [slat,slon] = WhichProjSite(Proj,site)
% find lat lon of Proj site
if strcmp(Proj,'FLIP')
    switch site
        case 'F1'
            slat = 33 +(08.126/60); slon = 118 + (42.540/60);  %2006
    end
end
if strcmp(Proj,'GofAK')
    switch site
        case 'CB'
            slat = 58.66302424; slon =	148.0451015;  %CB
        case 'PT'
            slat = 56.24340417;	slon = 142.7572458;  %PT
        case 'QN'
            slat = 56.34023333;	slon = 145.1855944; %QN
        case 'AB'
            slat = 57.51366667;	slon = 146.5008333; %AB
        case 'CA'
            slat = 59.00897667; slon =	148.90422; %CA
        case 'KO'
            slat = 57.33508889;	slon = 150.6878222; %KO
        case 'BD'
            slat = 52.076000000; slon = 184.3601667; %BD
        case 'KOA'
            slat = 57 + (13.440/60);	slon = 150 +(31.700/60); %KOA
    end
end
if strcmp(Proj,'SOCAL')
    switch site
        
        case 'A'
            slat = 33.25184697;	slon = 118.2506545; %A
        case 'A2'
            slat = 33.22731667;	slon = 118.2755229; %A2
        case 'B'
            slat = 34.274958; slon = 	120.0244633; %B
        case 'C'
            slat = 34.31946708; slon =	120.8053204; %C
        case 'M'
            slat = 33.51263095; slon =	119.2500944; %M
        case 'N'
            slat = 32.36977843; slon =	118.5645078; %N
        case 'E'
            slat = 32.65695833; slon =	119.4771906; %E
        case 'H'
            % CORRECTED 2026-09-01: was slat = 32.84412432; slon = 119.8441243;
            % that longitude repeated the latitude's digits (8441243) and sat
            % 66 km from every recent deployment. Replaced with the mean of
            % SOCAL_H_76 to SOCAL_H_80 (5 deployments, 0.10 km spread).
            slat = 32.862028; slon = 119.135992; %H
        case 'Q'
            slat = 33.820175; slon = 	118.6290333; %Q
        case 'R'
            slat = 33.16013889; slon =	120.0092806; %R
        case 'S'
            slat = 32.484875; slon =	118.2724111; %S
        case 'SN'
            slat = 32.91499;    slon = 120.37539; %SN
        case 'T'
            slat = 32.88024; slon =	117.5742; %T
        case 'G'
            slat = 32.9263; slon = 118.6170; %G
        case 'CCE'
            slat = 33.47808333; slon = 122.5496667;  % CCE!
        case 'DCPPC'
            slat = 35.400000000; slon=  121.562500000; % DCPPC
        case 'CORC'
            slat = 31.747000000;  slon = 121.378000000; %CORC
        case 'GC'
            slat = 36.4351;	slon = 121.9608; % Granite Canyon
        case 'U'
            slat =31.85163333;	slon =	118.4845167; % U
        case 'BajaGI'
            slat =29.14103333	;	slon =118.2609667; %BajaGI
        case 'FLIP08N1'
            slat = 33+(03.023/60); slon =	118+(40.893/60); %FLIP 08N1
        case 'W'
            slat = 33.54045; slon = 120.25855; % W
        case 'P'
            slat = 32 + (52.9171/60); slon = 	117 + (23.9115/60); %P
        case 'Benio'
             slat = 34 + (16.515/60); slon = 	119 + (35.53/60); %P
        % ---- added 2026-09-01 from 2023dep_to_260828rec.xlsx ----
        case 'GI'
            slat = 29.142475; slon = 118.260767; % Baja_GI depl 05,06; same site as 'BajaGI' above (0.16 km); added 2026-09-01
        case 'IV'
            slat = 34.299017; slon = 119.916367; % CINMS_IV depl 01, mean of 2; added 2026-09-01
        case 'V'
            slat = 32.594839; slon = 118.043063; % SOCAL_V depl 02,03,05,06,07,08, mean of 10; added 2026-09-01
    end
end

if strcmp(Proj,'SDT')
    switch site
        case 'BF'
            slat = 32 + (51.718/60); slon = 	117 + (36.448/60); % SDT_BF_01
        case 'DP'
            slat = 32 + (51.494/60); slon = 	117 + (27.172/60); % SDT_DP_01
        case 'GR'
            slat = 32 + (49.220/60); slon = 	117 + (41.800/60); % SDT_GR_01
        case 'HP'
            slat = 32 + (45.597/60); slon = 	117 + (39.302/60); % SDT_HP_01
        case 'PR'
            slat = 32.9147; slon = 117.4962; % SDT_PR_01
        case 'SL'
            slat = 32 + (47.916/60); slon = 	117 + (34.489/60); % SDT_SL_01
        case 'SW'
            slat = 32 + (42.502/60); slon = 	117 + (45.800/60); % SDT_SW_01
        case 'SZ'
            slat = 32 + (49.691/60); slon = 	117 + (30.947/60); % SDT_SZ_01
        case 'WQ'
            slat = 32 + (46.301/60); slon = 	117 + (47.905/60); % SDT_WQ_01
        case 'NDBC' %buoy 46086
            slat = 32.504; slon = 118.029; % buoy coordinates (San Clemente Basin, 46086)
        % ---- added 2026-09-01 from 2023dep_to_260828rec.xlsx ----
        case 'WWE'
            slat = 32.853950; slon = 117.618100; % SDT_WWE_01; added 2026-09-01
    end
end

if strcmp(Proj,'GofMX')
    switch site
        case 'DC'
            slat = 29.0490; slon = 86.0975; %GofMx DC
        case 'DT'
            slat = 25.53484394; slon = 84.6340803; %GOM DT
        case 'GC'
            slat = 27.55671212; slon = 91.1689303; %GOM GC
        case 'MP'
            slat = 29.25399697; slon = 88.29345455; % GOM MP
        case 'HH'
            slat = 25.02466; slon =	84.39344333; % HH
        case 'EF'
            slat = 27.7330833; slon = 92.46221806; %GOM EF
        case 'EI'
            slat =27.88453333;	slon =92.40936667;%GOM EI
        case 'WF'
            slat =	27.65405;	slon =	93.39408333;% GOM WF
        case 'GI'
            slat = 28.6292;	slon = 	90.04048333; %GOM GI
        case 'EP'
            slat =29.28108333;	slon =	87.85831667; %GOM EP
        case 'NRS0614'
            slat =  28.00;  slon = 86.994; %GOM NRS06 2014
        case 'NRS0616'
            slat = 28.2502; slon = 86.8327; %GOM NRS06 2016
        case 'AC'
            slat = 26 + (53.8430/60); slon = 94 + (30.1209/60); %AC
        case 'MR'
            slat = 23 + (6.3713/60); slon =	97 + (5.4657/60); %MexRdiges
        case 'GA'
            slat = 27 +(54.4164/60);  slon = 	92 + (36.9155/60);
        case 'Y1C'
            slat = 21 + (07.0230/60);	slon = 95  + (15.3482/60);
        case 'CE'
            slat = 22 + (51.78042/60); slon =	91 + (01.48440/60);
        case 'Y1B'
            slat = 24 + (58.166/60); slon = 	87 + (12.516/60);
        case 'Y5A'
            slat = 27 + (33.205/60); slon = 	89 + (51.210/60);
        case 'LC'
            slat = 26 + (44.7913/60); slon =	85 + (57.9978/60);
        case 'SL'
            slat = 28 + (35.9813/60); slon = 	89 + (16.5632/60);
        case 'CC'
            slat = 27 + (06.583/60); slon = 	96 + (19.467/60);
        case 'TUX'
            slat = 20 + (51.325/60); slon = 	96 + (49.477/60);
        % ---- added 2026-09-01 from 2023dep_to_260828rec.xlsx ----
        case 'EB'
            slat = 27.492445; slon = 96.007697; % GOM_EB depl 01,02, mean of 2; added 2026-09-01
        case 'MC'
            slat = 28.846015; slon = 88.468517; % GOM_MC depl 18,19, mean of 2; added 2026-09-01
        case 'NPI'
            slat = 26.675480; slon = 96.405928; % GOM_NPI_02; added 2026-09-01
        case 'RW1'
            slat = 22.360417; slon = 86.742550; % GOM_RW1_01; added 2026-09-01
        case 'RW2'
            slat = 23.866650; slon = 87.752033; % GOM_RW2_01; added 2026-09-01
        case 'RW3'
            slat = 23.369150; slon = 89.620717; % GOM_RW3_01; added 2026-09-01
        case 'RW4'
            slat = 22.572050; slon = 90.581633; % GOM_RW4_01; added 2026-09-01
        case 'RW5'
            slat = 21.815133; slon = 92.445083; % GOM_RW5_01; added 2026-09-01
        case 'RW6'
            slat = 18.770017; slon = 94.179850; % GOM_RW6_01; added 2026-09-01
        case 'RW7'
            slat = 22.691067; slon = 97.397433; % GOM_RW7_01; added 2026-09-01
        case 'RW8'
            slat = 24.399300; slon = 96.949950; % GOM_RW8_01; added 2026-09-01
        case 'RW9'
            slat = 25.498267; slon = 96.348417; % GOM_RW9_01; added 2026-09-01
        case 'SF'
            slat = 26.100133; slon = 84.602150; % GOM_SF_01; added 2026-09-01
        case 'SJ'
            slat = 27.824000; slon = 95.016350; % GOM_SJ_01; added 2026-09-01
        case 'Y4A'
            slat = 25.368167; slon = 90.373667; % GOM_Y4A_01; added 2026-09-01
        case 'Y4B'
            slat = 26.931478; slon = 93.032615; % GOM_Y4B_01; added 2026-09-01
        case 'Y4D'
            slat = 20.147597; slon = 93.737070; % GOM_Y4D_01; added 2026-09-01
        case 'Y5B'
            slat = 24.869650; slon = 93.539350; % GOM_Y5B_01; added 2026-09-01
        case 'Y5C'
            slat = 19.312600; slon = 92.882450; % GOM_Y5C_01; added 2026-09-01
        case 'Y5D'
            slat = 24.312250; slon = 91.097833; % GOM_Y5D_01; added 2026-09-01
    end
end

if strcmp(Proj,'WAT')
    switch site
        case 'JAXD'
            slat = 30.75156667 ; slon =	 79.8587375; %JAXD
        case 'NFCA'
            slat = 37.16671667;  slon =	27.996; %NFCA
        case 'HATB'
            slat = 35.58413333; slon = 	74.74985; %HATB
        case 'WC'
            slat = 39.83248333;	slon= 69.98205; %WC
        case 'OC'
            slat = 40.26331667;	slon=	67.98626667;% OC
        case 'BR'
            slat =	40+ (01.967/60); slon = 67+ (59.301/60); %BR
        case 'BC'
            slat = 39.190775; slon = 72.22791667; % BC
        case 'NC'
            slat = 39.83248333; slon =  69.98205; % NC
        case 'BS'
            slat = 30.58340833; slon = 77.390575; % BS
        case 'GS'
            slat = 33.666325; slon = 76.00875833;  % GS
        case 'BP'
            slat = 32.10649167;  slon =	77.09220833;% BP
        case 'HZ'
            slat = 41 + (03.699/60); slon =	66 + (21.093/60);
    end
end

if strcmp(Proj,'ADRIA')
    switch site
        case 'JD'
            slat = 42+(20.651/60); slon = 360-(17+(49.235/60)); %JD east long
    end
end

if strcmp(Proj,'Antarc')
    switch site
        case 'EA'
           slat = -65 - (50.54/60);	slon = 360 - (144 + (26.7/60)); %EAST Long
        case 'SSI'
          slat =  -61- (27.469/60); slon = 57 + (56.515/60); %Antarc SSI
        case 'EI'
            slat = -60 - (53.214/60); slon =	55 + (57.238/60);
        case 'EIE'
           slat =  -61 - (15.112/60); slon =	53 + (29.006/60);

    end
end

if strcmp(Proj,'CANARC')
    switch site
        case 'PI'
            slat = 72.72497; slon = 74.5; % Pond Inlet
        case 'BS'
            slat = 74.34078; slon = 94.53752; % Barrow Strait
        case 'LI'
            slat = 72 +(15.260/60); slon = 80 + (34.205/60); % LI
        case 'MI'
            slat = 72 + (17/60); slon = 80 +(27.2/60); % Milne Inlet
    end
end

if strcmp(Proj,'NUNAT')
    switch site
        case 'RB'
            slat = 59 +(31.5/60); slon = 63 + (15.14/60); % 
        case 'SB'
            slat = 58 + (42/60); slon = 62 +(31.15/60); % 
    end
end

if strcmp(Proj,'HAWAII')
    switch site
        case 'Pagan'
            slat = 17.96308; slon = 145.481117; % Pagan in East Lon
        case 'PHA12'
            slat =	27+ (43.774/60); slon = 175+ (33.221/60); %PHA12
        case 'LANAIA'
            slat = 20  + (43.742/60); slon =	157 + (04.363/60);
        case 'PHRB'
            slat = 27 + (43.054/60);	slon = 175 + (33.283/60);
        case 'TinianA'
            slat = 15 + (02.402/60); slon = 360-(145 +(45.463/60)); % east
        case 'SaipanA'
            slat = 15 + (18.969/60); slon = 360 - (145 + (27.402/60)); % east


    end
end

if strcmp(Proj,'OCNMS')
    switch site
        case ' '
    end
end

if strcmp(Proj,'SEAK')
    switch site
        case 'SS'
           slat = 57 + (06.516/60); slon =	135 + (30.516/60);

    end
end

if strcmp(Proj,'OOI')
    switch site
        case 'AXBS'
            slat = 45.81681; slon =	129.75421; % AXBS
        case ''
            slat = 44.51519; slon =	125.38987; % AXBS
    end
end

if strcmp(Proj,'SanctSound')
    switch site
        case 'MB01'
            slat = 36.798; slon =	121.976; % MB01
        case 'OC01'
            slat = 48.3938; slon =	124.654; % OC01
        case 'MB03'
            slat = 36.3703; slon = 122.3148; % MB03 - Pt Sur Sosus
        case "CI03"
            slat = 33.48687; slon = 119.01609; % Channal ISlands 03
        case "FK01"
            slat = 24.43313; slon = 81.93068; % Florida Keys 2020 

    end
end

% ---- AZORES (Azores, Atlantic) added 2026-09-01 from 2023dep_to_260828rec.xlsx ----
if strcmp(Proj,'AZORES')
    switch site
        case 'A'
            slat = 38.626156; slon = 27.413850; % AZORES_A depl 03,04, mean of 3; added 2026-09-01
        case 'B'
            slat = 38.648367; slon = 27.381483; % AZORES_B_01; added 2026-09-01
    end
end

% ---- CHNMS (Chumash Heritage NMS) added 2026-09-01 from 2023dep_to_260828rec.xlsx ----
if strcmp(Proj,'CHNMS')
    switch site
        case 'NO'
            slat = 34.574278; slon = 120.713283; % CHNMS_NO depl 01,02,03, mean of 3; added 2026-09-01
        case 'SLE'
            slat = 34.663250; slon = 121.604000; % CHNMS_SLE_01; added 2026-09-01
    end
end

% ---- WEA (Wind Energy Areas) added 2026-09-01 from 2023dep_to_260828rec.xlsx ----
if strcmp(Proj,'WEA')
    switch site
        case 'HUA'
            slat = 41.057483; slon = 124.685317; % WEA_HUA_01; added 2026-09-01
        case 'MBA'
            slat = 35.537350; slon = 121.782500; % WEA_MBA_01; added 2026-09-01
    end
end

% ---- LJ (La Jolla) added 2026-09-01 from 2023dep_to_260828rec.xlsx ----
if strcmp(Proj,'LJ')
    switch site
        case 'RW'
            slat = 32.858325; slon = 117.357642; % LJ_RW depl 01,02, mean of 2; added 2026-09-01
    end
end
