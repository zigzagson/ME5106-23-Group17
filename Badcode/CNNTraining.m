clear;
%clc;
% cd('D:\ME5106\Assignment 4\Data');   

fs = 128000;
FrequencyRange = [1,64000];
% ���� 1: ��������
data = load('SingleTrack_Division.mat');
variableNames = fieldnames(data); % ��ȡ���е�ѹ�źŵı����� ��A1 - C14, ������Ҫ�����Ƴ�

variableNames = variableNames(~ismember(variableNames, {'B10','C9', 'C13', 'C14'})); % ɾ��û�б�ǩ�ı�����

% ����÷��Ƶ�ʷ�������ʱ��֡��
numMelCoefficients = 128; % ÷��ϵ��������
numTimeFrames = 44;       % ʱ��֡��
numVariables = length(variableNames); % ���±���������

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

% ���ɱ�ǩ���������źŵ�÷����
labels = zeros(numVariables, 1); % ��ʼ����ֵ�������ռ���ǩ
isEmptyLabel = false(numVariables, 1); % ��ʼ���߼���������ǿձ�ǩ

for i = 1:numVariables
    var_name = variableNames{i};
    signal = data.(var_name);
    % ���Ҳ����ñ�ǩ
    label_index = find(strcmp(labels_map(:,1), var_name));
    if isempty(label_index)
        isEmptyLabel(i) = true; % ���Ϊ�ձ�ǩ
        continue; % ����û�б�ǩ�ı���
    else
        labels(i) = str2double(labels_map{label_index, 2});
    end
    
    % ����÷����
    melSpec = melSpectrogram(signal, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    
    % ����÷���׵Ĵ�С���ܲ�һ�£������Ҫ���в�ֵ��ü���ƥ��CNN����ߴ�
    resizedMelSpec = imresize(melSpec, [numMelCoefficients, numTimeFrames]);
    
    % ���������÷���״洢��������
    melSpectrograms(:,:,1,i) = resizedMelSpec;
end

% ʹ���߼�����������ֵ����
regressionLabels = labels(~isEmptyLabel);

layers = [
    imageInputLayer([numMelCoefficients numTimeFrames 1], 'Name', 'input')

    convolution2dLayer(3, 16, 'Padding', 'same', 'Name', 'conv1')
    batchNormalizationLayer('Name', 'bn1')
    geluLayer('Name', 'relu1')
    % dropoutLayer(0.1, 'Name', 'dropout1')  % ���Dropout

    maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool1')

    convolution2dLayer(3, 32, 'Padding', 'same', 'Name', 'conv2')
    batchNormalizationLayer('Name', 'bn2')
    reluLayer('Name', 'relu2')
    % dropoutLayer(0.2, 'Name', 'dropout2')  % ���Dropout
    

    maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool2')

    fullyConnectedLayer(64, 'Name', 'fc1')
    geluLayer('Name', 'relu3')
    % dropoutLayer(0.2, 'Name', 'dropout3')  % ���Dropout

    fullyConnectedLayer(1, 'Name', 'fc2')
    regressionLayer('Name', 'output') 
];

% ����ѵ��ѡ��
options = trainingOptions('adam', ...
    'MaxEpochs', 600, ...
    'Plots', 'training-progress');



% ���� 5: ѵ��CNNģ��

model = trainNetwork(melSpectrograms, regressionLabels, layers, options);

% ����Ƿ����C13����
if isfield(data, 'C13')
    % ��ȡC13�ź�
    signalC13 = data.C13;
    signalC14 = data.C14;
    signalB10 = data.B10;
    signalC9 = data.C9;
    % ����C13��÷����
    melSpectrogramC13 = melSpectrogram(signalC13, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    melSpectrogramC14 = melSpectrogram(signalC14, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    melSpectrogramB10 = melSpectrogram(signalB10, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    melSpectrogramC9 = melSpectrogram(signalC9, fs, 'WindowLength', 256, 'OverlapLength', 128, 'FFTLength', 512, 'NumBands', numMelCoefficients, 'FrequencyRange', FrequencyRange);
    % ����÷���׵Ĵ�С���ܲ�һ�£������Ҫ���в�ֵ��ü���ƥ��CNN����ߴ�
    melSpectrogramC13 = imresize(melSpectrogramC13, [numMelCoefficients, numTimeFrames]);
    melSpectrogramC14 = imresize(melSpectrogramC14, [numMelCoefficients, numTimeFrames]);
    melSpectrogramB10 = imresize(melSpectrogramB10, [numMelCoefficients, numTimeFrames]);
    melSpectrogramC9 = imresize(melSpectrogramC9, [numMelCoefficients, numTimeFrames]);
    % ������С�Է�����������
    % ע�⣺melSpectrogramC13������һ��4D���飬�����ǵ���ͼ��ҲҪ��չά��
    melSpectrogramC13 = reshape(melSpectrogramC13, [numMelCoefficients, numTimeFrames, 1, 1]);
    melSpectrogramC14 = reshape(melSpectrogramC14, [numMelCoefficients, numTimeFrames, 1, 1]);
    melSpectrogramB10 = reshape(melSpectrogramB10, [numMelCoefficients, numTimeFrames, 1, 1]);
    melSpectrogramC9 = reshape(melSpectrogramC9, [numMelCoefficients, numTimeFrames, 1, 1]);
    % ʹ��ѵ���õ�����Ԥ��C13�ı�ǩ
    predictedValueC13 = predict(model, melSpectrogramC13);
    predictedValueC14 = predict(model, melSpectrogramC14);
    predictedValueB10 = predict(model, melSpectrogramB10);
    predictedValueC9 = predict(model, melSpectrogramC9);
    % ��ʾԤ����
    disp(['Predicted value for B10 is: ', num2str(predictedValueB10)]);
    disp(['Predicted value for C9 is: ', num2str(predictedValueC9)]);
    disp(['Predicted value for C13 is: ', num2str(predictedValueC13)]);
    disp(['Predicted value for C14 is: ', num2str(predictedValueC14)]);
else
    disp('C13 data is not available in the loaded dataset.');
end
% % ��ʾ÷����ͼ
% figure;
% 
% subplot(2, 2, 1);
% imagesc(log(melSpectrogramC13(:,:,1,1) + 1)); % ��1��Ϊ�˱���log(0)
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



