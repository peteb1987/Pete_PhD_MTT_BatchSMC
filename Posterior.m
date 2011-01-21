function [ post ] = Posterior(t, L, Set, Observs )
%POSTERIOR Calculate posterior probability of a TrackSet

global Par;

% This version is for a single track, no birth or death
assert(length(Set.tracks)==1, 'There should be only 1 track in this version.');

% Initialise probabilities
like = 0;
trans = 0;

% Loop through window
for tt = t-L+1:t
    
    % Get states
    state = Set.tracks{1}.GetState(tt);
    prev_state = Set.tracks{1}.GetState(tt-1);
    
    % Calculate likelihood
    if Par.FLAG_ObsMod == 0
        if any(abs(state(3:4))>1.5*Par.Vmax)||any(abs(state(1:2))>Par.Xmax)
            like = -inf;
        else
            like = like + log( mvnpdf(Observs(tt).r(1, :), state(1:2)', Par.ObsNoiseVar*ones(1,2)) );
        end
    elseif Par.FLAG_ObsMod == 1
        [bng, ~] = Cart2Pol(state(1:2));
        like = like + log( mvnpdf(Observs(tt).r(1, 1), bng, Par.ObsNoiseVar) );
    end
    
    % Calculate transition density
    trans = trans + log( mvnpdf(state', (Par.A * prev_state)', Par.Q) );
    
end

% Combine likelihood and transition density terms
post = like + trans;

end

