clear;
%clc;
% cd('D:\ME5106\Assignment 4\Data');   

fs = 128000;
FrequencyRange = [1,64000];
% 步骤 1: 加载数据
data = load('SingleTrack_Division.mat');
variableNames = fieldnames(data); % 获取所有电压信号的变量名 从A1 - C14, 接下来要进行移除

variableNames = variableNames(~ismember(variableNames, {'B10','C9', 'C13', 'C14'})); % 删除没有标签的变量名

% 定义梅尔频率分量数和时间帧数
numMelCoefficients = 128; % 梅尔系数的数量
numTimeFrames = 44;       % 时间帧数
numVariables = length(variableNames); % 更新变量的数量

melSpectrograms = zeros(numMelCoefficients, numTimeFrames, 1, numVariables);
labels_map = {...
    'A1', '350.00'; 'A2', '400.00'; 'A3', '250.00'; 'A4', '250.00'; 'A5', '400.00'; 'A6', '375.00'; 'A7', '350.00'; 'A8', '200.00'; 
    'A9', '350.00'; 'A10', '200.00'; 'A11', '200.00'; 'A12', '250.00'; 'A13', '400.00'; 
    'B1', '200.00'; 'B2', '300.00'; 'B3', '150.00'; 
    'B4', '400.00'; 
    'B5', '150.00'; 'B6', '300.00'; 'B7', '150.00'; 
    'B8', '300.00'; 'B9', '400.00'; 
    %'B10', '330.00';
    'B11', '150.00'; 
    'B12', '300.00'; 
    'B13', '400.00'; 
    'C1', '150.00'; 'C2', '200.00'; 'C3', '200.00'; 'C4', '250.00'; 'C5', '250.00'; 'C6', '250.00'; 
    'C7', '300.00'; 'C8', '300.00'; 'C10', '330.00'; 'C11', '350.00'; 'C12', '350.00'
};

% 生成标签数组和相关信号的梅尔谱
labels = zeros(numVariables, 1); % 初始化数值数组来收集标签
isEmptyLabel = false(numVariables, 1); % 初始化逻辑数组来标记空标签

