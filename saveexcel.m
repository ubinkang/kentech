clc; clear; close all;

%% 1. .mat 파일 불러오기
matFileName = 'MergedData.mat';
matData = load(matFileName);

% 불러온 변수명 확인
vars = fieldnames(matData);
fprintf('불러온 변수들:\n');
disp(vars);

%% 2. 각 변수를 Excel 파일로 저장
% MATLAB R2019a 이상에서는 writetable, writematrix 함수 사용 가능
for i = 1:length(vars)
    varName = vars{i};
    varData = matData.(varName);
    
    % 저장할 파일 이름 (예: 변수명이 "data"이면 data.xlsx)
    excelFileName = sprintf('%s.xlsx', varName);
    
    % 변수의 타입에 따라 저장 방법 선택
    if istable(varData)
        % 이미 테이블인 경우 바로 저장
        writetable(varData, excelFileName);
        fprintf('테이블 변수 "%s"를 "%s"로 저장하였습니다.\n', varName, excelFileName);
        
    elseif isstruct(varData)
        % 구조체인 경우, 가능한 경우 struct2table을 사용하여 테이블로 변환
        try
            tbl = struct2table(varData);
            writetable(tbl, excelFileName);
            fprintf('구조체 변수 "%s"를 테이블로 변환하여 "%s"로 저장하였습니다.\n', varName, excelFileName);
        catch ME
            warning('구조체 변수 "%s"를 테이블로 변환하는데 실패하였습니다.\n오류 메시지: %s', varName, ME.message);
        end
        
    elseif isnumeric(varData)
        % 숫자 행렬인 경우
        try
            writematrix(varData, excelFileName);
            fprintf('숫자 행렬 변수 "%s"를 "%s"로 저장하였습니다.\n', varName, excelFileName);
        catch ME
            warning('숫자 행렬 변수 "%s"를 저장하는데 실패하였습니다.\n오류 메시지: %s', varName, ME.message);
        end
        
    else
        warning('변수 "%s"의 타입은 Excel로 바로 저장할 수 없는 형태입니다.', varName);
    end
end

fprintf('모든 변수의 Excel 파일 저장이 완료되었습니다.\n');
