function curSequence = markovChain(level,nElements) %
switch level
    case 'random'
        transitionMatrix = [.25 .25 .25 .25 ; .25 .25 .25 .25; .25 .25 .25 .25; .25 .25 .25 .25];
    case 'ordered'
        transitionMatrix = [.25 .75 0 0 ; 0 .25 .75 0; 0 0 .25 .75; .75 0 0 .25];       
end

curSequence = zeros(nElements,1);
pool = zeros(4,1);
for iSeq=1:4
    pool(iSeq) = round(nElements/4); % four sound, 1/4th per sound
end

rng('shuffle');
iLoop=1;
flagStuck =0;

while iLoop <= nElements
    % decide the entry point of the markov sequence
    if iLoop> 1 && flagStuck ==0 %from the second trial onwards
        startingPoint = curSequence(iLoop-1);
    elseif iLoop> 1 && flagStuck ==1 % ... but if I have emptied a pool alread!
        tmpIdx =(find(pool>0)); %? was circshift(find(pool>0),1);
        startingPoint = tmpIdx(randi(length(tmpIdx)));
        flagStuck =0;
    else
        startingPoint = randi(4); % start at a random 4 tone, at the very first trial
    end

    % do the markov sequence
    % compute the ending point then check
    curSequence(iLoop) = find(mnrnd(1,transitionMatrix(:,startingPoint)));
    if pool(curSequence(iLoop)) >0 %if i have still stimuli left, then subtract
        % decrease the pool and increase the loop if no pool is empty
        pool(curSequence(iLoop))= pool(curSequence(iLoop)) -1;
        iLoop = iLoop+1;
    else
        fprintf('pool %d  empty! \n',startingPoint);
        flagStuck =1;
        %rng('shuffle'); %restting num gen for better luck
        continue % do another loop, one pool was empty
    end

end
curSequence = curSequence';
