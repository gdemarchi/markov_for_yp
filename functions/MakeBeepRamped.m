function beep = MakeBeepRamped(beepFreq,beepDuration, rampTime) % Hz,s,s
Fs = 44100;
beep(1,:) = MakeBeep(beepFreq,beepDuration , Fs); %
rampSamples = (rampTime* Fs); % 5ms in samples
amplitudeEnvelope = [linspace(0, 1, rampSamples) ones(1,length(beep(1,:))-2*rampSamples+1) linspace(1, 0, rampSamples)];
beep(1,:)=  beep(1,:) .* amplitudeEnvelope;
beep(2,:) =   beep(1,:);
% plot to check 
% plot(beep(1,:))
end 