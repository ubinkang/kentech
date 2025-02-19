% 1. 엑셀 파일 불러오기
T = readtable('Step_Data.xlsx');

% 2. 0.5C Step만 추출
T_05C = T(strcmp(T.Step, '0.5C'), :);  % "0.5C" Step을 포함하는 행만 선택

% 3. 0.5C Step 데이터만 새로운 엑셀 파일로 저장
writetable(T_05C, 'Step_Data_0.5C.xlsx', 'Sheet', '0.5C_Only');

% 4. V vs Time 그래프 시각화 (0.5C Step만)
figure;
plot(T_05C.Time, T_05C.Voltage, 'b-', 'LineWidth', 1.5);
title('V vs Time (0.5C Step Only)');
xlabel('Time (s)');
ylabel('Voltage (V)');
grid on;
legend('V vs Time for 0.5C');

% 5. 결과 출력
disp('0.5C Step data successfully extracted and saved to Step_Data_0.5C.xlsx');
disp('V vs Time (0.5C Step Only) plot generated successfully.');
