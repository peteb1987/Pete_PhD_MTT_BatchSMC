function [ jah_ppsl ] = SampleJAH( t, Set, Observs )
%SAMPLEJAH Probabilistically generates a joint association hypothesis for a
% single frame.

global Par;

N = Observs(t).N;
jah_ppsl = zeros(Set.N, 1);

% Generate a random permutation order
order = randperm(Set.N);

% List of used associations
used_ass = [];

% Loop through targets
for j = order
        
        ppsl_weights = zeros(N+1, 1);
        
        % Get state
        x = Set.tracks{j}.GetState(t);
        
        [bng, rng] = Cart2Pol(x(1:2));
        range_squ = x(1)^2 + x(2)^2;
        range = sqrt(range_squ);
        jac = [-x(2)/range_squ, x(1)/range_squ, 0, 0; x(1)/range, x(2)/range, 0, 0];
        mean_obs = [bng; rng];
        var_obs = Par.R + jac * Par.Q * jac';
        
        % Find the marginal likelihood of each observation, given the previous state
        for i = 1:N
            
            obs_cart  = Pol2Cart(Observs(t).r(i, 1), Observs(t).r(i, 2));
            mean_cart = Pol2Cart(mean_obs(1), mean_obs(2));
            if Dist(obs_cart, mean_cart)<Par.Vmax
                ppsl_weights(i) = (Par.PDetect/Observs(t).N) * mvnpdf(Observs(t).r(i, :), mean_obs', 7.5* var_obs);
%                 ppsl_weights(i) = mvnpdfFastSymm(obs_cart, mean_cart, Par.AuctionVar);
            else
                ppsl_weights(i) = 0;
            end
%             ppsl_weights(i) = mvnpdf(Observs(t).r(i, :), mean_obs', var_obs);
            
%             obs_cart = Pol2Cart(Observs(t).r(i, 1), Observs(t).r(i, 2));
%             ppsl_weights(i) = mvnpdf([obs_cart Set.tracks{j}.state{t}(3:4)' ], Set.tracks{j}.state{t}', Par.Q);
%             [bng, rng] = Cart2Pol(Set.tracks{j}.state{t}(1:2));
%             if (Observs(t).r(i, 1) - bng) > pi
%                 bng = bng + 2*pi;
%             elseif (Observs(t).r(i, 1) - bng) < -pi
%                 bng = bng - 2*pi;
%             end
%             ppsl_weights(i) = mvnpdf(Observs(t).r(i, :), [bng, rng], diag(Par.R)');
        end
        
        % Clutter
%         ppsl_weights(N+1) = Par.UnifPosDens;
        ppsl_weights(N+1) = Par.ClutDens * (1-Par.PDetect);
%         ppsl_weights(N+1) = 0.001*mvnpdf(mean_obs', mean_obs', var_obs);
        
        % Remove used ones
        ppsl_weights(used_ass) = 0;
        
%         % Never let anything be much more likely than clutter, 
%         if ppsl_weights(N+1) < 0.1*max(ppsl_weights)
%             ppsl_weights(N+1) = 0.1*max(ppsl_weights);
%         end
%         if ppsl_weights(N+1) > 2*max(ppsl_weights)
%             ppsl_weights(N+1) = 2*max(ppsl_weights);
%         end
        
        % Normalise
        ppsl_weights = ppsl_weights/sum(ppsl_weights);
        
        % Sample
        ass = randsample(N+1, 1, true, ppsl_weights);
        
        % Probability
        jah_ppsl(j) = log(ppsl_weights(ass));        
        
        % Assign it
        if ass==N+1
            ass = 0;
        else
            used_ass = [used_ass; ass];
        end
        Set.tracks{j}.SetAssoc(t, ass);
        
end

end

function d = Dist(x1, x2)
d = sqrt((x1(1)-x2(1))^2+(x1(2)-x2(2))^2);
end