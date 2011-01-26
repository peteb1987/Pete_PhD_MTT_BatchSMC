function [ AssocVector ] = AuctionAssoc( State, Obs )
%AUCTIONASSOC Use the auction algorithm to find the maximum likelihood
%assignment between targets and observations

% State is a cell array of target states
% Obs is an array of observations (row-wise)

global Par;

No = size(Obs, 1);
Ns = size(State, 1);

% First create an association array with No extra elements corresponding
% to a clutter assignment for each observation
Assoc = zeros(No, No+Ns);

% Create an array of prices
Prices = zeros(1, No+Ns);

% Create an array of payoffs for an assignment, the log of the likelihood
% of each observation given an association with a target
temp = -inf*( xor(ones(No), eye(No)) );
temp(isnan(temp)) = 0;
Payoffs = [temp zeros(No, Ns)];
clear temp;

for j = 1:Ns
    for i = 1:No
        Payoffs(i, No+j) = log(  mvnpdfFastSymm(Obs(i, :), State{j}(1:2), 10*Par.ObsNoiseVar) / Par.UnifPosDens  );
        
%         % If the payoff is less than that of a clutter assignment, disallow
%         % assignment by setting payoff to -inf.
%         if Payoffs(i, No+j) < 0
%             Payoffs(i, No+j) = -inf;
%         end
    end
end        

% Auction iterations
done = false;
while ~done
    
    % Iterate over observations ("persons")
    for i = 1:No
        
        if sum(Assoc(i, :))==0
            
            % Find the target or clutter ("object") that gives the biggest reward
            Rewards = Payoffs(i, :) - Prices;
            k = find(Rewards==max(Rewards));
            
            if length(k)>1
                error('More than one best assignment');
            end
            
            % Calculate the bidding increment
            BestReward = Rewards(k);
            Rewards(k) = -inf;
            
            SecondReward = Rewards(Rewards==max(Rewards));
            SecondReward = SecondReward(1);
            Bid = BestReward - SecondReward;
            
            if isnan(Bid)
                error('Bid is NaN');
            end
            
            % Increase the price and assign this target
            Prices(k) = Prices(k) + Bid;
            Assoc(:, k) = 0;
            Assoc(i, k) = 1;
            
        end
  
    end
    
    if all(sum(Assoc, 2))
        done = true;
    end
    
end

% Remove the associations corresponding to clutter
Assoc(:, 1:No) = [];

AssocVector = zeros(Ns, 1);
for j = 1:Ns
    if ~isempty(find(Assoc(:, j), 1))
        AssocVector(j) = find(Assoc(:, j));
    end
end

end %AuctionAssoc