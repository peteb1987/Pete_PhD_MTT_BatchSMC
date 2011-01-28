function [ post ] = Posterior(t, L, Set, Observs )
%POSTERIOR Calculate posterior probability of a TrackSet

% DOES NOT DO TARGET BIRTH/DEATH

global Par;

% Initialise probabilities
like = zeros(Set.N, 1);
trans = zeros(Set.N, 1);
clut = zeros(L, 1);
assoc = zeros(L, 1);

% Loop through targets
for j = 1:Set.N
    
    end_time = min(t, Set.tracks{j}.death-1);
    
    % Loop through window
    for tt = t-L+1:end_time
        
        % Get states
        state = Set.tracks{j}.GetState(tt);
        prev_state = Set.tracks{j}.GetState(tt-1);
        
        % Calculate likelihood
        if any(abs(state(3:4))>2.5*Par.Vmax)||any(abs(state(1:2))>Par.Xmax)
            like(j) = -inf;
        else
            ass = Set.tracks{j}.GetAssoc(tt);
            if ass~=0
                if Par.FLAG_ObsMod == 0
                    like(j) = like(j) + log( mvnpdfFastSymm(Observs(tt).r(ass, :), state(1:2)', Par.ObsNoiseVar) );
                elseif Par.FLAG_ObsMod == 1
                    [bng, ~] = Cart2Pol(state(1:2));
                    like = like + log( mvnpdf(Observs(tt).r(ass, 1), bng, Par.ObsNoiseVar) );
                elseif Par.FLAG_ObsMod == 2
                    [bng, rng] = Cart2Pol(state(1:2));
                    if abs(Observs(tt).r(ass, 1) - bng) > pi
                        bng = bng + 2*pi;
                    elseif abs(Observs(tt).r(ass, 1) - bng) < - pi
                        bng = bng - 2*pi;
                    end
                    like(j) = like(j) + log( mvnpdf(Observs(tt).r(ass, :), [bng rng], diag(Par.R)') );
                end
            end
        end
        
        % Calculate transition density
        trans(j) = trans(j) + log( (1-Par.PDeath) * mvnpdfQ(state', (Par.A * prev_state)') );
%         trans(j) = trans(j) + log( (1-Par.PDeath) * mvnpdf(state', (Par.A * prev_state)', Par.Q) );
        
    end
    
    if end_time < t
        trans(j) = trans(j) + log(Par.PDeath);
    end
    
end

% Clutter and association terms
for tt = t-L+1:t
    k = tt - (t-L);
    
    % Association prior
    num_unassigned = Observs(tt).N;
    obs_assigned = [];
    for j = 1:Set.N
        if Set.tracks{j}.Present(tt)
            ass = Set.tracks{j}.GetAssoc(tt);
            if any(ass==obs_assigned)
                assoc(k) = -inf;
                break
            elseif ass>0
                obs_assigned = [obs_assigned; ass];
                num_unassigned = num_unassigned - 1;
                assoc(k) = assoc(k) + log(Par.PDetect/num_unassigned);
            elseif ass==0
                assoc(k) = assoc(k) + log(1-Par.PDetect);
            else
                error('Invalid association');
            end
        end
    end
    
    % Clutter term
    num_targ = length(obs_assigned);
    num_clut = Observs(tt).N - num_targ;
    clut(k) = num_clut * log(Par.ClutDens);

end

% Combine likelihood and transition density terms
post = sum(like) + sum(trans) + sum(clut) + sum(assoc);

end