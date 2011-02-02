classdef TrackSet < handle
    %TRACKSET A set of track objects, comprising a multi-target state over
    %the duration of a scene
    
    properties
        tracks          % Cell array of track objects
        N               % Number of tracks
        
    end
    
    methods
        
        % Constructor
        function obj = TrackSet(tracks)
            obj.tracks = tracks;
            obj.N = length(tracks);
        end %Constructor
        
        % Copy
        function new = Copy(obj)
            t = cell(size(obj.tracks));
            for k = 1:length(t)
                t{k} = obj.tracks{k}.Copy;
            end
            new = TrackSet(t);
        end
        
        
        
        % Remove Track
        function RemoveTrack(obj, j)
            obj.tracks(j) = [];
            obj.N = obj.N - 1;
        end
        
        
        
        % Add Track
        function AddTrack(obj, NewTrack)
            obj.tracks = [obj.tracks; {NewTrack}];
            obj.N = obj.N + 1;
        end
        
        
        
        %ProjectTracks - Projects each track in a TrackSet forward by one frame.
        function ProjectTracks(obj, t)
            
            global Par;
            
            % Loop through targets
            for j = 1:obj.N
                
                if obj.tracks{j}.death == t
                    % Only extend it if it dies in the current frame. If
                    % not, its expired completely.
                    
                    % % Check that the track ends at t-1
                    % assert(obj.tracks{j}.death==t, 'Track to be projected does not end at t-1');
                    
                    % Get previous state
                    prev_state = obj.tracks{j}.GetState(t-1);
                    
                    % Project it forward
                    state = Par.A * prev_state;
                    
                    % Extend the track
                    obj.tracks{j}.Extend(t, state, 0);
                    
                end
                
            end
            
        end
        
        
        
        %SamplfJAH - Probabilitically selects a joint association hypothesis for a frame
        function prob = SampleJAH(obj, t, Observs, BirthSites )

            global Par;
            
            prob = 0;
            
            % Propose target birth
            for j = 1:obj.N
                for tt = t-2:t
                    for k = length(BirthSites):-1:1
                        if any(BirthSites{k}==obj.tracks{j}.GetAssoc(tt))
                            BirthSites(k)=[];
                        end
                    end
                end
            end
            if ~isempty(BirthSites)&&(rand<Par.PAdd)
                
                prob = prob + log(Par.PAdd);
                
                % Select a random birth site
                k = unidrnd(length(BirthSites));
                
                % Construct a new track start point
                NewStates = cell(3,1);
                NewStates{1} = zeros(4,1);
                NewStates{3} = zeros(4,1);
                if Par.FLAG_ObsMod == 0
                    NewStates{3}(1:2) = Observs(t).r( BirthSites{k}(3), : )';
                    vel = (Observs(t).r( BirthSites{k}(3), : ) - Observs(t-1).r( BirthSites{k}(2), : )) / Par.P;
                    NewStates{3}(3:4) = vel';
                elseif Par.FLAG_ObsMod == 2
                    
                    % Set final state (for projecting forward)
                    xt = Pol2Cart(Observs(t).r( BirthSites{k}(3), 1 ), Observs(t).r( BirthSites{k}(3), 2 ));
                    xt_1 = Pol2Cart(Observs(t-1).r( BirthSites{k}(2), 1 ), Observs(t-1).r( BirthSites{k}(2), 2 ));
                    NewStates{3}(1:2) = xt;
                    NewStates{3}(3:4) = (xt-xt_1)/Par.P;
                    
                    % Set first state (for initialising KF)
                    xt = Pol2Cart(Observs(t-2).r( BirthSites{k}(1), 1 ), Observs(t-2).r( BirthSites{k}(1), 2 ));
                    xt_1 = Pol2Cart(Observs(t-1).r( BirthSites{k}(2), 1 ), Observs(t-1).r( BirthSites{k}(2), 2 ));
                    NewStates{1}(1:2) = xt;
                    NewStates{1}(3:4) = (xt_1-xt)/Par.P;
                    
                end
                
                % Create and add the new track
                NewTrack = Track(t-2, t+1, NewStates, BirthSites{k}');
                obj.AddTrack(NewTrack);
                
            end
            
            % Propose target death
            if (t>2)
                for j = 1:obj.N
                    if (obj.tracks{j}.Present(t)) ...
                            && (obj.tracks{j}.GetAssoc(t)==0) ...
                            && (obj.tracks{j}.GetAssoc(t-1)==0) ...
                            && (obj.tracks{j}.GetAssoc(t-2)==0)
                        if rand < Par.PRemove
                            tt = t-2;
                            while (obj.tracks{j}.GetAssoc(tt)==0)
                                tt = tt-1;
                            end
                            tt = tt+1;
                            obj.tracks{j}.EndTrack(tt);
                        end
                        prob = prob + log(Par.PRemove);
                    end
                end
            end
            
            % % % As a first approximation, use ML associations % % %
            
            % Dig out target states
            states = cell(obj.N, 1);
            for j = obj.N:-1:1
                if obj.tracks{j}.Present(t)
                    states{j} = obj.tracks{j}.GetState(t)';
                else
                    states(j) = [];
                end
            end
            
            % Fudge to make sure its the right way round
            if isempty(states)
                states = cell(0, 1);
            end
            
            % Generate a list of observations
            if Par.FLAG_ObsMod == 0
                obs = Observs(t).r;
            elseif Par.FLAG_ObsMod == 2
                obs = zeros(size(Observs(t).r));
                obs(:,1) = Observs(t).r(:,2).*cos(Observs(t).r(:,1));
                obs(:,2) = Observs(t).r(:,2).*sin(Observs(t).r(:,1));
            end
            
            % Auction algorithm for ML associations
            assoc = AuctionAssoc( states, obs );
            
            % Set associations
            i = 0;
            for j = 1:obj.N
                if (obj.tracks{j}.Present(t))
                    i = i + 1;
                    obj.tracks{j}.SetAssoc(t, assoc(i));
                end
            end
            
        end
        
    end
    
end

