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
            if (k<1)||(k>length(obj.assoc))
                assoc = 0;
            else
                assoc = obj.assoc(k);
            end
        end
        
        
        
        % Set Assoc
        function SetAssoc(obj, t, assoc)
            k = obj.Time(t);
            assert((k>1)&&(k<length(obj.assoc)), 'Cannot set an association because the track is not present at the given time')
            obj.assoc(k) = assoc;
        end
        
        
        
        % Get State
        function state = GetState(obj, t)
            k = obj.Time(t);
            assert((k>1)&&(k<length(obj.assoc)), 'Cannot get state because the track is not present at the given time')
            state = obj.state{k};
        end
        
        
        
        % Set State
        function SetState(obj, t, state)
            k = obj.Time(t);
            assert((k>1)&&(k<length(obj.state)), 'Cannot set a state because the track is not present at the given time')
            obj.state{k} = state;
        end
        
        
        
        % Check Presence
        function pres = Present(obj, t)
            k = obj.Time(t);
            if (k>1)&&(k<length(obj.state))
                pres = true;
            else
                pres = false;
            end
        end

        
        
        
        
        
    end
    
end

