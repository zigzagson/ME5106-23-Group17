% 清空工作区
clear;

% 从文件 'SingleTrack_Division.mat' 中加载所有变量
load('SingleTrack_Division.mat');

% 获取工作区中的变量列表
variables = who;

% 采样率
fs = 128000; % 128 kHz

% 创建一个结构体用于存储FFT结果
fft_results = struct();

% 循环遍历每个变量
for i = 1:length(variables)
    var_name = variables{i}; % 获取变量名
    
    % 检查变量是否是数值数组
    if isnumeric(eval(var_name))
        data = eval(var_name); % 获取数据
        
        % 执行离散傅立叶变换
        fft_data = fft(data);
        
        % 创建一个时间向量，以秒为单位
        t = (0:length(data) - 1) / fs;
        
        % 创建一个频率向量，以Hz为单位
        f = (0:length(fft_data) - 1) * fs / length(fft_data);
        
        % 将FFT结果存储在结构体中
        fft_results.([var_name '_fft']) = fft_data;
        
        % 创建一个新图形窗口
        figure;
        
        % 在第一个子图中绘制原始数据的 plot 图，并标上时间
        subplot(2, 1, 1);
        plot(t, data);
        xlabel('时间 (秒)');
        title(['原始数据 - ', var_name]);
        
        % 在第二个子图中绘制频谱图，并标上频率值
        subplot(2, 1, 2);
        plot(f, abs(fft_data));
        xlabel('频率 (Hz)');
        title(['频谱图 - ', var_name]);
    end
end

% 保存FFT结果到fft.mat
save('fft.mat', 'fft_results');
