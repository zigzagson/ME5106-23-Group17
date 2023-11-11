% 清空工作区
clc;
clear;
close all;


% 从文件 'SingleTrack_Division.mat' 中加载所有信号
load('SingleTrack_Division.mat');

% 获取工作区中的变量列表
variables = who;
% 采样率
fs = 128000; % 128 kHz
% 初始化中值频率数组
median_frequencies = [];
average_amplitudes = [];
vpps = [];

% 循环遍历每个信号
for i = 1:length(variables)
    var_name = variables{i}; % 获取信号变量名

    % 检查变量是否是数值数组
    if isnumeric(eval(var_name))
        data = eval(var_name); % 获取信号数据

        % 执行FFT
        fft_data = fft(data);

        % 创建时间向量，以秒为单位
        t = (0:length(data) - 1) / fs;

        % % 使用spectrogram生成谱图
        % figure;
        % subplot(3, 1, 1);
        % spectrogram(data, hamming(256), 128, 256, fs, 'yaxis');
        % title(['Spectrogram - ', var_name]);
        % 
        % % 使用pwelch计算功率谱密度
        % subplot(3, 1, 2);
        % [pxx, f_pxx] = pwelch(data, hamming(512), 256, 512, fs);
        % plot(f_pxx, 10*log10(pxx));
        % xlabel('Frequency (Hz)');
        % title(['Power Spectral Density (PWELCH) - ', var_name]);
        % 
        % % 使用periodogram计算周期图
        % subplot(3, 1, 3);
        % [pxx_periodogram, f_periodogram] = periodogram(data, hamming(length(data)), length(data), fs);
        % plot(f_periodogram, 10*log10(pxx_periodogram));
        % xlabel('Frequency (Hz)');
        % title(['Periodogram - ', var_name]);

        % 生成文件名
        file_name = sprintf('谱图_%s.png', var_name);
        
        % 保存当前图形到子文件夹
        saveas(gcf, fullfile('figure', file_name));

        % 计算信号的中值频率等离散特征
        median_freq = medfreq(data, fs);
        median_frequencies(end + 1) = median_freq;
        average_amplitude = mean(abs(data));
        average_amplitudes(end + 1) = average_amplitude;
        vpp = peak2peak(data);
        vpps(end + 1) = vpp;

        % 查找信号中的峰值
        % [peaks, peak_locs] = findpeaks(data, 'MinPeakDistance', 100, 'MinPeakProminence', 10);
        % figure;
        % subplot(2, 1, 1);
        % plot(t, data);
        % title(['Signal - ', var_name]);
        % subplot(2, 1, 2);
        % plot(t(peak_locs), peaks, 'ro');
        % title(['Peaks - ', var_name]);
        % 生成文件名
        file_name = sprintf('peak_%s.png', var_name);
        
        % 保存当前图形到子文件夹
        saveas(gcf, fullfile('figure', file_name));

    end
end
