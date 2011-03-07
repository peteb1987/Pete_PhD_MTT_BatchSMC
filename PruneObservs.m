function [ Pruned ] = PruneObservs(t, Observs, Distn )
%PRUNEOBSERVS Remove all observations which are not near a target to save
%checking them every time

global Par;

Ns = length(Distn.clusters);
States = zeros(Ns, 4);
Spread = zeros(Ns, 4);

% Loop through targets and fetch state
for j = 1:Ns
    Parts = zeros(Par.NumPart, 4);
    for ii = 1:Par.NumPart
        Parts(ii, :) = Distn.clusters{j}.particles{ii}.tracks{1}.GetState(t)';
    end
    
    States(j, :) = mean(Parts);
    Spread(j, :) = range(Parts);
end

% Loop through observations and delete obvious clutter
for i = Observs.N:-1:1
    obs_cart = Pol2Cart(Observs.r(i, 1), Observs.r(i, 2));
    keep = false;
    for j = 1:Ns
        if (abs(obs_cart(1)-States(j,1))<(Spread(j,1)+Par.Vlimit))&&(abs(obs_cart(2)-States(j,2))<(Spread(j,2)+Par.Vlimit))
            keep = true;
            break;
        end
    end
    if ~keep
        Observs.r(i, :) = [];
        Observs.N = Observs.N - 1;
    end
end

Pruned = Observs;

end

function d = Dist(x1, x2)
d = sqrt((x1(1)-x2(1))^2+(x1(2)-x2(2))^2);
end