for i = 1:numVariables
    var_name = variableNames{i};
    signal = data.(var_name);
    % 查找并设置标签
    label_index = find(strcmp(labels_map(:,1), var_name));
    if isempty(label_index)
        isEmptyLabel(i) = true; % 标记为空标签
        continue; % 跳过没有标签的变量
    else
        labels(i) = str2double(labels_map{label_index, 2});
    end
    
    % 计算梅尔谱
    melSpec = melSpectrogram(signal, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    
    % 由于梅尔谱的大小可能不一致，因此需要进行插值或裁剪以匹配CNN输入尺寸
    resizedMelSpec = imresize(melSpec, [numMelCoefficients, numTimeFrames]);
    
    % 将计算出的梅尔谱存储在数组中
    melSpectrograms(:,:,1,i) = resizedMelSpec;
end

% 使用逻辑索引创建数值数组
regressionLabels = labels(~isEmptyLabel);

layers = [
    imageInputLayer([numMelCoefficients numTimeFrames 1], 'Name', 'input')

    convolution2dLayer(3, 16, 'Padding', 'same', 'Name', 'conv1')
    batchNormalizationLayer('Name', 'bn1')
    geluLayer('Name', 'relu1')
    % dropoutLayer(0.1, 'Name', 'dropout1')  % 添加Dropout

    maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool1')

    convolution2dLayer(3, 32, 'Padding', 'same', 'Name', 'conv2')
    batchNormalizationLayer('Name', 'bn2')
    reluLayer('Name', 'relu2')
    % dropoutLayer(0.2, 'Name', 'dropout2')  % 添加Dropout
    

    maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool2')

    fullyConnectedLayer(64, 'Name', 'fc1')
    geluLayer('Name', 'relu3')
    % dropoutLayer(0.2, 'Name', 'dropout3')  % 添加Dropout

    fullyConnectedLayer(1, 'Name', 'fc2')
    regressionLayer('Name', 'output') 
];

% 设置训练选项
options = trainingOptions('adam', ...
    'MaxEpochs', 600, ...
    'Plots', 'training-progress');



% 步骤 5: 训练CNN模型

model = trainNetwork(melSpectrograms, regressionLabels, layers, options);

% 检查是否存在C13数据
if isfield(data, 'C13')
    % 提取C13信号
    signalC13 = data.C13;
    signalC14 = data.C14;
    signalB10 = data.B10;
    signalC9 = data.C9;
    % 计算C13的梅尔谱
    melSpectrogramC13 = melSpectrogram(signalC13, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    melSpectrogramC14 = melSpectrogram(signalC14, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    melSpectrogramB10 = melSpectrogram(signalB10, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    melSpectrogramC9 = melSpectrogram(signalC9, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    % 由于梅尔谱的大小可能不一致，因此需要进行插值或裁剪以匹配CNN输入尺寸
    melSpectrogramC13 = imresize(melSpectrogramC13, [numMelCoefficients, numTimeFrames]);
    melSpectrogramC14 = imresize(melSpectrogramC14, [numMelCoefficients, numTimeFrames]);
    melSpectrogramB10 = imresize(melSpectrogramB10, [numMelCoefficients, numTimeFrames]);
    melSpectrogramC9 = imresize(melSpectrogramC9, [numMelCoefficients, numTimeFrames]);
    % 调整大小以符合网络输入
    % 注意：melSpectrogramC13必须是一个4D数组，即便是单个图像也要扩展维度
    melSpectrogramC13 = reshape(melSpectrogramC13, [numMelCoefficients, numTimeFrames, 1, 1]);
    melSpectrogramC14 = reshape(melSpectrogramC14, [numMelCoefficients, numTimeFrames, 1, 1]);
    melSpectrogramB10 = reshape(melSpectrogramB10, [numMelCoefficients, numTimeFrames, 1, 1]);
    melSpectrogramC9 = reshape(melSpectrogramC9, [numMelCoefficients, numTimeFrames, 1, 1]);
    % 使用训练好的网络预测C13的标签
    predictedValueC13 = predict(model, melSpectrogramC13);
    predictedValueC14 = predict(model, melSpectrogramC14);
    predictedValueB10 = predict(model, melSpectrogramB10);
    predictedValueC9 = predict(model, melSpectrogramC9);
    % 显示预测结果
    disp(['Predicted value for B10 is: ', num2str(predictedValueB10)]);
    disp(['Predicted value for C9 is: ', num2str(predictedValueC9)]);
    disp(['Predicted value for C13 is: ', num2str(predictedValueC13)]);
    disp(['Predicted value for C14 is: ', num2str(predictedValueC14)]);
else
    disp('C13 data is not available in the loaded dataset.');
end
% % 显示梅尔谱图
% figure;
% 
% subplot(2, 2, 1);
% imagesc(log(melSpectrogramC13(:,:,1,1) + 1)); % 加1是为了避免log(0)
% title('Mel Spectrogram - C13');
% xlabel('Time Frames');
% ylabel('Mel Coefficients');
% colorbar;
% 
% subplot(2, 2, 2);
% imagesc(log(melSpectrogramC14(:,:,1,1) + 1));
% title('Mel Spectrogram - C14');
% xlabel('Time Frames');
% ylabel('Mel Coefficients');
% colorbar;
% 
% subplot(2, 2, 3);
% imagesc(log(melSpectrogramB10(:,:,1,1) + 1));
% title('Mel Spectrogram - B10');
% xlabel('Time Frames');
% ylabel('Mel Coefficients');
% colorbar;
% 
% subplot(2, 2, 4);
% imagesc(log(melSpectrogramC9(:,:,1,1) + 1));
% title('Mel Spectrogram - C9');
% xlabel('Time Frames');
% ylabel('Mel Coefficients');
% colorbar;



