function PlotObs( Observs )
%PLOTOBS Plot observations

global Par;

T = length(Observs);

figure, hold on
xlim([-Par.Xmax Par.Xmax]), ylim([-Par.Xmax Par.Xmax])

for t = 1:T
    plot(Observs(t).r(:, 1), Observs(t).r(:, 2), 'xr');
end
    
pause(0.2);

end

