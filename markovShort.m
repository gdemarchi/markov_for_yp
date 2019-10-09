function markovShort(cfg)
%% default values
addpath('functions');

if isfield(cfg,'volume')
    volume = cfg.volume;
else
    volume =0.1 ;
end

if isfield(cfg,'intvol')
    intvol = cfg.intvol;
else
    intvol =0.5 ;
end

if isfield(cfg,'trials')
    trials = cfg.trials;
else
    trials = repmat([1 2 3 4],4,2);
end

if isfield(cfg,'testmode') % small screenNumber for testing
    testmode = cfg.testmode;
else
    testmode = 0;
end

if isfield(cfg,'flipmode') % flipped for inside the meg msr
    flipmode = cfg.flipmode;
else
    flipmode = 1;
end

if isfield(cfg,'meg')% if MEG do Datapixx otherwise do PsychPortAudio
    meg = cfg.meg;
else
    meg = 0;
end

if isfield(cfg,'audiofreqs') % defaults log freqs
    audiofreqs = cfg.audiofreqs;
else
    audiofreqs =  logspace(log10(200),log10(2000),4);
end

if isfield(cfg,'frequency')
    frequency = str2num([cfg.frequency{:}]');
else
    frequency = [3 2 2 3];%{'3', '2', '2','3'}; %Hz
end

if isfield(cfg,'session')
    session = cfg.session;
else
    session = 1; % defaults session 1 (2 only for tinnitus pats)
end

nBlocks = size(trials,1); % total blocks
nTrials = size(trials,2); % trials per block

% Screen stuff
if testmode Screen('Preference', 'SkipSyncTests', 1); else end

PsychDefaultSetup(2);

screenNumber = max(Screen('Screens')); % Screen Number

white = WhiteIndex(screenNumber); % Define black, white and grey
grey = GrayIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open the screenNumber and create a window on it
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');

if flipmode PsychImaging('AddTask', 'AllViews', 'FlipHorizontal'); else end

if testmode % small screen
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black  ,[0 0 800 600]);
elseif meg
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber,black);
else
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
end

HideCursor; % Hide the cursor

% Query the frame duration and frame rate
ifi = Screen('GetFlipInterval', window);
if meg; fr = Screen('NominalFrameRate', window); else fr =60; end

topPriorityLevel = MaxPriority(window); % Maximum priority level

%[xCenter, yCenter] = RectCenter(windowRect); % Get the centre coordinate of the window

% Keyboard stuff
KbName('UnifyKeyNames');
esc=KbName('ESCAPE');

% Text stuff - 40 points Arial white
Screen('TextSize', window, 40 );
Screen('TextFont', window, 'Arial');
Screen('TextColor', window, white);


moviename = [pwd '/cirquedusoleil.mp4'];

rate=1;
preloadsecs = 10;
blocking =0;
[movie , movieduration , fps , imgw,  imgh] = Screen('OpenMovie', window, moviename, [], preloadsecs);

%%%%%%% IMPORTANT !!!
xFrames = (fps ./ frequency); % How often do i want a stimulus, in movie frames
%%%%%%%


% Initial display and sync to timestamp:
Screen('Flip',window);

% Audio stuff
freq = 44100; % self explanatory
for iBeep=1:length(audiofreqs) % create the stimuli at the beginning
    beep{iBeep} =  MakeBeepRamped(audiofreqs(iBeep),0.05, 0.005);
end

beep{length(audiofreqs)+1} =  MakeBeepRamped(0,0.05, 0.005); %no tone, not needed here
%beepSilent =  MakeBeepRamped(0,0.05, 0.005); % zero freq, i.e. silent

% Get the size of the audio wave
nFrames = max(size(beep{1}));
lrMode = 3;

if meg
    % Setup the Datapixx, both for audio and DIO
    Datapixx('Open'); % General part
    Datapixx('StopAllSchedules');
    Datapixx('InitAudio'); % Audio part
    Datapixx('SetAudioVolume', [volume intvol]);   % ('SetAudioVolume', [extVol intVolsca])
