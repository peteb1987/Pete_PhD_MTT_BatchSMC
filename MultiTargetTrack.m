function [ Distns, ESS, ESS_pre_resam, num_resamples ] = MultiTargetTrack( Observs )
%MULTITARGETTRACK Runs a batch SMC tracking algorithm for multiple
% targets with missed observations and clutter

global Par;

% Initialise particle array (an array of particle arrays)
Distns = cell(Par.T, 1);
ESS = zeros(Par.T, 1);
ESS_pre_resam = zeros(Par.T, 1);
num_resamples = 0;

% Initialise particle set
init_track = cell(Par.NumTgts, 1);
for j = 1:Par.NumTgts
    init_track{j} = Track(0, 1, {Par.TargInitState{j}-[Par.TargInitState{j}(3:4)' 0 0]'}, 0);
end
init_track_set = TrackSet(init_track);
part_set = repmat({init_track_set}, Par.NumPart, 1);
InitEst = PartDistn(part_set);

% Loop through time
for t = 1:Par.T
    
    tic;
    
    disp('**************************************************************');
    disp(['*** Now processing frame ' num2str(t)]);
    
    if t==1
        [Distns{t}, ESS(t), ESS_pre_resam(t), resample] = BatchSMC(t, t, InitEst, Observs);
    elseif t<Par.L
        [Distns{t}, ESS(t), ESS_pre_resam(t), resample] = BatchSMC(t, t, Distns{t-1}, Observs);
    else
        [Distns{t}, ESS(t), ESS_pre_resam(t), resample] = BatchSMC(t, Par.L, Distns{t-1}, Observs);
    end

    if resample
        num_resamples = num_resamples + 1;
    end
    
    if resample
        disp('*** Resampled in this frame');
    end
    disp(['*** Frame ' num2str(t) ' processed in ' num2str(toc) ' seconds']);
    disp('**************************************************************');

end




end



function [Distn, ESS, ESS_pre, resample] = BatchSMC(t, L, Previous, Observs)
% Execute a step of the SMC batch sampler

global Par;

% Runs an SMC on a batch of frames. We can alter states in t-L+1:t. Frame
% t-L is also needed for filtering, transition density calculations, etc.

% Initialise particle array and weight array
Distn = Previous.Copy;

% Create a temporary array for un-normalised weights
weight = zeros(Par.NumPart, 1);

% Loop through particles
for ii = 1:Par.NumPart
    
    Part = Distn.particles{ii};
    
    % Calculate outgoing posterior probability term
    prev_post_prob = Posterior(t-1, L-1, Part, Observs);
    
    % Extend all tracks with an ML prediction
    Part.ProjectTracks(t);
    
    % Sample a joint association hypothesis for time t
    jah_ppsl = Part.SampleJAH(t, Observs);
    
    state_ppsl = zeros(Par.NumTgts, 1);
    NewTracks = cell(Par.NumTgts, 1);
    
    % Loop through targets
    for j = 1:Par.NumTgts
        
        % Draw up a list of associated hypotheses
        obs = ListAssocObservs(t, L, Part.tracks{j}, Observs);
        
        % Run a Kalman filter for each target
        [KFMean, KFVar] = KalmanFilter(obs, Part.tracks{j}.GetState(t-L), 1E-2*eye(4));
        
        % Sample Kalman filter
        [NewTracks{j}, state_ppsl(j)] = SampleKalman(KFMean, KFVar);
        
        % Update distribution
        Part.tracks{j}.Update(t, NewTracks{j}, []);
        
    end
    
    % Calculate new posterior
    post_prob = Posterior(t, L, Part, Observs);
    
    % Update the weight
    weight(ii) = Distn.weight(ii) ...
               + (post_prob - prev_post_prob) ...
               - (sum(state_ppsl) + jah_ppsl);

    if isnan(weight(ii))
        weight(ii) = -inf;
    end
    
    if isinf(weight(ii))
        disp(['zero weight in particle ' num2str(ii)]);
    end
    
end

assert(~all(isinf(weight)), 'All weights are zero');

% disp(['Mean/Variance of proposal term: ' num2str([mean(ppsl_arr), var(ppsl_arr)])]);
% disp(['Mean/Variance of posterior term: ' num2str([mean(post_arr), var(post_arr)])]);

% Normalise weights
weight = exp(weight);
weight = weight/sum(weight);
weight = log(weight);

% Attach weights to particles
for ii = 1:Par.NumPart
    Distn.weight(ii) = weight(ii);
end

% Test effective sample size
ESS_pre = CalcESS(weight);
assert(~isnan(ESS_pre), 'Effective Sample Size is non defined (probably all weights negligible)');

% PlotTracks(Distn)
% uiwait

if (ESS_pre < 0.5*Par.NumPart)
    % Resample
    Distn = SystematicResample(Distn, weight);
    ESS = Par.NumPart;
    resample = true;
   
else
    resample = false;
    ESS = ESS_pre;
    
end

% PlotTracks(Distn)
% uiwait

end