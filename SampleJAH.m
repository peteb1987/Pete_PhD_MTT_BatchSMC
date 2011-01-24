function [ Set, prob ] = SampleJAH( t, SetIn, Observs )
%SAMPLEJAH Probabilitically selects a joint association hypothesis for
%time t.

Set = SetIn.Copy;

% % % As a first approximation, use ML

% Dig out target states
states = cell(Set.N, 1);
for j = 1:Set.N
    states{j} = Set.tracks{j}.GetState(t)';
end

% Auction algorithm for ML associations
assoc = AuctionAssoc( states, Observs(t).r );

% Set associations
for j = 1:Set.N
    Set.tracks{j}.SetAssoc(t, assoc(j));
end

prob = log(1);

end