%% Read the output file

% clear

filenameTrain = 'LargeOfficeFUN2012.csv';
[~,~,RawDataTrain] = xlsread(filenameTrain);

filenameTest = 'LargeOfficeOPT11.csv';
[~,~,RawDataTest] = xlsread(filenameTest);

TimeStep = 5; % In mins
OrderOfAR = 8; %0.5*60/TimeStep; % less than 24 hrs here
ARinInput = 0; % 0 => Auto-reg terms from output only i.e no terms from previous inputs 
StartIndex = 1+24*60/TimeStep+1; % 1 for string names, then autoregressive terms, then 1 for next index

%% Organize the data

% Input Variables
InputData = {};

% Training Features without autoregressive contribution
% Specify the features from EnergyPlus .idf output variables
% TrainingData{end+1}.Name = '';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Drybulb Temperature [C](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Wetbulb Temperature [C](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Relative Humidity [%](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Wind Speed [m/s](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Wind Direction [deg](TimeStep)';

InputData{end+1}.Name = 'EMS:currentDayOfMonth [](TimeStep)';
InputData{end+1}.Name = 'EMS:currentDayOfWeek [](TimeStep)';
InputData{end+1}.Name = 'EMS:currentTimeOfDay [](TimeStep)';

InputData{end+1}.Name = 'HTGSETP_SCH:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'HW-LOOP-TEMP-SCHEDULE:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'CW-LOOP-TEMP-SCHEDULE:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'CLGSETP_SCH:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'BLDG_LIGHT_SCH:Schedule Value [](TimeStep)';

InputData{end+1}.Name = 'COOLSYS1 CHILLER 1:Chiller Evaporator Outlet Temperature [C](TimeStep)';
% InputData{end+1}.Name = 'COOLSYS1 CHILLER 2:Chiller Evaporator Outlet Temperature [C](TimeStep)';
InputData{end+1}.Name = 'HEATSYS1 BOILER:Boiler Outlet Temperature [C](TimeStep) ';

InputData{end+1}.Name = 'BASEMENT:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'CORE_BOTTOM:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'CORE_MID:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'CORE_TOP:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'GROUNDFLOOR_PLENUM:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'MIDFLOOR_PLENUM:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_BOT_ZN_1:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_BOT_ZN_2:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_BOT_ZN_3:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_BOT_ZN_4:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_MID_ZN_1:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_MID_ZN_2:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_MID_ZN_3:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_MID_ZN_4:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_TOP_ZN_1:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_TOP_ZN_2:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_TOP_ZN_3:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_TOP_ZN_4:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'TOPFLOOR_PLENUM:Zone Air Temperature [C](TimeStep)';


for idx = 1:size(InputData,2)
    for idy = 1:size(RawDataTrain,2)
        if strcmp(RawDataTrain{1,idy}, InputData{idx}.Name)
            InputData{idx}.TrainData = RawDataTrain(StartIndex:end,idy);
            InputData{idx}.TestData = RawDataTest(StartIndex:end,idy);
        end
    end
end

NoOfTrainDataPoints = size(InputData{1}.TrainData,1);
NoOfTestDataPoints = size(InputData{1}.TestData,1);

if ARinInput
    for idx = 1:OrderOfAR %#ok<UNRCH>
        for idname = 1:size(InputData,2)
            for idy = 1:size(RawDataTrain,2)
                if strcmp(RawDataTrain{1,idy}, InputData{idname}.Name)
                    InputData{end+1}.Name = [InputData{idname}.Name '(k-' num2str(idx) ')'];
                    InputData{end}.TrainData = RawDataTrain(StartIndex-idx:StartIndex-idx+NoOfTrainDataPoints-1,idy);
                    InputData{end}.TestData = RawDataTest(StartIndex-idx:StartIndex-idx+NoOfTestDataPoints-1,idy);
                end
            end
        end
    end
end

% Training Features for previous time instances of desired output
ARVariable.Name = 'Whole Building:Facility Total Electric Demand Power [W](TimeStep)';
 
for idx = 1:OrderOfAR
    for idy = 1:size(RawDataTrain,2)
        if strcmp(RawDataTrain{1,idy}, ARVariable.Name)
            InputData{end+1}.Name = [ARVariable.Name '(k-' num2str(idx) ')']; %#ok<SAGROW>
            InputData{end}.TrainData = RawDataTrain(StartIndex-idx:StartIndex-idx+NoOfTrainDataPoints-1,idy);
            InputData{end}.TestData = RawDataTest(StartIndex-idx:StartIndex-idx+NoOfTestDataPoints-1,idy);
        end
    end
end


% Output Variables
NoOfOutput = 1;
OutputData = {};
OutputData{end+1}.Name = 'Whole Building:Facility Total Electric Demand Power [W](TimeStep)';
for idx = 1:NoOfOutput
    for idy = 1:size(RawDataTrain,2)
        if strcmp(RawDataTrain{1,idy}, OutputData{idx}.Name)
            OutputData{idx}.TrainData = RawDataTrain(StartIndex:end,idy);
            OutputData{idx}.TestData = RawDataTest(StartIndex:end,idy);
        end
    end
end

%% Preprocess training and testing data

NoOfFeatures = size(InputData,2);
TrainingInput = zeros(NoOfTrainDataPoints, NoOfFeatures);
TestingInput = zeros(NoOfTestDataPoints, NoOfFeatures);

for idx = 1:NoOfFeatures
    if iscell(InputData{idx}.TrainData)
        TrainingInput(:,idx) = cell2mat(InputData{idx}.TrainData);
        TestingInput(:,idx) = cell2mat(InputData{idx}.TestData);
    else
        TrainingInput(:,idx) = InputData{idx}.TrainData;
        TestingInput(:,idx) = InputData{idx}.TestData;
    end
end

TrainingOutput = cell2mat(OutputData{1}.TrainData);
TestingOutput = cell2mat(OutputData{1}.TestData);

%% Fit regression tree

train =0;
if train
    catcol = [6,7,8];
    leafsize = 5;
    rtree = fitrtree(TrainingInput, TrainingOutput, 'MinLeafSize', leafsize, 'CategoricalPredictors', catcol);
    % view(rtree, 'Mode', 'graph');
    
% Fit boosted tree
    
    brtree = fitensemble(TrainingInput, TrainingOutput, 'LSBoost', 500, 'Tree', 'CategoricalPredictors', catcol, 'LearnRate', 0.01);
    
% Fit cross validated tree
    
    % cvtree = fitrtree(TrainingInput, TrainingOutput, 'CategoricalPredictors', catcol,...
    %     'MinLeafSize', leafsize, 'CrossVal', 'on', 'KFold', 20); % default is 10-fold
    
% Fit random forest
    
    rforest = TreeBagger(500, TrainingInput, TrainingOutput, 'Method', 'regression', 'OOBPred', 'On', 'OOBVarImp', 'on',...
        'CategoricalPredictors', catcol, 'MinLeaf', leafsize);
end
%% Predict results on testing set

ActualOutput = TestingOutput;

rtreeOutput = predict(rtree, TestingInput);
brtreeOutput = predict(brtree, TestingInput);
% cvtreeOutput = kfoldPredict(cvtree);
rforestOutput = predict(rforest, TestingInput);

rtreeNRMSE = sqrt(mean((rtreeOutput-ActualOutput).^2))/mean(ActualOutput);
brtreeNRMSE = sqrt(mean((brtreeOutput-ActualOutput).^2))/mean(ActualOutput);
rforestNRMSE = sqrt(mean((rforestOutput-ActualOutput).^2))/mean(ActualOutput);
% cvtreeNRMSE = sqrt(mean((cvtreeOutput-ActualOutput).^2))/mean(ActualOutput);


figure; hold on;
title(['Testing Data July 2013, Order of AR = ' num2str(OrderOfAR)]);
h1 = plot(1:length(ActualOutput), ActualOutput, 'b');
h2 = plot(1:length(ActualOutput), rtreeOutput, 'r');
h3 = plot(1:length(ActualOutput), brtreeOutput, 'g');
% h4 = plot(1:length(ActualOutput), cvtreeOutput, 'c');
h5 = plot(1:length(ActualOutput), rforestOutput, 'm');
legend([h1, h2, h3, h5], 'Actual', ['Single Tree ' num2str(rtreeNRMSE,2)], ['Boosted Tree ' num2str(brtreeNRMSE,2)],...
     ['Random Forest ' num2str(rforestNRMSE,2)])

% figure; hold on;
% title(['Testing Data July 2013, Order of AR = ' num2str(OrderOfAR)]);
% h1 = plot(TestingOutput, ActualOutput, '--b', 'MarkerSize', 2);
% h2 = plot(TestingOutput, rtreeOutput, 'dr', 'MarkerSize', 2);
% h3 = plot(TestingOutput, brtreeOutput, '+g', 'MarkerSize', 2);
% % h4 = plot(TestingOutput, cvtreeOutput, 'dc', 'MarkerSize', 2);
% h5 = plot(TestingOutput, rforestOutput, '+m', 'MarkerSize', 2);
% xlabel('Actual Power [W]');
% ylabel('Predicted Power [W]');
% legend([h2, h3, h5], ['Single Tree ' num2str(rtreeNRMSE,2)], ['Boosted Tree ' num2str(brtreeNRMSE,2)],...
%      ['Random Forest ' num2str(rforestNRMSE,2)], 'Location', 'Best')

%% Predict results on training set

% ActualOutput = TrainingOutput;
% 
% rtreeOutput = predict(rtree, TrainingInput);
% brtreeOutput = predict(brtree, TrainingInput);
% 
% rtreeNRMSE = sqrt(mean((rtreeOutput-ActualOutput).^2))/mean(ActualOutput);
% brtreeNRMSE = sqrt(mean((brtreeOutput-ActualOutput).^2))/mean(ActualOutput);
% 
% figure; hold on;
% title(['Training Data July 2012, Order of AR = ' num2str(OrderOfAR)]);
% h1 = plot(1:length(ActualOutput), ActualOutput, 'b');
% h2 = plot(1:length(ActualOutput), rtreeOutput, 'r');
% h3 = plot(1:length(ActualOutput), brtreeOutput, '--g');
% legend([h1, h2, h3], 'Actual', ['Single Tree ' num2str(rtreeNRMSE,2)], ['Boosted Tree ' num2str(brtreeNRMSE,2)])
% 
% figure; hold on;
% title(['Training Data July 2012, Order of AR = ' num2str(OrderOfAR)]);
% h1 = plot(TrainingOutput, TrainingOutput, '--b', 'MarkerSize', 2);
% h2 = plot(TrainingOutput, rtreeOutput, 'dr', 'MarkerSize', 2);
% h3 = plot(TrainingOutput, brtreeOutput, '+g', 'MarkerSize', 2);
% xlabel('Actual Power [W]');
% ylabel('Predicted Power [W]');
% legend([h2, h3], ['Single Tree ' num2str(rtreeNRMSE,2)], ['Boosted Tree ' num2str(brtreeNRMSE,2)], 'Location', 'Best')

