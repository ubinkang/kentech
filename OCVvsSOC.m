% 1. 첫 번째 파일 불러오기 (OCV vs SOC)
data1 = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');
SOC_OCV = data1.meas.SOC;  % SOC 데이터
OCV = data1.meas.Voltage;  % OCV 데이터

% 2. 두 번째 파일 불러오기 (V vs SOC)
data2 = load('03-21-17_00.29 25degC_UDDS_Pan18650PF_with_SOC.mat');
SOC_V = data2.meas.SOC;  % SOC 데이터
V = data2.meas.Voltage;  % 전압 데이터

% 3. SOC 범위 조정 (첫 번째 데이터의 SOC가 두 번째 데이터의 SOC 범위를 초과하지 않도록)
SOC_max = max(SOC_V);  % 두 번째 파일의 최대 SOC 값
valid_indices = SOC_OCV <= SOC_max;  % SOC_V의 최대값보다 작은 OCV만 선택

SOC_OCV_trimmed = SOC_OCV(valid_indices);
OCV_trimmed = OCV(valid_indices);

% 4. 중복된 SOC 값 제거 (interp1을 수행하기 전에 필요)
[SOC_OCV_unique, unique_indices] = unique(SOC_OCV_trimmed, 'stable');
OCV_unique = OCV_trimmed(unique_indices);

% 5. SOC 보간 (interp1을 사용해 SOC_V에 맞춤)
OCV_interpolated = interp1(SOC_OCV_unique, OCV_unique, SOC_V, 'linear', 'extrap');

% 6. 겹치는 SOC 부분 제거 (중복된 SOC 값 제거)
[unique_SOC_V, unique_indices] = unique(SOC_V, 'stable');
V_unique = V(unique_indices);
OCV_interpolated_unique = OCV_interpolated(unique_indices);

% 7. 결과 시각화 (OCV vs SOC 및 V vs SOC)
figure;

% OCV vs SOC 그래프
subplot(2,1,1);
plot(SOC_OCV_unique, OCV_unique, 'bo-', 'LineWidth', 0.5);
title('OCV vs SOC');
xlabel('SOC');
ylabel('OCV (V)');
grid on;
legend('OCV vs SOC');

% V vs SOC 및 보간된 OCV vs SOC 비교 그래프
subplot(2,1,2);
plot(unique_SOC_V, V_unique, 'r-', 'LineWidth', 0.5);
hold on;
plot(unique_SOC_V, OCV_interpolated_unique, 'b--', 'LineWidth', 0.5);
title('V vs SOC and Interpolated OCV vs SOC');
xlabel('SOC');
ylabel('Voltage (V)');
legend('V vs SOC', 'Interpolated OCV vs SOC');
grid on;

% 8. 결과 출력
disp('OCV vs SOC and V vs SOC plots have been generated.');
