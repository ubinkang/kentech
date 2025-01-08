% MAT 파일 로드
fileName = '03-21-17_00.29 25degC_UDDS_Pan18650PF.mat';
data = load(fileName);

% Time, Voltage, Current 데이터 추출
time = data.meas.Time;       % 시간 데이터
voltage = data.meas.Voltage; % 전압 데이터
current = data.meas.Current; % 전류 데이터

% 전류 데이터를 스케일링 (정규화)
current_scaled = (current - min(current)) / (max(current) - min(current)) * (max(voltage) - min(voltage)) + min(voltage);

%% 전압 및 스케일된 전류 vs 시간 그래프 생성 및 저장
figure;

% 전압 플롯 (파란색)
plot(time, current_scaled, 'LineWidth', 0.5, 'Color', 'r','LineStyle',':');
hold on;

% 스케일된 전류 플롯 (빨간색)

plot(time, voltage, 'LineWidth', 0.5, 'Color', 'b','LineStyle',':');
% 레이블 및 제목
xlabel('Time (s)');
ylabel('Voltage (V) & Scaled Current');
title('Voltage and Scaled Current vs Time');
legend('Voltage (V)', 'Scaled Current (A)');
grid on;

% 그래프 저장
outputFileName = 'Voltage_and_Scaled_Current_vs_Time_UDDS.png';
saveas(gcf, outputFileName);
disp(['전압 및 스케일된 전류 vs 시간 그래프가 저장되었습니다: ', outputFileName]);
