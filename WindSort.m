function [MPTF] = WindSort(wsfinal,mpwfinal)
% JAH 11-2020
%sort into speed bins
    force{1} = find(wsfinal > 0.3 & wsfinal <= 1.6);
    MPTF{1} = mpwfinal(:,force{1});
    force{2} = find(wsfinal > 1.6 & wsfinal <= 3.4);
    MPTF{2} = mpwfinal(:,force{2});
    force{3} = find(wsfinal > 3.4 & wsfinal <= 5.5);
    MPTF{3} = mpwfinal(:,force{3});
    force{4} = find(wsfinal > 5.5 & wsfinal <= 8.0);
    MPTF{4} = mpwfinal(:,force{4});
    force{5} = find(wsfinal > 8.0 & wsfinal <= 10.8);
    MPTF{5} = mpwfinal(:,force{5});
    force{6} = find(wsfinal > 10.8 & wsfinal <= 13.9);
    MPTF{6} = mpwfinal(:,force{6});
    force{7} = find(wsfinal > 13.9 & wsfinal <= 17.2);
    MPTF{7} = mpwfinal(:,force{7});
    force{8} = find(wsfinal > 17.2 & wsfinal <= 20.8);
    MPTF{8} = mpwfinal(:,force{8});
    force{9} = find(wsfinal > 20.8 & wsfinal <= 24.5);
    MPTF{9} = mpwfinal(:,force{9});
    force{10} = find(wsfinal > 24.5 & wsfinal <= 28.5);
    MPTF{10} = mpwfinal(:,force{10});
    force{11} = find(wsfinal > 28.5 & wsfinal <= 32.7);
    MPTF{11} = mpwfinal(:,force{11});
    force{12} = find(wsfinal > 32.7 );
    MPTF{12} = mpwfinal(:,force{12});