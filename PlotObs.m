function PlotObs( Observs )
%PLOTOBS Plot observations

global Par;

T = length(Observs);

figure, hold on

if Par.FLAG_ObsMod == 0
    
    xlim([-Par.Xmax Par.Xmax]), ylim([-Par.Xmax Par.Xmax])
    
    for t = 1:T
        plot(Observs(t).r(:, 1), Observs(t).r(:, 2), 'xr');
    end
    
elseif Par.FLAG_ObsMod == 1
    
    xlim([0 T]), ylim([-pi, pi]);
    
    for t = 1:T
        plot(t, Observs(t).r(:,1), 'xr');
    end

end

pause(0.2);

end