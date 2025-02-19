% 1. 파일 불러오기
data = load('03-21-17_00.29 25degC_UDDS_Pan18650PF.mat');

% 2. 필요한 데이터 가져오기
current = data.meas.Current;  % 전류 데이터 (A)
time = data.meas.Time;        % 시간 데이터 (초 단위)

% 3. 초기 SOC 및 Q 설정
SOC = zeros(size(current));
SOC(1) = 0.9907;  % 초기 SOC 값
Q_initial = 2.9596;  % 초기 전하량 (Ah)

% 4. 시간 간격 설정 (초 단위 데이터 처리)
dt = diff(time);
dt = [dt; dt(end)];  % 마지막 간격을 유지

% 5. SOC 계산 (전류 적분 기반, 충방전 구분)
for i = 2:length(current)
    dQ = current(i) * dt(i) / 3600;  % Ah 단위 변환 (초 -> 시간)
    
    if current(i) < 0  % 방전 과정 (전류가 음수 -> SOC 감소)
        SOC(i) = SOC(i-1) - abs(dQ / Q_initial);
    elseif current(i) > 0  % 충전 과정 (전류가 양수 -> SOC 증가)
        SOC(i) = SOC(i-1) + abs(dQ / Q_initial);
    else  % 전류가 0일 경우 SOC 유지
        SOC(i) = SOC(i-1);
    end

    % SOC 범위 제한 (0~1)
    SOC(i) = max(0, min(SOC(i), 1));
end

% 6. 데이터에 SOC 추가
data.meas.SOC = SOC;

% 7. 변경된 데이터를 새로운 MAT 파일로 저장
save('03-21-17_00.29 25degC_UDDS_Pan18650PF_with_SOC.mat', '-struct', 'data');

% 8. 결과 출력
disp('SOC data successfully added to the MAT file.');

% 9. 시각화 확인
figure;
subplot(2,1,1);
plot(time / 60, SOC, 'g', 'LineWidth', 1.5);
title('SOC vs Time');
xlabel('Time (min)');
ylabel('SOC');
ylim([0 1]);
grid on;

subplot(2,1,2);
plot(time / 60, current, 'b');
title('Current vs Time');
xlabel('Time (min)');
ylabel('Current (A)');
grid on;
