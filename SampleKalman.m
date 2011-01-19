function [ NewTrack, ppsl_prob ] = SampleKalman( KFMean, KFVar )
%SAMPLEKALMAN Sample from a set of Kalman estimates to generate a new track

global Par;

% Sample backwards from the end, as in Doucet, Briers, Senecal

% Create arrays
NewTrack = cell(size(KFMean));
prob = zeros(size(KFMean));

% Last point
NewTrack{end} = mvnrnd(KFMean{end}', KFVar{end})';
prob(end) = mvnpdf(NewTrack{end}', KFMean{end}', KFVar{end});

% Loop though time
for k = length(NewTrack)-1:-1:1
    
    norm_mean = (Par.A' * (Par.Q \ Par.A) + inv(Par.Q)) \ (Par.A' * (Par.Q \ NewTrack{k+1}) + (Par.Q \ KFMean{k}));
    norm_var = inv(Par.A' * (Par.Q \ Par.A) + inv(Par.Q));
    
    NewTrack{k} = mvnrnd(norm_mean', norm_var)';
    prob(k) = mvnpdf(NewTrack{k}', norm_mean', norm_var);

end

ppsl_prob = sum(log(prob));

end

