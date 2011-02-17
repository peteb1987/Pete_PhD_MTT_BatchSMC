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
if Par.FLAG_TargInit
    init_track = cell(Par.NumTgts, 1);
    for j = 1:Par.NumTgts
        init_track{j} = Track(0, 1, {Par.TargInitState{j}-[Par.TargInitState{j}(3:4)' 0 0]'}, 0);
    end
else
    init_track = {};
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
        disp(['*** ESS = ' num2str(ESS_pre_resam(t)) ' : Resampled in this frame']);
    else
        disp(['*** ESS = ' num2str(ESS_pre_resam(t))]);
    end
    disp(['*** Tracks detected in first particle: ' num2str(Distns{t}.particles{1}.N)]);
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

% Identify potential birth sites
if (~Par.FLAG_TargInit)&&(t>2)
    BirthSites = FindBirthSites(t, Observs);
else
    BirthSites = cell(0, 1);
end
disp(['*** ' num2str(size(BirthSites, 1)) ' birth sites in this frame']);

Diagnostics.post_arr = zeros(Par.NumPart, 1);
% Diagnostics.prev_post_arr = zeros(Par.NumPart, 1);
Diagnostics.state_ppsl_arr = zeros(Par.NumPart, 1);
Diagnostics.jah_ppsl_arr = zeros(Par.NumPart, 1);
Diagnostics.weight_arr = zeros(Par.NumPart, 1);

% Loop through particles
for ii = 1:Par.NumPart
    
    Part = Distn.particles{ii};
    
    % % Calculate outgoing posterior probability term
    % prev_post_prob = Posterior(t-1, L-1, Part, Observs);
    
    % Extend all tracks with an ML prediction
    Part.ProjectTracks(t);
    
    % Sample associations
    jah_ppsl = Part.SampleAssociations(t, L, Observs, BirthSites);
    
    state_ppsl = zeros(Par.NumTgts, 1);
    NewTracks = cell(Par.NumTgts, 1);
    
    % Loop through targets
    for j = 1:Part.N
        
        % Only need examine those which are present after t-L
        if Part.tracks{j}.death > t-L+1
            
            % How long should the KF run for?
            last = min(t, Part.tracks{j}.death - 1);
            first = max(t-L+1, Part.tracks{j}.birth+1);
            num = last - first + 1;
            
            % Draw up a list of associated hypotheses
            obs = ListAssocObservs(last, num, Part.tracks{j}, Observs);
            
            % Run a Kalman filter the target
            [KFMean, KFVar] = KalmanFilter(obs, Part.tracks{j}.GetState(first-1), Par.KFInitVar*eye(4));
            
            % Sample Kalman filter
            [NewTracks{j}, state_ppsl(j)] = SampleKalman(KFMean, KFVar);
            
            % Update distribution
            Part.tracks{j}.Update(last, NewTracks{j}, []);
            
        end
        
    end
    
    % Calculate new posterior
    post_prob = Posterior(t, L, Part, Observs);
%     post_prob = Posterior(t-1, L-1, Part, Observs);
    
    % Update the weight
    weight(ii) = Distn.weight(ii) ...
               + (post_prob)... - prev_post_prob) ...
               - (sum(state_ppsl) + jah_ppsl);
           
	  Diagnostics.post_arr(ii) = post_prob;
%     Diagnostics.prev_post_arr(ii) = prev_post_prob;
    Diagnostics.state_ppsl_arr(ii) = sum(state_ppsl);
    Diagnostics.jah_ppsl_arr(ii) = jah_ppsl;
    Diagnostics.weight_arr(ii) = weight(ii);
           
    if isnan(weight(ii))
        weight(ii) = -inf;
    end
    
    if isinf(weight(ii))
        disp(['zero weight in particle ' num2str(ii)]);
    end
    
end

assert(~all(isinf(weight)), 'All weights are zero');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DIAGNOSTICS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Diagnostics.post_arr = sort(Diagnostics.post_arr, 'descend');
% % Diagnostics.prev_post_arr = sort(Diagnostics.prev_post_arr, 'descend');
% Diagnostics.state_ppsl_arr = sort(Diagnostics.state_ppsl_arr, 'descend');
% Diagnostics.jah_ppsl_arr = sort(Diagnostics.jah_ppsl_arr, 'descend');
% Diagnostics.weight_arr = sort(Diagnostics.weight_arr, 'descend');
% 
% Diagnostics.post_arr(1) - Diagnostics.post_arr(2)
% Diagnostics.prev_post_arr(1) - Diagnostics.prev_post_arr(2)
% Diagnostics.state_ppsl_arr(1) - Diagnostics.state_ppsl_arr(2)
% Diagnostics.jah_ppsl_arr(1) - Diagnostics.jah_ppsl_arr(2)
% Diagnostics.weight_arr(2) - Diagnostics.weight_arr(2)

% std(Diagnostics.post_arr)
% std(Diagnostics.prev_post_arr)
% std(Diagnostics.state_ppsl_arr)
% std(Diagnostics.jah_ppsl_arr)
% std(Diagnostics.weight_arr)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Normalise weights
max_weight = max(weight);
max_weight = max_weight(1);
weight = weight - max_weight;
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
    ResamDistn = SystematicResample(Distn, weight);
    if Par.FLAG_ResamMove
        Distn = MoveMCMC(t, L, ResamDistn, Distn, Observs);
    else
        Distn = ResamDistn;
    end
    ESS = Par.NumPart;
    resample = true;
   
%     Distn = SecondarySampling(t, L, Distn, Observs);
    
else
    resample = false;
    ESS = ESS_pre;
    
end



% PlotTracks(Distn)
% uiwait

end