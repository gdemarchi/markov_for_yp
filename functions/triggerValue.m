function triggerValue(cfg,value)

if cfg.meg == 1
    Datapixx('SetDoutValues', value);
    Datapixx('RegWrRd');
    WaitSecs(0.02); % 20 ms
    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    
else
    fprintf(1,'Trigger %d !\n', value);
end
end