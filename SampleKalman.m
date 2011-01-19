function [ NewTrack, ppsl_prob ] = SampleKalman( KFMean, KFVar, track )
%SAMPLEKALMAN Sample from a set of Kalman estimates to generate a new track

% If a new track is supplied, just calculate its probability

global Par;

% Sample backwards from the end, as in Doucet, Briers, Senecal

L = size(KFMean,1); 

if L == 0
    NewTrack = [];
    ppsl_prob = 0;
    return
end

if nargin == 3
    NewTrack = track.state(end-L+1:end);
    
elseif nargin == 2
    NewTrack = cell(L, 1);
    
    % Last point
    NewTrack{end} = mvnrnd(KFMean{end}', KFVar{end})';
    
end

prob = zeros(size(KFMean));
prob(end) = mvnpdf(NewTrack{end}', KFMean{end}', KFVar{end});

% Loop though time
for k = length(NewTrack)-1:-1:1
    
    norm_mean = (Par.A' * (Par.Q \ Par.A) + inv(Par.Q)) \ (Par.A' * (Par.Q \ NewTrack{k+1}) + (Par.Q \ KFMean{k}));
    norm_var = inv(Par.A' * (Par.Q \ Par.A) + inv(Par.Q));
    
    if nargin == 2
        NewTrack{k} = mvnrnd(norm_mean', norm_var)';
    end
        
    prob(k) = mvnpdf(NewTrack{k}', norm_mean', norm_var);

end

ppsl_prob = sum(log(prob));

end

