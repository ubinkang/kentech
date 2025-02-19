% 1. 첫 번째 파일 불러오기 (OCV vs Time)
data1 = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');
SOC_OCV = data1.meas.SOC;  % SOC 데이터
OCV = data1.meas.Voltage;  % OCV 데이터
current_OCV = data1.meas.Current;  % 전류 데이터
time_OCV = data1.meas.Time;  % 시간 데이터 (초 단위)

% 2. 두 번째 파일 불러오기 (V vs SOC)
data2 = load('03-21-17_00.29 25degC_UDDS_Pan18650PF_with_SOC.mat');
SOC_V = data2.meas.SOC;  % SOC 데이터
V = data2.meas.Voltage;  % 전압 데이터
current_V = data2.meas.Current;  % 전류 데이터 (전압 데이터에 대한)

% 3. OCV의 SOC 범위를 V의 SOC 범위로 제한
SOC_min_V = min(SOC_V);  % V의 최소 SOC 값
SOC_max_V = max(SOC_V);  % V의 최대 SOC 값

valid_OCV_indices = (SOC_OCV >= SOC_min_V) & (SOC_OCV <= SOC_max_V);  % SOC 범위 필터링

SOC_OCV_trimmed = SOC_OCV(valid_OCV_indices);
OCV_trimmed = OCV(valid_OCV_indices);
current_trimmed = current_OCV(valid_OCV_indices);
time_OCV_trimmed = time_OCV(valid_OCV_indices);  % 시간 데이터도 필터링

% 4. 방전 과정만 필터링 (충전 과정 제거)
discharging_indices = current_trimmed < 0;  % 방전 과정 (전류 < 0)

SOC_discharging = SOC_OCV_trimmed(discharging_indices);
OCV_discharging = OCV_trimmed(discharging_indices);
time_discharging = time_OCV_trimmed(discharging_indices);

% 5. SOC에 대응되는 Time을 찾기 위해 보간 수행 (방전 과정만 사용)
time_V_mapped = interp1(SOC_discharging, time_discharging, SOC_V, 'linear', 'extrap');  % SOC_V를 Time으로 변환

% 6. 중복된 Time 값 제거
[unique_time_V, unique_indices] = unique(time_V_mapped, 'stable');
V_unique = V(unique_indices);
current_V_unique = current_V(unique_indices);

% 7. 방전 OCV 데이터에 대한 Time 보간 수행
time_discharging_mapped = interp1(SOC_discharging, time_discharging, SOC_discharging, 'linear', 'extrap');

% 8. 결과 시각화 (V, Current, OCV 한 화면에 표시 - 방전 과정만 포함)
figure;

% **왼쪽 Y축 (전류) - 자홍색**
yyaxis left
plot(unique_time_V, current_V_unique, 'm-', 'LineWidth', 0.5);  % 전류: 자홍색
ylabel('Current (A)', 'Color', 'm');  % 좌측 Y축: 전류 (자홍색)
ax = gca;
ax.YColor = 'm';  % 좌측 Y축 색상 통일 (자홍색)

% **오른쪽 Y축 (전압 & OCV) - 연두색**
yyaxis right
plot(unique_time_V, V_unique, 'g-', 'LineWidth', 1.5);  % 전압: 연두색
hold on;
plot(time_discharging_mapped, OCV_discharging, 'r--', 'LineWidth', 0.5);  % OCV 방전: 빨간색 점선
ylabel('Voltage / OCV (V)', 'Color', 'g');  % 우측 Y축: 전압 & OCV (연두색)
ax.YColor = 'g';  % 우측 Y축 색상 통일 (연두색)

% 그래프 제목 및 범례 설정
title('Voltage, Current, and OCV vs Time (Discharge Only)');
xlabel('Time (s) from Discharging OCV');  % X축을 Time(s)으로 변경
legend({'Current (A)', 'Voltage (V)', 'OCV Discharging (V)'}, 'Location', 'best');
grid on;
hold off;

% 9. 결과 출력
disp('Voltage, Current, and OCV vs Time plots have been generated (Discharge Only).');
