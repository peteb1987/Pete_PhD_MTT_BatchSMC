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
    
elseif Par.FLAG_ObsMod == 2
        
        xlim([-Par.Xmax Par.Xmax]), ylim([-Par.Xmax Par.Xmax])
        
        for t = 1:T
            plot(Observs(t).r(:, 2).*cos(Observs(t).r(:, 1)), Observs(t).r(:, 2).*sin(Observs(t).r(:, 1)), 'xr');
        end
        
        figure, hold on
        xlim([-pi, pi]), ylim([0 Par.Xmax]);
        for t = 1:T
            plot(Observs(t).r(:, 1), Observs(t).r(:, 2), 'xr');
        end
        
        figure
        subplot(1, 2, 1), hold on
        xlim([0, Par.T]), ylim([-pi, pi])
        for t = 1:T
            plot(t, Observs(t).r(:, 1), 'xr');
        end
        subplot(1, 2, 2), hold on
        xlim([0, Par.T]), ylim([0, Par.Xmax])
        for t = 1:T
            plot(t, Observs(t).r(:, 2), 'xr');
        end

end

pause(0.2);

end