else
    %not in MEG, use PsychPortAudio for audio and other stuff for triggering
    nrchannels = 2;
    InitializePsychSound(1);
    waitForDeviceStart = 1;
    pahandle = PsychPortAudio('Open', [], 1, 1, freq, nrchannels);
    PsychPortAudio('Volume', pahandle, 0.1);
end %end audio part

DrawFormattedText(window, 'Press to start ...', 'center', 'center');
Screen('Flip',window);
KbPressWait(-1);


Screen('PlayMovie', movie, rate, 1, 0);  % Start playback of movie.  now [soundvolume]=0
t1 = GetSecs;

% loop start
iteration = 0;
abortit = 0;
iTrial = 1;
iBlock = 1; %use this one to check the speed :-)
iFrame=0;
while 1 % Infinite playback loop: Fetch video frames and display them...

    % mergency exit !!!
    [keyIsDown,secs,keyCode]=KbCheck(-1); %
    if (keyIsDown==1 && keyCode(esc)) % to break ESC
        sca;
        return
    end;

    [tex, newTimeIdx] = Screen('GetMovieImage', window, movie, 1);
    Screen('DrawTexture', window, tex);
    % Audio trials
    if mod(iFrame,xFrames(iBlock)) == 0 % i.e. every 8 movie frames e.g. 1/3 Hz at 24 fps

        % NO control for the omissions
        soundToSend = beep{trials(iBlock,iTrial)};
        trigger = trials(iBlock,iTrial);%2^(trials(iBlock,iTrial)-1); % encode entropy
        iTrial=iTrial+1; % increase the trial here;

        if meg % prepare the sound and the trigger to be sent and the next refresh
            Datapixx('SetAudioSchedule', 0, freq, nFrames, lrMode, 0, nFrames); % DataPixx
            % Download the entire waveform to address 0.
            Datapixx('WriteAudioBuffer', soundToSend, 0);
            Datapixx('StartAudioSchedule');
            Datapixx('RegWrVideoSync');
            triggerValue(cfg,trigger);
        else
            PsychPortAudio('FillBuffer', pahandle, soundToSend); %Psychportaudio part
            PsychPortAudio('Start', pahandle, 1, [], waitForDeviceStart);
            % no trigger here
        end
    else
    end
    Screen('Flip', window);% *THE* Flip
    % Release texture:
    Screen('Close', tex);

    if iTrial == nTrials % last trial of a block
        if  iBlock==nBlocks% last block done
            DrawFormattedText(window,'End of the experiment !!!', 'center', 'center'); % flipped
            Screen('Flip', window);
            KbWait(-1);
            break; % exit gracefully

        else
            oldTimeIdx = Screen('GetMovieTimeIndex', movie); %needed to keep the movie in sync when pausing
            DrawFormattedText(window,'End of the block, relax a bit', 'center', 'center'); % flipped
            Screen('Flip', window);
            oldTimeIdx = newTimeIdx;
            KbWait(-1); % wait for some button to be pressed
            Screen('SetMovieTimeIndex', movie, oldTimeIdx);
            % increase the block and reset the trials
            iTrial =1; % reset the trial counter
            iBlock = iBlock +1; % increase the block counter
        end
    else
    end
    iFrame=iFrame+1;    % here the frame counters
end; % while loop of the movie

% END !!!
telapsed = GetSecs - t1;
fprintf('Elapsed time %f seconds, for %i frames.\n', telapsed, iFrame);

% Wait for keyboard press
Screen('Flip', window);
KbReleaseWait(-1);

% Done. Stop playback:
Screen('PlayMovie', movie, 0);

% Close movie object:
Screen('CloseMovie', movie);

% Show the cursor
ShowCursor;

% Job done
if meg
    Datapixx('Close');
else
    PsychPortAudio('Stop', pahandle);
    PsychPortAudio('Close', pahandle);
end

fprintf('\nDone !\n\n');

% Save and Clean up
fileName=[cfg.name,'_session_',num2str(session),'_OmissionMarkov'];
save(fileName,'cfg');
sca;
