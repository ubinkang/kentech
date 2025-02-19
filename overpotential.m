%% 스크립트 시작
clc; clear; close all;

%% 1. 첫 번째 파일 불러오기 (OCV Test 파일)
% 파일: "05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat"
data1 = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');
SOC_OCV = data1.meas.SOC;         % SOC 데이터 (OCV 테스트)
OCV = data1.meas.Voltage;         % OCV 데이터
current_OCV = data1.meas.Current;   % 전류 데이터 (충/방전 구분용)

%% 2. 두 번째 파일 불러오기 (V Test 파일)
% 파일: "03-21-17_00.29 25degC_UDDS_Pan18650PF_with_SOC.mat"
data2 = load('03-21-17_00.29 25degC_UDDS_Pan18650PF_with_SOC.mat');
SOC_V = data2.meas.SOC;           % SOC 데이터 (V 테스트)
V = data2.meas.Voltage;           % 전압 데이터
current_V = data2.meas.Current;   % 전류 데이터 (필요시 사용)

%% 3. OCV 파일의 SOC 범위를 V 파일의 SOC 범위로 제한
SOC_min_V = min(SOC_V);  % V 파일의 최소 SOC 값
SOC_max_V = max(SOC_V);  % V 파일의 최대 SOC 값

% 데이터1 (OCV 테스트)에서 SOC가 V 파일의 범위 내에 있는 인덱스 선택
valid_OCV_indices = (SOC_OCV >= SOC_min_V) & (SOC_OCV <= SOC_max_V);
SOC_OCV_trimmed = SOC_OCV(valid_OCV_indices);
OCV_trimmed = OCV(valid_OCV_indices);
current_trimmed = current_OCV(valid_OCV_indices);

%% 4. 데이터1에서 충전 및 방전 과정 분리
% 전류 > 0이면 충전, 전류 < 0이면 방전으로 구분
charging_indices = current_trimmed > 0;
discharging_indices = current_trimmed < 0;

SOC_charging = SOC_OCV_trimmed(charging_indices);
OCV_charging = OCV_trimmed(charging_indices);

SOC_discharging = SOC_OCV_trimmed(discharging_indices);
OCV_discharging = OCV_trimmed(discharging_indices);

%% 5. 중복된 SOC 값 제거 (보간 전 정리)
% 'stable' 옵션으로 순서를 유지하며 고유한 값 추출
[SOC_charging_unique, idx_charging] = unique(SOC_charging, 'stable');
OCV_charging_unique = OCV_charging(idx_charging);

[SOC_discharging_unique, idx_discharging] = unique(SOC_discharging, 'stable');
OCV_discharging_unique = OCV_discharging(idx_discharging);

%% 6. 데이터2의 SOC, V, current도 고유값으로 정리 (이미 중복 제거)
[unique_SOC_V, unique_indices] = unique(SOC_V, 'stable');
V_unique = V(unique_indices);
current_V_unique = current_V(unique_indices);

%% 7. 공통 SOC 범위 결정 및 데이터 제한
common_min = max(min(unique_SOC_V), min(SOC_discharging_unique));
common_max = min(max(unique_SOC_V), max(SOC_discharging_unique));

% 공통 SOC 범위 내에서 데이터2 (V 파일)의 SOC와 V 선택
common_idx = (unique_SOC_V >= common_min) & (unique_SOC_V <= common_max);
SOC_common = unique_SOC_V(common_idx);
V_common = V_unique(common_idx);

%% 8. 데이터1의 방전 OCV를 보간하여 공통 SOC에 대응하는 값을 구하기
% 데이터1의 discharging OCV 커브는 SOC_discharging_unique와 OCV_discharging_unique로 구성됨
% 중복 제거는 이미 진행됨
dischg_ocv_interp = interp1(SOC_discharging_unique, OCV_discharging_unique, SOC_common, 'linear', 'extrap');

%% 9. V와 discharging OCV (보간값) 차이 계산
diff_voltage = V_common - dischg_ocv_interp;

%% 10. 결과 플롯: x축은 SOC, y축은 (V - discharging OCV)
figure;
plot(SOC_common, diff_voltage, '-b', 'LineWidth', 0.5);
xlabel('SOC');
ylabel('Voltage Difference (V - Discharging OCV) (V)');
title('Difference between V and Discharging OCV vs SOC');
grid on;

%% 11. 결과 데이터 테이블 생성 및 Excel 저장 (선택사항)
ResultTable = table(SOC_common, V_common, dischg_ocv_interp, diff_voltage, ...
    'VariableNames', {'SOC', 'V', 'Discharging_OCV', 'Voltage_Difference'});
writetable(ResultTable, 'Voltage_Difference_vs_SOC.xlsx');
fprintf('Voltage difference vs SOC 데이터가 "Voltage_Difference_vs_SOC.xlsx" 파일로 저장되었습니다.\n');

%% 12. 결과 출력 메시지
disp('Voltage difference vs SOC 플롯을 생성하였습니다.');
