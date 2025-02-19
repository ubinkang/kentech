clc; clear; close all;

%% 1. MAT 파일 불러오기
matFileName = '05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat';
matData = load(matFileName);

% 불러온 변수명 확인
vars = fieldnames(matData);
fprintf('불러온 변수들:\n');
disp(vars);

%% 2. 저장할 Excel 파일 이름 설정 (MAT 파일 이름과 동일하게)
[~, baseName, ~] = fileparts(matFileName);  % 예: "03-11-17_08.25 3390_TS003014"
excelFileName = [baseName, '.xlsx'];         % 예: "03-11-17_08.25 3390_TS003014.xlsx"

% 기존에 같은 이름의 Excel 파일이 있으면 삭제 (덮어쓰기)
if isfile(excelFileName)
    delete(excelFileName);
end

%% 3. 각 변수를 Excel 파일의 개별 시트에 저장
% MATLAB R2019a 이상에서는 writetable, writematrix 함수를 사용할 수 있습니다.
for i = 1:length(vars)
    varName = vars{i};
    varData = matData.(varName);
    
    % 시트 이름은 변수명과 동일하게 설정
    try
        if istable(varData)
            writetable(varData, excelFileName, 'Sheet', varName);
            fprintf('테이블 변수 "%s"를 시트 "%s"에 저장하였습니다.\n', varName, varName);
            
        elseif isstruct(varData)
            % 구조체인 경우, 필드들이 모두 동일하다면 struct2table로 변환 가능
            try
                tbl = struct2table(varData);
                writetable(tbl, excelFileName, 'Sheet', varName);
                fprintf('구조체 변수 "%s"를 시트 "%s"에 저장하였습니다.\n', varName, varName);
            catch ME
                warning('구조체 변수 "%s"를 테이블로 변환하는데 실패하였습니다.\n오류 메시지: %s', varName, ME.message);
            end
            
        elseif isnumeric(varData)
            writematrix(varData, excelFileName, 'Sheet', varName);
            fprintf('숫자 행렬 변수 "%s"를 시트 "%s"에 저장하였습니다.\n', varName, varName);
            
        else
            warning('변수 "%s"의 타입은 Excel로 바로 저장할 수 없는 형태입니다.', varName);
        end
    catch ME
        warning('변수 "%s" 저장 중 오류 발생: %s', varName, ME.message);
    end
end

fprintf('모든 변수의 Excel 저장이 완료되었습니다. 저장 파일: %s\n', excelFileName);
