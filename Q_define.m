% 1. 파일 불러오기
data = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_Q.mat');

% 2. 필요한 데이터 가져오기
current = data.meas.Current;  % 전류 데이터 (A)
time = data.meas.Time;        % 시간 데이터 (60초 간격)
step = data.meas.step;        % 스텝 데이터

% 3. 방전 및 충전량(Q) 초기화
Q_discharge = zeros(size(current));
Q_charge = zeros(size(current));

% 4. 시간 간격 설정 (60초 간격 적용)
dt = 60;  % 60초 단위 시간 간격

% 5. 방전 과정 (Step 2) - Ah 단위 변환 (60초 간격 적용)
discharge_indices = (step == 2);
Q_discharge(discharge_indices) = -cumtrapz(current(discharge_indices) * dt / 3600);  % Ah 단위 변환
Q_discharge(~discharge_indices) = 0;  % 나머지 구간은 0으로 처리

% 6. 충전 과정 (Step 4) - Ah 단위 변환 (60초 간격 적용)
charge_indices = (step == 4);
Q_charge(charge_indices) = cumtrapz(current(charge_indices) * dt / 3600);  % Ah 단위 변환
Q_charge(~charge_indices) = 0;  % 나머지 구간은 0으로 처리

% 7. 누적 방전량과 충전량 계산 (양수값으로 저장)
Q_discharge = abs(Q_discharge);
Q_charge = abs(Q_charge);

% 8. 총 방전량 및 충전량 계산
total_Q_discharge = Q_discharge(find(discharge_indices, 1, 'last'));  % 최종 방전량
total_Q_charge = Q_charge(find(charge_indices, 1, 'last'));  % 최종 충전량

% 9. 결과 저장
data.meas.Q_discharge = Q_discharge;
data.meas.Q_charge = Q_charge;

% 10. 변경된 데이터를 새로운 MAT 파일로 저장
save('05-08-17_13.26 C20 OCV Test_C20_25dC_corrected.mat', '-struct', 'data');

% 11. 총 방전량 및 충전량 출력
disp(['Total Discharge Q: ', num2str(total_Q_discharge, '%.4f'), ' Ah']);
disp(['Total Charge Q: ', num2str(total_Q_charge, '%.4f'), ' Ah']);

% 12. 시각화 확인
figure;
subplot(3,1,1);
plot(time / 3600, current);
title('Current vs Time');
xlabel('Time (h)');
ylabel('Current (A)');
grid on;

subplot(3,1,2);
plot(time / 3600, Q_discharge, 'b');
title(['Discharge Q vs Time (Total: ', num2str(total_Q_discharge, '%.4f'), ' Ah)']);
xlabel('Time (h)');
ylabel('Q Discharge (Ah)');
grid on;

subplot(3,1,3);
plot(time / 3600, Q_charge, 'r');
title(['Charge Q vs Time (Total: ', num2str(total_Q_charge, '%.4f'), ' Ah)']);
xlabel('Time (h)');
ylabel('Q Charge (Ah)');
grid on;
