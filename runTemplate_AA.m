%% Anna Anonymous
% starting stuff
if IsLinux
    cd /home/gd_markov/ownCloud/MEGLab/Experiments/MarkovThreeSeconds
    path(pathdef);
elseif ismac
    cd /Users/gianpaolo/Nextcloud/MEGLab/Experiments/MarkovThreeSeconds
else
    disp('Where are u?!')
end
addpath('functions');

%% ctrl enter to run this piece of code only
cfg= [];
cfg.name = 'AA'; % Anna Anonymous
cfg.gender = 'W';
cfg.birthdate = '19921117'; %  19921117AGAE


% RD3Hz:1 OR3Hz:2
% rng('shuffle'); randperm(2)
% >> 1 2

cfg.entropy = {'random','ordered'}; % entropy order
% not needed any longer cfg.frequency = {'3', '3', '2','2'}; % frequency order

cfg.trials = [markovChain('random',1200);...
    markovChain('ordered',1200);...
    ];

cfg.testmode =  0; % 1 or 0, one is small  screen,  to test e.g. the audio

%%%
cfg.flipmode = 1; % 1 in the meg
cfg.meg =1;

%%% keep changing it till the subjets says it s ok, then dont forget to put
% cfg.testmode to 0
% quick staircase here ?!
cfg.volume= 0.030 ; %0.018;

%%% volume outside at the loud speakers
cfg.intvol=0.1;

markovShort(cfg);
