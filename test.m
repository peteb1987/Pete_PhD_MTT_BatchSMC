arr = zeros(1000,1);
for ii = 1:1000
    arr(ii) = Distns{13}.particles{ii}.tracks{4}.assoc(14);
end

mode(arr)