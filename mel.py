import scipy.io
import numpy as np
import librosa
import os
import librosa.display
import matplotlib.pyplot as plt

# 读取.mat文件
mat_data = scipy.io.loadmat('SingleTrack_Division.mat')

# 获取.mat文件中的变量名称
variable_names = mat_data.keys()
fs = 128000
# 定义标签映射
labels_map = {
    'A1': '350.00', 'A2': '400.00', 'A3': '250.00', 'A4': '250.00', 'A5': '400.00', 'A6': '375.00', 'A7': '350.00', 'A8': '200.00',
    'A9': '350.00', 'A10': '200.00', 'A11': '200.00', 'A12': '250.00', 'A13': '400.00',
    'B1': '200.00', 'B2': '300.00', 'B3': '150.00',
    'B4': '400.00',
    'B5': '150.00', 'B6': '300.00', 'B7': '150.00',
    'B8': '300.00', 'B9': '400.00',
    'B10': '330.00',
    'B11': '150.00',
    'B12': '300.00',
    'B13': '400.00',
    'C1': '150.00', 'C2': '200.00', 'C3': '200.00', 'C4': '250.00', 'C5': '250.00', 'C6': '250.00',
    'C7': '300.00', 'C8': '300.00', 'C10': '330.00', 'C11': '350.00', 'C12': '350.00'
}

# 转换标签映射为数字标签
label_encoder = {label: float(value) for label, value in labels_map.items()}
# 创建 figure 文件夹（如果不存在）
figure_folder = 'figure'
os.makedirs(figure_folder, exist_ok=True)

# 遍历每个变量，生成梅尔图并保存
for variable_name in variable_names:
    if variable_name.startswith('A') or variable_name.startswith('B') or variable_name.startswith('C'):
        # 获取声音幅度序列
        audio_sequence = mat_data[variable_name].flatten()  # 将整个声音序列展平成一个向量

        # 计算梅尔频谱图
        n_fft = max(2048, len(audio_sequence) // 2)
        mel_spec = librosa.feature.melspectrogram(y=audio_sequence, sr=fs, n_fft=n_fft)

        # 可以选择绘制梅尔图并保存
        plt.figure(figsize=(10, 4))
        plt.imshow(librosa.power_to_db(mel_spec, ref=np.max), cmap='viridis', origin='lower', aspect='auto')
        plt.axis('off')  # 关闭坐标轴
        plt.savefig(os.path.join(figure_folder, f'{variable_name}_mel_spec.png'), bbox_inches='tight', pad_inches=0)
        plt.close()
