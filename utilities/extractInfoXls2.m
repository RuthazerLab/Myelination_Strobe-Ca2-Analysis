%{
function to extract experiment info from input xls file
output table of experiment info

read example: inputT.Date(2)

%}

function [expInfo,columnheads] = extractInfoXls2(xlsinput)

[~,~,raw] = xlsread(xlsinput);
columnheads = {raw{1,:}};

expInfo = cell2table(raw(2:end,:));
expInfo.Properties.VariableNames = columnheads;

end