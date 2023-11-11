% 清空工作区
clc;
clear;
close all;


% 从文件 'SingleTrack_Division.mat' 中加载所有变量
load('SingleTrack_Division.mat');

% 获取工作区中的变量列表
variables = who;

% 采样率
fs = 128000; % 128 kHz
%% 存入Laser 和Speed
% 读取 Excel 文件中的数据
[~, variable_names, variable_data] = xlsread('parameters.xlsx');

% 创建一个空的结构体
parameters = struct();

% 遍历每一行数据
for i = 1:length(variable_names)
    var_name = variable_names{i, 1};  % 获取变量名
    var_data1 = variable_data{i, 2};  % 获取第二列的数据
    var_data2 = variable_data{i, 3};  % 获取第三列的数据
    var_data3 = variable_data{i, 4};  % 获取第4列的数据
    var_data4 = variable_data{i, 5};  % 获取第5列的数据
    % 将数据存入结构体
    parameters.(var_name).data1 = var_data1;
    parameters.(var_name).data2 = var_data2;
    parameters.(var_name).data3 = var_data3;
    parameters.(var_name).data4 = var_data4;
end

% 显示结构体中的数据
disp(parameters);

%% 计算各域的数值
% 创建一个结构体数组用于存储FFT结果和能量信息
        results = struct('var_name', {}, 'fft_results', [], 'total_energy_time_domain', [], 'total_energy_freq_domain', [], 'half_power_frequency', [], 'prop', []);

% 循环遍历每个变量
for i = 1:length(variables)
    var_name = variables{i}; % 获取变量名

    % 检查变量是否是数值数组
    if isnumeric(eval(var_name))

        data = eval(var_name); % 获取数据

        % 计算原始时间域数据的总功率
        total_power_time_domain = sum(data.^2);

        % 执行离散傅立叶变换
        fft_data = fft(data);

        % 创建一个时间向量，以秒为单位
        t = (0:length(data) - 1) / fs;

        % 创建一个频率向量，以Hz为单位
        f = (-length(fft_data)/2:length(fft_data)/2 - 1) * fs / length(fft_data);

        % 计算功率谱
        power_spectrum = abs(fft_data).^2 / (fs*length(fft_data));
        % 计算频域总能量
        total_energy_freq_domain = sum(abs(fft_data).^2) / length(fft_data);
        % 计算总功率
        total_power = sum(power_spectrum);
%% 计算半功率频率
        % 初始化累积功率和频率成分
        cumulative_power = 0;
        cumulative_index = 1;
        half_power_frequency = 0;

        % 逐步累积能量，找到累积到总能量的一半时的频率
        while cumulative_power < total_energy_freq_domain * 0.75
            cumulative_power = cumulative_power + power_spectrum(cumulative_index) * fs;
            half_power_frequency = f(cumulative_index);
            cumulative_index = cumulative_index + 1;
        end
        prop = total_energy_freq_domain / total_power_time_domain;
        fprintf('%s:\n', var_name);
        fprintf('原始时间域数据的总能量: %.2f\n', total_power_time_domain);
        % 输出结果
        fprintf('频域总能量: %.2f\n', total_energy_freq_domain);
        fprintf('比值: %.2f\n', prop);
        fprintf('功率累积到总功率的一半时的频率: %.2f Hz\n', half_power_frequency);
%% 创建一个结构体来存储当前变量的信息        
        var_info.var_name = var_name;
        var_info.fft_results = fft_data;
        var_info.total_energy_time_domain = total_power_time_domain;
        var_info.total_energy_freq_domain = total_energy_freq_domain;
        var_info.half_power_frequency = half_power_frequency;
        var_info.prop = prop;
        % 将变量信息添加到结果数组
        results(end+1) = var_info;
%% 绘图
        % figure;
        % 
        % subplot(3, 1, 1);
        % plot(t, data);
        % xlabel('时间 (秒)');
        % title(['原始数据 - ', var_name]);
        % 
        % subplot(3, 1, 2);
        % plot(f, abs(fft_data));
        % xlabel('频率 (Hz)');
        % title(['频谱图 - ', var_name]);
        % 
        % subplot(3, 1, 3);
        % % 绘制功率-频率曲线
        % plot(f, power_spectrum);
        % half_str = sprintf('%.0f', half_power_frequency);
        % title(['功率-频率曲线 -' , var_name, ' ',half_str,'Hz']);
        % xlabel('频率 (Hz)');
        % ylabel('功率');
        % 
        % if ~exist('figure', 'dir')
        %     mkdir('figure');
        % end
        % 
        % file_name = sprintf('figure_%s.png', var_name);
        % saveas(gcf, fullfile('figure', file_name));


    end
end
save('results. Mat', 'results');