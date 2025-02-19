% 1. 파일 불러오기
data = load('05-08-17_13.26 C20 OCV Test_C20_25dC_updated.mat');

% 2. step 데이터 불러오기
step = data.meas.step;

% 3. state 배열 초기화 (문자열 배열로 생성)
state = strings(size(step));

% 4. step 별 state 정의
state(step == 1 | step == 3 | step == 5) = "Rest";      % Step 1, 3, 5 -> Rest
state(step == 2) = "Discharge";                         % Step 2 -> Discharge
state(step == 4) = "Charge";                            % Step 4 -> Charge

% 5. state 데이터를 meas 구조체에 추가
data.meas.state = state;

% 6. 변경된 데이터를 새로운 MAT 파일로 저장
save('05-08-17_13.26 C20 OCV Test_C20_25dC_final.mat', '-struct', 'data');

% 7. 결과 확인을 위한 state 데이터 출력
disp('State data successfully added to the MAT file.');

% 8. 시각화 확인 (step과 state 시각적으로 확인)
figure;
subplot(2,1,1);
plot(data.meas.Time, step);
title('Step vs Time');
xlabel('Time');
ylabel('Step');
grid on;

subplot(2,1,2);
unique_states = unique(state);
state_numeric = double(categorical(state, unique_states));
plot(data.meas.Time, state_numeric);
title('State vs Time');
xlabel('Time');
ylabel('State');
yticks(1:length(unique_states));
yticklabels(unique_states);
grid on;
