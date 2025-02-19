clc;
clear;

% MAT 파일 로드
fileName = '05-08-17_13.26_C20_OCV_Test_with_Steps.mat';
data = load(fileName);

% 데이터 추출
time = data.meas.Time;       % 시간 데이터
current = data.meas.Current; % 전류 데이터
voltage = data.meas.Voltage; % 전압 데이터
step = data.meas.Step;       % Step 데이터

% 초기 SOC 및 시간 간격 정의
SOC_initial = 0.9907; % 초기 SOC
SOC_last=0; % 마지막 SOC
dt = 60;              % 시간 간격 (1분 = 60초)

% 상태별 데이터 추출
dischargeIndices = (current < 0); % 방전 상태
chargeIndices = (current > 0);    % 충전 상태

% 방전 Q_total 계산
discharge_Q_total = abs(sum(current(dischargeIndices) * dt)) / 3600; % 방전 총 용량 (Ah)
disp(['방전 Q_total: ', num2str(discharge_Q_total), ' Ah']);

% 충전 Q_total 계산
charge_Q_total = abs(sum(current(chargeIndices) * dt)) / 3600; % 충전 총 용량 (Ah)
disp(['충전 Q_total: ', num2str(charge_Q_total), ' Ah']);

% 방전 SOC 계산
SOC_discharge = zeros(size(current)); % 방전 SOC 초기화
SOC_discharge(1) = SOC_initial;       % 초기 SOC 설정
for i = 2:length(current)
    if dischargeIndices(i)
        dSOC = current(i) * (dt / 3600) / discharge_Q_total; % SOC 감소
        SOC_discharge(i) = SOC_discharge(i-1) + dSOC;
    else
        SOC_discharge(i) = SOC_discharge(i-1); % SOC 유지
    end
end
SOC_discharge = max(0, min(SOC_discharge, 1)); % SOC를 0~1 범위로 제한

% 충전 SOC 계산
SOC_charge = zeros(size(current)); % 충전 SOC 초기화
SOC_charge(1) = SOC_last;       % 초기 SOC 설정
for i = 2:length(current)
    if chargeIndices(i)
        dSOC = current(i) * (dt / 3600) / charge_Q_total; % SOC 증가
        SOC_charge(i) = SOC_charge(i-1) + dSOC;
    else
        SOC_charge(i) = SOC_charge(i-1); % SOC 유지
    end
end
SOC_charge = max(0, min(SOC_charge, 1)); % SOC를 0~1 범위로 제한

% 방전 및 충전 구간 데이터 추출
discharge_SOC = SOC_discharge(dischargeIndices);
discharge_OCV = voltage(dischargeIndices);

charge_SOC = SOC_charge(chargeIndices);
charge_OCV = voltage(chargeIndices);

% OCV와 SOC를 테이블로 저장 (방전)
dischargeTable = table(discharge_SOC, discharge_OCV, ...
    'VariableNames', {'SOC', 'OCV'});
writetable(dischargeTable, 'Discharge_OCV_vs_SOC.xlsx');
disp('방전 데이터가 저장되었습니다: Discharge_OCV_vs_SOC.xlsx');

% OCV와 SOC를 테이블로 저장 (충전)
chargeTable = table(charge_SOC, charge_OCV, ...
    'VariableNames', {'SOC', 'OCV'});
writetable(chargeTable, 'Charge_OCV_vs_SOC.xlsx');
disp('충전 데이터가 저장되었습니다: Charge_OCV_vs_SOC.xlsx');

% 그래프 그리기
figure;
plot(discharge_SOC, discharge_OCV, 'r', 'LineWidth', 1.5); % 방전
hold on;
plot(charge_SOC, charge_OCV, 'b', 'LineWidth', 1.5);       % 충전
hold off;

% 그래프 설정
xlabel('SOC');
ylabel('OCV (V)');
title('OCV vs SOC (Charge and Discharge)');
legend('Discharge', 'Charge', 'Location', 'best');
grid on;

% 그래프 저장
outputGraphFile = 'OCV_vs_SOC_Charge_and_Discharge.png';
saveas(gcf, outputGraphFile);

disp(['OCV vs SOC 그래프가 저장되었습니다: ', outputGraphFile]);
