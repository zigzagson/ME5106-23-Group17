clear;
labels_map = {...
    'A1', '350.00'; 'A2', '400.00'; 'A3', '250.00'; 'A4', '250.00'; 'A5', '400.00'; 'A6', '375.00'; 'A7', '350.00'; 'A8', '200.00'; 
    'A9', '350.00'; 'A10', '200.00'; 'A11', '200.00'; 'A12', '250.00'; 'A13', '400.00'; 
    'B1', '200.00'; 'B2', '300.00'; 'B3', '150.00'; 'B4', '400.00'; 'B5', '150.00'; 'B6', '300.00'; 'B7', '150.00'; 
    'B8', '300.00'; 'B9', '400.00'; 
    'B10', '330.00';
    'B11', '150.00'; 
    'B12', '300.00'; 
    'B13', '400.00'; 
    'C1', '150.00'; 'C2', '200.00'; 'C3', '200.00'; 'C4', '250.00'; 'C5', '250.00'; 'C6', '250.00'; 
    'C7', '300.00'; 'C8', '300.00'; 'C10', '330.00'; 'C11', '350.00'; 'C12', '350.00'
};

% 指定Mel文件夹路径
melFolderPath = './Mel';

% 获取Mel文件夹下的所有PNG文件
pngFiles = dir(fullfile(melFolderPath, '*.png'));

% 初始化存储数据的结构
data = struct('var', {}, 'image', {}, 'label', {}); % Added 'label' field

% 遍历每个PNG文件
for i = 1:numel(pngFiles)
    % 获取文件名
    filename = pngFiles(i).name;
    
    % 提取标签（假设文件名格式为 var_filename.png）
    underscoreIndex = strfind(filename, '_');
    var = filename(1:underscoreIndex(1)-1);
    
    % 查找对应的标签值
    label = '';
    for j = 1:size(labels_map, 1)
        if strcmp(var, labels_map{j, 1})
            label = labels_map{j, 2};
            break;
        end
    end
    
    % 构建文件的完整路径
    filepath = fullfile(melFolderPath, filename);
    
    % 读取PNG文件的图像数据
    image_data = imread(filepath);
    
    % 将标签和图像数据保存在数据结构中
    data(end+1).var = var;
    data(end).image = image_data;
    data(end).label = label;
end


% Create a regression CNN
layers = [
    imageInputLayer([308 775 3],'Name','input')

    convolution2dLayer(3,16,'Padding','same','Name','conv1')
    batchNormalizationLayer('Name','bn1')
    reluLayer('Name','relu1')

    maxPooling2dLayer(2,'Stride',2,'Name','pool1')

    convolution2dLayer(3,32,'Padding','same','Name','conv2')
    batchNormalizationLayer('Name','bn2')
    reluLayer('Name','relu2')

    maxPooling2dLayer(2,'Stride',2,'Name','pool2')
    
    convolution2dLayer(3,128,'Padding','same','Name','conv3')
    batchNormalizationLayer('Name','bn3')
    reluLayer('Name','relu3')

    maxPooling2dLayer(4,'Stride',4,'Name','pool3')
    
    convolution2dLayer(3,64,'Padding','same','Name','conv4')
    batchNormalizationLayer('Name','bn4')
    reluLayer('Name','relu4')

   % maxPooling2dLayer(2,'Stride',2,'Name','pool4')%加了效果差

    fullyConnectedLayer(32,'Name','fc1')
    reluLayer('Name','relu5')

    fullyConnectedLayer(1,'Name','output') % Regression layer

    regressionLayer('Name','regression')];

% Set the training options
options = trainingOptions('adam', ...
    'MaxEpochs',50, ...
    'MiniBatchSize', 16, ...
    'Shuffle','every-epoch', ...
    'Verbose',false, ...
    'Plots','training-progress');

% Filter out specific entries from data
exclude_indices = ismember({data.var}, {'B10', 'C9', 'C13', 'C14'});
filtered_data = data(~exclude_indices);
% Convert labels to double for regression
labels = str2double({filtered_data.label});
labels = labels(:);
% Concatenate image data along the fourth dimension to create a 4D array
imageData = cat(4, filtered_data.image);

% Train the CNN
net = trainNetwork(imageData, labels, layers, options);
view(net);
% 提取被排除的数据
excluded_data = data(ismember({data.var}, {'B10', 'C9', 'C13', 'C14'}));

% 提取图像数据
excluded_images = cat(4, excluded_data.image);

% 使用训练好的网络进行预测
predictions = predict(net, excluded_images);

% 打印每个预测值对应的变量名
for i = 1:numel(excluded_data)
    fprintf('Variable: %s, Prediction: %f\n', excluded_data(i).var, predictions(i));
end
