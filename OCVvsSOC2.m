% 1. 첫 번째 파일 불러오기 (OCV vs SOC)
data1 = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');
SOC_OCV = data1.meas.SOC;  % SOC 데이터
OCV = data1.meas.Voltage;  % OCV 데이터
current_OCV = data1.meas.Current;  % 전류 데이터 (충/방전 구분용)

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
current_trimmed = current_OCV(valid_OCV_indices);  % 전류 데이터도 동일한 인덱스로 정리

% 4. 충전 및 방전 과정 분리
charging_indices = current_trimmed > 0;  % 충전 과정 (전류 > 0)
discharging_indices = current_trimmed < 0;  % 방전 과정 (전류 < 0)

SOC_charging = SOC_OCV_trimmed(charging_indices);
OCV_charging = OCV_trimmed(charging_indices);

SOC_discharging = SOC_OCV_trimmed(discharging_indices);
OCV_discharging = OCV_trimmed(discharging_indices);

% 5. 중복된 SOC 값 제거 (보간을 수행하기 전에 필요)
[SOC_charging_unique, charging_indices_unique] = unique(SOC_charging, 'stable');
OCV_charging_unique = OCV_charging(charging_indices_unique);

[SOC_discharging_unique, discharging_indices_unique] = unique(SOC_discharging, 'stable');
OCV_discharging_unique = OCV_discharging(discharging_indices_unique);

% 6. 겹치는 SOC 부분 제거 (중복된 SOC 값 제거)
[unique_SOC_V, unique_indices] = unique(SOC_V, 'stable');
V_unique = V(unique_indices);
current_V_unique = current_V(unique_indices);  % 전류 데이터도 같은 인덱스로 정리

% 7. 결과 시각화 (V, Current, OCV 한 화면에 표시)
figure;

% **왼쪽 Y축 (전류) - 자홍색**
yyaxis left
plot(unique_SOC_V, current_V_unique, 'm-', 'LineWidth', 0.5);  % 전류: 자홍색
ylabel('Current (A)', 'Color', 'm');  % 좌측 Y축: 전류 (자홍색)
ax = gca;
ax.YColor = 'm';  % 좌측 Y축 색상 통일 (자홍색)

% **오른쪽 Y축 (전압 & OCV) - 연두색**
yyaxis right
plot(unique_SOC_V, V_unique, 'g-', 'LineWidth', 1.5);  % 전압: 연두색
hold on;
plot(SOC_charging_unique, OCV_charging_unique, 'b--', 'LineWidth', 0.5);  % OCV 충전: 파란색 점선
plot(SOC_discharging_unique, OCV_discharging_unique, 'r--', 'LineWidth', 0.5);  % OCV 방전: 빨간색 점선
ylabel('Voltage / OCV (V)', 'Color', 'g');  % 우측 Y축: 전압 & OCV (연두색)
ax.YColor = 'g';  % 우측 Y축 색상 통일 (연두색)

% 그래프 제목 및 범례 설정
title('Voltage, Current, and OCV vs SOC (OCV SOC Range Limited)');
xlabel('SOC');
legend({'Current (A)', 'Voltage (V)', 'OCV Charging (V)', 'OCV Discharging (V)'}, 'Location', 'best');
grid on;
hold off;

% 8. 결과 출력
disp('Voltage, Current, and OCV vs SOC plots have been generated with OCV SOC range limited.');
