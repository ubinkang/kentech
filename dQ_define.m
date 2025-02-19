% 1. 파일 불러오기
data = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_cumQ.mat');

% 2. 필요한 데이터 가져오기
current = data.meas.Current;  % 전류 데이터 (A)
time = data.meas.Time;        % 시간 데이터 (60초 간격)
step = data.meas.step;        % 스텝 데이터

% 3. 총 방전량 및 충전량 계산
total_Q_discharge = sum(abs(current(step == 2)) * 60 / 3600);  % Ah 단위 변환
total_Q_charge = sum(abs(current(step == 4)) * 60 / 3600);      % Ah 단위 변환

% 4. cumQ 데이터 초기화 (초기값은 총 방전량)
cumQ = zeros(size(current));
cumQ(1) = total_Q_discharge;  % 초기값 설정

% 5. 시간 간격 설정 (60초 간격 적용)
dt = 60;  % 각 샘플 간의 시간 간격이 60초

% 6. 누적 Q 계산 (방전 시 감소, 충전 시 증가)
for i = 2:length(current)
    if step(i) == 2  % 방전 과정 (누적 감소)
        cumQ(i) = cumQ(i-1) - abs(current(i) * dt / 3600);  % Ah 단위 변환
    elseif step(i) == 4  % 충전 과정 (누적 증가)
        cumQ(i) = cumQ(i-1) + abs(current(i) * dt / 3600);
    else  % 나머지 과정 (Rest)에서는 그대로 유지
        cumQ(i) = cumQ(i-1);
    end
end

% 7. 새로운 cumQ 데이터를 원래 데이터에 추가
data.meas.cumQ = cumQ;

% 8. 변경된 데이터를 새로운 MAT 파일로 저장
new_filename = '05-08-17_13.26 C20 OCV Test_C20_25dC_with_cumQ_added.mat';
save(new_filename, '-struct', 'data');

% 9. 결과 출력
disp(['New MAT file with cumQ added successfully saved as: ', new_filename]);

% 10. 시각화 확인
figure;
subplot(2,1,1);
plot(time / 60, cumQ, 'm', 'LineWidth', 1.5);
title('Cumulative Q (cumQ) vs Time');
xlabel('Time (min)');
ylabel('cumQ (Ah)');
grid on;

subplot(2,1,2);
plot(time / 60, current, 'b');
title('Current vs Time');
xlabel('Time (min)');
ylabel('Current (A)');
grid on;
