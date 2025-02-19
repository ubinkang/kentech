%% 스크립트 시작
clc; clear; close all;

%% 1. MergedData.mat 파일 불러오기
load('MergedData.mat', 'newData');  % newData 구조체에는 SOC, Voltage, Current, OCV, 그리고 Time 필드가 있다고 가정

% "Time" 필드가 있는지 확인하고, 없으면 인덱스를 사용
if isfield(newData, 'Time')
    timeVec = newData.Time;
else
    timeVec = (1:length(newData.Voltage))';  % 인덱스를 시간으로 사용
    warning('Time 필드가 없습니다. 인덱스를 시간으로 사용합니다.');
end

%% 2. 필요한 데이터 추출
Voltage_data = newData.Voltage;    % 두 번째 파일의 전압 데이터
Current_data = newData.Current;      % 두 번째 파일의 전류 데이터
OCV_data_interp = newData.OCV;       % 보간된 OCV 데이터 (첫 번째 파일의 OCV가 SOC에 맞춰 보간된 값)

%% 3. 플롯 생성 (x축: Time)
figure;
hold on;

% 왼쪽 y축: Current (자홍색)
yyaxis left
plot(timeVec, Current_data, 'm-', 'LineWidth', 1.5);
ylabel('Current (A)', 'Color', 'm');
set(gca, 'YColor', 'm');

% 오른쪽 y축: Voltage (연두색)와 OCV (파란색 점선)
yyaxis right
plot(timeVec, Voltage_data, 'g-', 'LineWidth', 1.5);
hold on;
plot(timeVec, OCV_data_interp, 'b-', 'LineWidth', 1);
ylabel('Voltage / OCV (V)', 'Color', 'g');
set(gca, 'YColor', 'g');

% x축 및 제목
xlabel('Time');
title('Voltage, Current, and OCV vs Time');

% 범례 (각 데이터에 대해)
legend({'Current', 'Voltage', 'OCV'}, 'Location', 'best');
grid on;
hold off;
