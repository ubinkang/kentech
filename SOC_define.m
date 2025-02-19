% 1. 파일 불러오기
data = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_cumQ_added.mat');

% 2. 필요한 데이터 가져오기
cumQ = data.meas.cumQ;  % 누적 충전 및 방전량 데이터
step = data.meas.step;  % 스텝 데이터
time = data.meas.Time;  % 시간 데이터 (60초 간격)

% 3. 초기 SOC 설정
SOC = zeros(size(cumQ));
SOC(1) = 0.9907;  % 초기 SOC 값 설정

% 4. 총 방전량 및 충전량 (최종 값)
total_Q_discharge = max(cumQ(step == 2)) - min(cumQ(step == 2));  % 방전 구간 최대 - 최소
total_Q_charge = max(cumQ(step == 4)) - min(cumQ(step == 4));      % 충전 구간 최대 - 최소

% 5. SOC 계산 (방전 시 감소, 충전 시 증가)
for i = 2:length(cumQ)
    if step(i) == 2  % 방전 과정 (SOC 감소)
        dQ = abs(cumQ(i) - cumQ(i-1));
        SOC(i) = SOC(i-1) - (dQ / total_Q_discharge);
    elseif step(i) == 4  % 충전 과정 (SOC 증가)
        dQ = abs(cumQ(i) - cumQ(i-1));
        SOC(i) = SOC(i-1) + (dQ / total_Q_charge);
    else
        SOC(i) = SOC(i-1);  % 나머지 구간에서는 SOC 유지
    end

    % SOC 범위 제한 (0~1)
    SOC(i) = max(0, min(SOC(i), 1));
end

% 6. 결과 저장
data.meas.SOC = SOC;

% 7. 변경된 데이터를 새로운 MAT 파일로 저장
save('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat', '-struct', 'data');

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
plot(time / 60, step, 'b');
title('Step vs Time');
xlabel('Time (min)');
ylabel('Step');
grid on;
