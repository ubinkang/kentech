% 1. 파일 불러오기
data = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');

% 2. 데이터 추출
time = data.meas.Time;          % 시간 (60초 단위)
current = data.meas.Current;    % 전류 데이터 (A)
step = data.meas.step;          % 스텝 데이터
Q_discharge = data.meas.Q_discharge;  % 방전량 (Ah)
Q_charge = data.meas.Q_charge;        % 충전량 (Ah)
SOC = data.meas.SOC;            % SOC 값

% 3. 데이터 테이블 생성
T = table(time, current, step, Q_discharge, Q_charge, SOC);

% 4. 엑셀 파일로 저장
filename = '05-08-17_13.26_C20_OCV_Test_C20_25dC_with_SOC.xlsx';
writetable(T, filename, 'Sheet', 1);

% 5. 저장 완료 메시지 출력
disp(['Data successfully saved to ', filename]);

% 6. 시각화 확인
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
