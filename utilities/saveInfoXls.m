%{
saveInfoXls
append input data variables to existing Excel data sheet
input: Excel datasheet filepath, cell array of variables to append
%}

function saveInfoXls(xlslog,Tnew_table)
[~,~,raw] = xlsread(xlslog);
columnheads = {raw{1,:}};
expInfo = cell2table(raw(2:end,:));
expInfo.Properties.VariableNames = columnheads;
Tnew_table.Properties.VariableNames = columnheads;
if width(Tnew_table) ~= width(expInfo)
    error('Append table dimension mismatch!');
    return
else
    expInfo = [expInfo;Tnew_table];
    outcell = table2cell(expInfo);
    outcell = [columnheads;outcell];
    
    xlswrite(xlslog,outcell);

end