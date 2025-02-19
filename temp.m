% 1. 파일 불러오기
data = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');

% 2. 필요한 데이터 가져오기
Q_discharge = data.meas.Q_discharge;  % 방전량 데이터
Q_charge = data.meas.Q_charge;        % 충전량 데이터
step = data.meas.step;                 % 스텝 데이터
time = data.meas.Time;                  % 시간 데이터 (60초 간격)

% 3. cumQ 데이터 생성
cumQ = zeros(size(Q_discharge));

% 방전 과정에서는 Q_discharge 값을 적용 (음수로 저장)
cumQ(step == 2) = -Q_discharge(step == 2);

% 충전 과정에서는 Q_charge 값을 적용 (양수로 저장)
cumQ(step == 4) = Q_charge(step == 4);

% 나머지 구간은 이전 상태 유지
for i = 2:length(cumQ)
    if step(i) == 2  % 방전 시
        cumQ(i) = cumQ(i-1) - abs(Q_discharge(i) - Q_discharge(i-1));
    elseif step(i) == 4  % 충전 시
        cumQ(i) = cumQ(i-1) + abs(Q_charge(i) - Q_charge(i-1));
    else
        cumQ(i) = cumQ(i-1);  % 나머지 구간은 그대로 유지
    end
end

% 4. 새로운 데이터 추가
data.meas.cumQ = cumQ;

% 5. 변경된 데이터를 새로운 MAT 파일로 저장
save('05-08-17_13.26 C20 OCV Test_C20_25dC_with_cumQ.mat', '-struct', 'data');

% 6. 엑셀 파일로 저장
T = table(time, data.meas.Current, step, Q_discharge, Q_charge, cumQ, data.meas.SOC);
writetable(T, '05-08-17_13.26_C20_OCV_Test_C20_25dC_with_cumQ.xlsx', 'Sheet', 1);

% 7. 결과 출력
disp('cumQ data successfully added and saved to the MAT and Excel file.');

% 8. 시각화 확인
figure;
subplot(2,1,1);
plot(time / 60, cumQ, 'm', 'LineWidth', 1.5);
title('Cumulative Q (cumQ) vs Time');
xlabel('Time (min)');
ylabel('cumQ (Ah)');
grid on;

subplot(2,1,2);
plot(time / 60, step, 'b');
title('Step vs Time');
xlabel('Time (min)');
ylabel('Step');
grid on;
