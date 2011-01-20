function PlotTracks( Distn, f )
%PLOTTRACKS Plot the output of the batch SMC multi-target tracker

global Par;

if nargin == 1
    % Create a window
    figure, hold on
    xlim([-Par.Xmax Par.Xmax]), ylim([-Par.Xmax Par.Xmax])

else
    figure(f)
end
    
% Loop through particles
for ii = 1:Par.NumPart
    
    % Loop through targets
    for j = 1:Distn.particles{ii}.N
        
        % Choose a colour
        col = [rand, rand, rand];
        
        % create an array
        num = Distn.particles{ii}.tracks{j}.num;
        x = zeros(num,1);
        y = zeros(num,1);
        
        % Collate state
        for k = 1:num
            x(k) = Distn.particles{ii}.tracks{j}.state{k}(1);
            y(k) = Distn.particles{ii}.tracks{j}.state{k}(2);
        end
            
        % Plot track
        plot(x, y, '-', 'color', col);
        
    end

end

plot(0, 0, 'xk');

end