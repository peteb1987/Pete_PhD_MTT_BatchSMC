classdef Track < handle
    %TRACK Contains details of a target track
    
    properties
        num         % Number of frames in the track
        birth       % Target birth time (set to 0 if target is initialised a priori)
        death       % Target death time (set to inf if target does not die)
        state       % Cell vector of target states, length num
        assoc       % Vector of association indices, length num

    end
    
    methods
        
        % Constructor
        function obj = Track(birth, death, state, assoc)
            
            obj.birth = birth;
            obj.death = death;
            obj.num = death - birth;
            
            assert(obj.num > 0, 'Track length is negative or zero');
            
            obj.state = state;
            obj.assoc = assoc;
            
            assert(length(state)==obj.num, 'Track length does not match state array size')
            assert(length(assoc)==obj.num, 'Track length does not match association array size')
            
        end %Constructor
        
        
        
        % Copy
        function new = Copy(obj)
            new = Track(obj.birth, obj.death, obj.state, obj.assoc);
        end
        
        
        
        % Find Time
        function k = Time(obj, t)
            k = t - obj.birth + 1;
        end
        
        
        
        % Get Assoc
        function assoc = GetAssoc(obj, t)
            k = obj.Time(t);
            if (k<0)||(k>length(obj.assoc))
                assoc = 0;
            else
                assoc = obj.assoc(k);
            end
        end
        
        
        
        % Set Assoc
        function SetAssoc(obj, t, assoc)
            k = obj.Time(t);
            assert((k>0)&&(k<=length(obj.assoc)), 'Cannot set an association because the track is not present at the given time')
            obj.assoc(k) = assoc;
        end
        
        
        
        % Get State
        function state = GetState(obj, t)
            k = obj.Time(t);
            assert((k>=0)&&(k<=length(obj.state)), 'Cannot get state because the track is not present at the given time')
            state = obj.state{k};
        end
        
        
        
        % Set State
        function SetState(obj, t, state)
            k = obj.Time(t);
            assert((k>0)&&(k<=length(obj.state)), 'Cannot set a state because the track is not present at the given time')
            obj.state{k} = state;
        end
        
        
        
        % Extend
        function Extend(obj, t, state, assoc)
            assert(t==obj.death, 'Can only extend track by one state at a time');
            obj.death = t + 1;
            obj.num = obj.num + 1;
            obj.state = [obj.state; state];
            obj.assoc = [obj.assoc; assoc];
        end
        
        
        
        % Check Presence
        function pres = Present(obj, t)
            k = obj.Time(t);
            if (k>0)&&(k<=length(obj.state))
                pres = true;
            else
                pres = false;
            end
        end
        
        
        
        % Update - update a section of track (multiple states)
        function Update(obj, t, NewTrack, assoc)
            
            L = length(NewTrack);
            assert(length(assoc)==L, 'Association vector has incorrect length');
            for tt = t-L+1:t-1
                k = tt-(t-L);
                obj.SetState(tt, NewTrack{k})
                obj.SetAssoc(tt, assoc(k));
            end
            obj.Extend(t, NewTrack{L}, assoc(L));
            
        end

        
        
        
        
        
    end
    
end

