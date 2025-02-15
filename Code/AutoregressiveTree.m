%% Read the output file

clear

filename = '5ZoneSteamBaseboard.csv';
[~,~,RawData] = xlsread(filename);

% First 48*60/TimeStep numeric entries in the excel file correspond to design days
% These must be excluded. Higher start index can be chosen to account for
% autoregrssive part

TimeStep = 15; % In mins
OrderOfAR = 1*60/TimeStep; % less than 24 hrs here
StartIndex = 1+2*24*60/TimeStep+24*60/TimeStep+1; % 1 for string names, 2 days for design days data, then autoregressive terms, then 1 for next index

%% Organize the data

% Input Variables
InputData = {};

% Training Features without autoregressive contribution
% Specify the features from EnergyPlus .idf output variables
% TrainingData{end+1}.Name = '';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Drybulb Temperature [C](TimeStep)';
% InputData{end+1}.Name = 'SPACE1-1:Zone Air System Sensible Heating Rate [W](TimeStep)';
% InputData{end+1}.Name = 'SPACE1-1:Zone Air Heat Balance Air Energy Storage Rate [W](TimeStep)';
% InputData{end+1}.Name = 'SPACE1-1:Zone Total Internal Total Heating Rate [W](TimeStep)';
% InputData{end+1}.Name = 'Environment:Site Direct Solar Radiation Rate per Area [W/m2](TimeStep)';
InputData{end+1}.Name = 'FRONT-1:Surface Outside Face Incident Solar Radiation Rate per Area [W/m2](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Relative Humidity [%](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Wind Speed [m/s](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Wind Direction [deg](TimeStep)';
InputData{end+1}.Name = 'SPACE1-1:Zone People Occupant Count [](TimeStep)';
InputData{end+1}.Name = 'SPACE1-1:Zone Lights Total Heating Energy [J](TimeStep)';
InputData{end+1}.Name = 'SPACE1-1 BASEBOARD:Baseboard Total Heating Rate [W](TimeStep)';


for idx = 1:size(InputData,2)
    for idy = 1:size(RawData,2)
        if strcmp(RawData{1,idy}, InputData{idx}.Name)
            InputData{idx}.Data = RawData(StartIndex:end,idy);
        end
    end
end

NoOfDataPoints = size(InputData{1}.Data,1);

for idx = 1:OrderOfAR
    for idname = 1:size(InputData,2)
        for idy = 1:size(RawData,2)
            if strcmp(RawData{1,idy}, InputData{idname}.Name)
                InputData{end+1}.Name = [InputData{idname}.Name '(k-' num2str(idx) ')']; %#ok<SAGROW>
                InputData{end}.Data = RawData(StartIndex-idx:StartIndex-idx+NoOfDataPoints-1,idy);
            end
        end
    end
end

% Training Features for previous time stances of desired output
% 'SPACE1-1:Zone Air Temperature [C](TimeStep)';

ARVariable.Name = 'SPACE1-1:Zone Air Temperature [C](TimeStep)';

for idx = 1:OrderOfAR
    for idy = 1:size(RawData,2)
        if strcmp(RawData{1,idy}, ARVariable.Name)
            InputData{end+1}.Name = [ARVariable.Name '(k-' num2str(idx) ')']; %#ok<SAGROW>
            InputData{end}.Data = RawData(StartIndex-idx:StartIndex-idx+NoOfDataPoints-1,idy);
        end
    end
end
% Reference for day of week
% Example: Start Day  = Monday
% Mon = 0, Tue = 1, Wed = 2, Thur = 3, Fri = 4, Sat = 5, Sun = 6

NoOfDays = NoOfDataPoints/(24*60/TimeStep);
InputData{end+1}.Name = 'Day';

x1 = [0:NoOfDataPoints-1]';
x2 = mod(x1,(24*60/TimeStep));
InputData{end}.Data = mod((x1-x2)/(24*60/TimeStep),7);

% Time of day
InputData{end+1}.Name = 'Time';
for idy = 1:size(RawData,2)
    if strcmp(RawData{1,idy}, 'Date/Time')
        InputData{end}.Data = RawData(StartIndex:end,idy);
        chartime = char(InputData{end}.Data);
        InputData{end}.Data = str2num(chartime(:,9:10))*60+str2num(chartime(:,12:13)); %#ok<ST2NM>
    end
end

% Output Variables
NoOfOutput = 1;
OutputData = {};
OutputData{end+1}.Name = 'SPACE1-1:Zone Air Temperature [C](TimeStep)';
for idx = 1:NoOfOutput
    for idy = 1:size(RawData,2)
        if strcmp(RawData{1,idy}, OutputData{idx}.Name)
            OutputData{idx}.Data = RawData(StartIndex:end,idy);
        end
    end
end

%% Divide into training and testing data

NoOfFeatures = size(InputData,2);
Input = zeros(NoOfDataPoints, NoOfFeatures);
for idx = 1:NoOfFeatures
    if iscell(InputData{idx}.Data)
        Input(:,idx) = cell2mat(InputData{idx}.Data);
    else
        Input(:,idx) = InputData{idx}.Data;
    end
end

TrainingDays = 60;
TrainingInput = Input(1:(24*60/TimeStep)*TrainingDays,:);
TestingInput = Input(1+(24*60/TimeStep)*TrainingDays:end,:);

Output = cell2mat(OutputData{1}.Data);
TrainingOutput = Output(1:(24*60/TimeStep)*TrainingDays,:);

%% Fit regression tree

rtree = fitrtree(TrainingInput, TrainingOutput, 'MinLeafSize',60);
[~,~,~,bestLevel] = cvloss(rtree, 'SubTrees', 'all', 'KFold', 5);
% view(rtree, 'Mode', 'graph');

prunedrtree = prune(rtree, 'Level', bestLevel);
% view(prunedtree, 'Mode', 'graph');


%% Fit boosted tree

brtree = fitensemble(TrainingInput, TrainingOutput, 'LSBoost', 500, 'Tree');

%% Predict results

ActualOutput = Output(1+(24*60/TimeStep)*TrainingDays:end,:);

rtreeOutput = predict(rtree, TestingInput);
brtreeOutput = predict(brtree, TestingInput);

rtreeNRMSE = sqrt(mean((rtreeOutput-ActualOutput).^2))/mean(ActualOutput);
brtreeNRMSE = sqrt(mean((brtreeOutput-ActualOutput).^2))/mean(ActualOutput);

figure; hold on;
title(['Order of AR = ' num2str(OrderOfAR)]);
h1 = plot(1:length(ActualOutput), ActualOutput, 'b');
h2 = plot(1:length(ActualOutput), rtreeOutput, 'r');
h3 = plot(1:length(ActualOutput), brtreeOutput, '--g');
% h4 = plot(1:length(ActualOutput), ActualOutput, 'b');
legend([h1, h2, h3], 'Actual', ['Single Tree ' num2str(rtreeNRMSE,2)], ['Boosted Tree ' num2str(brtreeNRMSE,2)])

% figure; hold on;
% plot(TrainingInput(:,2)/50, 'r');
% plot(TrainingOutput(:,1), 'b')

